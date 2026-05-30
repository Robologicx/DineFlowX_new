// permission_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/models/permission_model.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'dart:convert';
import 'package:hotel_management_system/permissions.dart';

class PermissionRepository {
  PermissionRepository({required String businessId, required String branchId})
    : _businessId = businessId,
      _branchId = branchId;
  // Reference to the nested permissions collection
  CollectionReference<Map<String, dynamic>> get _permissionsRef =>
      FirebaseFirestore.instance
          .collection('businesses')
          .doc(_businessId)
          .collection('branches')
          .doc(_branchId)
          .collection('permissions');
  final String _businessId;
  final String _branchId;

  Future<void> createPermission(PermissionModel permission) async {
    await _permissionsRef.doc(permission.id).set(permission.toMap());
  }

  Future<PermissionModel?> getPermissionById(String id) async {
    final doc = await _permissionsRef.doc(id).get();
    if (!doc.exists) return null;
    return PermissionModel.fromMap(doc.data()!);
  }

  Future<void> updatePermission(PermissionModel permission) async {
    await _permissionsRef.doc(permission.id).update(permission.toMap());
  }

  Future<void> deletePermission(String id) async {
    await _permissionsRef.doc(id).delete();
  }

  /// Get all permissions (non-deleted)
  Future<List<PermissionModel>> getAllPermissions() async {
    final q = await _permissionsRef.orderBy('name').get();
    return q.docs
        .map((d) => PermissionModel.fromMap(d.data()))
        .toList(growable: false);
  }

  /// Get permissions by status (active/inactive)
  Future<List<PermissionModel>> getPermissionsByStatus(bool isActive) async {
    final q = await _permissionsRef
        .where('isActive', isEqualTo: isActive)
        .orderBy('name')
        .get();
    return q.docs.map((d) => PermissionModel.fromMap(d.data())).toList();
  }

  /// Get permissions that are shown to all admins
  Future<List<PermissionModel>> getPermissionsShownToAllAdmins() async {
    final q = await _permissionsRef
        .where('isShowingToAllAdmins', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .get();
    return q.docs.map((d) => PermissionModel.fromMap(d.data())).toList();
  }

  /// Search permissions by name or description (case-insensitive prefix search)
  Future<List<PermissionModel>> searchPermissions(
    String searchTerm, {
    int limit = 20,
  }) async {
    final prefix = searchTerm.trim().toLowerCase();
    if (prefix.isEmpty) return [];

    // This requires your documents to also store lowercase fields for search
    final q = await _permissionsRef
        .where('name_lower', isGreaterThanOrEqualTo: prefix)
        .where('name_lower', isLessThanOrEqualTo: '$prefix\uf8ff')
        .limit(limit)
        .get();

    return q.docs.map((d) => PermissionModel.fromMap(d.data())).toList();
  }

  /// Get permissions by multiple IDs
  Future<List<PermissionModel>> getPermissionsByIds(List<String> ids) async {
    if (ids.isEmpty) return [];

    const int batchSize = 10;
    List<PermissionModel> allPermissions = [];

    for (int i = 0; i < ids.length; i += batchSize) {
      final batch = ids.skip(i).take(batchSize).toList();

      final q = await _permissionsRef
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      final batchPermissions = q.docs
          .map((d) => PermissionModel.fromMap(d.data()))
          .toList();

      allPermissions.addAll(batchPermissions);
    }

    return allPermissions;
  }

  /// Streams
  Stream<PermissionModel?> listenToPermission(String id) {
    return _permissionsRef.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return PermissionModel.fromMap(doc.data()!);
    });
  }

  Stream<List<PermissionModel>> listenToAllPermissions() {
    return _permissionsRef
        .orderBy('name')
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => PermissionModel.fromMap(d.data())).toList(),
        );
  }

  // -------------------- ROLE-PERMISSION RELATIONSHIP METHODS --------------------

  /// Get all roles that use a specific permission
  Future<List<RoleModel>> getRolesUsingPermission(String permissionId) async {
    final rolesSnapshot = await FirebaseFirestore.instance
        .collectionGroup('roles')
        .get();

    List<RoleModel> rolesUsingPermission = [];

    for (final doc in rolesSnapshot.docs) {
      try {
        final roleData = doc.data();
        final permissions = roleData['permissions'] as List<dynamic>? ?? [];

        // Check if this role has the permission
        final hasPermission = permissions.any((perm) {
          if (perm is Map<String, dynamic>) {
            return perm['id'] == permissionId;
          }
          return false;
        });

        if (hasPermission) {
          final role = RoleModel.fromMap(doc.data());
          rolesUsingPermission.add(role);
        }
      } catch (e) {
        // Skip malformed role documents
        continue;
      }
    }

    return rolesUsingPermission;
  }

  /// Remove a permission from all roles that use it
  Future<void> removePermissionFromAllRoles(String permissionId) async {
    final rolesSnapshot = await FirebaseFirestore.instance
        .collectionGroup('roles')
        .get();

    final batch = FirebaseFirestore.instance.batch();

    for (final roleDoc in rolesSnapshot.docs) {
      final roleData = roleDoc.data();
      final permissions = roleData['permissions'] as List<dynamic>? ?? [];

      final updatedPermissions = permissions.where((permissionMap) {
        if (permissionMap is Map<String, dynamic>) {
          return permissionMap['id'] != permissionId;
        }
        return true;
      }).toList();

      // If permissions changed, update the role
      if (updatedPermissions.length != permissions.length) {
        batch.update(roleDoc.reference, {
          'permissions': updatedPermissions,
          'updatedAt': DateTime.now().toIso8601String(),
        });
      }
    }

    await batch.commit();
  }

  /// Check if a permission exists
  Future<bool> permissionExists(String permissionId) async {
    final doc = await _permissionsRef.doc(permissionId).get();
    return doc.exists;
  }

  /// Get permission statistics
  Future<Map<String, dynamic>> getPermissionStats() async {
    final permissionsSnapshot = await _permissionsRef.get();
    final rolesSnapshot = await FirebaseFirestore.instance
        .collectionGroup('roles')
        .get();

    // Count permissions
    final totalPermissions = permissionsSnapshot.docs.length;

    // Count how many roles use each permission
    Map<String, int> permissionUsage = {};

    for (final roleDoc in rolesSnapshot.docs) {
      try {
        final roleData = roleDoc.data();
        final permissions = roleData['permissions'] as List<dynamic>? ?? [];

        for (final perm in permissions) {
          if (perm is Map<String, dynamic> && perm['id'] is String) {
            final permId = perm['id'] as String;
            permissionUsage[permId] = (permissionUsage[permId] ?? 0) + 1;
          }
        }
      } catch (e) {
        // Skip malformed documents
        continue;
      }
    }

    return {
      'totalPermissions': totalPermissions,
      'totalRoles': rolesSnapshot.docs.length,
      'permissionUsage': permissionUsage,
      'unusedPermissions': totalPermissions - permissionUsage.keys.length,
      'mostUsedPermission': permissionUsage.isNotEmpty
          ? permissionUsage.entries
                .reduce((a, b) => a.value > b.value ? a : b)
                .key
          : null,
    };
  }

  /// Uploads all core permissions if not already existing
  Future<void> uploadCorePermissionsIfMissing(
    String businessId,
    List<PermissionModel> corePermissions,
  ) async {
    final existingDocs = await _permissionsRef.get();
    final existingIds = existingDocs.docs.map((d) => d.id).toSet();

    for (final perm in corePermissions) {
      if (!existingIds.contains(perm.id)) {
        await _permissionsRef.doc(perm.id).set(perm.toMap());
        print("✅ Uploaded: ${perm.name}");
      } else {
        print("⚪ Skipped existing: ${perm.name}");
      }
    }
  }

  /// Export all permissions for a business as JSON string (for backup/sharing)
  Future<String> exportPermissions(String businessId) async {
    final snapshot = await _permissionsRef.get();

    final permissions = snapshot.docs
        .map((doc) => PermissionModel.fromMap(doc.data()).toMap())
        .toList();

    return jsonEncode(permissions);
  }

  /// Import permissions in bulk (restore or merge)
  /// If `overwrite` = false, only adds missing ones
  Future<void> importPermissionsFromLocalToDB({bool overwrite = false}) async {
    // if we want to import using string then uncomment it.
    // final core_permissions =
    //     jsonDecode(permissionsRegistry) as List<Map<String, dynamic>>;

    // final decoded = jsonDecode(jsonPermissions) as List<Map<String, dynamic>>;
    final corePermissions =
        permissionsRegistry; // Already a List<Map<String, dynamic>>
    final newPermissions = corePermissions
        .map((e) => PermissionModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();

    final existingDocs = await _permissionsRef.get();
    final existingIds = existingDocs.docs.map((d) => d.id).toSet();

    for (final perm in newPermissions) {
      if (overwrite || !existingIds.contains(perm.id)) {
        await _permissionsRef.doc(perm.id).set(perm.toMap());
        print("✅ Imported: ${perm.name}");
      } else {
        print("⚪ Skipped: ${perm.name}");
      }
    }
  }
}
