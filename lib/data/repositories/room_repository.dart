import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
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

  List<RoomModel> _mergeRoomsPreferLocal({
    required List<RoomModel> local,
    required List<RoomModel> remote,
  }) {
    final merged = <String, RoomModel>{};
    for (final room in remote) {
      merged[room.id] = room;
    }
    for (final room in local) {
      merged[room.id] = room;
    }
    final list = merged.values.toList(growable: false);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  List<RoomModel> _filterRooms(
    List<RoomModel> rooms, {
    RoomStatus? status,
    RoomType? type,
  }) {
    Iterable<RoomModel> result = rooms;
    if (status != null) {
      result = result.where((r) => r.status == status);
    }
    if (type != null) {
      result = result.where((r) => r.type == type);
    }
    final list = result.toList(growable: false);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Stream<List<RoomModel>> _hybridRoomsStream({
    RoomStatus? status,
    RoomType? type,
  }) {
    return Stream.multi((controller) {
      List<RoomModel> latestRemote = const [];
      StreamSubscription<QuerySnapshot>? remoteSub;
      Timer? localTick;
      bool isCancelled = false;

      Future<void> emitMerged() async {
        if (isCancelled) return;
        final localRows = await OfflineLocalReadService.instance
            .getBranchCollection(
              businessId: _businessId,
              branchId: _branchId,
              collectionName: 'rooms',
            );
        if (isCancelled) return;

        final local = _filterRooms(
          localRows.map((m) => RoomModel.fromMap(m)).toList(growable: false),
          status: status,
          type: type,
        );
        final remote = _filterRooms(latestRemote, status: status, type: type);
        controller.add(_mergeRoomsPreferLocal(local: local, remote: remote));
      }

      localTick = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(emitMerged());
      });

      remoteSub = _roomsRef.snapshots().listen(
        (snapshot) {
          latestRemote = snapshot.docs
              .map((doc) => RoomModel.fromFirestore(doc))
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

  // ---------- CRUD Operations ----------

  Future<void> createRoom(RoomModel room) async {
    final String newId = _roomsRef.doc().id;
    final map = room.toMap();
    map['id'] = newId;
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'businesses/$_businessId/branches/$_branchId/rooms/$newId',
      data: map,
      merge: false,
    );
  }

  Future<RoomModel?> getRoomById(String roomId) async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'rooms',
      documentId: roomId,
    );
    if (localDoc != null) {
      return RoomModel.fromMap({...localDoc, 'id': roomId});
    }

    final doc = await _roomsRef.doc(roomId).get();
    if (!doc.exists) return null;
    return RoomModel.fromFirestore(doc);
  }

  Future<void> updateRoom(RoomModel room) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/rooms/${room.id}',
      data: room.toMap(),
      merge: true,
    );
  }

  Future<void> deleteRoom(String roomId) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath: 'businesses/$_businessId/branches/$_branchId/rooms/$roomId',
    );
  }

  // ---------- Query Operations ----------

  Future<List<RoomModel>> getAllRooms() async {
    try {
      final localRows = await OfflineLocalReadService.instance
          .getBranchCollection(
            businessId: _businessId,
            branchId: _branchId,
            collectionName: 'rooms',
          );
      final local = localRows
          .map((map) => RoomModel.fromMap(map))
          .toList(growable: false);

      try {
        final query = await _roomsRef.orderBy('name').get();
        final remote = query.docs
            .map((doc) => RoomModel.fromFirestore(doc))
            .toList(growable: false);
        return _mergeRoomsPreferLocal(local: local, remote: remote);
      } catch (_) {
        local.sort((a, b) => a.name.compareTo(b.name));
        return local;
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<RoomModel>> getRoomsByStatus(RoomStatus status) async {
    try {
      final all = await getAllRooms();
      return _filterRooms(all, status: status);
    } catch (e) {
      return [];
    }
  }

  Future<List<RoomModel>> getRoomsByType(RoomType type) async {
    try {
      final all = await getAllRooms();
      return _filterRooms(all, type: type);
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
      final all = await getAllRooms();
      return all
          .where((room) => room.name.toLowerCase().contains(prefix))
          .take(limit)
          .toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  // ---------- Room Management Operations ----------

  Future<void> updateRoomStatus(String roomId, RoomStatus status) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'businesses/$_businessId/branches/$_branchId/rooms/$roomId',
      data: {
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      merge: true,
    );
  }

  Future<void> updateRoomOccupancy(String roomId, int occupancy) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'businesses/$_businessId/branches/$_branchId/rooms/$roomId',
      data: {
        'currentOccupancy': occupancy,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      merge: true,
    );
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
    return _hybridRoomsStream().map((rooms) {
      for (final room in rooms) {
        if (room.id == roomId) return room;
      }
      return null;
    });
  }

  Stream<List<RoomModel>> listenToAllRooms() {
    return _hybridRoomsStream();
  }

  Stream<List<RoomModel>> listenToRoomsByStatus(RoomStatus status) {
    return _hybridRoomsStream(status: status);
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
