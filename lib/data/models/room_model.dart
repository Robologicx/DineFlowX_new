import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomType { regular, vip, private }

enum RoomStatus {
  available,
  occupied,
  cleaning,
  maintenance,
  reserved,
  outOfService,
}

class RoomModel {
  final String id;
  final String businessId;
  final String branchId;
  final String name;
  final String? description;
  final RoomType type;
  final int capacity;
  final int currentOccupancy;
  final RoomStatus status;
  // final List<String> tableIds; // References to dining tables in this room ---------------// dont wanna store table ids here, instead table will have room id
  final List<String> amenities;
  final String? floor;
  final String? section;
  final DateTime createdAt;
  final DateTime updatedAt;

  RoomModel({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.name,
    this.description,
    required this.type,
    required this.capacity,
    required this.currentOccupancy,
    required this.status,
    // required this.tableIds,
    required this.amenities,
    this.floor,
    this.section,
    required this.createdAt,
    required this.updatedAt,
  });

  RoomModel copyWith({
    String? id,
    String? businessId,
    String? branchId,
    String? name,
    String? description,
    RoomType? type,
    int? capacity,
    int? currentOccupancy,
    RoomStatus? status,
    List<String>? tableIds,
    List<String>? amenities,
    String? floor,
    String? section,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RoomModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      capacity: capacity ?? this.capacity,
      currentOccupancy: currentOccupancy ?? this.currentOccupancy,
      status: status ?? this.status,
      // tableIds: tableIds ?? this.tableIds,
      amenities: amenities ?? this.amenities,
      floor: floor ?? this.floor,
      section: section ?? this.section,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ---------- Firestore Serialization ----------

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'businessId': businessId,
      'branchId': branchId,
      'name': name,
      'description': description,
      'type': type.name,
      'capacity': capacity,
      'currentOccupancy': currentOccupancy,
      'status': status.name,
      // 'tableIds': tableIds,
      'amenities': amenities,
      'floor': floor,
      'section': section,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory RoomModel.fromMap(Map<String, dynamic> map) {
    return RoomModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      branchId: map['branchId'] ?? '',
      name: map['name'] ?? '',
      description: map['description'],
      type: RoomType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => RoomType.regular,
      ),
      capacity: map['capacity'] ?? 0,
      currentOccupancy: map['currentOccupancy'] ?? 0,
      status: RoomStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RoomStatus.available,
      ),
      // tableIds: List<String>.from(map['tableIds'] ?? []),
      amenities: List<String>.from(map['amenities'] ?? []),
      floor: map['floor'],
      section: map['section'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] ?? '') ?? DateTime.now(),
    );
  }

  factory RoomModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RoomModel.fromMap({...data, 'id': doc.id});
  }

  // ---------- Helper Methods ----------

  bool get isAvailable => status == RoomStatus.available;
  bool get isOccupied => status == RoomStatus.occupied;
  bool get isReserved => status == RoomStatus.reserved;
  bool get canBeOccupied =>
      status == RoomStatus.available || status == RoomStatus.reserved;

  double get occupancyRate => capacity > 0 ? currentOccupancy / capacity : 0.0;
  bool get isAtCapacity => currentOccupancy >= capacity;
  int get availableSpots => capacity - currentOccupancy;

  // ---------- Validation ----------

  bool get isValid {
    return name.isNotEmpty &&
        businessId.isNotEmpty &&
        branchId.isNotEmpty &&
        capacity > 0 &&
        currentOccupancy >= 0 &&
        currentOccupancy <= capacity;
  }
}
