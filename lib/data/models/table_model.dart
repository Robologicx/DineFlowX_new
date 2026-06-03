import 'package:cloud_firestore/cloud_firestore.dart';

enum TableStatus { available, occupied, reserved, cleaning, outOfService }

class TableModel {
  final String id;
  final String businessId;
  final String branchId;
  final String tableNumber;
  final String? roomId; // null if standalone table
  final int seats;
  final TableStatus status;
  final String? locationHint;
  final int? mergeGroupId; // for merged tables
  final DateTime createdAt;
  final DateTime updatedAt;

  TableModel({
    required this.id,
    required this.businessId,
    required this.branchId,
    required this.tableNumber,
    this.roomId,
    required this.seats,
    required this.status,
    this.locationHint,
    this.mergeGroupId,
    required this.createdAt,
    required this.updatedAt,
  });

  TableModel copyWith({
    String? id,
    String? businessId,
    String? branchId,
    String? tableNumber,
    String? roomId,
    int? seats,
    TableStatus? status,
    String? locationHint,
    int? mergeGroupId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TableModel(
      id: id ?? this.id,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      tableNumber: tableNumber ?? this.tableNumber,
      roomId: roomId ?? this.roomId,
      seats: seats ?? this.seats,
      status: status ?? this.status,
      locationHint: locationHint ?? this.locationHint,
      mergeGroupId: mergeGroupId ?? this.mergeGroupId,
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
      'tableNumber': tableNumber,
      'roomId': roomId,
      'seats': seats,
      'status': status.name,
      'locationHint': locationHint,
      'mergeGroupId': mergeGroupId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory TableModel.fromMap(Map<String, dynamic> map) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      return DateTime.now();
    }

    return TableModel(
      id: map['id'] ?? '',
      businessId: map['businessId'] ?? '',
      branchId: map['branchId'] ?? '',
      tableNumber: map['tableNumber'] ?? '',
      roomId: map['roomId'],
      seats: map['seats'] ?? 0,
      status: TableStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => TableStatus.available,
      ),
      locationHint: map['locationHint'],
      mergeGroupId: map['mergeGroupId'],
      createdAt: parseDateTime(map['createdAt']),
      updatedAt: parseDateTime(map['updatedAt']),
    );
  }

  factory TableModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TableModel.fromMap({...data, 'id': doc.id});
  }

  // ---------- Helper Methods ----------

  bool get isAvailable => status == TableStatus.available;
  bool get isOccupied => status == TableStatus.occupied;
  bool get isReserved => status == TableStatus.reserved;
  bool get canBeOccupied =>
      status == TableStatus.available || status == TableStatus.reserved;

  bool get isInRoom => roomId != null && roomId!.isNotEmpty;
  bool get isStandalone => roomId == null || roomId!.isEmpty;

  // QR Code Generation (Dynamic - No storage needed)
  String generateQRData() {
    return '$businessId:$branchId:$id';
  }
  // ---------- Validation ----------

  bool get isValid {
    return tableNumber.isNotEmpty &&
        businessId.isNotEmpty &&
        branchId.isNotEmpty &&
        seats > 0;
  }
}
