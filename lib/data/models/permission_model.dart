import 'package:cloud_firestore/cloud_firestore.dart';

class PermissionModel {
  final String id; // Permission ID (doc ID or key)
  final String name; // e.g. "create_order"
  final String description; // Human-friendly description
  final String category;
  final bool isActive; // Whether the permission is active
  final bool isShowingToAllAdmins; // Whether to show to all admins
  final bool isSystemDefined;
  final DateTime createdAt;
  final DateTime updatedAt;

  PermissionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    this.isActive = true,
    this.isShowingToAllAdmins = true,
    this.isSystemDefined = false,
    required this.createdAt,
    required this.updatedAt,
  });

  PermissionModel copyWith({
    String? id,
    String? name,
    String? description,
    String? category,
    bool? isActive,
    bool? isShowingToAllAdmins,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PermissionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      isShowingToAllAdmins: isShowingToAllAdmins ?? this.isShowingToAllAdmins,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------- Firestore Serialization ----------

  Map<String, dynamic> toMap() {
    // Conversion to avid issues with DateTime serialization

    return {
      'id': id,
      'name': name,
      'description': description,
      'category': category,
      'isActive': isActive,
      'isSystemDefined': isSystemDefined,
      'isShowingToAllAdmins': isShowingToAllAdmins,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PermissionModel.fromMap(Map<String, dynamic> map) {
    // To avoid conversion issues., make dataTime strings
    if (map['createdAt']!.runtimeType == DateTime ||
        map['updatedAt']!.runtimeType == DateTime) {
      map['createdAt'] = map['createdAt'].toIso8601String();
      map['updatedAt'] = map['updatedAt'].toIso8601String();
    }
    return PermissionModel(
      id: map['id'],
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      category: map['category'] ?? 'Uncategorized',
      isActive: map['isActive'] ?? true,
      isShowingToAllAdmins: map['isShowingToAllAdmins'] ?? true,
      isSystemDefined: map['isSystemDefined'] ?? true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  factory PermissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PermissionModel.fromMap(data);
  }
}
