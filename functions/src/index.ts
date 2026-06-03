import * as admin from 'firebase-admin';
import { HttpsError, onCall } from 'firebase-functions/v2/https';
import { logger } from 'firebase-functions/v2';

admin.initializeApp();

type TenantPayload = {
  businessName: string;
  industryType: string;
  country?: string;
  city?: string;
  ownerName: string;
  ownerEmail: string;
  ownerPhone: string;
  ownerPassword: string;
  selectedPlan: string;
  limits: {
    maxBranches: number;
    maxUsers: number;
    maxOrdersPerMonth: number;
    storageLimitMb: number;
  };
  featureFlags: {
    qrOrderingEnabled: boolean;
    onlineOrderingEnabled: boolean;
    customerAppEnabled: boolean;
    hotelModuleEnabled: boolean;
    inventoryModuleEnabled: boolean;
  };
};

export const createBusinessTenant = onCall({ cors: true }, async (request) => {
  const caller = request.auth;
  if (!caller) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const callerEmail = (caller.token.email as string | undefined)?.toLowerCase() ?? '';
  const isSuperAdmin =
    caller.token.superAdmin === true ||
    callerEmail.endsWith('@robologicx.com') ||
    await isAllowlistedSuperAdmin(admin.firestore(), caller.uid, callerEmail);
  if (!isSuperAdmin) {
    throw new HttpsError('permission-denied', 'Only super admins can create tenants.');
  }

  const payload = request.data as TenantPayload;
  validatePayload(payload);

  const db = admin.firestore();
  const auth = admin.auth();

  const now = admin.firestore.Timestamp.now();
  const plan = payload.selectedPlan.trim();
  const expiryDays = plan.toLowerCase() === 'trial' ? 14 : 30;
  const expiryDate = admin.firestore.Timestamp.fromMillis(Date.now() + expiryDays * 24 * 60 * 60 * 1000);

  const businessId = await nextBusinessId(db);
  const branchId = 'BR01';

  let ownerRecord: admin.auth.UserRecord | null = null;

  try {
    ownerRecord = await auth.createUser({
      email: payload.ownerEmail.trim().toLowerCase(),
      password: payload.ownerPassword,
      displayName: payload.ownerName.trim(),
      disabled: false,
    });

    const ownerUid = ownerRecord.uid;

    // Assign tenant context claims for owner login segregation.
    await auth.setCustomUserClaims(ownerUid, {
      tenantId: businessId,
      role: 'owner',
      superAdmin: false,
    });

    const businessRef = db.collection('businesses').doc(businessId);
    const branchRef = businessRef.collection('branches').doc(branchId);
    const branchUserRef = branchRef.collection('users').doc(ownerUid);
    const subscriptionRef = businessRef.collection('subscriptions').doc('current');
    const settingsRef = businessRef.collection('settings').doc('default');
    const platformSubRef = db.collection('platform_subscriptions').doc(businessId);
    const rootUserRef = db.collection('users').doc(ownerUid);

    const batch = db.batch();

    batch.set(
      businessRef,
      {
        id: businessId,
        tenantId: businessId,
        title: payload.businessName.trim(),
        title_lower: payload.businessName.trim().toLowerCase(),
        ownerId: ownerUid,
        ownerName: payload.ownerName.trim(),
        ownerEmail: payload.ownerEmail.trim().toLowerCase(),
        ownerPhone: payload.ownerPhone.trim(),
        industryType: payload.industryType.trim(),
        country: (payload.country ?? '').trim(),
        city: (payload.city ?? '').trim(),
        branchesCount: 1,
        usersCount: 1,
        subscriptionPlan: plan,
        subscriptionExpiry: expiryDate,
        monthlyRevenue: 0,
        totalOrders: 0,
        status: 'active',
        isActive: true,
        isDeleted: false,
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );

    batch.set(
      branchRef,
      {
        id: branchId,
        name: 'Main Branch',
        name_lower: 'main branch',
        tenantId: businessId,
        businessId,
        isDefault: true,
        isActive: true,
        country: (payload.country ?? '').trim(),
        city: (payload.city ?? '').trim(),
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );

    batch.set(
      branchUserRef,
      {
        uid: ownerUid,
        roleId: 'owner',
        roleName: 'Owner',
        extraPermissions: {},
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );

    batch.set(
      rootUserRef,
      {
        uid: ownerUid,
        name: payload.ownerName.trim(),
        email: payload.ownerEmail.trim().toLowerCase(),
        phoneNumber: payload.ownerPhone.trim(),
        primarybusinessId: businessId,
        primaryBranchId: branchId,
        isStaffMember: true,
        roleName: 'Owner',
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );

    batch.set(
      subscriptionRef,
      {
        businessId,
        planName: plan,
        status: 'active',
        billingModel: plan.toLowerCase() === 'custom' ? 'custom' : 'monthly',
        startDate: now,
        expiryDate,
        limits: payload.limits,
        featureFlags: payload.featureFlags,
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );

    batch.set(
      platformSubRef,
      {
        businessId,
        businessName: payload.businessName.trim(),
        ownerEmail: payload.ownerEmail.trim().toLowerCase(),
        planName: plan,
        status: 'active',
        startDate: now,
        expiryDate,
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );

    batch.set(
      settingsRef,
      {
        businessId,
        platformBrand: 'RoboLogicx',
        currencyCode: 'PKR',
        taxPercent: 0,
        timezone: 'Asia/Karachi',
        createdAt: now,
        updatedAt: now,
      },
      { merge: true },
    );

    await batch.commit();
    await refreshOverviewCounters(db);

    // Welcome email placeholder event (to be handled by SMTP/SendGrid worker function)
    await db.collection('mail_queue').add({
      type: 'welcome_owner',
      to: payload.ownerEmail.trim().toLowerCase(),
      subject: `Welcome to RoboLogicx - ${payload.businessName}`,
      template: 'welcome_owner',
      context: {
        businessId,
        businessName: payload.businessName.trim(),
        ownerName: payload.ownerName.trim(),
        plan,
      },
      status: 'queued',
      createdAt: now,
      updatedAt: now,
    });

    logger.info('Business tenant created', { businessId, ownerUid });

    return {
      success: true,
      businessId,
      ownerUid,
      branchId,
      message: 'Tenant created successfully.',
    };
  } catch (error) {
    logger.error('createBusinessTenant failed', error as Error);

    if (ownerRecord) {
      try {
        await auth.deleteUser(ownerRecord.uid);
      } catch (cleanupError) {
        logger.error('Rollback failed: could not delete owner auth user', cleanupError as Error);
      }
    }

    throw new HttpsError('internal', 'Failed to create tenant.');
  }
});

async function isAllowlistedSuperAdmin(
  db: admin.firestore.Firestore,
  uid: string,
  email: string,
): Promise<boolean> {
  if (email === 'info.robologicx@gmail.com') {
    return true;
  }

  const doc = await db.collection('super_admins').doc(uid).get();
  if (!doc.exists) {
    return false;
  }

  const data = doc.data() ?? {};
  return data.isActive === true;
}

function validatePayload(payload: TenantPayload): void {
  if (!payload || typeof payload !== 'object') {
    throw new HttpsError('invalid-argument', 'Payload is required.');
  }

  const required = [
    ['businessName', payload.businessName],
    ['industryType', payload.industryType],
    ['ownerName', payload.ownerName],
    ['ownerEmail', payload.ownerEmail],
    ['ownerPhone', payload.ownerPhone],
    ['ownerPassword', payload.ownerPassword],
    ['selectedPlan', payload.selectedPlan],
  ] as const;

  for (const [name, value] of required) {
    if (!value || !String(value).trim()) {
      throw new HttpsError('invalid-argument', `${name} is required.`);
    }
  }

  const email = payload.ownerEmail.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpsError('invalid-argument', 'ownerEmail is invalid.');
  }

  if (payload.ownerPassword.length < 6) {
    throw new HttpsError('invalid-argument', 'ownerPassword must be at least 6 characters.');
  }

  if (!payload.limits || !payload.featureFlags) {
    throw new HttpsError('invalid-argument', 'limits and featureFlags are required.');
  }
}

async function nextBusinessId(db: admin.firestore.Firestore): Promise<string> {
  const counterRef = db.collection('platform').doc('counters');

  const nextNumber = await db.runTransaction(async (tx) => {
    const snap = await tx.get(counterRef);
    const current = Number((snap.data()?.businessCounter ?? 1000));
    const next = current + 1;
    tx.set(
      counterRef,
      {
        businessCounter: next,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return next;
  });

  return `RLX${nextNumber}`;
}

async function refreshOverviewCounters(db: admin.firestore.Firestore): Promise<void> {
  const allBusinesses = await db.collection('businesses').get();

  let active = 0;
  let suspended = 0;
  let expired = 0;
  let branches = 0;
  let users = 0;

  const now = Date.now();

  for (const doc of allBusinesses.docs) {
    const data = doc.data();
    const status = String(data.status ?? 'active').toLowerCase();
    if (status === 'active') active += 1;
    if (status === 'suspended') suspended += 1;

    const expiryRaw = data.subscriptionExpiry;
    const expiryMs = expiryRaw instanceof admin.firestore.Timestamp ? expiryRaw.toMillis() : 0;
    if (expiryMs > 0 && expiryMs < now) expired += 1;

    branches += Number(data.branchesCount ?? 0);
    users += Number(data.usersCount ?? 0);
  }

  await db.collection('platform').doc('overview').set(
    {
      totalBusinesses: allBusinesses.size,
      activeBusinesses: active,
      suspendedBusinesses: suspended,
      expiredSubscriptions: expired,
      totalBranches: branches,
      totalStaffUsers: users,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}
