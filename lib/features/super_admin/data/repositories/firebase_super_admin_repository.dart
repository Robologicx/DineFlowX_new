import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hotel_management_system/features/super_admin/domain/entities/super_admin_entities.dart';
import 'package:hotel_management_system/features/super_admin/domain/repositories/super_admin_repository.dart';

class FirebaseSuperAdminRepository implements SuperAdminRepository {
  FirebaseSuperAdminRepository({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  @override
  Stream<PlatformKpi> watchPlatformKpi() {
    return _firestore
        .collection('businesses')
        .snapshots()
        .asyncMap((snap) async {
          final docs = snap.docs;
          final totalBusinesses = docs.length;

          var activeBusinesses = 0;
          var suspendedBusinesses = 0;
          var expiredSubscriptions = 0;
          var totalBranches = 0;
          var totalStaffUsers = 0;

          final now = DateTime.now();
          for (final doc in docs) {
            final data = doc.data();
            final status = (data['status'] ?? 'active')
                .toString()
                .toLowerCase();
            if (status == 'active') activeBusinesses++;
            if (status == 'suspended') suspendedBusinesses++;

            final expiry = _toDateTime(data['subscriptionExpiry']);
            if (expiry != null && expiry.isBefore(now)) {
              expiredSubscriptions++;
            }

            totalBranches += _toInt(data['branchesCount']);
            totalStaffUsers += _toInt(data['usersCount']);
          }

          final todayStart = DateTime(now.year, now.month, now.day);
          final monthStart = DateTime(now.year, now.month, 1);
          final yearStart = DateTime(now.year, 1, 1);

          var totalOrdersToday = 0;
          var totalOrdersThisMonth = 0;
          var totalRevenueThisMonth = 0.0;
          var totalRevenueThisYear = 0.0;

          try {
            final todaySnap = await _firestore
                .collectionGroup('orders')
                .where(
                  'createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(todayStart),
                )
                .get();
            totalOrdersToday = todaySnap.size;

            final monthSnap = await _firestore
                .collectionGroup('orders')
                .where(
                  'createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(monthStart),
                )
                .get();
            totalOrdersThisMonth = monthSnap.size;
            totalRevenueThisMonth = monthSnap.docs.fold<double>(
              0,
              (acc, d) => acc + _toDouble(d.data()['totalAmount']),
            );

            final yearSnap = await _firestore
                .collectionGroup('orders')
                .where(
                  'createdAt',
                  isGreaterThanOrEqualTo: Timestamp.fromDate(yearStart),
                )
                .get();
            totalRevenueThisYear = yearSnap.docs.fold<double>(
              0,
              (acc, d) => acc + _toDouble(d.data()['totalAmount']),
            );
          } catch (_) {
            // Fallback when order collection-group access/index is unavailable.
            totalOrdersThisMonth = docs.fold<int>(
              0,
              (acc, d) => acc + _toInt(d.data()['totalOrders']),
            );
            totalRevenueThisMonth = docs.fold<double>(
              0,
              (acc, d) => acc + _toDouble(d.data()['monthlyRevenue']),
            );
            totalRevenueThisYear = totalRevenueThisMonth;
          }

          final avgOrdersPerBusiness = totalBusinesses == 0
              ? 0.0
              : totalOrdersThisMonth / totalBusinesses;
          final avgRevenuePerBusiness = totalBusinesses == 0
              ? 0.0
              : totalRevenueThisMonth / totalBusinesses;

          return PlatformKpi(
            totalBusinesses: totalBusinesses,
            activeBusinesses: activeBusinesses,
            suspendedBusinesses: suspendedBusinesses,
            expiredSubscriptions: expiredSubscriptions,
            totalBranches: totalBranches,
            totalStaffUsers: totalStaffUsers,
            totalOrdersToday: totalOrdersToday,
            totalOrdersThisMonth: totalOrdersThisMonth,
            totalRevenueThisMonth: totalRevenueThisMonth,
            totalRevenueThisYear: totalRevenueThisYear,
            platformGrowthPercent: 0,
            averageOrdersPerBusiness: avgOrdersPerBusiness,
            averageRevenuePerBusiness: avgRevenuePerBusiness,
          );
        })
        .handleError((_) => PlatformKpi.empty());
  }

  @override
  Stream<List<TrendPoint>> watchMonthlyOrdersTrend() {
    return _watchLiveOrdersTrend();
  }

  @override
  Stream<List<TrendPoint>> watchMonthlyRevenueTrend() {
    return _watchLiveRevenueTrend();
  }

  Stream<List<TrendPoint>> _watchLiveOrdersTrend() {
    return _firestore
        .collectionGroup('orders')
        .snapshots()
        .map((snap) {
          final buckets = _monthBuckets();
          for (final doc in snap.docs) {
            final createdAt = _toDateTime(doc.data()['createdAt']);
            if (createdAt == null) continue;
            final key = _monthKey(createdAt);
            if (buckets.containsKey(key)) {
              buckets[key] = (buckets[key] ?? 0) + 1;
            }
          }

          return _trendFromBuckets(buckets);
        })
        .handleError((_) => const <TrendPoint>[]);
  }

  Stream<List<TrendPoint>> _watchLiveRevenueTrend() {
    return _firestore
        .collectionGroup('orders')
        .snapshots()
        .map((snap) {
          final buckets = _monthBuckets();
          for (final doc in snap.docs) {
            final createdAt = _toDateTime(doc.data()['createdAt']);
            if (createdAt == null) continue;
            final key = _monthKey(createdAt);
            if (buckets.containsKey(key)) {
              buckets[key] =
                  (buckets[key] ?? 0) + _toDouble(doc.data()['totalAmount']);
            }
          }

          return _trendFromBuckets(buckets);
        })
        .handleError((_) => const <TrendPoint>[]);
  }

  Stream<List<TrendPoint>> _watchTrendCollection(String collectionName) {
    return _firestore
        .collection('platform')
        .doc('analytics')
        .collection(collectionName)
        .orderBy('sortOrder')
        .snapshots()
        .map((snap) {
          return snap.docs
              .map(
                (d) => TrendPoint(
                  label: (d.data()['label'] ?? '').toString(),
                  value: _toDouble(d.data()['value']),
                ),
              )
              .toList(growable: false);
        });
  }

  @override
  Stream<List<BusinessTenantSummary>> watchBusinesses() {
    return _firestore.collection('businesses').snapshots().map((snap) {
      final docs = [...snap.docs]
        ..sort((a, b) {
          final aDate =
              _toDateTime(a.data()['createdAt']) ??
              _toDateTime(a.data()['updatedAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          final bDate =
              _toDateTime(b.data()['createdAt']) ??
              _toDateTime(b.data()['updatedAt']) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          return bDate.compareTo(aDate);
        });

      return docs
          .map((doc) {
            final data = doc.data();
            return BusinessTenantSummary(
              businessId: doc.id,
              businessName: (data['title'] ?? '').toString(),
              createdAt: _toDateTime(data['createdAt']),
              ownerName: (data['ownerName'] ?? '').toString(),
              email: (data['ownerEmail'] ?? '').toString(),
              phone: (data['ownerPhone'] ?? '').toString(),
              industryType: (data['industryType'] ?? '').toString(),
              country: (data['country'] ?? '').toString(),
              city: (data['city'] ?? '').toString(),
              branches: _toInt(data['branchesCount']),
              users: _toInt(data['usersCount']),
              subscriptionPlan: (data['subscriptionPlan'] ?? 'Trial')
                  .toString(),
              expiryDate: _toDateTime(data['subscriptionExpiry']),
              monthlyRevenue: _toDouble(data['monthlyRevenue']),
              totalOrders: _toInt(data['totalOrders']),
              status: (data['status'] ?? 'active').toString(),
            );
          })
          .toList(growable: false);
    });
  }

  @override
  Future<void> suspendBusiness(String businessId) async {
    await _firestore.collection('businesses').doc(businessId).set({
      'status': 'suspended',
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> activateBusiness(String businessId) async {
    await _firestore.collection('businesses').doc(businessId).set({
      'status': 'active',
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> deleteBusiness(String businessId) async {
    await _firestore.collection('businesses').doc(businessId).set({
      'status': 'deleted',
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateBusiness(
    String businessId, {
    String? businessName,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    String? industryType,
    String? country,
    String? city,
    String? subscriptionPlan,
    DateTime? subscriptionExpiry,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (businessName != null && businessName.trim().isNotEmpty) {
      updates['title'] = businessName.trim();
      updates['title_lower'] = businessName.trim().toLowerCase();
    }
    if (ownerName != null && ownerName.trim().isNotEmpty) {
      updates['ownerName'] = ownerName.trim();
    }
    if (ownerEmail != null && ownerEmail.trim().isNotEmpty) {
      updates['ownerEmail'] = ownerEmail.trim().toLowerCase();
    }
    if (ownerPhone != null && ownerPhone.trim().isNotEmpty) {
      updates['ownerPhone'] = ownerPhone.trim();
    }
    if (industryType != null && industryType.trim().isNotEmpty) {
      updates['industryType'] = industryType.trim();
    }
    if (country != null) {
      updates['country'] = country.trim();
    }
    if (city != null) {
      updates['city'] = city.trim();
    }
    if (subscriptionPlan != null && subscriptionPlan.trim().isNotEmpty) {
      updates['subscriptionPlan'] = subscriptionPlan.trim();
    }
    if (subscriptionExpiry != null) {
      updates['subscriptionExpiry'] = Timestamp.fromDate(subscriptionExpiry);
    }

    await _firestore
        .collection('businesses')
        .doc(businessId)
        .set(updates, SetOptions(merge: true));

    if ((subscriptionPlan != null && subscriptionPlan.trim().isNotEmpty) ||
        subscriptionExpiry != null) {
      final subscriptionUpdates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (subscriptionPlan != null && subscriptionPlan.trim().isNotEmpty) {
        subscriptionUpdates['planName'] = subscriptionPlan.trim();
      }
      if (subscriptionExpiry != null) {
        subscriptionUpdates['expiryDate'] = Timestamp.fromDate(
          subscriptionExpiry,
        );
      }

      await _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('subscriptions')
          .doc('current')
          .set(subscriptionUpdates, SetOptions(merge: true));
    }
  }

  @override
  Future<String> createBusinessTenant(CreateBusinessRequest request) async {
    await _ensureBootstrapSuperAdminAllowlist();

    try {
      final callable = _functions.httpsCallable('createBusinessTenant');
      final result = await callable
          .call(<String, dynamic>{
            'businessName': request.businessName,
            'industryType': request.industryType,
            'country': request.country,
            'city': request.city,
            'ownerName': request.ownerName,
            'ownerEmail': request.ownerEmail,
            'ownerPhone': request.ownerPhone,
            'ownerPassword': request.ownerPassword,
            'selectedPlan': request.selectedPlan,
            'limits': {
              'maxBranches': request.maxBranches,
              'maxUsers': request.maxUsers,
              'maxOrdersPerMonth': request.maxOrdersPerMonth,
              'storageLimitMb': request.storageLimitMb,
            },
            'featureFlags': {
              'qrOrderingEnabled': request.qrOrderingEnabled,
              'onlineOrderingEnabled': request.onlineOrderingEnabled,
              'customerAppEnabled': request.customerAppEnabled,
              'hotelModuleEnabled': request.hotelModuleEnabled,
              'inventoryModuleEnabled': request.inventoryModuleEnabled,
            },
          })
          .timeout(const Duration(seconds: 8));

      final response = (result.data as Map<dynamic, dynamic>?) ?? const {};
      final businessId = (response['businessId'] ?? '').toString();
      if (businessId.isNotEmpty) return businessId;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'not-found' ||
          error.code == 'unavailable' ||
          error.code == 'internal') {
        return _createBusinessTenantDirect(request);
      }

      rethrow;
    } catch (_) {
      // Fall through to direct Firestore provisioning when Cloud Function is missing/unavailable.
      return _createBusinessTenantDirect(request);
    }

    return _createBusinessTenantDirect(request);
  }

  Future<void> _ensureBootstrapSuperAdminAllowlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final email = (user.email ?? '').toLowerCase();
    if (email != 'info.robologicx@gmail.com') return;

    await _firestore.collection('super_admins').doc(user.uid).set({
      'uid': user.uid,
      'email': email,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await user.getIdToken(true);
  }

  Future<String> _createBusinessTenantDirect(
    CreateBusinessRequest request,
  ) async {
    final now = DateTime.now();
    final businessId = await _nextBusinessId();
    final branchId = 'BR01';
    final ownerEmail = request.ownerEmail.trim().toLowerCase();
    final ownerAuth = await _createOwnerAuthAccount(
      email: ownerEmail,
      password: request.ownerPassword,
      displayName: request.ownerName,
    );
    final ownerUid = ownerAuth.uid;

    final expiryDays = request.selectedPlan.toLowerCase() == 'trial' ? 14 : 30;
    final expiryDate = now.add(Duration(days: expiryDays));

    final businessRef = _firestore.collection('businesses').doc(businessId);
    final branchRef = businessRef.collection('branches').doc(branchId);
    final branchUserRef = branchRef.collection('users').doc(ownerUid);
    final subscriptionRef = businessRef
        .collection('subscriptions')
        .doc('current');
    final settingsRef = businessRef.collection('settings').doc('default');
    final platformSubRef = _firestore
        .collection('platform_subscriptions')
        .doc(businessId);
    final rootUserRef = _firestore.collection('users').doc(ownerUid);

    final batch = _firestore.batch();

    batch.set(businessRef, {
      'id': businessId,
      'title': request.businessName,
      'title_lower': request.businessName.toLowerCase(),
      'ownerId': ownerUid,
      'ownerName': request.ownerName,
      'ownerEmail': request.ownerEmail,
      'ownerPhone': request.ownerPhone,
      'industryType': request.industryType,
      'country': request.country,
      'city': request.city,
      'branchesCount': 1,
      'usersCount': 1,
      'subscriptionPlan': request.selectedPlan,
      'subscriptionExpiry': Timestamp.fromDate(expiryDate),
      'monthlyRevenue': 0,
      'totalOrders': 0,
      'status': 'active',
      'isActive': true,
      'isDeleted': false,
      'tenantId': businessId,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(branchRef, {
      'id': branchId,
      'name': 'Main Branch',
      'name_lower': 'main branch',
      'tenantId': businessId,
      'businessId': businessId,
      'isDefault': true,
      'isActive': true,
      'country': request.country,
      'city': request.city,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(branchUserRef, {
      'uid': ownerUid,
      'roleId': 'owner',
      'roleName': 'Owner',
      'extraPermissions': <String, String>{},
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(subscriptionRef, {
      'businessId': businessId,
      'planName': request.selectedPlan,
      'status': 'active',
      'billingModel': request.selectedPlan.toLowerCase() == 'custom'
          ? 'custom'
          : 'monthly',
      'startDate': Timestamp.fromDate(now),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'limits': {
        'maxBranches': request.maxBranches,
        'maxUsers': request.maxUsers,
        'maxOrdersPerMonth': request.maxOrdersPerMonth,
        'storageLimitMb': request.storageLimitMb,
      },
      'featureFlags': {
        'qrOrderingEnabled': request.qrOrderingEnabled,
        'onlineOrderingEnabled': request.onlineOrderingEnabled,
        'customerAppEnabled': request.customerAppEnabled,
        'hotelModuleEnabled': request.hotelModuleEnabled,
        'inventoryModuleEnabled': request.inventoryModuleEnabled,
      },
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(platformSubRef, {
      'businessId': businessId,
      'businessName': request.businessName,
      'ownerEmail': request.ownerEmail,
      'planName': request.selectedPlan,
      'status': 'active',
      'startDate': Timestamp.fromDate(now),
      'expiryDate': Timestamp.fromDate(expiryDate),
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(settingsRef, {
      'businessId': businessId,
      'platformBrand': 'RoboLogicx',
      'currencyCode': 'PKR',
      'taxPercent': 0,
      'timezone': 'Asia/Karachi',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    batch.set(rootUserRef, {
      'uid': ownerUid,
      'name': request.ownerName,
      'email': ownerEmail,
      'phoneNumber': request.ownerPhone,
      'primarybusinessId': businessId,
      'primaryBranchId': branchId,
      'isStaffMember': true,
      'roleName': 'Owner',
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));

    try {
      await batch.commit();
      await _refreshPlatformOverviewCounters();
    } catch (error) {
      try {
        await ownerAuth.delete();
      } catch (_) {
        // If cleanup fails, surface the original error.
      }
      rethrow;
    }

    return businessId;
  }

  Future<User> _createOwnerAuthAccount({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final app = await _secondaryFirebaseApp();
    final auth = FirebaseAuth.instanceFor(app: app);
    final credential = await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user;
    if (user == null) {
      throw StateError('Failed to create owner auth account.');
    }

    await user.updateDisplayName(displayName);
    return user;
  }

  Future<FirebaseApp> _secondaryFirebaseApp() async {
    const appName = 'owner-provisioning-app';
    try {
      return Firebase.app(appName);
    } catch (_) {
      return Firebase.initializeApp(
        name: appName,
        options: Firebase.app().options,
      );
    }
  }

  Future<String> _nextBusinessId() async {
    final counterRef = _firestore.collection('platform').doc('counters');

    final nextNumber = await _firestore.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);
      final current =
          ((snap.data() ?? const <String, dynamic>{})['businessCounter'] ??
                  1000)
              as int;
      final next = current + 1;
      tx.set(counterRef, {
        'businessCounter': next,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return next;
    });

    return 'RLX$nextNumber';
  }

  Future<void> _refreshPlatformOverviewCounters() async {
    final allBusinesses = await _firestore.collection('businesses').get();

    var active = 0;
    var suspended = 0;
    var expired = 0;
    var branches = 0;
    var users = 0;

    final now = DateTime.now();
    for (final doc in allBusinesses.docs) {
      final data = doc.data();
      final status = (data['status'] ?? 'active').toString().toLowerCase();
      if (status == 'active') active++;
      if (status == 'suspended') suspended++;
      final expiry = _toDateTime(data['subscriptionExpiry']);
      if (expiry != null && expiry.isBefore(now)) expired++;
      branches += (data['branchesCount'] ?? 0) as int;
      users += (data['usersCount'] ?? 0) as int;
    }

    final totalBusinesses = allBusinesses.docs.length;
    await _firestore.collection('platform').doc('overview').set({
      'totalBusinesses': totalBusinesses,
      'activeBusinesses': active,
      'suspendedBusinesses': suspended,
      'expiredSubscriptions': expired,
      'totalBranches': branches,
      'totalStaffUsers': users,
      'averageOrdersPerBusiness': 0,
      'averageRevenuePerBusiness': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return 0;
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _monthKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
  }

  Map<String, double> _monthBuckets() {
    final now = DateTime.now();
    final buckets = <String, double>{};
    for (var i = 5; i >= 0; i--) {
      final d = DateTime(now.year, now.month - i, 1);
      buckets[_monthKey(d)] = 0;
    }
    return buckets;
  }

  List<TrendPoint> _trendFromBuckets(Map<String, double> buckets) {
    return buckets.entries
        .map((e) {
          final ym = e.key.split('-');
          final month = int.tryParse(ym[1]) ?? 1;
          const labels = [
            'Jan',
            'Feb',
            'Mar',
            'Apr',
            'May',
            'Jun',
            'Jul',
            'Aug',
            'Sep',
            'Oct',
            'Nov',
            'Dec',
          ];
          return TrendPoint(label: labels[month - 1], value: e.value);
        })
        .toList(growable: false);
  }
}
