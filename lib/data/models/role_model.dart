import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/models/permission_model.dart';

class RoleModel {
  final String id; // Role ID (doc ID in Firestore)
  final String
  businessId; // Multi-tenant: which hotel/business this role belongs to
  final String name; // e.g. "Manager", "Waiter"
  final List<PermissionModel> permissions; // List of permission IDs or keys
  final DateTime createdAt;
  final DateTime updatedAt;

  RoleModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.permissions,
    required this.createdAt,
    required this.updatedAt,
  });

  RoleModel copyWith({
    String? id,
    String? businessId,
    String? name,
    List<PermissionModel>? permissions,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoleModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      name: name ?? this.name,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------- Firestore Serialization ----------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'name': name,
      'permissions': permissions
          .map((permission) => permission.toMap())
          .toList(), // LOGICAL ERROR HERE
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RoleModel.fromMap(Map<String, dynamic> map) {
    return RoleModel(
      id: map['id'],
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      permissions: List<PermissionModel>.from(
        map['permissions']?.map((perm) => PermissionModel.fromMap(perm)) ?? [],
      ),
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  factory RoleModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoleModel.fromMap(data);
  }
}
