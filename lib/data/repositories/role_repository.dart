// role_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/models/role_model.dart';

class RoleRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final String _businessId;
  final String _branchId;

  RoleRepository({required String businessId, required String branchId})
    : _businessId = businessId,
      _branchId = branchId;

  CollectionReference<Object?> get _rolesRef => FirebaseFirestore.instance
      .collection('businesses')
      .doc(_businessId)
      .collection('branches')
      .doc(_branchId)
      .collection('roles');

  Future<void> createRole(RoleModel role) async {
    // Generate a new Firestore document ID
    String newId = _rolesRef.doc().id;

    // Convert the role to a map and add the new ID
    final map = role.toMap();
    map['id'] = newId; // Add the new ID to the map

    // Set the data to Firestore
    await _rolesRef.doc(newId).set(map);
  }

  Future<RoleModel?> getRoleById(String roleId) async {
    final doc = await _rolesRef.doc(roleId).get();
    if (!doc.exists) return null;
    return RoleModel.fromFirestore(doc);
  }

  Future<void> updateRole(RoleModel role) async {
    await _rolesRef.doc(role.id).update(role.toMap());
  }

  Future<void> deleteRole(String roleId) async {
    await _rolesRef.doc(roleId).delete();
  }

  /// Get all roles for a specific business
  Future<List<RoleModel>> getRolesByBusiness(String businessId) async {
    try {
      final q = await _rolesRef
          // .where('businessId', isEqualTo: businessId)
          // .orderBy('name')
          .get();
      return q.docs
          .map((d) => RoleModel.fromMap(d.data() as Map<String, dynamic>))
          .toList(growable: false);
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

    final q = await _rolesRef
        .where('name_lower', isGreaterThanOrEqualTo: prefix)
        .where('name_lower', isLessThanOrEqualTo: '$prefix\uf8ff')
        .limit(limit)
        .get();

    return q.docs
        .map((d) => RoleModel.fromMap(d.data()! as Map<String, dynamic>))
        .toList();
  }

  /// Get roles that contain a specific permission
  Future<List<RoleModel>> getRolesByPermission(String permissionId) async {
    final rolesSnapshot = await _firestore.collectionGroup('roles').get();

    List<RoleModel> rolesWithPermission = [];

    for (final doc in rolesSnapshot.docs) {
      try {
        final roleData = doc.data();
        final permissions = roleData['permissions'] as List<dynamic>? ?? [];

        final hasPermission = permissions.any((perm) {
          if (perm is Map<String, dynamic>) {
            return perm['id'] == permissionId;
          }
          return false;
        });

        if (hasPermission) {
          final role = RoleModel.fromMap(roleData);
          rolesWithPermission.add(role);
        }
      } catch (e) {
        continue;
      }
    }

    return rolesWithPermission;
  }

  /// Streams
  Stream<RoleModel?> listenToRole(String roleId) {
    return _rolesRef.doc(roleId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RoleModel.fromMap(doc.data()! as Map<String, dynamic>);
    });
  }

  Stream<List<RoleModel>> listenToBusinessRoles(String businessId) {
    return _rolesRef
        .orderBy('name')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => RoleModel.fromMap(d.data()! as Map<String, dynamic>))
              .toList(),
        );
  }

  /// Check if a role exists
  Future<bool> roleExists(String roleId) async {
    if (roleId.isEmpty) return false;
    final doc = await _rolesRef.doc(roleId).get();
    return doc.exists;
  }
}
