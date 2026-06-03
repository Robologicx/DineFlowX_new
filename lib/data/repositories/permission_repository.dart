// permission_repository.dart
import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import 'package:hotel_management_system/data/models/permission_model.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
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

  List<PermissionModel> _mergePermissionsPreferLocal({
    required List<PermissionModel> local,
    required List<PermissionModel> remote,
  }) {
    final merged = <String, PermissionModel>{};
    for (final item in remote) {
      merged[item.id] = item;
    }
    for (final item in local) {
      merged[item.id] = item;
    }
    final list = merged.values.toList(growable: false);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Stream<List<PermissionModel>> _hybridPermissionsStream() {
    return Stream.multi((controller) {
      List<PermissionModel> latestRemote = const [];
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? remoteSub;
      Timer? localTick;
      bool isCancelled = false;

      Future<void> emitMerged() async {
        if (isCancelled) return;
        final localRows = await OfflineLocalReadService.instance
            .getBranchCollection(
              businessId: _businessId,
              branchId: _branchId,
              collectionName: 'permissions',
            );
        if (isCancelled) return;

        final local = localRows
            .map(
              (d) => PermissionModel.fromMap({
                ...d,
                'id': (d['__documentId'] ?? '').toString(),
              }),
            )
            .toList(growable: false);
        controller.add(
          _mergePermissionsPreferLocal(local: local, remote: latestRemote),
        );
      }

      localTick = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(emitMerged());
      });

      remoteSub = _permissionsRef.snapshots().listen(
        (snapshot) {
          latestRemote = snapshot.docs
              .map(
                (doc) => PermissionModel.fromMap({...doc.data(), 'id': doc.id}),
              )
              .toList(growable: false);
          unawaited(emitMerged());
        },
        onError: (_) {
          // Keep local polling alive even if remote stream fails.
        },
      );

      unawaited(emitMerged());

      controller.onCancel = () {
        isCancelled = true;
        localTick?.cancel();
        remoteSub?.cancel();
      };
    });
  }

  Future<void> createPermission(PermissionModel permission) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/permissions/${permission.id}',
      data: permission.toMap(),
      merge: false,
    );
  }

  Future<PermissionModel?> getPermissionById(String id) async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'permissions',
      documentId: id,
    );
    if (localDoc != null) {
      return PermissionModel.fromMap({...localDoc, 'id': id});
    }

    final doc = await _permissionsRef.doc(id).get();
    if (!doc.exists) return null;
    return PermissionModel.fromMap(doc.data()!);
  }

  Future<void> updatePermission(PermissionModel permission) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/permissions/${permission.id}',
      data: permission.toMap(),
      merge: true,
    );
  }

  Future<void> deletePermission(String id) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/permissions/$id',
    );
  }

  /// Get all permissions (non-deleted)
  Future<List<PermissionModel>> getAllPermissions() async {
    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'permissions',
        );
    final local = localRows
        .map(
          (d) => PermissionModel.fromMap({
            ...d,
            'id': (d['__documentId'] ?? '').toString(),
          }),
        )
        .toList(growable: false);

    try {
      final q = await _permissionsRef.orderBy('name').get();
      final remote = q.docs
          .map((d) => PermissionModel.fromMap({...d.data(), 'id': d.id}))
          .toList(growable: false);
      return _mergePermissionsPreferLocal(local: local, remote: remote);
    } catch (_) {
      local.sort((a, b) => a.name.compareTo(b.name));
      return local;
    }
  }

  /// Get permissions by status (active/inactive)
  Future<List<PermissionModel>> getPermissionsByStatus(bool isActive) async {
    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'permissions',
        );
    if (localRows.isNotEmpty) {
      return localRows
          .where((d) => (d['isActive'] ?? true) == isActive)
          .map(
            (d) => PermissionModel.fromMap({
              ...d,
              'id': (d['__documentId'] ?? '').toString(),
            }),
          )
          .toList();
    }

    final q = await _permissionsRef
        .where('isActive', isEqualTo: isActive)
        .orderBy('name')
        .get();
    return q.docs.map((d) => PermissionModel.fromMap(d.data())).toList();
  }

  /// Get permissions that are shown to all admins
  Future<List<PermissionModel>> getPermissionsShownToAllAdmins() async {
    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'permissions',
        );
    if (localRows.isNotEmpty) {
      return localRows
          .where(
            (d) =>
                (d['isShowingToAllAdmins'] ?? false) == true &&
                (d['isActive'] ?? true) == true,
          )
          .map(
            (d) => PermissionModel.fromMap({
              ...d,
              'id': (d['__documentId'] ?? '').toString(),
            }),
          )
          .toList();
    }

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

    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'permissions',
        );
    if (localRows.isNotEmpty) {
      return localRows
          .where(
            (d) =>
                ((d['name'] ?? '').toString().toLowerCase()).contains(prefix),
          )
          .take(limit)
          .map(
            (d) => PermissionModel.fromMap({
              ...d,
              'id': (d['__documentId'] ?? '').toString(),
            }),
          )
          .toList();
    }

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

    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'permissions',
        );
    if (localRows.isNotEmpty) {
      final target = ids.toSet();
      return localRows
          .where((d) => target.contains((d['__documentId'] ?? '').toString()))
          .map(
            (d) => PermissionModel.fromMap({
              ...d,
              'id': (d['__documentId'] ?? '').toString(),
            }),
          )
          .toList();
    }

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
    return _hybridPermissionsStream().map((permissions) {
      for (final item in permissions) {
        if (item.id == id) return item;
      }
      return null;
    });
  }

  Stream<List<PermissionModel>> listenToAllPermissions() {
    return _hybridPermissionsStream();
  }

  // -------------------- ROLE-PERMISSION RELATIONSHIP METHODS --------------------

  /// Get all roles that use a specific permission
  Future<List<RoleModel>> getRolesUsingPermission(String permissionId) async {
    final localRoles = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'roles',
        );
    return localRoles
        .map(
          (r) => RoleModel.fromMap({
            ...r,
            'id': (r['__documentId'] ?? '').toString(),
          }),
        )
        .where(
          (role) => role.permissions.any((perm) => perm.id == permissionId),
        )
        .toList();
  }

  /// Remove a permission from all roles that use it
  Future<void> removePermissionFromAllRoles(String permissionId) async {
    final localRoles = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'roles',
        );

    for (final roleDoc in localRoles) {
      final roleId = (roleDoc['__documentId'] ?? '').toString();
      final permissions = (roleDoc['permissions'] as List<dynamic>? ?? []);
      final updatedPermissions = permissions.where((permissionMap) {
        if (permissionMap is Map<String, dynamic>) {
          return permissionMap['id'] != permissionId;
        }
        return true;
      }).toList();

      if (updatedPermissions.length != permissions.length) {
        await OfflineFirestoreWriteQueueService.instance.setOrQueue(
          documentPath:
              'businesses/$_businessId/branches/$_branchId/roles/$roleId',
          data: {
            'permissions': updatedPermissions,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          merge: true,
        );
      }
    }
  }

  /// Check if a permission exists
  Future<bool> permissionExists(String permissionId) async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'permissions',
      documentId: permissionId,
    );
    if (localDoc != null) return true;
    final doc = await _permissionsRef.doc(permissionId).get();
    return doc.exists;
  }

  /// Get permission statistics
  Future<Map<String, dynamic>> getPermissionStats() async {
    final permissions = await getAllPermissions();
    final localRoles = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'roles',
        );

    final totalPermissions = permissions.length;

    // Count how many roles use each permission
    Map<String, int> permissionUsage = {};

    for (final roleDoc in localRoles) {
      try {
        final roleData = roleDoc;
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
      'totalRoles': localRoles.length,
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
    final existing = await getAllPermissions();
    final existingIds = existing.map((d) => d.id).toSet();

    for (final perm in corePermissions) {
      if (!existingIds.contains(perm.id)) {
        await createPermission(perm);
      }
    }
  }

  /// Export all permissions for a business as JSON string (for backup/sharing)
  Future<String> exportPermissions(String businessId) async {
    final permissions = (await getAllPermissions())
        .map((doc) => doc.toMap())
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

    final existing = await getAllPermissions();
    final existingIds = existing.map((d) => d.id).toSet();

    for (final perm in newPermissions) {
      if (overwrite || !existingIds.contains(perm.id)) {
        await createPermission(perm);
      }
    }
  }
}
