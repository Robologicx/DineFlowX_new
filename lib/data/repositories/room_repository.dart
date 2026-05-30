import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/models/room_model.dart';

class RoomRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _businessId;
  final String _branchId;

  RoomRepository({required String businessId, required String branchId})
    : _businessId = businessId,
      _branchId = branchId;

  CollectionReference get _roomsRef => _firestore
      .collection('businesses')
      .doc(_businessId)
      .collection('branches')
      .doc(_branchId)
      .collection('rooms');

  // ---------- CRUD Operations ----------

  Future<void> createRoom(RoomModel room) async {
    final String newId = _roomsRef.doc().id;
    final map = room.toMap();
    map['id'] = newId;
    await _roomsRef.doc(newId).set(map);
  }

  Future<RoomModel?> getRoomById(String roomId) async {
    final doc = await _roomsRef.doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromFirestore(doc);
  }

  Future<void> updateRoom(RoomModel room) async {
    await _roomsRef.doc(room.id).update(room.toMap());
  }

  Future<void> deleteRoom(String roomId) async {
    await _roomsRef.doc(roomId).delete();
  }

  // ---------- Query Operations ----------

  Future<List<RoomModel>> getAllRooms() async {
    try {
      final query = await _roomsRef.orderBy('name').get();
      return query.docs
          .map((doc) => RoomModel.fromFirestore(doc))
          .toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  Future<List<RoomModel>> getRoomsByStatus(RoomStatus status) async {
    try {
      final query = await _roomsRef
          .where('status', isEqualTo: status.name)
          .orderBy('name')
          .get();
      return query.docs
          .map((doc) => RoomModel.fromFirestore(doc))
          .toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  Future<List<RoomModel>> getRoomsByType(RoomType type) async {
    try {
      final query = await _roomsRef
          .where('type', isEqualTo: type.name)
          .orderBy('name')
          .get();
      return query.docs
          .map((doc) => RoomModel.fromFirestore(doc))
          .toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  Future<List<RoomModel>> getAvailableRooms() async {
    return getRoomsByStatus(RoomStatus.available);
  }

  Future<List<RoomModel>> getOccupiedRooms() async {
    return getRoomsByStatus(RoomStatus.occupied);
  }

  Future<List<RoomModel>> searchRooms(
    String searchTerm, {
    int limit = 20,
  }) async {
    final prefix = searchTerm.trim().toLowerCase();
    if (prefix.isEmpty) return [];

    try {
      final query = await _roomsRef
          .where('name_lower', isGreaterThanOrEqualTo: prefix)
          .where('name_lower', isLessThanOrEqualTo: '$prefix\uf8ff')
          .limit(limit)
          .get();

      return query.docs.map((doc) => RoomModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------- Room Management Operations ----------

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await _roomsRef.doc(roomId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> updateRoomOccupancy(String roomId, int occupancy) async {
    await _roomsRef.doc(roomId).update({
      'currentOccupancy': occupancy,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  // ------------------------No need to put table ID's in Rooms-----------------------//
  // Future<void> addTableToRoom(String roomId, String tableId) async {
  //   final room = await getRoomById(roomId);
  //   if (room == null) throw Exception('Room not found');

  //   final updatedTableIds = List<String>.from(room.tableIds)..add(tableId);
  //   await _roomsRef.doc(roomId).update({
  //     'tableIds': updatedTableIds,
  //     'updatedAt': DateTime.now().toIso8601String(),
  //   });
  // }

  // Future<void> removeTableFromRoom(String roomId, String tableId) async {
  //   final room = await getRoomById(roomId);
  //   if (room == null) throw Exception('Room not found');

  //   // final updatedTableIds = room.tableIds.where((id) => id != tableId).toList();
  //   // await _roomsRef.doc(roomId).update({
  //   //   'tableIds': updatedTableIds,
  //   //   'updatedAt': DateTime.now().toIso8601String(),
  //   // });
  // }

  // ---------- Stream Operations ----------

  Stream<RoomModel?> listenToRoom(String roomId) {
    return _roomsRef.doc(roomId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return RoomModel.fromFirestore(doc);
    });
  }

  Stream<List<RoomModel>> listenToAllRooms() {
    return _roomsRef
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList(growable: false),
        );
  }

  Stream<List<RoomModel>> listenToRoomsByStatus(RoomStatus status) {
    return _roomsRef
        .where('status', isEqualTo: status.name)
        .orderBy('name')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
              .toList(growable: false),
        );
  }

  // ---------- Validation ----------

  Future<bool> roomExists(String roomId) async {
    final doc = await _roomsRef.doc(roomId).get();
    return doc.exists;
  }

  Future<bool> isRoomNameUnique(String name) async {
    final query = await _roomsRef
        .where('name_lower', isEqualTo: name.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }
}
