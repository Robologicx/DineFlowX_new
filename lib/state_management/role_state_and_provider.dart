// role_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'package:hotel_management_system/data/models/permission_model.dart';
import 'package:hotel_management_system/data/services/role_service.dart';

// State class
class RoleState {
  final List<RoleModel> roles;
  final RoleModel? currentRole;
  final bool isLoading;
  final String? error;
  final String currentBusinessId;

  const RoleState({
    this.roles = const [],
    this.currentRole,
    this.isLoading = false,
    this.error,
    this.currentBusinessId = '',
  });

  RoleState copyWith({
    List<RoleModel>? roles,
    RoleModel? currentRole,
    bool? isLoading,
    String? error,
    String? currentBusinessId,
  }) {
    return RoleState(
      roles: roles ?? this.roles,
      currentRole: currentRole ?? this.currentRole,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentBusinessId: currentBusinessId ?? this.currentBusinessId,
    );
  }
}

// Notifier class
class RoleNotifier extends StateNotifier<RoleState> {
  final RoleService _service;

  RoleNotifier(this._service) : super(const RoleState());

  // Set current business ID
  void setBusinessId(String businessId) {
    state = state.copyWith(currentBusinessId: businessId);
  }

  // Load all roles for current business
  Future<void> getAllRolesOfBuisness() async {
    if (state.currentBusinessId.isEmpty) {
      state = state.copyWith(error: 'Business ID not set');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final roles = await _service.getRolesByBusiness(state.currentBusinessId);
      state = state.copyWith(roles: roles, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get a specific role
  Future<void> getRole(String roleId) async {
    if (state.currentBusinessId.isEmpty) {
      state = state.copyWith(error: 'Business ID not set');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final role = await _service.getRoleById(roleId);
      state = state.copyWith(currentRole: role, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Create a new role
  Future<bool> createRole(RoleModel role) async {
    if (state.currentBusinessId.isEmpty) {
      state = state.copyWith(error: 'Business ID not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createRole(role);
      await getAllRolesOfBuisness(); // Reload the list
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update a role
  Future<bool> updateRole(RoleModel role) async {
    if (state.currentBusinessId.isEmpty) {
      state = state.copyWith(error: 'Business ID not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateRole(role);
      await getAllRolesOfBuisness(); // Reload the list
      await getRole(role.id); // Refresh current role
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete a role
  Future<bool> deleteRole(String roleId) async {
    if (state.currentBusinessId.isEmpty) {
      state = state.copyWith(error: 'Business ID not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteRole(roleId, state.currentBusinessId);

      // Update local state without reloading
      final updatedRoles = state.roles.where((r) => r.id != roleId).toList();

      state = state.copyWith(
        roles: updatedRoles,
        isLoading: false,
        error: null,
        currentRole: state.currentRole?.id == roleId ? null : state.currentRole,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Add permission to role
  Future<bool> addPermissionToRole(
    String roleId,
    PermissionModel permission,
  ) async {
    if (state.currentBusinessId.isEmpty) {
      state = state.copyWith(error: 'Business ID not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.addPermissionToRole(
        roleId,
        state.currentBusinessId,
        permission,
      );
      await getRole(roleId); // Refresh current role
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Remove permission from role
  Future<bool> removePermissionFromRole(
    String roleId,
    String permissionId,
  ) async {
    if (state.currentBusinessId.isEmpty) {
      state = state.copyWith(error: 'Business ID not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.removePermissionFromRole(
        roleId,
        state.currentBusinessId,
        permissionId,
      );
      await getRole(roleId); // Refresh current role
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update role permissions
  Future<bool> updateRolePermissions(
    String roleId,
    List<PermissionModel> permissions,
  ) async {
    if (state.currentBusinessId.isEmpty) {
      state = state.copyWith(error: 'Business ID not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateRolePermissions(
        roleId,
        state.currentBusinessId,
        permissions,
      );
      await getRole(roleId); // Refresh current role
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Search roles
  Future<void> searchRoles(String searchTerm) async {
    if (state.currentBusinessId.isEmpty) {
      state = state.copyWith(error: 'Business ID not set');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.searchRoles(
        state.currentBusinessId,
        searchTerm,
      );
      state = state.copyWith(roles: results, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get roles by permission
  Future<List<RoleModel>> getRolesByPermission(String permissionId) async {
    try {
      return await _service.getRolesByPermission(permissionId);
    } catch (e) {
      throw Exception('Failed to get roles by permission: $e');
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear current role
  void clearCurrentRole() {
    state = state.copyWith(currentRole: null);
  }

  // Reset to initial state
  void reset() {
    state = const RoleState();
  }
}

// /// Role Notifier provider
// final myRoleProvider = StateNotifierProvider<RoleNotifier, RoleState>((ref) {
//   final service = ref.read(roleProvider);
//   return RoleNotifier(service);
// });

// // Selectors for easier access
// final rolesListProvider = Provider<List<RoleModel>>((ref) {
//   return ref.watch(myRoleProvider).roles;
// });

// final currentRoleProvider = Provider<RoleModel?>((ref) {
//   return ref.watch(myRoleProvider).currentRole;
// });

// final roleLoadingProvider = Provider<bool>((ref) {
//   return ref.watch(myRoleProvider).isLoading;
// });

// final roleErrorProvider = Provider<String?>((ref) {
//   return ref.watch(myRoleProvider).error;
// });

// final currentBusinessIdProvider = Provider<String>((ref) {
//   return ref.watch(myRoleProvider).currentBusinessId;
// });
