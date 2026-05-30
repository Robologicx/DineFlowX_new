import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Create a new user document
  Future<void> createUser(UserModel user) async {
    await _usersCollection.doc(user.uid).set(user.toMap());
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
      print('Error getting user: $e');
      return null;
    }
  }

  // Get user role from nested collection

  // OLD CODE TO GET SINGLE USER
  Future<UserModel?> getSingleUser(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.id, doc.data()! as Map<String, dynamic>);
  }

  /// Update an existing user
  Future<void> updateUser(UserModel user) async {
    await _usersCollection.doc(user.uid).update(user.toMap());
  }

  /// Delete a user
  Future<void> deleteUser(String uid) async {
    await _usersCollection.doc(uid).delete();
  }

  /// Listen to a specific user's changes
  Stream<UserModel?> listenToUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data()! as Map<String, dynamic>);
    });
  }

  /// Get all users (optional, for admin use)
  Future<List<UserModel>> getAllUsers() async {
    final querySnapshot = await _usersCollection.get();
    return querySnapshot.docs
        .map(
          (doc) =>
              UserModel.fromMap(doc.id, doc.data() as Map<String, dynamic>),
        )
        .toList();
  }

  Future<List<UserModel>> getUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];

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
        print('Error fetching chunk: $e');
      }
    }

    return users;
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
    required Map<String, String> extraPermissions,
    String? email, // Required for new user
    String? name,
    String? phoneNumber,
  }) async {
    try {
      String userId;

      if (uid == null || uid.isEmpty) {
        // Create new user at root level
        final newUserRef = _usersCollection.doc();
        userId = newUserRef.id;

        await newUserRef.set({
          'uid': userId,
          'email': email ?? '',
          'name': name ?? '',
          'phoneNumber': phoneNumber,
          'profileImageUrl': null,
          'primarybusinessId': businessId,
          'primaryBranchId': branchId,
          'isStaffMember': true,
          'favoriteProductIds': [],
          'userLocationText': null,
          'userLatlng': null,
          'deliveryAddresses': [],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        // Update existing user
        userId = uid;

        final updateData = <String, dynamic>{
          'primarybusinessId': businessId,
          'primaryBranchId': branchId,
          'isStaffMember': true,
          'updatedAt': FieldValue.serverTimestamp(),
        };

        // Add optional fields if provided
        if (name != null && name.isNotEmpty) updateData['name'] = name;
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          updateData['phoneNumber'] = phoneNumber;
        }

        await _usersCollection.doc(uid).update(updateData);
      }

      // Set/Update branch-specific user info
      await _specificBranchUsersRef(businessId, branchId).doc(userId).set({
        'uid': userId,
        'roleId': roleId,
        'extraPermissions': extraPermissions,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return userId;
    } catch (e) {
      print('Error setting branch specific user info: $e');
      rethrow;
    }
  }

  /// Get single branch-specific user info (role and permissions only)
  Future<Map<String, dynamic>?> getBranchSpecificUsersInfo({
    required String businessId,
    required String branchId,
    required String uid,
  }) async {
    try {
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
      print('Error getting branch specific user info: $e');
      return null;
    }
  }

  /// Get all branch-specific users info (Stream for real-time updates)
  Stream<List<Map<String, dynamic>>> getBranchSpecificAllUsersInfoStream({
    required String businessId,
    required String branchId,
  }) {
    try {
      return _specificBranchUsersRef(businessId, branchId).snapshots().map(
        (snapshot) => snapshot.docs
            .map(
              (doc) => {...doc.data() as Map<String, dynamic>, 'uid': doc.id},
            )
            .toList(),
      );
    } catch (e) {
      print('Error getting branch specific users stream: $e');
      return Stream.value([]);
    }
  }

  /// Get all branch-specific users info (Future for one-time fetch)
  Future<List<Map<String, dynamic>>> getBranchSpecificAllUsersInfo({
    required String businessId,
    required String branchId,
  }) async {
    try {
      final snapshot = await _specificBranchUsersRef(
        businessId,
        branchId,
      ).get();

      return snapshot.docs
          .map((doc) => {...doc.data() as Map<String, dynamic>, 'uid': doc.id})
          .toList();
    } catch (e) {
      print('Error getting branch specific users: $e');
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

      // Fetch root user data in batches (Firestore 'in' query limit is 10)
      final List<UserModel> users = [];

      for (int i = 0; i < userIds.length; i += 10) {
        final batch = userIds.skip(i).take(10).toList();
        final querySnapshot = await _usersCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        for (final doc in querySnapshot.docs) {
          if (doc.exists) {
            final userData = doc.data() as Map<String, dynamic>;

            // Find corresponding branch-specific data
            final branchData = branchUsers.firstWhere(
              (u) => u['uid'] == doc.id,
              orElse: () => {},
            );

            // Create basic UserModel from root data
            final user = UserModel.fromMap(doc.id, userData);

            // Note: Role and permissions will be merged in the service layer
            // Store branch-specific data temporarily in the model if needed
            users.add(user);
          }
        }
      }

      return users;
    } catch (e) {
      print('Error getting all users of branch: $e');
      return [];
    }
  }

  /// Get all users of branch (Stream for real-time updates)
  Stream<List<String>> getAllUsersOfBranchStream({
    required String branchId,
    required String businessId,
  }) {
    try {
      return _specificBranchUsersRef(businessId, branchId).snapshots().map(
        (snapshot) => snapshot.docs.map((doc) => doc.id).toList(),
      );
    } catch (e) {
      print('Error getting users stream: $e');
      return Stream.value([]);
    }
  }

  /// Delete branch-specific user
  Future<void> deleteBranchSpecificUser({
    required String businessId,
    required String branchId,
    required String uid,
    bool deleteRootUser = false, // Optional: delete from root users collection
  }) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      // Delete from branch-specific collection
      final branchUserRef = _specificBranchUsersRef(
        businessId,
        branchId,
      ).doc(uid);
      batch.delete(branchUserRef);

      // Optional: Delete from root users collection
      if (deleteRootUser) {
        final rootUserRef = _usersCollection.doc(uid);
        batch.delete(rootUserRef);
      } else {
        // Just update to mark as no longer staff member
        final rootUserRef = _usersCollection.doc(uid);
        batch.update(rootUserRef, {
          'isStaffMember': false,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting branch specific user: $e');
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
      await _specificBranchUsersRef(businessId, branchId).doc(uid).update({
        'roleId': roleId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user role: $e');
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
      await _specificBranchUsersRef(businessId, branchId).doc(uid).update({
        'extraPermissions': extraPermissions,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating user extra permissions: $e');
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
