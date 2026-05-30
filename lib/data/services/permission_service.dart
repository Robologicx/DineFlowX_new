// permission_service.dart
import 'package:hotel_management_system/data/models/permission_model.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'package:hotel_management_system/data/repositories/permission_repository.dart';

class PermissionService {
  final PermissionRepository _repository;

  PermissionService(this._repository);

  // ---------- CRUD OPERATIONS ----------

  Future<List<PermissionModel>> getAllPermissions() async {
    try {
      return await _repository.getAllPermissions();
    } catch (e) {
      throw Exception('Failed to fetch permissions: $e');
    }
  }

  Future<PermissionModel?> getPermissionById(String permissionId) async {
    try {
      if (permissionId.isEmpty) {
        throw Exception('Permission ID cannot be empty');
      }
      return await _repository.getPermissionById(permissionId);
    } catch (e) {
      throw Exception('Failed to fetch permission: $e');
    }
  }

  Future<void> createPermission(PermissionModel permission) async {
    try {
      // Validate permission data
      if (!isValidPermissionId(permission.id)) {
        throw Exception(
          'Invalid permission ID format. Use lowercase letters, numbers, underscores, and hyphens only.',
        );
      }

      if (!isValidPermissionName(permission.name)) {
        throw Exception('Permission name must be between 1-100 characters');
      }

      if (!isValidPermissionDescription(permission.description)) {
        throw Exception(
          'Permission description must be between 1-500 characters',
        );
      }

      // Check if permission already exists
      final exists = await _repository.permissionExists(permission.id);
      if (exists) {
        throw Exception('Permission with ID "${permission.id}" already exists');
      }

      await _repository.createPermission(permission);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to create permission: $e');
    }
  }

  Future<void> updatePermission(PermissionModel permission) async {
    try {
      // Validate permission exists
      final existingPermission = await _repository.getPermissionById(
        permission.id,
      );
      if (existingPermission == null) {
        throw Exception('Permission with ID "${permission.id}" not found');
      }

      // Validate updated data
      if (!isValidPermissionName(permission.name)) {
        throw Exception('Permission name must be between 1-100 characters');
      }

      if (!isValidPermissionDescription(permission.description)) {
        throw Exception(
          'Permission description must be between 1-500 characters',
        );
      }

      await _repository.updatePermission(permission);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update permission: $e');
    }
  }

  Future<void> deletePermission(String permissionId) async {
    try {
      if (permissionId.isEmpty) {
        throw Exception('Permission ID cannot be empty');
      }

      // Check if permission exists
      final exists = await _repository.permissionExists(permissionId);
      if (!exists) {
        throw Exception('Permission with ID "$permissionId" not found');
      }

      // Check if permission is used by any roles
      final rolesUsingPermission = await _repository.getRolesUsingPermission(
        permissionId,
      );
      if (rolesUsingPermission.isNotEmpty) {
        throw Exception(
          'Cannot delete permission. It is used by ${rolesUsingPermission.length} role(s). Remove it from all roles first.',
        );
      }

      await _repository.deletePermission(permissionId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to delete permission: $e');
    }
  }

  Future<void> forceDeletePermission(String permissionId) async {
    try {
      if (permissionId.isEmpty) {
        throw Exception('Permission ID cannot be empty');
      }

      // Check if permission exists
      final exists = await _repository.permissionExists(permissionId);
      if (!exists) {
        throw Exception('Permission with ID "$permissionId" not found');
      }

      // Remove permission from all roles first
      await _repository.removePermissionFromAllRoles(permissionId);

      // Then delete the permission
      await _repository.deletePermission(permissionId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to force delete permission: $e');
    }
  }

  // ---------- QUERY OPERATIONS ----------

  Future<List<PermissionModel>> getPermissionsByStatus(bool isActive) async {
    try {
      return await _repository.getPermissionsByStatus(isActive);
    } catch (e) {
      throw Exception('Failed to fetch permissions by status: $e');
    }
  }

  Future<List<PermissionModel>> getPermissionsShownToAllAdmins() async {
    try {
      return await _repository.getPermissionsShownToAllAdmins();
    } catch (e) {
      throw Exception('Failed to fetch permissions shown to all admins: $e');
    }
  }

  Future<List<PermissionModel>> searchPermissions(
    String searchTerm, {
    int limit = 20,
  }) async {
    try {
      if (searchTerm.trim().isEmpty) {
        return await _repository.getAllPermissions();
      }
      return await _repository.searchPermissions(searchTerm, limit: limit);
    } catch (e) {
      throw Exception('Failed to search permissions: $e');
    }
  }

  Future<List<PermissionModel>> getPermissionsByIds(
    List<String> permissionIds,
  ) async {
    try {
      if (permissionIds.isEmpty) return [];
      return await _repository.getPermissionsByIds(permissionIds);
    } catch (e) {
      throw Exception('Failed to fetch permissions by IDs: $e');
    }
  }

  Future<List<RoleModel>> getRolesUsingPermission(String permissionId) async {
    try {
      if (permissionId.isEmpty) {
        throw Exception('Permission ID cannot be empty');
      }
      return await _repository.getRolesUsingPermission(permissionId);
    } catch (e) {
      throw Exception('Failed to fetch roles using permission: $e');
    }
  }

  Future<Map<String, dynamic>> getPermissionStats() async {
    try {
      return await _repository.getPermissionStats();
    } catch (e) {
      throw Exception('Failed to fetch permission statistics: $e');
    }
  }

  // ---------- VALIDATION METHODS ----------

  bool isValidPermissionId(String id) {
    return RegExp(r'^[a-z0-9_-]+$').hasMatch(id) && id.isNotEmpty;
  }

  bool isValidPermissionName(String name) {
    return name.isNotEmpty && name.length <= 100;
  }

  bool isValidPermissionDescription(String description) {
    return description.isNotEmpty && description.length <= 500;
  }

  // ---------- STREAM OPERATIONS ----------

  Stream<PermissionModel?> listenToPermission(String permissionId) {
    try {
      if (permissionId.isEmpty) {
        throw Exception('Permission ID cannot be empty');
      }
      return _repository.listenToPermission(permissionId);
    } catch (e) {
      throw Exception('Failed to listen to permission: $e');
    }
  }

  Stream<List<PermissionModel>> listenToAllPermissions() {
    try {
      return _repository.listenToAllPermissions();
    } catch (e) {
      throw Exception('Failed to listen to permissions: $e');
    }
  }

  Future<void> importPermissionsToFirebase() {
    try {
      return _repository.importPermissionsFromLocalToDB();
    } catch (e) {
      throw Exception('Failed to listen to permissions: $e');
    }
  }
}
