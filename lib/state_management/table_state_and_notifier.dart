import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/data/services/table_service.dart';

class TableState {
  final List<TableModel> tables;
  final TableModel? currentTable;
  final bool isLoading;
  final String? error;
  // final String currentBusinessId;
  // final String currentBranchId;

  const TableState({
    this.tables = const [],
    this.currentTable,
    this.isLoading = false,
    this.error,
    // this.currentBusinessId = '',
    // this.currentBranchId = '',
  });

  TableState copyWith({
    List<TableModel>? tables,
    TableModel? currentTable,
    bool? isLoading,
    String? error,
    // String? currentBusinessId,
    // String? currentBranchId,
  }) {
    return TableState(
      tables: tables ?? this.tables,
      currentTable: currentTable ?? this.currentTable,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      // currentBusinessId: currentBusinessId ?? this.currentBusinessId,
      // currentBranchId: currentBranchId ?? this.currentBranchId,
    );
  }
}

class TableNotifier extends StateNotifier<TableState> {
  final TableService _service;

  TableNotifier(this._service) : super(const TableState());

  // Set current business context
  // void setBusinessContext(String businessId, String branchId) {
  //   state = state.copyWith(
  //     currentBusinessId: businessId,
  //     currentBranchId: branchId,
  //   );
  // }

  // Load all tables
  Future<void> loadAllTables() async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final tables = await _service.getAllTables();
      state = state.copyWith(tables: tables, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Get specific table
  Future<void> getTable(String tableId) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final table = await _service.getTableById(tableId);
      state = state.copyWith(
        currentTable: table,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Create new table
  Future<bool> createTable(TableModel table) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return false;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.createTable(table);
      await loadAllTables(); // Reload the list
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Update table
  Future<bool> updateTable(TableModel table) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return false;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateTable(table);
      await loadAllTables(); // Reload the list
      await getTable(table.id); // Refresh current table
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // Delete table
  Future<bool> deleteTable(String tableId) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return false;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteTable(tableId);

      // Update local state without reloading
      final updatedTables = state.tables.where((t) => t.id != tableId).toList();
      state = state.copyWith(
        tables: updatedTables,
        isLoading: false,
        error: null,
        currentTable: state.currentTable?.id == tableId
            ? null
            : state.currentTable,
      );
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ---------- Status Automation (Call from Order System) ----------

  Future<bool> occupyTable(String tableId) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return false;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.occupyTable(tableId);
      await loadAllTables(); // Reload to reflect status changes
      await getTable(tableId); // Refresh current table
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> releaseTable(String tableId) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return false;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.releaseTable(tableId);
      await loadAllTables(); // Reload to reflect status changes
      await getTable(tableId); // Refresh current table
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> markTableAvailable(String tableId) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return false;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.markTableAvailable(tableId);
      await loadAllTables(); // Reload to reflect status changes
      await getTable(tableId); // Refresh current table
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ---------- Room Assignment ----------

  Future<bool> assignTableToRoom(String tableId, String? roomId) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return false;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.assignTableToRoom(tableId, roomId);
      await getTable(tableId); // Refresh current table
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ---------- Reservation System ----------

  Future<bool> reserveTable(String tableId, Duration duration) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return false;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.reserveTable(tableId, duration);
      await loadAllTables(); // Reload to reflect status changes
      await getTable(tableId); // Refresh current table
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> cancelReservation(String tableId) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return false;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.cancelReservation(tableId);
      await loadAllTables(); // Reload to reflect status changes
      await getTable(tableId); // Refresh current table
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  // ---------- Merge/Split Operations (Commented Out) ----------
  /*
  Future<bool> mergeTables(List<String> tableIds) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.mergeTables(tableIds);
      await loadAllTables();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> splitTables(String mergeGroupId) async {
    if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
      state = state.copyWith(error: 'Business context not set');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.splitTables(mergeGroupId);
      await loadAllTables();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
  */

  // ---------- Search and Filter ----------

  Future<void> searchTables(String searchTerm) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final results = await _service.searchTables(searchTerm);
      state = state.copyWith(tables: results, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getAvailableTables() async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final tables = await _service.getAvailableTables();
      state = state.copyWith(tables: tables, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getOccupiedTables() async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final tables = await _service.getOccupiedTables();
      state = state.copyWith(tables: tables, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getTablesByRoom(String roomId) async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final tables = await _service.getTablesByRoom(roomId);
      state = state.copyWith(tables: tables, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> getStandaloneTables() async {
    // if (state.currentBusinessId.isEmpty || state.currentBranchId.isEmpty) {
    //   state = state.copyWith(error: 'Business context not set');
    //   return;
    // }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final tables = await _service.getStandaloneTables();
      state = state.copyWith(tables: tables, isLoading: false, error: null);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ---------- QR Code Generation ----------

  String generateQRCodeData(String tableId) {
    return _service.generateQRCodeData(tableId);
  }

  // ---------- Utility Methods ----------

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearCurrentTable() {
    state = state.copyWith(currentTable: null);
  }

  void reset() {
    state = const TableState();
  }
}
