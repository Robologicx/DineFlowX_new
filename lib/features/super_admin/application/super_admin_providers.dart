import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/features/super_admin/data/repositories/firebase_super_admin_repository.dart';
import 'package:hotel_management_system/features/super_admin/domain/entities/super_admin_entities.dart';
import 'package:hotel_management_system/features/super_admin/domain/repositories/super_admin_repository.dart';

Future<void> _selfHealSuperAdminAccess() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = user.email?.toLowerCase() ?? '';
    final isTrustedEmail =
        email == 'info.robologicx@gmail.com' ||
        email.endsWith('@robologicx.com');

    final tokenResult = await user.getIdTokenResult(true);
    final hasClaim = tokenResult.claims?['superAdmin'] == true;

    final firestore = FirebaseFirestore.instance;
    final superAdminRef = firestore.collection('super_admins').doc(user.uid);
    final superAdminDoc = await superAdminRef.get();
    final superAdminData = superAdminDoc.data() ?? const <String, dynamic>{};
    final hasAllowlist = superAdminData['isActive'] == true;

    if (!isTrustedEmail && !hasClaim && !hasAllowlist) {
      return;
    }

    final batch = firestore.batch();

    batch.set(superAdminRef, {
      'uid': user.uid,
      'email': email,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    final userRef = firestore.collection('users').doc(user.uid);
    batch.set(userRef, {
      'uid': user.uid,
      'email': email,
      'role': 'super_admin',
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
    await user.getIdToken(true);
  } catch (_) {
    // Never block UI/providers because of a best-effort access bootstrap.
  }
}

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return FirebaseSuperAdminRepository();
});

final superAdminAuthUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final isRoboLogicxSuperAdminProvider = FutureProvider<bool>((ref) async {
  final user = await ref.watch(superAdminAuthUserProvider.future);
  if (user == null) return false;

  final email = user.email?.toLowerCase() ?? '';
  final isTrustedEmail =
      email == 'info.robologicx@gmail.com' || email.endsWith('@robologicx.com');

  await _selfHealSuperAdminAccess();

  if (isTrustedEmail) return true;

  final idTokenResult = await user.getIdTokenResult(true);
  final superAdminClaim = idTokenResult.claims?['superAdmin'] == true;
  if (superAdminClaim) return true;

  final doc = await FirebaseFirestore.instance
      .collection('super_admins')
      .doc(user.uid)
      .get();
  if (!doc.exists) return false;
  final data = doc.data() ?? const <String, dynamic>{};
  return data['isActive'] == true;
});

final platformKpiProvider = StreamProvider<PlatformKpi>((ref) {
  return ref.read(superAdminRepositoryProvider).watchPlatformKpi();
});

final monthlyOrdersTrendProvider = StreamProvider<List<TrendPoint>>((ref) {
  return ref.read(superAdminRepositoryProvider).watchMonthlyOrdersTrend();
});

final monthlyRevenueTrendProvider = StreamProvider<List<TrendPoint>>((ref) {
  return ref.read(superAdminRepositoryProvider).watchMonthlyRevenueTrend();
});

final businessesProvider = StreamProvider<List<BusinessTenantSummary>>((ref) {
  return Stream.fromFuture(
    ref.watch(isRoboLogicxSuperAdminProvider.future),
  ).asyncExpand((isSuperAdmin) {
    if (!isSuperAdmin) {
      return Stream.value(const <BusinessTenantSummary>[]);
    }

    return Stream.fromFuture(_selfHealSuperAdminAccess()).asyncExpand((_) {
      return ref.read(superAdminRepositoryProvider).watchBusinesses();
    });
  });
});
