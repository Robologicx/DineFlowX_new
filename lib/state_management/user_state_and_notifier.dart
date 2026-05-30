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

  UserState copyWith({
    UserModel? selectedUser,
    List<UserModel>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      selectedUser: selectedUser ?? this.selectedUser,
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// StateNotifier handles business logic for UserState

class UserNotifier extends StateNotifier<UserState> {
  final UserService _service;

  UserNotifier(this._service) : super(const UserState());

  void setUser(UserModel user) {
    state = state.copyWith(selectedUser: user, isLoading: false, error: null);
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

  bool hasPermissionOfCurrentUser(String permission) {
    final selectedUser = state.selectedUser;
    if (selectedUser == null) {
      return false;
    }

    final roleName = selectedUser.role.name.toLowerCase();
    if (roleName == 'admin' || roleName == 'owner') {
      return true;
    }

    if (selectedUser.extraPermissions.keys.contains(permission)) {
      return true;
    }

    final rolePermissionIds = selectedUser.role.permissions
        .map((p) => p.id)
        .toSet();

    return rolePermissionIds.contains(permission);
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
    _service.listenToUser(uid).listen((user) {
      state = state.copyWith(selectedUser: user);
    });
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
