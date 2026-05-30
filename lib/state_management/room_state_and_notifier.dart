import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/room_model.dart';
import 'package:hotel_management_system/data/services/room_service.dart';

class RoomState {
  final List<RoomModel> rooms;
  final RoomModel? currentRoom;
  final bool isLoading;
  final String? error;
  final String currentBusinessId;
  final String currentBranchId;

  const RoomState({
    this.rooms = const [],
    this.currentRoom,
    this.isLoading = false,
    this.error,
    this.currentBusinessId = '',
    this.currentBranchId = '',
  });

  RoomState copyWith({
    List<RoomModel>? rooms,
    RoomModel? currentRoom,
    bool? isLoading,
    String? error,
    String? currentBusinessId,
    String? currentBranchId,
  }) {
    return RoomState(
      rooms: rooms ?? this.rooms,
      currentRoom: currentRoom ?? this.currentRoom,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentBusinessId: currentBusinessId ?? this.currentBusinessId,
      currentBranchId: currentBranchId ?? this.currentBranchId,
    );
  }
}

class RoomNotifier extends StateNotifier<RoomState> {
  final RoomService _service;

  RoomNotifier(this._service) : super(const RoomState());

  // Set current business context
  void setBusinessContext(String businessId, String branchId) {
    state = state.copyWith(
      currentBusinessId: businessId,
      currentBranchId: branchId,
    );
  }

  // Load all rooms
  Future<void> loadAllRooms() async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final rooms = await _service.getAllRooms();
      state = state.copyWith(rooms: rooms, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get specific room
  Future<void> getRoom(String roomId) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final room = await _service.getRoomById(roomId);
      state = state.copyWith(currentRoom: room, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Create new room
  Future<bool> createRoom(RoomModel room) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createRoom(room);
      await loadAllRooms(); // Reload the list
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update room
  Future<bool> updateRoom(RoomModel room) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateRoom(room);
      await loadAllRooms(); // Reload the list
      await getRoom(room.id); // Refresh current room
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete room
  Future<bool> deleteRoom(String roomId) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteRoom(roomId);

      // Update local state without reloading
      final updatedRooms = state.rooms.where((r) => r.id != roomId).toList();
      state = state.copyWith(
        rooms: updatedRooms,
        isLoading: false,
        error: null,
        currentRoom: state.currentRoom?.id == roomId ? null : state.currentRoom,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Room status management
  Future<bool> setRoomStatus(String roomId, RoomStatus status) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.setRoomStatus(roomId, status);
      await loadAllRooms(); // Reload to reflect status changes
      await getRoom(roomId); // Refresh current room
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> occupyRoom(String roomId, int occupancy) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.occupyRoom(roomId, occupancy);
      await loadAllRooms();
      await getRoom(roomId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> vacateRoom(String roomId) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.vacateRoom(roomId);
      await loadAllRooms();
      await getRoom(roomId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> markRoomAvailable(String roomId) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.markRoomAvailable(roomId);
      await loadAllRooms();
      await getRoom(roomId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Reservation system
  Future<bool> reserveRoom(String roomId, Duration duration) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.reserveRoom(roomId, duration);
      await loadAllRooms();
      await getRoom(roomId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelReservation(String roomId) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.cancelReservation(roomId);
      await loadAllRooms();
      await getRoom(roomId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Table management will be handled in separate repo / service / class and screen.
  // Future<bool> addTableToRoom(String roomId, String tableId) async {
  //   if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
  //     state = state.copyWith(error: 'Business context not set');
  //     return false;
  //   }

  //   state = state.copyWith(isLoading: true, error: null);
  //   try {
  //     await _service.addTableToRoom(roomId, tableId);
  //     await getRoom(roomId); // Refresh current room
  //     return true;
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //     return false;
  //   }
  // }

  // Future<bool> removeTableFromRoom(String roomId, String tableId) async {
  //   if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
  //     state = state.copyWith(error: 'Business context not set');
  //     return false;
  //   }

  //   state = state.copyWith(isLoading: true, error: null);
  //   try {
  //     await _service.removeTableFromRoom(roomId, tableId);
  //     await getRoom(roomId); // Refresh current room
  //     return true;
  //   } catch (e) {
  //     state = state.copyWith(isLoading: false, error: e.toString());
  //     return false;
  //   }
  // }

  // Search rooms
  Future<void> searchRooms(String searchTerm) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.searchRooms(searchTerm);
      state = state.copyWith(rooms: results, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get filtered rooms
  Future<void> getAvailableRooms() async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final rooms = await _service.getAvailableRooms();
      state = state.copyWith(rooms: rooms, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getOccupiedRooms() async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final rooms = await _service.getOccupiedRooms();
      state = state.copyWith(rooms: rooms, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Utility methods
  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearCurrentRoom() {
    state = state.copyWith(currentRoom: null);
  }

  void reset() {
    state = const RoomState();
  }
}
