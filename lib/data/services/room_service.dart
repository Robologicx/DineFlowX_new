import 'package:hotel_management_system/data/models/room_model.dart';
import 'package:hotel_management_system/data/repositories/room_repository.dart';

class RoomService {
  final RoomRepository _repository;

  RoomService(this._repository);

  // ---------- CRUD Operations ----------

  Future<List<RoomModel>> getAllRooms() async {
    try {
      return await _repository.getAllRooms();
    } catch (e) {
      throw Exception('Failed to fetch rooms: $e');
    }
  }

  Future<RoomModel?> getRoomById(String roomId) async {
    try {
      if (roomId.isEmpty) throw Exception('Room ID cannot be empty');
      return await _repository.getRoomById(roomId);
    } catch (e) {
      throw Exception('Failed to fetch room: $e');
    }
  }

  Future<void> createRoom(RoomModel room) async {
    try {
      // Validation
      if (!isValidRoomName(room.name)) {
        throw Exception('Room name must be between 1-100 characters');
      }
      if (room.capacity <= 0) {
        throw Exception('Room capacity must be greater than 0');
      }
      if (room.currentOccupancy < 0) {
        throw Exception('Current occupancy cannot be negative');
      }
      if (room.currentOccupancy > room.capacity) {
        throw Exception('Current occupancy cannot exceed capacity');
      }

      // Check if room name is unique
      final isUnique = await _repository.isRoomNameUnique(room.name);
      if (!isUnique) {
        throw Exception('Room with name "${room.name}" already exists');
      }

      await _repository.createRoom(room);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to create room: $e');
    }
  }

  Future<void> updateRoom(RoomModel room) async {
    try {
      // Validate room exists
      final existingRoom = await _repository.getRoomById(room.id);
      if (existingRoom == null) {
        throw Exception('Room with ID "${room.id}" not found');
      }

      // Validation
      if (!isValidRoomName(room.name)) {
        throw Exception('Room name must be between 1-100 characters');
      }
      if (room.capacity <= 0) {
        throw Exception('Room capacity must be greater than 0');
      }
      if (room.currentOccupancy < 0) {
        throw Exception('Current occupancy cannot be negative');
      }
      if (room.currentOccupancy > room.capacity) {
        throw Exception('Current occupancy cannot exceed capacity');
      }

      // Check if room name is unique (excluding current room)
      final isUnique = await _repository.isRoomNameUnique(room.name);
      if (!isUnique) {
        final existingWithName = await _repository.searchRooms(
          room.name,
          limit: 1,
        );
        if (existingWithName.isNotEmpty &&
            existingWithName.first.id != room.id) {
          throw Exception('Room with name "${room.name}" already exists');
        }
      }

      await _repository.updateRoom(room);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update room: $e');
    }
  }

  Future<void> deleteRoom(String roomId) async {
    try {
      if (roomId.isEmpty) throw Exception('Room ID cannot be empty');

      // Check if room exists
      final exists = await _repository.roomExists(roomId);
      if (!exists) {
        throw Exception('Room with ID "$roomId" not found');
      }

      // Check if room is occupied
      final room = await _repository.getRoomById(roomId);
      if (room != null && room.isOccupied) {
        throw Exception('Cannot delete an occupied room');
      }

      await _repository.deleteRoom(roomId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to delete room: $e');
    }
  }

  // ---------- Room Status Management ----------

  Future<void> setRoomStatus(String roomId, RoomStatus status) async {
    try {
      if (roomId.isEmpty) throw Exception('Room ID cannot be empty');

      final room = await _repository.getRoomById(roomId);
      if (room == null) throw Exception('Room not found');

      // Validate status transition
      if (!isValidStatusTransition(room.status, status)) {
        throw Exception(
          'Invalid status transition from ${room.status.name} to ${status.name}',
        );
      }

      await _repository.updateRoomStatus(roomId, status);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update room status: $e');
    }
  }

  Future<void> occupyRoom(String roomId, int occupancy) async {
    try {
      if (roomId.isEmpty) throw Exception('Room ID cannot be empty');
      if (occupancy <= 0) throw Exception('Occupancy must be greater than 0');

      final room = await _repository.getRoomById(roomId);
      if (room == null) throw Exception('Room not found');

      if (occupancy > room.capacity) {
        throw Exception('Occupancy cannot exceed room capacity');
      }

      if (!room.canBeOccupied) {
        throw Exception('Room is not available for occupancy');
      }

      // Update both status and occupancy
      await _repository.updateRoomStatus(roomId, RoomStatus.occupied);
      await _repository.updateRoomOccupancy(roomId, occupancy);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to occupy room: $e');
    }
  }

  Future<void> vacateRoom(String roomId) async {
    try {
      if (roomId.isEmpty) throw Exception('Room ID cannot be empty');

      final room = await _repository.getRoomById(roomId);
      if (room == null) throw Exception('Room not found');

      await _repository.updateRoomStatus(roomId, RoomStatus.cleaning);
      await _repository.updateRoomOccupancy(roomId, 0);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to vacate room: $e');
    }
  }

  Future<void> markRoomAvailable(String roomId) async {
    try {
      if (roomId.isEmpty) throw Exception('Room ID cannot be empty');

      final room = await _repository.getRoomById(roomId);
      if (room == null) throw Exception('Room not found');

      if (room.currentOccupancy > 0) {
        throw Exception('Cannot mark room as available when it has occupancy');
      }

      await _repository.updateRoomStatus(roomId, RoomStatus.available);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to mark room as available: $e');
    }
  }

  // ---------- Table Management will be dealt separately ---------- //

  // Future<void> addTableToRoom(String roomId, String tableId) async {
  //   try {
  //     if (roomId.isEmpty || tableId.isEmpty) {
  //       throw Exception('Room ID and Table ID cannot be empty');
  //     }

  //     final room = await _repository.getRoomById(roomId);
  //     if (room == null) throw Exception('Room not found');

  //     if (room.tableIds.contains(tableId)) {
  //       throw Exception('Table already exists in this room');
  //     }

  //     await _repository.addTableToRoom(roomId, tableId);
  //   } catch (e) {
  //     if (e is Exception) rethrow;
  //     throw Exception('Failed to add table to room: $e');
  //   }
  // }

  // Future<void> removeTableFromRoom(String roomId, String tableId) async {
  //   try {
  //     if (roomId.isEmpty || tableId.isEmpty) {
  //       throw Exception('Room ID and Table ID cannot be empty');
  //     }

  //     final room = await _repository.getRoomById(roomId);
  //     if (room == null) throw Exception('Room not found');

  //     if (!room.tableIds.contains(tableId)) {
  //       throw Exception('Table not found in this room');
  //     }

  //     await _repository.removeTableFromRoom(roomId, tableId);
  //   } catch (e) {
  //     if (e is Exception) rethrow;
  //     throw Exception('Failed to remove table from room: $e');
  //   }
  // }

  // ---------- Query Operations ----------

  Future<List<RoomModel>> getAvailableRooms() async {
    try {
      return await _repository.getAvailableRooms();
    } catch (e) {
      throw Exception('Failed to fetch available rooms: $e');
    }
  }

  Future<List<RoomModel>> getOccupiedRooms() async {
    try {
      return await _repository.getOccupiedRooms();
    } catch (e) {
      throw Exception('Failed to fetch occupied rooms: $e');
    }
  }

  Future<List<RoomModel>> getRoomsByType(RoomType type) async {
    try {
      return await _repository.getRoomsByType(type);
    } catch (e) {
      throw Exception('Failed to fetch rooms by type: $e');
    }
  }

  Future<List<RoomModel>> searchRooms(
    String searchTerm, {
    int limit = 20,
  }) async {
    try {
      if (searchTerm.trim().isEmpty) {
        return await _repository.getAllRooms();
      }
      return await _repository.searchRooms(searchTerm, limit: limit);
    } catch (e) {
      throw Exception('Failed to search rooms: $e');
    }
  }

  // ---------- Reservation System ----------

  Future<void> reserveRoom(String roomId, Duration duration) async {
    try {
      if (roomId.isEmpty) throw Exception('Room ID cannot be empty');

      final room = await _repository.getRoomById(roomId);
      if (room == null) throw Exception('Room not found');

      if (!room.isAvailable) {
        throw Exception('Room is not available for reservation');
      }

      await _repository.updateRoomStatus(roomId, RoomStatus.reserved);

      // Auto-release reservation after duration
      if (duration.inSeconds > 0) {
        Future.delayed(duration, () async {
          try {
            final currentRoom = await _repository.getRoomById(roomId);
            if (currentRoom != null && currentRoom.isReserved) {
              await _repository.updateRoomStatus(roomId, RoomStatus.available);
            }
          } catch (e) {
            // Log error but don't throw
            print('Auto-release reservation failed: $e');
          }
        });
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to reserve room: $e');
    }
  }

  Future<void> cancelReservation(String roomId) async {
    try {
      if (roomId.isEmpty) throw Exception('Room ID cannot be empty');

      final room = await _repository.getRoomById(roomId);
      if (room == null) throw Exception('Room not found');

      if (!room.isReserved) {
        throw Exception('Room is not reserved');
      }

      await _repository.updateRoomStatus(roomId, RoomStatus.available);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to cancel reservation: $e');
    }
  }

  // ---------- Validation Methods ----------

  bool isValidRoomName(String name) {
    return name.isNotEmpty && name.length <= 100;
  }

  bool isValidStatusTransition(RoomStatus from, RoomStatus to) {
    // Define valid status transitions
    const validTransitions = {
      RoomStatus.available: [
        RoomStatus.occupied,
        RoomStatus.reserved,
        RoomStatus.maintenance,
        RoomStatus.outOfService,
      ],
      RoomStatus.occupied: [
        RoomStatus.cleaning,
        RoomStatus.maintenance,
        RoomStatus.outOfService,
      ],
      RoomStatus.cleaning: [
        RoomStatus.available,
        RoomStatus.maintenance,
        RoomStatus.outOfService,
      ],
      RoomStatus.maintenance: [RoomStatus.available, RoomStatus.outOfService],
      RoomStatus.reserved: [
        RoomStatus.occupied,
        RoomStatus.available,
        RoomStatus.maintenance,
        RoomStatus.outOfService,
      ],
      RoomStatus.outOfService: [RoomStatus.available, RoomStatus.maintenance],
    };

    return validTransitions[from]?.contains(to) ?? false;
  }

  // ---------- Stream Operations ----------

  Stream<RoomModel?> listenToRoom(String roomId) {
    try {
      if (roomId.isEmpty) throw Exception('Room ID cannot be empty');
      return _repository.listenToRoom(roomId);
    } catch (e) {
      throw Exception('Failed to listen to room: $e');
    }
  }

  Stream<List<RoomModel>> listenToAllRooms() {
    try {
      return _repository.listenToAllRooms();
    } catch (e) {
      throw Exception('Failed to listen to rooms: $e');
    }
  }

  Stream<List<RoomModel>> listenToAvailableRooms() {
    try {
      return _repository.listenToRoomsByStatus(RoomStatus.available);
    } catch (e) {
      throw Exception('Failed to listen to available rooms: $e');
    }
  }
}
