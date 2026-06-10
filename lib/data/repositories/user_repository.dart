import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import '../models/user_model.dart';

class UserRepository {
  /// Firestore collection reference
  // final String _buisnessId;
  // final String _branchId;
  CollectionReference<Object?> get _usersCollection =>
      FirebaseFirestore.instance.collection('users');

  CollectionReference<Object?> _specificBranchUsersRef(
    String buisnessId,
    String branchId,
  ) {
    return FirebaseFirestore.instance
        .collection('businesses')
        .doc(buisnessId)
        .collection('branches')
        .doc(branchId)
        .collection('users');
  }

  List<UserModel> _mergeUsersPreferLocal({
    required List<UserModel> local,
    required List<UserModel> remote,
  }) {
    final merged = <String, UserModel>{};
    for (final user in remote) {
      merged[user.uid] = user;
    }
    for (final user in local) {
      merged[user.uid] = user;
    }
    return merged.values.toList(growable: false);
  }

  Stream<UserModel?> _hybridUserStream(String uid) {
    return Stream.multi((controller) {
      UserModel? latestRemote;
      bool hasRemoteSnapshot = false;
      StreamSubscription<DocumentSnapshot<Object?>>? remoteSub;
      Timer? localTick;
      bool isCancelled = false;

      Future<void> emitMerged() async {
        if (isCancelled) return;

        // If remote has confirmed the document is deleted, do not revive it
        // from stale local cache.
        if (hasRemoteSnapshot && latestRemote == null) {
          controller.add(null);
          return;
        }

        final localDoc = await OfflineLocalReadService.instance
            .getGlobalDocument(collectionName: 'users', documentId: uid);
        if (isCancelled) return;

        if (latestRemote != null) {
          controller.add(latestRemote);
        } else if (localDoc != null) {
          controller.add(UserModel.fromMap(uid, localDoc));
        } else {
          controller.add(latestRemote);
        }
      }

      localTick = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(emitMerged());
      });

      remoteSub = _usersCollection
          .doc(uid)
          .snapshots()
          .listen(
            (doc) {
              hasRemoteSnapshot = true;
              if (doc.exists && doc.data() != null) {
                latestRemote = UserModel.fromMap(
                  uid,
                  doc.data()! as Map<String, dynamic>,
                );
              } else {
                latestRemote = null;
              }
              unawaited(emitMerged());
            },
            onError: (_) {
              // Keep local polling active if remote listener fails.
            },
          );

      unawaited(emitMerged());

      controller.onCancel = () {
        isCancelled = true;
        localTick?.cancel();
        remoteSub?.cancel();
      };
    });
  }

  /// Create a new user document
  Future<void> createUser(UserModel user) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'users/${user.uid}',
      data: user.toMap(),
      merge: false,
    );
  }

  /// Get a user by ID
  Future<UserModel?> getUserById(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.id, doc.data()! as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      // Fallback to local only when remote is unavailable.
      final localDoc = await OfflineLocalReadService.instance.getGlobalDocument(
        collectionName: 'users',
        documentId: uid,
      );
      if (localDoc != null) {
        return UserModel.fromMap(uid, localDoc);
      }
      throw Exception('Failed to load user profile: $e');
    }
  }

  Future<UserModel?> getUserByIdForBusiness({
    required String uid,
    required String businessId,
  }) async {
    final user = await getUserById(uid);
    if (user == null) return null;
    if (user.primarybusinessId != businessId) return null;
    return user;
  }

  // Get user role from nested collection

  // OLD CODE TO GET SINGLE USER
  Future<UserModel?> getSingleUser(String uid) async {
    return getUserById(uid);
  }

  /// Update an existing user
  Future<void> updateUser(UserModel user) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'users/${user.uid}',
      data: user.toMap(),
      merge: true,
    );
  }

  /// Delete a user
  Future<void> deleteUser(String uid) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath: 'users/$uid',
    );
  }

  /// Listen to a specific user's changes
  Stream<UserModel?> listenToUser(String uid) {
    return _hybridUserStream(uid);
  }

  /// Get all users (optional, for admin use)
  Future<List<UserModel>> getAllUsers() async {
    final localRows = await OfflineLocalReadService.instance
        .getGlobalCollection(collectionName: 'users');
    final local = localRows
        .map(
          (doc) =>
              UserModel.fromMap((doc['__documentId'] ?? '').toString(), doc),
        )
        .toList(growable: false);

    try {
      final querySnapshot = await _usersCollection.get();
      final remote = querySnapshot.docs
          .map(
            (doc) =>
                UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          )
          .toList(growable: false);
      return _mergeUsersPreferLocal(local: local, remote: remote);
    } catch (_) {
      return local;
    }
  }

  Future<List<UserModel>> getAllUsersForBusiness(String businessId) async {
    final users = await getAllUsers();
    return users
        .where((u) => u.primarybusinessId == businessId)
        .toList(growable: false);
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

    final localRows = await OfflineLocalReadService.instance
        .getGlobalCollection(collectionName: 'users');
    final target = userIds.toSet();
    final local = localRows
        .where((row) => target.contains((row['__documentId'] ?? '').toString()))
        .map(
          (row) =>
              UserModel.fromMap((row['__documentId'] ?? '').toString(), row),
        )
        .toList(growable: false);

    final users = <UserModel>[];
    const chunkSize = 30; // Firestore's whereIn limit

    for (var i = 0; i < userIds.length; i += chunkSize) {
      final chunk = userIds.sublist(
        i,
        i + chunkSize > userIds.length ? userIds.length : i + chunkSize,
      );

      try {
        final querySnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        users.addAll(
          querySnapshot.docs.map(
            (doc) =>
                UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
          ),
        );
      } catch (e) {
        continue;
      }
    }

    return _mergeUsersPreferLocal(local: local, remote: users);
  }

  // Future<UserModel?> getBranchSpecificUsersInfo({
  //   required String businessId,
  //   required String branchId,
  //   required String uid,
  // }) async {
  //   try {
  //     final doc = await _specificBranchUsersRef(
  //       businessId,
  //       branchId,
  //     ).doc(uid).get();
  //     if (doc.exists) {
  //       //--------------------------THIS ONLY GIVES ROLE AND PERMISSIONS OF USER NOT OTHER DETAILS-----------FOR OTHER DETAILS USE GET USER BY ID---------------//
  //       return UserModel.fromMap(doc.id, doc.data()! as Map<String, dynamic>);
  //     }
  //     return null;
  //   } catch (e) {
  //     print('Error getting user of branch: $e');
  //     return null;
  //   }
  // }

  /// Add/Update branch-specific user info with root user creation
  Future<String> setBranchSpecificUsersInfo({
    required String businessId,
    required String branchId,
    String? uid, // null for new user, provided for update
    required String roleId,
    String? roleName,
    required Map<String, String> extraPermissions,
    String? email, // Required for new user
    String? name,
    String? phoneNumber,
  }) async {
    try {
      String userId;
      final nowIso = DateTime.now().toIso8601String();

      // Try to hydrate role payload so root user stream receives fresh role permissions.
      Map<String, dynamic>? rolePayload;
      try {
        final roleDoc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .collection('branches')
            .doc(branchId)
            .collection('roles')
            .doc(roleId)
            .get();

        if (roleDoc.exists && roleDoc.data() != null) {
          final roleData = roleDoc.data()!;
          rolePayload = {
            'id': roleId,
            'businessId': businessId,
            'name': (roleData['name'] ?? roleName ?? roleId).toString(),
            'permissions': roleData['permissions'] ?? [],
            'createdAt': roleData['createdAt'] ?? nowIso,
            'updatedAt': nowIso,
          };
        }
      } catch (_) {
        // Keep write path resilient if role lookup fails due to rules/network.
      }

      if (uid == null || uid.isEmpty) {
        // Create new user at root level
        userId = _usersCollection.doc().id;
        await OfflineFirestoreWriteQueueService.instance.setOrQueue(
          documentPath: 'users/$userId',
          data: {
            'uid': userId,
            'email': email ?? '',
            'name': name ?? '',
            'phoneNumber': phoneNumber,
            'profileImageUrl': null,
            'primarybusinessId': businessId,
            'primaryBranchId': branchId,
            'isStaffMember': true,
            'roleId': roleId,
            'roleName': roleName ?? roleId,
            'role': rolePayload,
            'extraPermissions': extraPermissions,
            'favoriteProductIds': [],
            'userLocationText': null,
            'userLatlng': null,
            'deliveryAddresses': [],
            'createdAt': nowIso,
            'updatedAt': nowIso,
          },
          merge: false,
        );
      } else {
        // Update existing user
        userId = uid;

        final updateData = <String, dynamic>{
          'primarybusinessId': businessId,
          'primaryBranchId': branchId,
          'isStaffMember': true,
          'roleId': roleId,
          'roleName': roleName ?? roleId,
          'role': rolePayload,
          'extraPermissions': extraPermissions,
          'updatedAt': nowIso,
        };

        // Add optional fields if provided
        if (name != null && name.isNotEmpty) updateData['name'] = name;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          updateData['phoneNumber'] = phoneNumber;
        }

        await OfflineFirestoreWriteQueueService.instance.setOrQueue(
          documentPath: 'users/$uid',
          data: updateData,
          merge: true,
        );
      }

      // Set/Update branch-specific user info
      final branchPayload = <String, dynamic>{
        'uid': userId,
        'roleId': roleId,
        'roleName': roleName,
        'extraPermissions': extraPermissions,
        'email': email,
        'name': name,
        'phoneNumber': phoneNumber,
        'isStaffMember': true,
        'primarybusinessId': businessId,
        'primaryBranchId': branchId,
        'createdAt': nowIso,
        'updatedAt': nowIso,
      };

      branchPayload.removeWhere((key, value) {
        if (value == null) return true;
        if (value is String && value.trim().isEmpty) return true;
        return false;
      });

      final branchWriteSuccess = await OfflineFirestoreWriteQueueService
          .instance
          .setOrQueue(
            documentPath:
                'businesses/$businessId/branches/$branchId/users/$userId',
            data: branchPayload,
            merge: true,
          );

      if (!branchWriteSuccess) {
        throw Exception('Failed to create branch-specific staff profile');
      }

      return userId;
    } catch (e) {
      rethrow;
    }
  }

  Future<String> createStaffAuthUser({
    required String businessId,
    required String branchId,
    required String email,
    required String password,
    required String roleId,
    required String roleName,
    required Map<String, String> extraPermissions,
    String? name,
    String? phoneNumber,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in. Please login again and retry.');
      }

      await currentUser.getIdToken(true);

      final callable = FirebaseFunctions.instance.httpsCallable(
        'createBranchStaffUser',
      );

      final result = await callable.call(<String, dynamic>{
        'businessId': businessId,
        'branchId': branchId,
        'email': email,
        'password': password,
        'roleId': roleId,
        'roleName': roleName,
        'extraPermissions': extraPermissions,
        'name': name,
        'phoneNumber': phoneNumber,
      });

      final data = Map<String, dynamic>.from(
        (result.data as Map?) ?? const <String, dynamic>{},
      );
      final uid = (data['uid'] ?? '').toString().trim();
      if (uid.isEmpty) {
        throw Exception('Staff auth user was not created.');
      }

      return uid;
    } on FirebaseFunctionsException catch (e) {
      final detailsText = e.details == null ? '' : ' Details: ${e.details}';
      throw Exception(
        '${e.code}: ${e.message ?? 'Failed to create staff login account.'}$detailsText',
      );
    }
  }

  Future<void> updateStaffAuthUser({
    required String businessId,
    required String branchId,
    required String uid,
    required String roleId,
    String? roleName,
    required Map<String, String> extraPermissions,
    String? name,
    String? phoneNumber,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in. Please login again and retry.');
      }

      await currentUser.getIdToken(true);

      final callable = FirebaseFunctions.instance.httpsCallable(
        'updateBranchStaffUser',
      );

      await callable.call(<String, dynamic>{
        'businessId': businessId,
        'branchId': branchId,
        'uid': uid,
        'roleId': roleId,
        'roleName': roleName,
        'extraPermissions': extraPermissions,
        'name': name,
        'phoneNumber': phoneNumber,
      });
    } on FirebaseFunctionsException catch (e) {
      final detailsText = e.details == null ? '' : ' Details: ${e.details}';
      throw Exception(
        '${e.code}: ${e.message ?? 'Failed to update staff account.'}$detailsText',
      );
    }
  }

  Future<void> deleteStaffAuthUser({
    required String businessId,
    required String branchId,
    required String uid,
  }) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('You are not logged in. Please login again and retry.');
      }

      await currentUser.getIdToken(true);

      final callable = FirebaseFunctions.instance.httpsCallable(
        'deleteBranchStaffUser',
      );

      await callable.call(<String, dynamic>{
        'businessId': businessId,
        'branchId': branchId,
        'uid': uid,
      });
    } on FirebaseFunctionsException catch (e) {
      final detailsText = e.details == null ? '' : ' Details: ${e.details}';
      throw Exception(
        '${e.code}: ${e.message ?? 'Failed to delete staff account.'}$detailsText',
      );
    }
  }

  /// Get single branch-specific user info (role and permissions only)
  Future<Map<String, dynamic>?> getBranchSpecificUsersInfo({
    required String businessId,
    required String branchId,
    required String uid,
  }) async {
    try {
      if (businessId.trim().isEmpty || branchId.trim().isEmpty) {
        return null;
      }

      final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
        businessId: businessId,
        branchId: branchId,
        collectionName: 'users',
        documentId: uid,
      );
      if (localDoc != null) return localDoc;

      //--------------------------THIS ONLY GIVES ROLE AND PERMISSIONS OF USER NOT OTHER DETAILS-----------
      //------------FOR OTHER DETAILS USE GET USER BY ID WHICH WILL RETURN USER OBJECT FROM USER REPOSITORY---------------//
      final doc = await _specificBranchUsersRef(
        businessId,
        branchId,
      ).doc(uid).get();

      if (doc.exists && doc.data() != null) {
        return doc.data() as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get all branch-specific users info (Stream for real-time updates)
  Stream<List<Map<String, dynamic>>> getBranchSpecificAllUsersInfoStream({
    required String businessId,
    required String branchId,
  }) {
    return Stream.multi((controller) {
      List<Map<String, dynamic>> latestRemote = const [];
      StreamSubscription<QuerySnapshot<Object?>>? remoteSub;
      Timer? localTick;
      bool isCancelled = false;

      Future<void> emitMerged() async {
        if (isCancelled) return;
        final local = await OfflineLocalReadService.instance
            .getBranchCollection(
              businessId: businessId,
              branchId: branchId,
              collectionName: 'users',
            );
        if (isCancelled) return;

        final merged = <String, Map<String, dynamic>>{};
        for (final row in local) {
          final uid = (row['__documentId'] ?? '').toString();
          merged[uid] = {...row, 'uid': uid};
        }
        for (final row in latestRemote) {
          // Prefer server truth when online.
          merged[(row['uid'] ?? '').toString()] = row;
        }
        controller.add(merged.values.toList(growable: false));
      }

      localTick = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(emitMerged());
      });

      remoteSub = _specificBranchUsersRef(businessId, branchId)
          .snapshots()
          .listen(
            (snapshot) {
              latestRemote = snapshot.docs
                  .map(
                    (doc) => {
                      ...doc.data() as Map<String, dynamic>,
                      'uid': doc.id,
                    },
                  )
                  .toList(growable: false);
              unawaited(emitMerged());
            },
            onError: (_) {
              // Keep local polling alive if remote listener fails.
            },
          );

      unawaited(emitMerged());

      controller.onCancel = () {
        isCancelled = true;
        localTick?.cancel();
        remoteSub?.cancel();
      };
    });
  }

  /// Get all branch-specific users info (Future for one-time fetch)
  Future<List<Map<String, dynamic>>> getBranchSpecificAllUsersInfo({
    required String businessId,
    required String branchId,
  }) async {
    try {
      final localRows = await OfflineLocalReadService.instance
          .getBranchCollection(
            businessId: businessId,
            branchId: branchId,
            collectionName: 'users',
          );
      final local = localRows
          .map((doc) => {...doc, 'uid': (doc['__documentId'] ?? '').toString()})
          .toList(growable: false);

      final snapshot = await _specificBranchUsersRef(
        businessId,
        branchId,
      ).get();

      final remote = snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'uid': doc.id})
          .toList(growable: false);

      final merged = <String, Map<String, dynamic>>{};
      for (final item in local) {
        merged[(item['uid'] ?? '').toString()] = item;
      }
      for (final item in remote) {
        // Prefer server truth when online.
        merged[(item['uid'] ?? '').toString()] = item;
      }
      return merged.values.toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  /// Get all users of branch (merged: branch-specific + root user data)
  Future<List<UserModel>> getAllUsersOfBranch({
    required String branchId,
    required String businessId,
  }) async {
    try {
      // Get all branch-specific user data
      final branchUsers = await getBranchSpecificAllUsersInfo(
        businessId: businessId,
        branchId: branchId,
      );

      if (branchUsers.isEmpty) return [];

      // Extract all UIDs
      final userIds = branchUsers.map((u) => u['uid'] as String).toList();

      // Root users are loaded local-first by getUsersByIds.
      return getUsersByIds(userIds);
    } catch (e) {
      return [];
    }
  }

  /// Get all users of branch (Stream for real-time updates)
  Stream<List<String>> getAllUsersOfBranchStream({
    required String branchId,
    required String businessId,
  }) {
    return getBranchSpecificAllUsersInfoStream(
      businessId: businessId,
      branchId: branchId,
    ).map((users) => users.map((e) => (e['uid'] ?? '').toString()).toList());
  }

  /// Delete branch-specific user
  Future<void> deleteBranchSpecificUser({
    required String businessId,
    required String branchId,
    required String uid,
    bool deleteRootUser = false, // Optional: delete from root users collection
  }) async {
    try {
      await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
        documentPath: 'businesses/$businessId/branches/$branchId/users/$uid',
      );

      if (deleteRootUser) {
        await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
          documentPath: 'users/$uid',
        );
      } else {
        await OfflineFirestoreWriteQueueService.instance.setOrQueue(
          documentPath: 'users/$uid',
          data: {
            'isStaffMember': false,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          merge: true,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's role
  Future<void> updateUserRole({
    required String uid,
    required String roleId,
    required String businessId,
    required String branchId,
  }) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      String roleName = roleId;
      Map<String, dynamic>? rolePayload;

      try {
        final roleDoc = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .collection('branches')
            .doc(branchId)
            .collection('roles')
            .doc(roleId)
            .get();

        if (roleDoc.exists && roleDoc.data() != null) {
          final roleData = roleDoc.data()!;
          roleName = (roleData['name'] ?? roleId).toString();
          rolePayload = {
            'id': roleId,
            'businessId': businessId,
            'name': roleName,
            'permissions': roleData['permissions'] ?? [],
            'createdAt': roleData['createdAt'] ?? nowIso,
            'updatedAt': nowIso,
          };
        }
      } catch (_) {
        // Keep role update resilient.
      }

      await OfflineFirestoreWriteQueueService.instance.setOrQueue(
        documentPath: 'businesses/$businessId/branches/$branchId/users/$uid',
        data: {'roleId': roleId, 'roleName': roleName, 'updatedAt': nowIso},
        merge: true,
      );

      await OfflineFirestoreWriteQueueService.instance.setOrQueue(
        documentPath: 'users/$uid',
        data: {
          'roleId': roleId,
          'roleName': roleName,
          'role': rolePayload,
          'updatedAt': nowIso,
        },
        merge: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Update user's extra permissions
  Future<void> updateUserExtraPermissions({
    required String uid,
    required Map<String, String> extraPermissions,
    required String businessId,
    required String branchId,
  }) async {
    try {
      final nowIso = DateTime.now().toIso8601String();
      await OfflineFirestoreWriteQueueService.instance.setOrQueue(
        documentPath: 'businesses/$businessId/branches/$branchId/users/$uid',
        data: {'extraPermissions': extraPermissions, 'updatedAt': nowIso},
        merge: true,
      );

      await OfflineFirestoreWriteQueueService.instance.setOrQueue(
        documentPath: 'users/$uid',
        data: {'extraPermissions': extraPermissions, 'updatedAt': nowIso},
        merge: true,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Send invitation email (Cloud Function)
  // Future<void> sendInvitationEmail({
  //   required String email,
  //   required String roleName,
  // }) async {
  //   try {
  //     final functions = FirebaseFunctions.instance;
  //     await functions.httpsCallable('sendStaffInvitation').call({
  //       'email': email,
  //       'businessId': businessId,
  //       'branchId': branchId,
  //       'roleName': roleName,
  //     });
  //   } catch (e) {
  //     print('Error sending invitation email: $e');
  //     rethrow;
  //   }
  // }
}
