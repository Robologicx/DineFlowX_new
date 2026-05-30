// permission_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/permission_model.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'package:hotel_management_system/data/services/permission_service.dart';

// State class
class PermissionState {
  final List<PermissionModel> permissions;
  final PermissionModel? currentPermission;
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? stats;

  const PermissionState({
    this.permissions = const [],
    this.currentPermission,
    this.isLoading = false,
    this.error,
    this.stats,
  });

  PermissionState copyWith({
    List<PermissionModel>? permissions,
    PermissionModel? currentPermission,
    bool? isLoading,
    String? error,
    Map<String, dynamic>? stats,
  }) {
    return PermissionState(
      permissions: permissions ?? this.permissions,
      currentPermission: currentPermission ?? this.currentPermission,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      stats: stats ?? this.stats,
    );
  }
}

// Notifier class
class PermissionNotifier extends StateNotifier<PermissionState> {
  final PermissionService _service;

  PermissionNotifier(this._service) : super(const PermissionState());

  // Load all permissions
  Future<void> loadAllPermissions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final permissions = await _service.getAllPermissions();
      state = state.copyWith(
        permissions: permissions,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadAllCorePermissions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final permissions = await _service.importPermissionsToFirebase();
      await loadAllPermissions();
      state = state.copyWith(isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get a specific permission
  Future<void> getPermissionById(String permissionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final permission = await _service.getPermissionById(permissionId);
      state = state.copyWith(
        currentPermission: permission,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Create a new permission
  Future<bool> createPermission(PermissionModel permission) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createPermission(permission);
      await loadAllPermissions(); // Reload the list
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update a permission
  Future<bool> updatePermission(PermissionModel permission) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updatePermission(permission);
      await loadAllPermissions(); // Reload the list
      await getPermissionById(permission.id); // Refresh current permission
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete a permission
  Future<bool> deletePermission(String permissionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deletePermission(permissionId);

      // Update local state without reloading
      final updatedPermissions = state.permissions
          .where((p) => p.id != permissionId)
          .toList();

      state = state.copyWith(
        permissions: updatedPermissions,
        isLoading: false,
        error: null,
        currentPermission: state.currentPermission?.id == permissionId
            ? null
            : state.currentPermission,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Force delete a permission
  Future<bool> forceDeletePermission(String permissionId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.forceDeletePermission(permissionId);

      // Update local state without reloading
      final updatedPermissions = state.permissions
          .where((p) => p.id != permissionId)
          .toList();

      state = state.copyWith(
        permissions: updatedPermissions,
        isLoading: false,
        error: null,
        currentPermission: state.currentPermission?.id == permissionId
            ? null
            : state.currentPermission,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Search permissions
  Future<void> searchPermissions(String searchTerm) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.searchPermissions(searchTerm);
      state = state.copyWith(
        permissions: results,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get roles using a permission
  Future<List<RoleModel>> getRolesUsingPermission(String permissionId) async {
    try {
      return await _service.getRolesUsingPermission(permissionId);
    } catch (e) {
      throw Exception('Failed to get roles using permission: $e');
    }
  }

  // Get permission statistics
  Future<void> loadPermissionStats() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final stats = await _service.getPermissionStats();
      state = state.copyWith(stats: stats, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear current permission
  void clearCurrentPermission() {
    state = state.copyWith(currentPermission: null);
  }

  // Reset to initial state
  void reset() {
    state = const PermissionState();
  }
}

// Notifier provider
// final myPermissionProvider =
//     StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
//       final service = ref.read(
//         permissionProvider((
//           branchId: ref.watch(userProvider).selectedUser!.primaryBranchId,
//           businessId: ref.watch(userProvider).selectedUser!.primarybusinessId,
//         )),
//       );
//       return PermissionNotifier(service);
//     });

// final myPermissionProvider = StateNotifierProvider<PermissionNotifier, PermissionState>((ref) {
//   final service = ref.read(
//     permissionProvider((
//       branchId: ref.watch(userProvider).selectedUser!.primaryBranchId,
//       businessId: ref.watch(userProvider).selectedUser!.primarybusinessId,
//     )),
//   );
//   return PermissionNotifier(service);
// });

// // Selectors for easier access
// final permissionsListProvider = Provider<List<PermissionModel>>((ref) {
//   return ref.watch(myPermissionProvider).permissions;
// });

// final currentPermissionProvider = Provider<PermissionModel?>((ref) {
//   return ref.watch(myPermissionProvider).currentPermission;
// });

// final permissionLoadingProvider = Provider<bool>((ref) {
//   return ref.watch(myPermissionProvider).isLoading;
// });

// final permissionErrorProvider = Provider<String?>((ref) {
//   return ref.watch(myPermissionProvider).error;
// });

// final permissionStatsProvider = Provider<Map<String, dynamic>?>((ref) {
//   return ref.watch(myPermissionProvider).stats;
// });
