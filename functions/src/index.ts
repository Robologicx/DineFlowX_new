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

type BranchStaffPayload = {
  businessId: string;
  branchId: string;
  email: string;
  password: string;
  name?: string;
  phoneNumber?: string;
  roleId: string;
  roleName?: string;
  extraPermissions?: Record<string, string>;
};

type UpdateBranchStaffPayload = {
  businessId: string;
  branchId: string;
  uid: string;
  roleId: string;
  roleName?: string;
  extraPermissions?: Record<string, string>;
  name?: string;
  phoneNumber?: string;
};

type DeleteBranchStaffPayload = {
  businessId: string;
  branchId: string;
  uid: string;
};

type ToggleUserActivationPayload = {
  uid: string;
  isActive: boolean;
};

type DeletePlatformUserPayload = {
  uid: string;
};

type SendPlatformAnnouncementPayload = {
  title: string;
  message: string;
  targetType: 'all' | 'selected';
  targetBusinessIds?: string[];
  channels?: {
    inApp?: boolean;
    push?: boolean;
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

export const createBranchStaffUser = onCall({ cors: true }, async (request) => {
  const caller = request.auth;
  if (!caller) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const payload = request.data as BranchStaffPayload;
  validateBranchStaffPayload(payload);

  const businessId = payload.businessId.trim();
  const branchId = payload.branchId.trim();
  const email = payload.email.trim().toLowerCase();
  const password = payload.password;
  const displayName = (payload.name ?? '').trim();
  const roleId = payload.roleId.trim();
  const roleName = (payload.roleName ?? '').trim();
  const phoneNumber = (payload.phoneNumber ?? '').trim();
  const extraPermissions = payload.extraPermissions ?? {};

  const db = admin.firestore();
  const auth = admin.auth();

  const isSuperAdmin =
    caller.token.superAdmin === true ||
    await isAllowlistedSuperAdmin(db, caller.uid, (caller.token.email as string | undefined)?.toLowerCase() ?? '');

  if (!isSuperAdmin) {
    const callerRootUser = await db.collection('users').doc(caller.uid).get();
    const callerBusinessId = String(callerRootUser.data()?.primarybusinessId ?? '').trim();
    if (callerBusinessId.length === 0 || callerBusinessId !== businessId) {
      throw new HttpsError('permission-denied', 'You can only create staff for your own business.');
    }
  }

  const branchRef = db
    .collection('businesses')
    .doc(businessId)
    .collection('branches')
    .doc(branchId);
  const branchDoc = await branchRef.get();
  if (!branchDoc.exists) {
    throw new HttpsError('not-found', 'Branch not found.');
  }

  let userRecord: admin.auth.UserRecord | null = null;
  let createdAuthUser = false;

  try {
    try {
      userRecord = await auth.getUserByEmail(email);
    } catch {
      userRecord = null;
    }

    if (!userRecord) {
      userRecord = await auth.createUser({
        email,
        password,
        displayName: displayName || undefined,
        disabled: false,
      });
      createdAuthUser = true;
    }

    const existingRootUser = await db.collection('users').doc(userRecord.uid).get();
    const existingBusinessId = String(existingRootUser.data()?.primarybusinessId ?? '').trim();
    if (existingBusinessId.length > 0 && existingBusinessId !== businessId) {
      throw new HttpsError(
        'permission-denied',
        'This staff account is already linked to another business.',
      );
    }

    await auth.setCustomUserClaims(userRecord.uid, {
      tenantId: businessId,
      role: 'staff',
      superAdmin: false,
    });

    const now = admin.firestore.Timestamp.now();
    const rootUserRef = db.collection('users').doc(userRecord.uid);
    const branchUserRef = db
      .collection('businesses')
      .doc(businessId)
      .collection('branches')
      .doc(branchId)
      .collection('users')
      .doc(userRecord.uid);

    const batch = db.batch();

    batch.set(
      rootUserRef,
      {
        uid: userRecord.uid,
        email,
        name: displayName,
        phoneNumber: phoneNumber || null,
        primarybusinessId: businessId,
        primaryBranchId: branchId,
        isStaffMember: true,
        roleName: roleName || roleId,
        updatedAt: now,
        createdAt: existingRootUser.exists ? existingRootUser.data()?.createdAt ?? now : now,
      },
      { merge: true },
    );

    batch.set(
      branchUserRef,
      {
        uid: userRecord.uid,
        email,
        name: displayName,
        phoneNumber: phoneNumber || null,
        roleId,
        roleName: roleName || roleId,
        extraPermissions,
        isStaffMember: true,
        primarybusinessId: businessId,
        primaryBranchId: branchId,
        updatedAt: now,
        createdAt: now,
      },
      { merge: true },
    );

    await batch.commit();

    return {
      success: true,
      uid: userRecord.uid,
      email,
    };
  } catch (error) {
    logger.error('createBranchStaffUser failed', error as Error);

    const errorCode = (
      error && typeof error === 'object' && 'code' in error
        ? String((error as { code?: unknown }).code ?? '')
        : ''
    ).toLowerCase();

    const errorMessage = (
      error && typeof error === 'object' && 'message' in error
        ? String((error as { message?: unknown }).message ?? '')
        : ''
    ).trim();

    if (errorCode === 'auth/email-already-exists' || errorCode.includes('email-already-exists')) {
      throw new HttpsError('already-exists', 'A user with this email already exists.');
    }

    if (errorCode.includes('invalid-password') || errorCode.includes('weak-password')) {
      throw new HttpsError('invalid-argument', 'Password must be at least 6 characters.');
    }

    if (errorCode.includes('insufficient-permission')) {
      throw new HttpsError('permission-denied', 'Function service account lacks Firebase Auth permissions.');
    }

    if (createdAuthUser && userRecord != null) {
      try {
        await auth.deleteUser(userRecord.uid);
      } catch (cleanupError) {
        logger.error('createBranchStaffUser rollback failed', cleanupError as Error);
      }
    }

    if (error instanceof HttpsError) {
      throw error;
    }

    throw new HttpsError(
      'internal',
      errorMessage.length > 0 ? errorMessage : 'Failed to create staff login account.',
    );
  }
});

export const updateBranchStaffUser = onCall({ cors: true }, async (request) => {
  const caller = request.auth;
  if (!caller) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const payload = request.data as UpdateBranchStaffPayload;
  validateUpdateBranchStaffPayload(payload);

  const businessId = payload.businessId.trim();
  const branchId = payload.branchId.trim();
  const uid = payload.uid.trim();
  const requestedRoleId = payload.roleId.trim();
  const roleName = (payload.roleName ?? '').trim();
  const name = (payload.name ?? '').trim();
  const phoneNumber = (payload.phoneNumber ?? '').trim();
  const extraPermissions = payload.extraPermissions ?? {};

  const db = admin.firestore();

  const isSuperAdmin =
    caller.token.superAdmin === true ||
    await isAllowlistedSuperAdmin(
      db,
      caller.uid,
      (caller.token.email as string | undefined)?.toLowerCase() ?? '',
    );

  if (!isSuperAdmin) {
    const callerRootUser = await db.collection('users').doc(caller.uid).get();
    const callerBusinessId = String(callerRootUser.data()?.primarybusinessId ?? '').trim();
    if (callerBusinessId.length === 0 || callerBusinessId !== businessId) {
      throw new HttpsError('permission-denied', 'You can only update staff for your own business.');
    }
  }

  const branchUserRef = db
    .collection('businesses')
    .doc(businessId)
    .collection('branches')
    .doc(branchId)
    .collection('users')
    .doc(uid);

  const rootUserRef = db.collection('users').doc(uid);

  const branchUserSnap = await branchUserRef.get();
  if (!branchUserSnap.exists) {
    throw new HttpsError('not-found', 'Staff member not found in branch.');
  }

  let effectiveRoleId = requestedRoleId;
  let roleDoc = await db
    .collection('businesses')
    .doc(businessId)
    .collection('branches')
    .doc(branchId)
    .collection('roles')
    .doc(effectiveRoleId)
    .get();

  if (!roleDoc.exists) {
    const requestedRoleName = requestedRoleId.toLowerCase();
    if (requestedRoleName.length > 0) {
      const rolesSnap = await db
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('roles')
        .get();

      for (const doc of rolesSnap.docs) {
        const candidateName = String(doc.data().name ?? '').trim().toLowerCase();
        if (candidateName === requestedRoleName) {
          roleDoc = doc;
          effectiveRoleId = doc.id;
          break;
        }
      }
    }
  }

  if (!roleDoc.exists) {
    throw new HttpsError('not-found', 'Selected role does not exist.');
  }

  const roleData = roleDoc.data() ?? {};
  const now = admin.firestore.Timestamp.now();

  const resolvedRoleName = roleName || String(roleData.name ?? effectiveRoleId);
  const rolePayload = {
    id: effectiveRoleId,
    businessId,
    name: resolvedRoleName,
    permissions: Array.isArray(roleData.permissions) ? roleData.permissions : [],
    createdAt: roleData.createdAt ?? now,
    updatedAt: now,
  };

  const batch = db.batch();

  batch.set(
    branchUserRef,
    {
      roleId: effectiveRoleId,
      roleName: resolvedRoleName,
      extraPermissions,
      ...(name ? { name } : {}),
      ...(phoneNumber ? { phoneNumber } : {}),
      updatedAt: now,
    },
    { merge: true },
  );

  batch.set(
    rootUserRef,
    {
      primarybusinessId: businessId,
      primaryBranchId: branchId,
      isStaffMember: true,
      roleId: effectiveRoleId,
      roleName: resolvedRoleName,
      role: rolePayload,
      extraPermissions,
      ...(name ? { name } : {}),
      ...(phoneNumber ? { phoneNumber } : {}),
      updatedAt: now,
    },
    { merge: true },
  );

  await batch.commit();

  return {
    success: true,
    uid,
    roleId: effectiveRoleId,
    roleName: resolvedRoleName,
  };
});

export const deleteBranchStaffUser = onCall({ cors: true }, async (request) => {
  const caller = request.auth;
  if (!caller) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const payload = request.data as DeleteBranchStaffPayload;
  validateDeleteBranchStaffPayload(payload);

  const businessId = payload.businessId.trim();
  const branchId = payload.branchId.trim();
  const uid = payload.uid.trim();

  if (uid === caller.uid) {
    throw new HttpsError('permission-denied', 'You cannot delete your own account.');
  }

  const db = admin.firestore();
  const auth = admin.auth();

  const isSuperAdmin =
    caller.token.superAdmin === true ||
    await isAllowlistedSuperAdmin(
      db,
      caller.uid,
      (caller.token.email as string | undefined)?.toLowerCase() ?? '',
    );

  if (!isSuperAdmin) {
    const callerRootUser = await db.collection('users').doc(caller.uid).get();
    const callerBusinessId = String(callerRootUser.data()?.primarybusinessId ?? '').trim();
    if (callerBusinessId.length === 0 || callerBusinessId !== businessId) {
      throw new HttpsError('permission-denied', 'You can only delete staff for your own business.');
    }
  }

  const branchUserRef = db
    .collection('businesses')
    .doc(businessId)
    .collection('branches')
    .doc(branchId)
    .collection('users')
    .doc(uid);
  const rootUserRef = db.collection('users').doc(uid);

  const [branchUserSnap, rootUserSnap] = await Promise.all([
    branchUserRef.get(),
    rootUserRef.get(),
  ]);

  if (!branchUserSnap.exists) {
    throw new HttpsError('not-found', 'Staff member not found in branch.');
  }

  const branchData = branchUserSnap.data() ?? {};
  const rootData = rootUserSnap.data() ?? {};
  const targetRoleName = String(branchData.roleName ?? rootData.roleName ?? '').trim().toLowerCase();
  const targetRoleId = String(branchData.roleId ?? rootData.roleId ?? '').trim().toLowerCase();

  if (targetRoleName === 'owner' || targetRoleId === 'owner') {
    throw new HttpsError('permission-denied', 'Owner account cannot be deleted.');
  }

  let authDeletedOrDisabled = false;
  try {
    await auth.deleteUser(uid);
    authDeletedOrDisabled = true;
  } catch (error) {
    const code = String((error as { code?: unknown })?.code ?? '').toLowerCase();
    if (code.includes('user-not-found')) {
      authDeletedOrDisabled = true;
    } else {
      try {
        await auth.updateUser(uid, { disabled: true });
        authDeletedOrDisabled = true;
      } catch (disableError) {
        logger.error('deleteBranchStaffUser auth cleanup failed', disableError as Error);
      }
    }
  }

  if (!authDeletedOrDisabled) {
    throw new HttpsError('internal', 'Failed to remove staff login access.');
  }

  const batch = db.batch();
  batch.delete(branchUserRef);
  batch.delete(rootUserRef);
  await batch.commit();

  return {
    success: true,
    uid,
  };
});

export const togglePlatformUserActivation = onCall({ cors: true }, async (request) => {
  const caller = request.auth;
  if (!caller) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const payload = request.data as ToggleUserActivationPayload;
  validateToggleUserActivationPayload(payload);

  const uid = payload.uid.trim();
  const isActive = payload.isActive === true;

  if (uid === caller.uid) {
    throw new HttpsError('permission-denied', 'You cannot change your own activation status.');
  }

  const db = admin.firestore();
  const auth = admin.auth();

  const isSuperAdmin =
    caller.token.superAdmin === true ||
    await isAllowlistedSuperAdmin(
      db,
      caller.uid,
      (caller.token.email as string | undefined)?.toLowerCase() ?? '',
    );

  if (!isSuperAdmin) {
    throw new HttpsError('permission-denied', 'Only super admins can update user activation.');
  }

  const rootUserRef = db.collection('users').doc(uid);
  const rootUserSnap = await rootUserRef.get();
  const rootData = rootUserSnap.data() ?? {};
  const rootRoleName = String(rootData.roleName ?? rootData.role?.name ?? '').trim().toLowerCase();
  const rootRoleId = String(rootData.roleId ?? rootData.role?.id ?? '').trim().toLowerCase();

  if (rootRoleName === 'owner' || rootRoleId === 'owner') {
    throw new HttpsError('permission-denied', 'Owner account cannot be deactivated from this module.');
  }

  const branchMembershipDocs = await findBranchUserDocsByUid(db, uid);

  for (const branchUserDoc of branchMembershipDocs) {
    const data = branchUserDoc.data() ?? {};
    const roleName = String(data.roleName ?? '').trim().toLowerCase();
    const roleId = String(data.roleId ?? '').trim().toLowerCase();
    if (roleName === 'owner' || roleId === 'owner') {
      throw new HttpsError('permission-denied', 'Owner account cannot be deactivated from this module.');
    }
  }

  try {
    await auth.updateUser(uid, { disabled: !isActive });
  } catch (error) {
    const code = String((error as { code?: unknown })?.code ?? '').toLowerCase();
    if (!code.includes('user-not-found')) {
      throw new HttpsError('internal', 'Failed to update Firebase Auth user status.');
    }
    if (isActive) {
      throw new HttpsError('not-found', 'Auth account not found for this user.');
    }
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const batch = db.batch();

  batch.set(
    rootUserRef,
    {
      isActive,
      isSuspended: !isActive,
      updatedAt: now,
    },
    { merge: true },
  );

  for (const branchUserDoc of branchMembershipDocs) {
    batch.set(
      branchUserDoc.ref,
      {
        isActive,
        isSuspended: !isActive,
        updatedAt: now,
      },
      { merge: true },
    );
  }

  await batch.commit();

  return {
    success: true,
    uid,
    isActive,
  };
});

export const deletePlatformUser = onCall({ cors: true }, async (request) => {
  const caller = request.auth;
  if (!caller) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const payload = request.data as DeletePlatformUserPayload;
  validateDeletePlatformUserPayload(payload);

  const uid = payload.uid.trim();
  if (uid === caller.uid) {
    throw new HttpsError('permission-denied', 'You cannot delete your own account.');
  }

  const db = admin.firestore();
  const auth = admin.auth();

  const isSuperAdmin =
    caller.token.superAdmin === true ||
    await isAllowlistedSuperAdmin(
      db,
      caller.uid,
      (caller.token.email as string | undefined)?.toLowerCase() ?? '',
    );

  if (!isSuperAdmin) {
    throw new HttpsError('permission-denied', 'Only super admins can delete users globally.');
  }

  const rootUserRef = db.collection('users').doc(uid);
  const rootUserSnap = await rootUserRef.get();
  const rootData = rootUserSnap.data() ?? {};
  const rootRoleName = String(rootData.roleName ?? rootData.role?.name ?? '').trim().toLowerCase();
  const rootRoleId = String(rootData.roleId ?? rootData.role?.id ?? '').trim().toLowerCase();

  if (rootRoleName === 'owner' || rootRoleId === 'owner') {
    throw new HttpsError('permission-denied', 'Owner account cannot be deleted from this module.');
  }

  const ownerBusinessesSnap = await db.collection('businesses').where('ownerId', '==', uid).limit(1).get();
  if (!ownerBusinessesSnap.empty) {
    throw new HttpsError('permission-denied', 'Business owner account cannot be deleted from this module.');
  }

  const branchMembershipDocs = await findBranchUserDocsByUid(db, uid);

  for (const branchUserDoc of branchMembershipDocs) {
    const data = branchUserDoc.data() ?? {};
    const roleName = String(data.roleName ?? '').trim().toLowerCase();
    const roleId = String(data.roleId ?? '').trim().toLowerCase();
    if (roleName === 'owner' || roleId === 'owner') {
      throw new HttpsError('permission-denied', 'Owner account cannot be deleted from this module.');
    }
  }

  let authDeletedOrDisabled = false;
  try {
    await auth.deleteUser(uid);
    authDeletedOrDisabled = true;
  } catch (error) {
    const code = String((error as { code?: unknown })?.code ?? '').toLowerCase();
    if (code.includes('user-not-found')) {
      authDeletedOrDisabled = true;
    } else {
      try {
        await auth.updateUser(uid, { disabled: true });
        authDeletedOrDisabled = true;
      } catch (disableError) {
        logger.error('deletePlatformUser auth cleanup failed', disableError as Error);
      }
    }
  }

  if (!authDeletedOrDisabled) {
    throw new HttpsError('internal', 'Failed to remove user login access.');
  }

  const batch = db.batch();
  for (const branchUserDoc of branchMembershipDocs) {
    batch.delete(branchUserDoc.ref);
  }
  batch.delete(rootUserRef);

  const superAdminRef = db.collection('super_admins').doc(uid);
  const superAdminSnap = await superAdminRef.get();
  if (superAdminSnap.exists) {
    batch.delete(superAdminRef);
  }

  await batch.commit();

  return {
    success: true,
    uid,
    deletedBranchRecords: branchMembershipDocs.length,
  };
});

export const sendPlatformAnnouncement = onCall({ cors: true }, async (request) => {
  const caller = request.auth;
  if (!caller) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const payload = request.data as SendPlatformAnnouncementPayload;
  validateSendPlatformAnnouncementPayload(payload);

  const db = admin.firestore();
  const isSuperAdmin =
    caller.token.superAdmin === true ||
    await isAllowlistedSuperAdmin(
      db,
      caller.uid,
      (caller.token.email as string | undefined)?.toLowerCase() ?? '',
    );

  if (!isSuperAdmin) {
    throw new HttpsError('permission-denied', 'Only super admins can send platform announcements.');
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  const title = payload.title.trim();
  const message = payload.message.trim();
  const targetType = payload.targetType;

  const channelsRef = db
    .collection('platform')
    .doc('settings')
    .collection('notifications')
    .doc('channels');
  const channelsSnap = await channelsRef.get();
  const channelSettings = channelsSnap.data() ?? {};

  const requestedInApp = payload.channels?.inApp === true;
  const requestedPush = payload.channels?.push === true;

  if (!requestedInApp && !requestedPush) {
    throw new HttpsError('invalid-argument', 'Select at least one channel (in-app or push).');
  }

  const effectiveInApp = requestedInApp && channelSettings.inAppEnabled === true;
  const effectivePush = requestedPush && channelSettings.pushEnabled === true;

  const businessesSnap = await db.collection('businesses').get();
  const activeBusinesses = businessesSnap.docs.filter((doc) => {
    const data = doc.data();
    if (data.isDeleted === true) return false;
    const status = String(data.status ?? 'active').trim().toLowerCase();
    return status != 'deleted';
  });

  let targetBusinessDocs: FirebaseFirestore.QueryDocumentSnapshot<FirebaseFirestore.DocumentData>[];
  if (targetType === 'all') {
    targetBusinessDocs = activeBusinesses;
  } else {
    const requestedIds = (payload.targetBusinessIds ?? [])
      .map((id) => String(id).trim())
      .filter((id) => id.length > 0);

    const requestedSet = new Set<string>(requestedIds);
    if (requestedSet.size === 0) {
      throw new HttpsError('invalid-argument', 'Select at least one business for selected target type.');
    }

    targetBusinessDocs = activeBusinesses.filter((doc) => requestedSet.has(doc.id));
  }

  const jobRef = db.collection('platform').doc('announcement_jobs').collection('jobs').doc();
  const targetBusinessIds = targetBusinessDocs.map((doc) => doc.id);

  await jobRef.set({
    title,
    message,
    targetType,
    targetBusinessIds,
    channels: {
      requested: {
        inApp: requestedInApp,
        push: requestedPush,
      },
      effective: {
        inApp: effectiveInApp,
        push: effectivePush,
      },
    },
    status: 'processing',
    totalBusinesses: targetBusinessIds.length,
    inAppSentCount: 0,
    pushSentCount: 0,
    pushFailureCount: 0,
    requestedByUid: caller.uid,
    requestedByEmail: (caller.token.email as string | undefined)?.toLowerCase() ?? '',
    createdAt: now,
    startedAt: now,
    updatedAt: now,
  }, { merge: true });

  if (targetBusinessIds.length == 0) {
    await jobRef.set({
      status: 'failed',
      errorMessage: 'No active businesses found for selected target.',
      completedAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    throw new HttpsError('failed-precondition', 'No active businesses found for selected target.');
  }

  let inAppSentCount = 0;
  let pushSentCount = 0;
  let pushFailureCount = 0;

  if (effectiveInApp) {
    for (const businessDoc of targetBusinessDocs) {
      const businessData = businessDoc.data();
      await businessDoc.ref.collection('notifications').doc(jobRef.id).set({
        id: jobRef.id,
        type: 'platform_announcement',
        title,
        message,
        businessId: businessDoc.id,
        businessName: String(businessData.title ?? ''),
        createdBy: caller.uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        readBy: [] as string[],
      }, { merge: true });
      inAppSentCount += 1;
    }
  }

  if (effectivePush) {
    const messaging = admin.messaging();

    for (const businessDoc of targetBusinessDocs) {
      const usersSnap = await db
        .collection('users')
        .where('primarybusinessId', '==', businessDoc.id)
        .get();

      const tokens = new Set<string>();
      for (const userDoc of usersSnap.docs) {
        const userData = userDoc.data() as Record<string, unknown>;
        for (const token of extractPushTokens(userData)) {
          tokens.add(token);
        }
      }

      const businessTokens = [...tokens];
      if (businessTokens.length == 0) {
        continue;
      }

      for (const tokenChunk of chunkArray(businessTokens, 500)) {
        try {
          const response = await messaging.sendEachForMulticast({
            tokens: tokenChunk,
            notification: {
              title,
              body: message,
            },
            data: {
              type: 'platform_announcement',
              jobId: jobRef.id,
              businessId: businessDoc.id,
            },
          });

          pushSentCount += response.successCount;
          pushFailureCount += response.failureCount;
        } catch (pushError) {
          logger.error('sendPlatformAnnouncement push send failed', pushError as Error);
          pushFailureCount += tokenChunk.length;
        }
      }
    }
  }

  const finalStatus = (effectiveInApp || effectivePush) ? 'completed' : 'failed';
  await jobRef.set({
    status: finalStatus,
    inAppSentCount,
    pushSentCount,
    pushFailureCount,
    completedAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    errorMessage: finalStatus == 'failed'
      ? 'Selected channels are disabled in platform settings.'
      : null,
  }, { merge: true });

  return {
    success: true,
    announcementJobId: jobRef.id,
    targetBusinesses: targetBusinessIds.length,
    inAppSentCount,
    pushSentCount,
    pushFailureCount,
    status: finalStatus,
  };
});

export const resolveCurrentUserProfile = onCall({ cors: true }, async (request) => {
  const caller = request.auth;
  if (!caller) {
    throw new HttpsError('unauthenticated', 'Authentication required.');
  }

  const db = admin.firestore();
  const uid = caller.uid;
  const email = ((caller.token.email as string | undefined) ?? '').trim().toLowerCase();
  const now = admin.firestore.Timestamp.now();

  const getRolePayload = async (
    businessId: string,
    branchId: string,
    roleIdInput: string,
    fallbackRoleName?: string,
  ): Promise<Record<string, unknown> | null> => {
    const roleId = String(roleIdInput ?? '').trim();
    if (!businessId || !branchId || !roleId) {
      return null;
    }

    const roleDoc = await db
      .collection('businesses')
      .doc(businessId)
      .collection('branches')
      .doc(branchId)
      .collection('roles')
      .doc(roleId)
      .get();

    if (!roleDoc.exists) {
      return null;
    }

    const roleData = roleDoc.data() ?? {};
    const permissions = Array.isArray(roleData.permissions) ? roleData.permissions : [];

    return {
      id: roleId,
      businessId,
      name: String(roleData.name ?? fallbackRoleName ?? roleId),
      permissions,
      createdAt: roleData.createdAt ?? now,
      updatedAt: now,
    };
  };

  const getRolePayloadByName = async (
    businessId: string,
    branchId: string,
    roleNameInput: string,
  ): Promise<Record<string, unknown> | null> => {
    const roleName = String(roleNameInput ?? '').trim().toLowerCase();
    if (!businessId || !branchId || !roleName) {
      return null;
    }

    const rolesSnap = await db
      .collection('businesses')
      .doc(businessId)
      .collection('branches')
      .doc(branchId)
      .collection('roles')
      .get();

    for (const doc of rolesSnap.docs) {
      const data = doc.data();
      const candidateName = String(data.name ?? '').trim().toLowerCase();
      if (candidateName !== roleName) {
        continue;
      }

      const permissions = Array.isArray(data.permissions) ? data.permissions : [];
      return {
        id: doc.id,
        businessId,
        name: String(data.name ?? roleNameInput),
        permissions,
        createdAt: data.createdAt ?? now,
        updatedAt: now,
      };
    }

    return null;
  };

  try {
    const rootUserRef = db.collection('users').doc(uid);
    const rootUserSnap = await rootUserRef.get();
    if (rootUserSnap.exists) {
      const rootData = rootUserSnap.data() ?? {};
      const existingRole =
        rootData.role && typeof rootData.role === 'object'
          ? (rootData.role as { permissions?: unknown[] })
          : null;

      const hasRolePermissions =
        existingRole != null &&
        Array.isArray(existingRole.permissions) &&
        existingRole.permissions.length > 0;

      if (hasRolePermissions) {
        return { success: true, uid, source: 'root' };
      }

      let businessId = String(rootData.primarybusinessId ?? '').trim();
      let branchId = String(rootData.primaryBranchId ?? '').trim();
      let roleId = String(rootData.roleId ?? rootData.role?.id ?? '').trim();
      let roleName = String(rootData.roleName ?? rootData.role?.name ?? '').trim();

      if (!businessId || !branchId || !roleId) {
        try {
          const branchUserSnap = await db
            .collectionGroup('users')
            .where('uid', '==', uid)
            .limit(1)
            .get();

          if (!branchUserSnap.empty) {
            const branchDoc = branchUserSnap.docs[0];
            const branchData = branchDoc.data();
            const pathParts = branchDoc.ref.path.split('/');

            if (!businessId) {
              businessId =
                pathParts.length >= 6
                  ? pathParts[1]
                  : String(branchData.primarybusinessId ?? '').trim();
            }

            if (!branchId) {
              branchId =
                pathParts.length >= 6
                  ? pathParts[3]
                  : String(branchData.primaryBranchId ?? '').trim();
            }

            if (!roleId) {
              roleId = String(branchData.roleId ?? '').trim();
            }

            if (!roleName) {
              roleName = String(branchData.roleName ?? roleId).trim();
            }
          }
        } catch (branchLookupErr) {
          logger.warn('Root hydration branch lookup failed', branchLookupErr as Error);
        }
      }

      if (businessId && branchId && (roleId || roleName)) {
        try {
          let rolePayload: Record<string, unknown> | null = null;

          if (roleId) {
            rolePayload = await getRolePayload(
              businessId,
              branchId,
              roleId,
              roleName,
            );
          }

          if (rolePayload == null && roleName) {
            rolePayload = await getRolePayloadByName(
              businessId,
              branchId,
              roleName,
            );
          }

          if (rolePayload != null) {
            await rootUserRef.set(
              {
                role: rolePayload,
                roleId: String((rolePayload.id as string | undefined) ?? roleId),
                roleName: String((rolePayload.name as string | undefined) ?? roleName),
                primarybusinessId: businessId,
                primaryBranchId: branchId,
                updatedAt: now,
              },
              { merge: true },
            );

            return { success: true, uid, source: 'root_hydrated' };
          }
        } catch (hydrateErr) {
          logger.warn('Root role hydration failed', hydrateErr as Error);
        }
      }

      return { success: true, uid, source: 'root' };
    }

    if (email.length > 0) {
      try {
        const legacyRootByEmail = await db
          .collection('users')
          .where('email', '==', email)
          .limit(1)
          .get();

        if (!legacyRootByEmail.empty) {
          const legacyDoc = legacyRootByEmail.docs[0];
          const data = legacyDoc.data();

          await rootUserRef.set(
            {
              ...data,
              uid,
              email,
              updatedAt: now,
              createdAt: data.createdAt ?? now,
            },
            { merge: true },
          );

          return { success: true, uid, source: 'legacy_root' };
        }
      } catch (legacyErr) {
        logger.warn('Legacy root lookup failed, trying branch fallback', legacyErr as Error);
      }
    }

    try {
      let branchUserSnap = await db
        .collectionGroup('users')
        .where('uid', '==', uid)
        .limit(1)
        .get();

      if (branchUserSnap.empty && email.length > 0) {
        branchUserSnap = await db
          .collectionGroup('users')
          .where('email', '==', email)
          .limit(1)
          .get();
      }

      if (!branchUserSnap.empty) {
        const branchDoc = branchUserSnap.docs[0];
        const branchData = branchDoc.data();
        const pathParts = branchDoc.ref.path.split('/');
        const businessId = pathParts.length >= 6 ? pathParts[1] : String(branchData.primarybusinessId ?? '').trim();
        const branchId = pathParts.length >= 6 ? pathParts[3] : String(branchData.primaryBranchId ?? '').trim();
        const roleId = String(branchData.roleId ?? '').trim();
        const roleName = String(branchData.roleName ?? roleId).trim();

        let rolePayload: Record<string, unknown> | null = null;
        if (businessId && branchId && (roleId || roleName)) {
          try {
            if (roleId) {
              rolePayload = await getRolePayload(
                businessId,
                branchId,
                roleId,
                roleName,
              );
            }

            if (rolePayload == null && roleName) {
              rolePayload = await getRolePayloadByName(
                businessId,
                branchId,
                roleName,
              );
            }
          } catch (roleErr) {
            logger.warn('Branch fallback role lookup failed', roleErr as Error);
          }
        }

        await rootUserRef.set(
          {
            uid,
            email: email.length > 0 ? email : String(branchData.email ?? '').trim().toLowerCase(),
            name: String(branchData.name ?? ''),
            phoneNumber: branchData.phoneNumber ?? null,
            profileImageUrl: null,
            primarybusinessId: businessId,
            primaryBranchId: branchId,
            isStaffMember: true,
            roleName,
            roleId: rolePayload != null
              ? String((rolePayload.id as string | undefined) ?? roleId)
              : roleId,
            role: rolePayload,
            extraPermissions: branchData.extraPermissions ?? {},
            favoriteProductIds: [],
            deliveryAddresses: [],
            createdAt: branchData.createdAt ?? now,
            updatedAt: now,
          },
          { merge: true },
        );

        return { success: true, uid, source: 'branch_fallback' };
      }
    } catch (branchErr) {
      logger.warn('Branch fallback lookup failed', branchErr as Error);
    }

    throw new HttpsError('not-found', 'No user profile found for the authenticated account.');
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error('resolveCurrentUserProfile failed', error as Error);
    throw new HttpsError('internal', String((error as Error)?.message ?? 'Failed to resolve user profile'));
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

async function findBranchUserDocsByUid(
  db: admin.firestore.Firestore,
  uid: string,
): Promise<FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>[]> {
  const branchDocs = await db.collectionGroup('branches').get();
  const matches: FirebaseFirestore.DocumentSnapshot<FirebaseFirestore.DocumentData>[] = [];

  for (const branchDoc of branchDocs.docs) {
    const userSnap = await branchDoc.ref.collection('users').doc(uid).get();
    if (!userSnap.exists || userSnap.data() == null) {
      continue;
    }

    matches.push(userSnap);
  }

  return matches;
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

function validateBranchStaffPayload(payload: BranchStaffPayload): void {
  if (!payload || typeof payload !== 'object') {
    throw new HttpsError('invalid-argument', 'Payload is required.');
  }

  if (!payload.businessId || !payload.businessId.trim()) {
    throw new HttpsError('invalid-argument', 'businessId is required.');
  }

  if (!payload.branchId || !payload.branchId.trim()) {
    throw new HttpsError('invalid-argument', 'branchId is required.');
  }

  const email = (payload.email ?? '').trim().toLowerCase();
  if (!email) {
    throw new HttpsError('invalid-argument', 'email is required.');
  }

  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
    throw new HttpsError('invalid-argument', 'email is invalid.');
  }

  if (!payload.password || payload.password.length < 6) {
    throw new HttpsError('invalid-argument', 'password must be at least 6 characters.');
  }

  if (!payload.roleId || !payload.roleId.trim()) {
    throw new HttpsError('invalid-argument', 'roleId is required.');
  }
}

function validateUpdateBranchStaffPayload(payload: UpdateBranchStaffPayload): void {
  if (!payload || typeof payload !== 'object') {
    throw new HttpsError('invalid-argument', 'Payload is required.');
  }

  if (!payload.businessId || !payload.businessId.trim()) {
    throw new HttpsError('invalid-argument', 'businessId is required.');
  }

  if (!payload.branchId || !payload.branchId.trim()) {
    throw new HttpsError('invalid-argument', 'branchId is required.');
  }

  if (!payload.uid || !payload.uid.trim()) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }

  if (!payload.roleId || !payload.roleId.trim()) {
    throw new HttpsError('invalid-argument', 'roleId is required.');
  }
}

function validateDeleteBranchStaffPayload(payload: DeleteBranchStaffPayload): void {
  if (!payload || typeof payload !== 'object') {
    throw new HttpsError('invalid-argument', 'Payload is required.');
  }

  if (!payload.businessId || !payload.businessId.trim()) {
    throw new HttpsError('invalid-argument', 'businessId is required.');
  }

  if (!payload.branchId || !payload.branchId.trim()) {
    throw new HttpsError('invalid-argument', 'branchId is required.');
  }

  if (!payload.uid || !payload.uid.trim()) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }
}

function validateToggleUserActivationPayload(payload: ToggleUserActivationPayload): void {
  if (!payload || typeof payload !== 'object') {
    throw new HttpsError('invalid-argument', 'Payload is required.');
  }

  if (!payload.uid || !payload.uid.trim()) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }

  if (typeof payload.isActive !== 'boolean') {
    throw new HttpsError('invalid-argument', 'isActive must be boolean.');
  }
}

function validateDeletePlatformUserPayload(payload: DeletePlatformUserPayload): void {
  if (!payload || typeof payload !== 'object') {
    throw new HttpsError('invalid-argument', 'Payload is required.');
  }

  if (!payload.uid || !payload.uid.trim()) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }
}

function validateSendPlatformAnnouncementPayload(payload: SendPlatformAnnouncementPayload): void {
  if (!payload || typeof payload !== 'object') {
    throw new HttpsError('invalid-argument', 'Payload is required.');
  }

  if (!payload.title || !payload.title.trim()) {
    throw new HttpsError('invalid-argument', 'title is required.');
  }

  if (!payload.message || !payload.message.trim()) {
    throw new HttpsError('invalid-argument', 'message is required.');
  }

  const targetType = String(payload.targetType ?? '').trim().toLowerCase();
  if (targetType != 'all' && targetType != 'selected') {
    throw new HttpsError('invalid-argument', 'targetType must be all or selected.');
  }
}

function extractPushTokens(data: Record<string, unknown>): string[] {
  const tokens = new Set<string>();

  const maybeAdd = (value: unknown) => {
    const token = String(value ?? '').trim();
    if (token.length > 0) {
      tokens.add(token);
    }
  };

  maybeAdd(data.fcmToken);
  maybeAdd(data.deviceToken);

  const maybeArray = [data.fcmTokens, data.deviceTokens, data.notificationTokens];
  for (const entry of maybeArray) {
    if (!Array.isArray(entry)) continue;
    for (const token of entry) {
      maybeAdd(token);
    }
  }

  return [...tokens];
}

function chunkArray<T>(items: T[], size: number): T[][] {
  const chunks: T[][] = [];
  if (size <= 0) return [items];

  for (let i = 0; i < items.length; i += size) {
    chunks.push(items.slice(i, i + size));
  }

  return chunks;
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
