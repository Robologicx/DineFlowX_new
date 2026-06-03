import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/models/permission_model.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'package:hotel_management_system/data/repositories/permission_repository.dart';
import 'package:hotel_management_system/data/repositories/role_repository.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';

class UserService {
  final UserRepository _userRepository;
  final RoleRepository Function(String branchId, String businessId)
  _roleRepoFactory;
  final PermissionRepository Function(String branchId, String businessId)
  _permissionRepoFactory;

  UserService(
    this._userRepository,
    this._roleRepoFactory,
    this._permissionRepoFactory,
  );

  /// Create a new user (with validation)
  Future<void> createUser(UserModel user) async {
    if (user.uid.isEmpty) {
      throw Exception('User ID is required');
    }
    // Additional validations here
    await _userRepository.createUser(user);
  }

  /// Fetch a user by ID
  Future<UserModel?> getUser(String uid) async {
    // This function is responsible for fetching user details from Gerenal Root 'users' collection in Firestore as well as branch specific 'users' collection.
    // General Root 'users' collection is used for authentication and basic user info (Enough for customer)

    // Branch specific 'users' collection is used for role-based access control and permissions (Enough for employee)
    //-----------------------------------------------------------------------------------------------USER CURRENTLY WORKING ON OT THIS     -----------------------------------------------------------------------------------------------//

    UserModel? user = await _userRepository.getUserById(uid);
    if (user != null) {
      Map<String, dynamic>? userDetails;
      final hasBusinessContext =
          user.primarybusinessId.trim().isNotEmpty &&
          user.primaryBranchId.trim().isNotEmpty;

      if (hasBusinessContext) {
        userDetails = await _userRepository.getBranchSpecificUsersInfo(
          businessId: user.primarybusinessId,
          branchId: user.primaryBranchId,
          uid: uid,
        );
      }

      if (userDetails != null) {
        //-------------------------------Merge branch specific details into user model----------------------------------//
        Timestamp timestamp =
            userDetails['createdAt']; // Assuming 'createdAt' is the field with the Timestamp
        DateTime createdAt = timestamp.toDate();

        Timestamp updatedAtTimestamp = userDetails['updatedAt'];
        DateTime updatedAt = updatedAtTimestamp.toDate();

        final rawPermissions = userDetails['permissions'];
        final List<PermissionModel> parsedPermissions = (rawPermissions is List)
            ? rawPermissions.map((perm) {
                if (perm is PermissionModel) {
                  return perm;
                }
                if (perm is Map<String, dynamic>) {
                  return PermissionModel.fromMap(perm);
                }
                if (perm is Map) {
                  return PermissionModel.fromMap(
                    Map<String, dynamic>.from(perm),
                  );
                }
                return PermissionModel(
                  id: perm.toString(),
                  name: perm.toString(),
                  description: '',
                  category: 'Uncategorized',
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                );
              }).toList()
            : <PermissionModel>[];

        final roleId = (userDetails['roleId'] ?? '').toString();
        final roleName =
            (userDetails['roleName'] ?? userDetails['name'] ?? roleId)
                .toString();

        RoleModel role = RoleModel(
          id: roleId,
          businessId: user.primarybusinessId,
          name: roleName,
          permissions: parsedPermissions,
          createdAt: createdAt,
          updatedAt: updatedAt,
        );
        // If user exists in branch specific collection, merge details
        final Map<String, String> stringPermissions =
            (userDetails['extraPermissions'] as Map<String, dynamic>?)?.map(
              (k, v) => MapEntry(k, v.toString()),
            ) ??
            {};
        user = user.copyWith(role: role, extraPermissions: stringPermissions);
      }
      if (!hasBusinessContext) {
        return user;
      }

      final roleId = user.role.id.trim();
      if (roleId.isEmpty) {
        return user;
      }

      final roleRepository = _roleRepoFactory(
        user.primaryBranchId,
        user.primarybusinessId,
      );

      final permissionRepository = _permissionRepoFactory(
        user.primaryBranchId,
        user.primarybusinessId,
      );

      // Now role model is complete with permissions.
      RoleModel? role = await roleRepository.getRoleById(roleId);
      if (role != null) {
        role = role.copyWith(
          permissions: await permissionRepository.getPermissionsByIds(
            role.permissions.map((p) => p.id).toList(),
          ),
        );
      }

      // Merging extra permissions if any
      if (user.extraPermissions.isNotEmpty) {
        final extraPermissions = await permissionRepository.getPermissionsByIds(
          user.extraPermissions.keys.map((p) => p.toString()).toList(),
        );
        // Filter only active permissions
        final activeExtraPermissions = extraPermissions
            .where((permission) => permission.isActive)
            .toList();

        if (role?.permissions == null) {
          role = role?.copyWith(permissions: activeExtraPermissions);
        } else {
          role?.permissions.addAll(activeExtraPermissions);
        }
        user = user.copyWith(role: role);
      }

      //Now user model is complete with role and permissions.

      return user;
    } else {
      return null;
    }
  }

  Future<UserModel?> getUserForBusiness({
    required String uid,
    required String businessId,
  }) async {
    return _userRepository.getUserByIdForBusiness(
      uid: uid,
      businessId: businessId,
    );
  }

  /// Update user data
  Future<void> updateUser(UserModel user) async {
    await _userRepository.updateUser(user);
  }

  /// Delete a user
  Future<void> deleteUser(String uid) async {
    await _userRepository.deleteUser(uid);
  }

  /// Listen to real-time updates
  Stream<UserModel?> listenToUser(String uid) {
    return _userRepository.listenToUser(uid);
  }

  /// Admin-only: Get all users
  Future<List<UserModel>> getAllUsers() async {
    return await _userRepository.getAllUsers();
  }

  Future<List<UserModel>> getAllUsersForBusiness(String businessId) async {
    return _userRepository.getAllUsersForBusiness(businessId);
  }

  //------------------------------Functions relevant to staff user management----------------------------------//

  /// Add new staff member
  Future<String> addStaffMember({
    required String email,
    required String roleId,
    required String roleName,
    required Map<String, String> extraPermissions,
    required String businessId,
    required String branchId,

    String? name,
    String? phoneNumber,
  }) async {
    try {
      // Validate email
      if (!_isValidEmail(email)) {
        throw StaffException('Invalid email address');
      }

      // Check if user already exists with this email
      final existingUser = await _checkUserExistsByEmail(email);
      if (existingUser != null) {
        throw StaffException('User with this email already exists');
      }

      // Create user and set branch-specific info
      final userId = await _userRepository.setBranchSpecificUsersInfo(
        // put new staff member in branch specific collection on provided business and branch
        businessId: businessId,
        branchId: branchId,
        uid: null, // New user
        roleId: roleId,
        extraPermissions: extraPermissions,
        email: email,
        name: name,
        phoneNumber: phoneNumber,
      );

      // Send invitation email
      // await sendInvitationEmail(
      //   email: email,
      //   roleName: roleName,
      // );

      return userId;
    } catch (e) {
      if (e is StaffException) rethrow;
      throw StaffException('Failed to add staff member: $e');
    }
  }

  /// Update existing staff member
  Future<void> updateStaffMember({
    required String uid,
    required String roleId,
    required Map<String, String> extraPermissions,
    required String businessId,
    required String branchId,
    String? name,
    String? phoneNumber,
  }) async {
    try {
      // Update branch-specific and root user info
      await _userRepository.setBranchSpecificUsersInfo(
        businessId: businessId,
        branchId: branchId,
        uid: uid,
        roleId: roleId,
        extraPermissions: extraPermissions,
        name: name,
        phoneNumber: phoneNumber,
      );
    } catch (e) {
      throw StaffException('Failed to update staff member: $e');
    }
  }

  /// Update only role
  Future<void> updateStaffRole({
    required String uid,
    required String roleId,
    required String businessId,
    required String branchId,
  }) async {
    try {
      await _userRepository.updateUserRole(
        uid: uid,
        roleId: roleId,
        businessId: businessId,
        branchId: branchId,
      );
    } catch (e) {
      throw StaffException('Failed to update staff role: $e');
    }
  }

  /// Update only extra permissions
  Future<void> updateStaffPermissions({
    required String uid,
    required Map<String, String> extraPermissions,
    required String businessId,
    required String branchId,
  }) async {
    try {
      await _userRepository.updateUserExtraPermissions(
        uid: uid,
        extraPermissions: extraPermissions,
        businessId: businessId,
        branchId: branchId,
      );
    } catch (e) {
      throw StaffException('Failed to update staff permissions: $e');
    }
  }

  /// Get all staff members with complete details
  Future<List<UserModel>> getAllStaffMembers(
    String businessId,
    String branchId,
  ) async {
    try {
      // Get all UIDs from branch-specific collection
      final branchUsers = await _userRepository.getBranchSpecificAllUsersInfo(
        businessId: businessId,
        branchId: branchId,
      );

      if (branchUsers.isEmpty) return [];

      // Fetch complete user details using UserService
      final List<UserModel> staffMembers = [];

      for (final branchUser in branchUsers) {
        final uid = branchUser['uid'] as String;

        // Use existing UserService.getUser which merges everything
        final user = await getUser(uid);

        if (user != null) {
          staffMembers.add(user);
        }
      }

      return staffMembers;
    } catch (e) {
      throw StaffException('Failed to fetch staff members: $e');
    }
  }

  /// Get single staff member with complete details
  Future<UserModel?> getStaffMember(String uid) async {
    try {
      // Use existing UserService.getUser which handles all merging
      return await getUser(uid);
    } catch (e) {
      throw StaffException('Failed to fetch staff member: $e');
    }
  }

  /// Delete staff member
  Future<void> deleteStaffMember({
    required String uid,
    bool deleteCompletely = false,
    required String businessId,
    required String branchId,
  }) async {
    try {
      await _userRepository.deleteBranchSpecificUser(
        businessId: businessId,
        branchId: branchId,
        uid: uid,
        deleteRootUser: deleteCompletely,
      );
    } catch (e) {
      throw StaffException('Failed to delete staff member: $e');
    }
  }

  /// Get staff members stream (returns UIDs only, fetch details separately)
  Stream<List<String>> getStaffMembersStream(
    String businessId,
    String branchId,
  ) {
    return _userRepository.getAllUsersOfBranchStream(
      branchId: branchId,
      businessId: businessId,
    );
  }

  /// Check if user exists by email
  Future<UserModel?> _checkUserExistsByEmail(String email) async {
    try {
      // Query Firestore for user with this email
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return UserModel.fromMap(doc.id, doc.data());
      }
      return null;
    } catch (e) {
      print('Error checking user exists: $e');
      return null;
    }
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}

/// Custom exception for staff operations
class StaffException implements Exception {
  final String message;
  StaffException(this.message);

  @override
  String toString() => message;
}
