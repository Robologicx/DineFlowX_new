// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hotel_management_system/data/models/permission_model.dart';
// import '../data/models/user_model.dart';
// import '../data/models/role_model.dart';
// import '../data/services/role_permission_service.dart';

// class RolePermissionState {
//   final List<RoleModel> roles; // all roles
//   final RoleModel? selectedRole;
//   final bool isLoading;
//   final String? error;

//   const RolePermissionState({
//     this.roles = const [],
//     this.selectedRole,
//     this.isLoading = false,
//     this.error,
//   });

//   RolePermissionState copyWith({
//     List<RoleModel>? roles,
//     RoleModel? selectedRole,
//     bool? isLoading,
//     String? error,
//   }) {
//     return RolePermissionState(
//       roles: roles ?? this.roles,
//       selectedRole: selectedRole ?? this.selectedRole,
//       isLoading: isLoading ?? this.isLoading,
//       error: error,
//     );
//   }
// }

// class RolePermissionNotifier extends StateNotifier<RolePermissionState> {
//   final RolePermissionService _service;

//   RolePermissionNotifier(this._service) : super(const RolePermissionState());

//   // ---------------- CRUD methods ----------------//
//   Future<void> loadRoles(String hotelId) async {
//     state = state.copyWith(isLoading: true, error: null);
//     try {
//       final roles = await _service.listRoles(hotelId);
//       state = state.copyWith(roles: roles, isLoading: false);
//     } catch (e) {
//       state = state.copyWith(error: e.toString(), isLoading: false);
//     }
//   }

//   Future<void> selectRole(String hotelId, String roleId) async {
//     state = state.copyWith(isLoading: true, error: null);
//     try {
//       final role = await _service.getRole(hotelId, roleId);
//       state = state.copyWith(selectedRole: role, isLoading: false);
//     } catch (e) {
//       state = state.copyWith(error: e.toString(), isLoading: false);
//     }
//   }

//   Future<void> createRole(String hotelId, String roleId, String name) async {
//     try {
//       await _service.createRole(hotelId, roleId, name: name);
//       await loadRoles(hotelId);
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//     }
//   }

//   Future<void> updateRole(
//     String hotelId,
//     String roleId, {
//     String? name,
//     List<PermissionModel>? permissions,
//   }) async {
//     try {
//       await _service.editRole(
//         hotelId,
//         roleId,
//         name: name,
//         permissions: permissions,
//       );
//       await loadRoles(hotelId);
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//     }
//   }

//   Future<void> deleteRole(String hotelId, String roleId) async {
//     try {
//       await _service.removeRole(hotelId, roleId);
//       await loadRoles(hotelId);
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//     }
//   }

//   // ---------------- New methods (added from service) ----------------

//   /// Assign role to a user
//   Future<void> assignRole(String hotelId, String userId, String roleId) async {
//     try {
//       await _service.assignRole(hotelId, userId, roleId);
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//     }
//   }

//   /// Set or overwrite user’s special permission
//   Future<void> setUserSpecialPermission(
//     String hotelId,
//     String userId,
//     String permission,
//   ) async {
//     try {
//       await _service.setUserSpecialPermission(hotelId, userId, permission);
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//     }
//   }

//   /// Get full access info of a user (role + special perms)
//   Future<RoleModel?> getUserAllPermissions(
//     String hotelId,
//     String userId,
//   ) async {
//     try {
//       return await _service.getUserAllPermissions(hotelId, userId);
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//       return null;
//     }
//   }

//   /// Check if user has a specific permission
//   Future<bool> checkPermission(
//     String hotelId,
//     String userId,
//     PermissionModel permission,
//   ) async {
//     try {
//       return await _service.checkPermission(hotelId, userId, permission);
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//       return false;
//     }
//   }

//   /// Check if user has ANY from a list of permissions
//   Future<bool> checkAnyPermission(
//     String hotelId,
//     String userId,
//     List<PermissionModel> permissions,
//   ) async {
//     try {
//       return await _service.checkAnyPermission(hotelId, userId, permissions);
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//       return false;
//     }
//   }

//   /// Check if user has ALL from a list of permissions
//   Future<bool> checkAllPermissions(
//     String hotelId,
//     String userId,
//     List<PermissionModel> permissions,
//   ) async {
//     try {
//       return await _service.checkAllPermissions(hotelId, userId, permissions);
//     } catch (e) {
//       state = state.copyWith(error: e.toString());
//       return false;
//     }
//   }
// }
