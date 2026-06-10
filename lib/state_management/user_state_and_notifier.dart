import 'dart:async';

import 'package:hotel_management_system/data/services/user_service.dart';

import '../data/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Immutable state for User
class UserState {
  final UserModel? selectedUser;
  final List<UserModel> users;
  final bool isLoading;
  final String? error;

  const UserState({
    this.selectedUser,
    this.users = const [],
    this.isLoading = false,
    this.error,
  });

  static const Object _noValue = Object();

  UserState copyWith({
    Object? selectedUser = _noValue,
    List<UserModel>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      selectedUser: identical(selectedUser, _noValue)
          ? this.selectedUser
          : selectedUser as UserModel?,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier handles business logic for UserState

class UserNotifier extends StateNotifier<UserState> {
  final UserService _service;
  StreamSubscription<UserModel?>? _userSubscription;

  UserNotifier(this._service) : super(const UserState());

  Set<String> _normalizedPermissionKeys(Map<String, String> permissions) {
    return permissions.keys.map((k) => k.trim().toLowerCase()).toSet();
  }

  Set<String> _normalizedRolePermissionKeys(UserModel user) {
    return user.role.permissions
        .map((p) => p.id.trim().toLowerCase())
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  bool _isSameUserSnapshot(UserModel? a, UserModel? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;

    return a.uid == b.uid &&
        a.name == b.name &&
        a.email == b.email &&
        a.phoneNumber == b.phoneNumber &&
        a.profileImageUrl == b.profileImageUrl &&
        a.primarybusinessId == b.primarybusinessId &&
        a.primaryBranchId == b.primaryBranchId &&
        a.role.id == b.role.id &&
        a.role.name == b.role.name &&
        _normalizedPermissionKeys(
          a.extraPermissions,
        ).difference(_normalizedPermissionKeys(b.extraPermissions)).isEmpty &&
        _normalizedPermissionKeys(
          b.extraPermissions,
        ).difference(_normalizedPermissionKeys(a.extraPermissions)).isEmpty &&
        _normalizedRolePermissionKeys(
          a,
        ).difference(_normalizedRolePermissionKeys(b)).isEmpty &&
        _normalizedRolePermissionKeys(
          b,
        ).difference(_normalizedRolePermissionKeys(a)).isEmpty;
  }

  void setUser(UserModel user) {
    state = state.copyWith(selectedUser: user, isLoading: false, error: null);
  }

  void clearCurrentUser() {
    state = state.copyWith(
      selectedUser: null,
      users: const [],
      isLoading: false,
      error: null,
    );
  }

  Future<void> loadAllUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _service.getAllUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadUser(String uid) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _service.getUser(uid);
      state = state.copyWith(selectedUser: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createUser(UserModel user) async {
    try {
      await _service.createUser(user);
      await loadAllUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  bool hasPermissionOfCurrentUser(String permission, {String? businessId}) {
    final selectedUser = state.selectedUser;
    if (selectedUser == null) {
      return false;
    }

    final normalizedPermission = permission.trim().toLowerCase();
    if (normalizedPermission.isEmpty) {
      return false;
    }

    if (businessId != null && selectedUser.primarybusinessId != businessId) {
      return false;
    }

    final roleName = selectedUser.role.name.trim().toLowerCase();
    // Never grant implicit access when role metadata is missing.
    // This prevents waiter/staff accounts from receiving full access.
    if (roleName.isEmpty) {
      return false;
    }

    if (roleName == 'admin' || roleName == 'owner') {
      return true;
    }

    final extraPermissionIds = selectedUser.extraPermissions.keys
        .map((p) => p.trim().toLowerCase())
        .toSet();

    if (extraPermissionIds.contains(normalizedPermission)) {
      return true;
    }

    final rolePermissionIds = selectedUser.role.permissions
        .map((p) => p.id.trim().toLowerCase())
        .toSet();

    if (rolePermissionIds.contains(normalizedPermission)) {
      return true;
    }

    // Fallback compatibility for records that may only hold permission names.
    final rolePermissionNames = selectedUser.role.permissions
        .map((p) => p.name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toSet();

    return rolePermissionNames.contains(normalizedPermission);
  }

  Future<void> updateUser(UserModel user) async {
    try {
      await _service.updateUser(user);
      await loadUser(user.uid);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteUser(String uid) async {
    try {
      await _service.deleteUser(uid);
      await loadAllUsers();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// Stream updates to keep UI synced in real-time
  void listenToUser(String uid) {
    _userSubscription?.cancel();
    _userSubscription = _service.listenToUser(uid).listen((user) {
      if (_isSameUserSnapshot(state.selectedUser, user)) {
        return;
      }
      state = state.copyWith(selectedUser: user);
    });
  }

  @override
  void dispose() {
    _userSubscription?.cancel();
    super.dispose();
  }

  /// ============================================================================
  /// STAFF MANAGEMENT FUNCTIONS (Add to UserNotifier)
  /// ============================================================================

  /// Temporary staff member for form submission (not the logged-in user)
  UserModel? _tempStaffMember;

  /// Load all staff members for a specific branch
  Future<void> loadAllStaffMembers({
    required String businessId,
    required String branchId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final staffMembers = await _service.getAllStaffMembers(
        businessId,
        branchId,
      );
      state = state.copyWith(
        users: staffMembers, // Reuse existing users list
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Load single staff member details
  Future<void> loadStaffMember(String uid) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final staff = await _service.getStaffMember(uid);
      if (staff != null) {
        _tempStaffMember = staff; // Store in temporary variable
        state = state.copyWith(isLoading: false);
      } else {
        state = state.copyWith(
          error: 'Staff member not found',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  /// Add new staff member
  Future<bool> addStaffMember({
    required String email,
    required String password,
    required String roleId,
    required String roleName,
    required Map<String, String> extraPermissions,
    required String businessId,
    required String branchId,
    String? name,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final userId = await _service.addStaffMember(
        email: email,
        password: password,
        roleId: roleId,
        roleName: roleName,
        extraPermissions: extraPermissions,
        businessId: businessId,
        branchId: branchId,
        name: name,
        phoneNumber: phoneNumber,
      );

      // Refresh staff list
      await loadAllStaffMembers(businessId: businessId, branchId: branchId);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Update staff member (role + permissions + optional details)
  Future<bool> updateStaffMember({
    required String uid,
    required String roleId,
    required Map<String, String> extraPermissions,
    required String businessId,
    required String branchId,
    String? name,
    String? phoneNumber,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateStaffMember(
        uid: uid,
        roleId: roleId,
        extraPermissions: extraPermissions,
        businessId: businessId,
        branchId: branchId,
        name: name,
        phoneNumber: phoneNumber,
      );

      // Refresh staff list
      await loadAllStaffMembers(businessId: businessId, branchId: branchId);

      // If current logged-in user was updated, refresh immediately so
      // permissions/role changes apply in-app without waiting for next login.
      if (state.selectedUser?.uid == uid) {
        await loadUser(uid);
      }

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Update only staff role
  Future<bool> updateStaffRole({
    required String uid,
    required String roleId,
    required String businessId,
    required String branchId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateStaffRole(
        uid: uid,
        roleId: roleId,
        businessId: businessId,
        branchId: branchId,
      );

      // Refresh staff list
      await loadAllStaffMembers(businessId: businessId, branchId: branchId);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Update only staff extra permissions
  Future<bool> updateStaffPermissions({
    required String uid,
    required Map<String, String> extraPermissions,
    required String businessId,
    required String branchId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.updateStaffPermissions(
        uid: uid,
        extraPermissions: extraPermissions,
        businessId: businessId,
        branchId: branchId,
      );

      // Refresh staff list
      await loadAllStaffMembers(businessId: businessId, branchId: branchId);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Delete staff member
  Future<bool> deleteStaffMember({
    required String uid,
    bool deleteCompletely = false,
    required String businessId,
    required String branchId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _service.deleteStaffMember(
        uid: uid,
        deleteCompletely: deleteCompletely,
        businessId: businessId,
        branchId: branchId,
      );

      // Refresh staff list
      await loadAllStaffMembers(businessId: businessId, branchId: branchId);

      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return false;
    }
  }

  /// Get temporary staff member (for forms/editing)
  UserModel? getTempStaffMember() {
    return _tempStaffMember;
  }

  /// Set temporary staff member (for editing)
  void setTempStaffMember(UserModel? staff) {
    _tempStaffMember = staff;
  }

  /// Clear temporary staff member
  void clearTempStaffMember() {
    _tempStaffMember = null;
  }
}
