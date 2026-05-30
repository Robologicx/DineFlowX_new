// import 'package:hotel_management_system/data/models/permission_model.dart';
// import 'package:hotel_management_system/data/repositories/role_permission_repository.dart';

// // 🔑 Highlights

// // Repository = pure Firestore CRUD

// // Service = business rules + wrapper methods

// // Added convenience checks (checkAnyPermission, checkAllPermissions)

// // Added default timestamps (createdAt, updatedAt)

// // Keeps the UI layer simple: it only calls the service
// import '../models/role_model.dart';
// import '../repositories/role_permission_repository.dart';

// class RolePermissionService {
//   final RolePermissionRepository _repo;

//   RolePermissionService(this._repo);

//   /// ---------------- Role Management ----------------

//   /// Create role with default empty permissions if none provided
//   Future<void> createRole(
//     String hotelId,
//     String roleId, {
//     required String name,
//     List<PermissionModel>? permissions,
//   }) async {
//     final role = RoleModel(
//       id: roleId,
//       name: name,
//       permissions: permissions ?? List<PermissionModel>.empty(),
//       createdAt: DateTime.now(),
//       businessId: hotelId,
//       updatedAt: DateTime.now(),
//     );
//     await _repo.createRole(hotelId, roleId, role);
//   }

//   /// Update role name or permissions
//   Future<void> editRole(
//     String hotelId,
//     String roleId, {
//     String? name,
//     List<PermissionModel>? permissions,
//   }) async {
//     final updateData = <String, dynamic>{};
//     if (name != null) updateData["name"] = name;
//     if (permissions != null) {
//       updateData["permissions"] = permissions
//           .map((perm) => perm.toMap())
//           .toList();
//     }
//     updateData["updatedAt"] = DateTime.now().toIso8601String();

//     await _repo.updateRole(hotelId, roleId, RoleModel.fromMap(updateData));
//   }

//   /// Delete role safely
//   Future<void> removeRole(String hotelId, String roleId) async {
//     await _repo.deleteRole(hotelId, roleId);
//   }

//   /// Get list of roles
//   Future<List<RoleModel>> listRoles(String hotelId) async {
//     return await _repo.getAllRoles(hotelId);
//   }

//   /// Get details of a single role
//   Future<RoleModel?> getRole(String hotelId, String roleId) async {
//     return await _repo.getRoleById(hotelId, roleId);
//   }

//   /// ---------------- User Role Management ----------------

//   /// Assign role to a user
//   Future<void> assignRole(String hotelId, String userId, String roleId) async {
//     await _repo.assignRoleToUser(hotelId, userId, roleId);
//   }

//   /// Set or overwrite user’s special permissions
//   Future<void> setUserSpecialPermission(
//     String hotelId,
//     String userId,
//     String permission,
//   ) async {
//     final perm = PermissionModel(
//       id: permission,
//       name: permission,
//       description: "Special permission for user",
//       createdAt: DateTime.now(),
//       updatedAt: DateTime.now(),
//     );
//     await _repo.grantExtraPermission(hotelId, userId, perm);
//   }

//   /// Get full access info of a user (role + special perms)
//   Future<RoleModel?> getUserAllPermissions(
//     String hotelId,
//     String userId,
//   ) async {
//     final role = await _repo.getUserRole(hotelId, userId);
//     final extraPermissions = await _repo.getUserExtraPermissions(
//       hotelId,
//       userId,
//     );
//     role.permissions.addAll(extraPermissions);
//     return role;
//   }

//   /// ---------------- Permission Checking ----------------

//   /// Check if user has a permission
//   Future<bool> checkPermission(
//     String hotelId,
//     String userId,
//     PermissionModel permission,
//   ) async {
//     return await _repo.hasPermission(hotelId, userId, permission);
//   }

//   /// Convenience: check if user has any from a list
//   Future<bool> checkAnyPermission(
//     String hotelId,
//     String userId,
//     List<PermissionModel> permissions,
//   ) async {
//     for (final p in permissions) {
//       if (await _repo.hasPermission(hotelId, userId, p)) return true;
//     }
//     return false;
//   }

//   /// Convenience: check if user has all from a list
//   Future<bool> checkAllPermissions(
//     String hotelId,
//     String userId,
//     List<PermissionModel> permissions,
//   ) async {
//     for (final p in permissions) {
//       if (!await _repo.hasPermission(hotelId, userId, p)) return false;
//     }
//     return true;
//   }
// }
