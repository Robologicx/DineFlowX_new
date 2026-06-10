// role_repository.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import 'package:hotel_management_system/data/models/role_model.dart';

class RoleRepository {
  final String _businessId;
  final String _branchId;

  RoleRepository({required String businessId, required String branchId})
    : _businessId = businessId,
      _branchId = branchId;

  CollectionReference<Map<String, dynamic>> get _rolesRef => FirebaseFirestore
      .instance
      .collection('businesses')
      .doc(_businessId)
      .collection('branches')
      .doc(_branchId)
      .collection('roles');

  CollectionReference<Map<String, dynamic>> get _branchUsersRef =>
      FirebaseFirestore.instance
          .collection('businesses')
          .doc(_businessId)
          .collection('branches')
          .doc(_branchId)
          .collection('users');

  List<RoleModel> _mergeRolesPreferLocal({
    required List<RoleModel> local,
    required List<RoleModel> remote,
  }) {
    final merged = <String, RoleModel>{};
    for (final role in remote) {
      merged[role.id] = role;
    }
    for (final role in local) {
      merged[role.id] = role;
    }
    final list = merged.values.toList(growable: false);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Stream<List<RoleModel>> _hybridRolesStream() {
    return Stream.multi((controller) {
      List<RoleModel> latestRemote = const [];
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? remoteSub;
      Timer? localTick;
      bool isCancelled = false;

      Future<void> emitMerged() async {
        if (isCancelled) return;
        final localRows = await OfflineLocalReadService.instance
            .getBranchCollection(
              businessId: _businessId,
              branchId: _branchId,
              collectionName: 'roles',
            );
        if (isCancelled) return;

        final local = localRows
            .map(
              (row) => RoleModel.fromMap({
                ...row,
                'id': (row['__documentId'] ?? '').toString(),
              }),
            )
            .toList(growable: false);

        controller.add(
          _mergeRolesPreferLocal(local: local, remote: latestRemote),
        );
      }

      localTick = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(emitMerged());
      });

      remoteSub = _rolesRef.snapshots().listen(
        (snapshot) {
          latestRemote = snapshot.docs
              .map((doc) => RoleModel.fromFirestore(doc))
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

  Future<void> createRole(RoleModel role) async {
    // Generate a new Firestore document ID
    String newId = _rolesRef.doc().id;

    // Convert the role to a map and add the new ID
    final map = role.toMap();
    map['id'] = newId; // Add the new ID to the map

    // Set the data to Firestore
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'businesses/$_businessId/branches/$_branchId/roles/$newId',
      data: map,
      merge: false,
    );
  }

  Future<RoleModel?> getRoleById(String roleId) async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'roles',
      documentId: roleId,
    );
    if (localDoc != null) {
      return RoleModel.fromMap({...localDoc, 'id': roleId});
    }

    final doc = await _rolesRef.doc(roleId).get();
    if (!doc.exists) return null;
    return RoleModel.fromFirestore(doc);
  }

  Future<void> updateRole(RoleModel role) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/roles/${role.id}',
      data: role.toMap(),
      merge: true,
    );

    // Keep user snapshots in sync so permission changes apply immediately
    // without waiting for a full profile rehydrate cycle.
    await _syncUpdatedRoleToUsers(role);
  }

  Future<void> _syncUpdatedRoleToUsers(RoleModel role) async {
    try {
      final seenUids = <String>{};
      final targetUserRefs = <DocumentReference<Map<String, dynamic>>>[];

      final byRoleId = await _branchUsersRef
          .where('roleId', isEqualTo: role.id)
          .get();
      for (final doc in byRoleId.docs) {
        if (seenUids.add(doc.id)) {
          targetUserRefs.add(doc.reference);
        }
      }

      final byRoleName = await _branchUsersRef
          .where('roleName', isEqualTo: role.name)
          .get();
      for (final doc in byRoleName.docs) {
        if (seenUids.add(doc.id)) {
          targetUserRefs.add(doc.reference);
        }
      }

      if (targetUserRefs.isEmpty) return;

      final rolePayload = role.toMap();
      rolePayload['id'] = role.id;
      rolePayload['businessId'] = _businessId;

      final now = FieldValue.serverTimestamp();
      final db = FirebaseFirestore.instance;

      var batch = db.batch();
      var opCount = 0;

      Future<void> flushBatch() async {
        if (opCount == 0) return;
        await batch.commit();
        batch = db.batch();
        opCount = 0;
      }

      for (final branchUserRef in targetUserRefs) {
        final uid = branchUserRef.id;
        final rootUserRef = db.collection('users').doc(uid);

        batch.set(branchUserRef, {
          'roleId': role.id,
          'roleName': role.name,
          'updatedAt': now,
        }, SetOptions(merge: true));
        opCount++;

        batch.set(rootUserRef, {
          'roleId': role.id,
          'roleName': role.name,
          'role': rolePayload,
          'updatedAt': now,
        }, SetOptions(merge: true));
        opCount++;

        if (opCount >= 450) {
          await flushBatch();
        }
      }

      await flushBatch();
    } catch (_) {
      // Do not block role update if fan-out sync fails; next profile hydration
      // will still resolve permissions from the role document.
    }
  }

  Future<void> deleteRole(String roleId) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath: 'businesses/$_businessId/branches/$_branchId/roles/$roleId',
    );
  }

  /// Get all roles for a specific business
  Future<List<RoleModel>> getRolesByBusiness(String businessId) async {
    try {
      final localRows = await OfflineLocalReadService.instance
          .getBranchCollection(
            businessId: _businessId,
            branchId: _branchId,
            collectionName: 'roles',
          );
      final local = localRows
          .map(
            (row) => RoleModel.fromMap({
              ...row,
              'id': (row['__documentId'] ?? '').toString(),
            }),
          )
          .toList(growable: false);

      try {
        final q = await _rolesRef.get();
        final remote = q.docs
            .map((d) => RoleModel.fromFirestore(d))
            .toList(growable: false);
        return _mergeRolesPreferLocal(local: local, remote: remote);
      } catch (_) {
        local.sort((a, b) => a.name.compareTo(b.name));
        return local;
      }
    } catch (e) {
      return [];
    }
  }

  /// Search roles by name within a business
  Future<List<RoleModel>> searchRoles(
    String businessId,
    String searchTerm, {
    int limit = 20,
  }) async {
    final prefix = searchTerm.trim().toLowerCase();
    if (prefix.isEmpty) return [];

    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'roles',
        );
    if (localRows.isNotEmpty) {
      return localRows
          .where(
            (row) =>
                ((row['name'] ?? '').toString().toLowerCase()).contains(prefix),
          )
          .take(limit)
          .map(
            (row) => RoleModel.fromMap({
              ...row,
              'id': (row['__documentId'] ?? '').toString(),
            }),
          )
          .toList();
    }

    final q = await _rolesRef
        .where('name_lower', isGreaterThanOrEqualTo: prefix)
        .where('name_lower', isLessThanOrEqualTo: '$prefix\uf8ff')
        .limit(limit)
        .get();

    return q.docs.map((d) => RoleModel.fromMap(d.data())).toList();
  }

  /// Get roles that contain a specific permission
  Future<List<RoleModel>> getRolesByPermission(String permissionId) async {
    final roles = await getRolesByBusiness(_businessId);
    return roles
        .where((role) => role.permissions.any((p) => p.id == permissionId))
        .toList();
  }

  /// Streams
  Stream<RoleModel?> listenToRole(String roleId) {
    return _hybridRolesStream().map((roles) {
      for (final role in roles) {
        if (role.id == roleId) return role;
      }
      return null;
    });
  }

  Stream<List<RoleModel>> listenToBusinessRoles(String businessId) {
    return _hybridRolesStream();
  }

  /// Check if a role exists
  Future<bool> roleExists(String roleId) async {
    if (roleId.isEmpty) return false;
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'roles',
      documentId: roleId,
    );
    if (localDoc != null) return true;
    final doc = await _rolesRef.doc(roleId).get();
    return doc.exists;
  }
}
