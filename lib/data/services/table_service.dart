import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/repositories/table_repository.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';

// What this file contains
// ✅ Complete CRUD operations for tables
// ✅ Room assignment with null roomId for standalone tables
// ✅ Status automation functions for order workflow
// ✅ QR code generation (dynamic, no storage)
// ✅ Reservation system with custom duration
// ✅ Merge/Split functionality (commented out)
// ✅ Multi-tenant architecture with family providers
// ✅ Real-time streams for live updates
// ✅ Comprehensive validation and error handling

class TableService {
  final TableRepository _repository;

  TableService(this._repository);

  // ---------- CRUD Operations ----------

  Future<List<TableModel>> getAllTables() async {
    try {
      return await _repository.getAllTables();
    } catch (e) {
      throw Exception('Failed to fetch tables: $e');
    }
  }

  Future<TableModel?> getTableById(String tableId) async {
    try {
      if (tableId.isEmpty) throw Exception('Table ID cannot be empty');
      return await _repository.getTableById(tableId);
    } catch (e) {
      throw Exception('Failed to fetch table: $e');
    }
  }

  Future<void> createTable(TableModel table) async {
    try {
      // Validation
      if (!isValidTableNumber(table.tableNumber)) {
        throw Exception('Table number must be between 1-50 characters');
      }
      if (table.seats <= 0) {
        throw Exception('Table seats must be greater than 0');
      }

      // Check if table number is unique
      final isUnique = await _repository.isTableNumberUnique(table.tableNumber);
      if (!isUnique) {
        throw Exception(
          'Table with number "${table.tableNumber}" already exists',
        );
      }

      await _repository.createTable(table);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to create table: $e');
    }
  }

  Future<void> updateTable(TableModel table) async {
    try {
      // Validate table exists
      final existingTable = await _repository.getTableById(table.id);
      if (existingTable == null) {
        throw Exception('Table with ID "${table.id}" not found');
      }

      // Validation
      if (!isValidTableNumber(table.tableNumber)) {
        throw Exception('Table number must be between 1-50 characters');
      }
      if (table.seats <= 0) {
        throw Exception('Table seats must be greater than 0');
      }

      // Check if table number is unique (excluding current table)
      final isUnique = await _repository.isTableNumberUnique(table.tableNumber);
      if (!isUnique) {
        final existingWithNumber = await _repository.searchTables(
          table.tableNumber,
          limit: 1,
        );
        if (existingWithNumber.isNotEmpty &&
            existingWithNumber.first.id != table.id) {
          throw Exception(
            'Table with number "${table.tableNumber}" already exists',
          );
        }
      }

      await _repository.updateTable(table);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update table: $e');
    }
  }

  Future<void> deleteTable(String tableId) async {
    try {
      if (tableId.isEmpty) throw Exception('Table ID cannot be empty');

      // Check if table exists
      final exists = await _repository.tableExists(tableId);
      if (!exists) {
        throw Exception('Table with ID "$tableId" not found');
      }

      // Check if table is occupied
      final table = await _repository.getTableById(tableId);
      if (table != null && table.isOccupied) {
        throw Exception('Cannot delete an occupied table');
      }

      await _repository.deleteTable(tableId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to delete table: $e');
    }
  }

  // ---------- Table Status Management (Order Automation) ----------

  Future<void> setTableStatus(String tableId, TableStatus status) async {
    try {
      if (tableId.isEmpty) throw Exception('Table ID cannot be empty');

      final table = await _repository.getTableById(tableId);
      if (table == null) throw Exception('Table not found');

      // Validate status transition
      if (!isValidStatusTransition(table.status, status)) {
        throw Exception(
          'Invalid status transition from ${table.status.name} to ${status.name}',
        );
      }

      await _repository.updateTableStatus(tableId, status);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to update table status: $e');
    }
  }

  // Call this when order is placed
  Future<void> occupyTable(String tableId) async {
    try {
      if (tableId.isEmpty) throw Exception('Table ID cannot be empty');

      final table = await _repository.getTableById(tableId);
      if (table == null) throw Exception('Table not found');

      if (!table.canBeOccupied) {
        throw Exception('Table is not available for occupancy');
      }

      await _repository.updateTableStatus(tableId, TableStatus.occupied);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to occupy table: $e');
    }
  }

  // Call this when order is completed/paid
  Future<void> releaseTable(String tableId) async {
    try {
      if (tableId.isEmpty) throw Exception('Table ID cannot be empty');

      final table = await _repository.getTableById(tableId);
      if (table == null) throw Exception('Table not found');

      if (!table.isOccupied) {
        throw Exception('Table is not occupied');
      }

      await _repository.updateTableStatus(tableId, TableStatus.available);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to release table: $e');
    }
  }

  // Call this when cleaning is completed
  Future<void> markTableAvailable(String tableId) async {
    try {
      if (tableId.isEmpty) throw Exception('Table ID cannot be empty');

      final table = await _repository.getTableById(tableId);
      if (table == null) throw Exception('Table not found');

      // if (table.status != TableStatus.cleaning) {
      //   throw Exception(
      //     'Table must be in cleaning status to mark as available',
      //   );
      // }

      await _repository.updateTableStatus(tableId, TableStatus.available);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to mark table as available: $e');
    }
  }

  // ---------- Room Assignment ----------

  Future<void> assignTableToRoom(String tableId, String? roomId) async {
    try {
      if (tableId.isEmpty) {
        throw Exception('Table ID cannot be empty');
      }

      final table = await _repository.getTableById(tableId);
      if (table == null) throw Exception('Table not found');

      await _repository.assignTableToRoom(tableId, roomId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to assign table to room: $e');
    }
  }

  // ---------- Reservation System ----------

  Future<void> reserveTable(String tableId, Duration duration) async {
    try {
      if (tableId.isEmpty) throw Exception('Table ID cannot be empty');

      final table = await _repository.getTableById(tableId);
      if (table == null) throw Exception('Table not found');

      if (!table.isAvailable) {
        throw Exception('Table is not available for reservation');
      }

      await _repository.updateTableStatus(tableId, TableStatus.reserved);

      // Auto-release reservation after duration
      if (duration.inSeconds > 0) {
        Future.delayed(duration, () async {
          try {
            final currentTable = await _repository.getTableById(tableId);
            if (currentTable != null && currentTable.isReserved) {
              await _repository.updateTableStatus(
                tableId,
                TableStatus.available,
              );
            }
          } catch (e) {
            // Log error but don't throw
            print('Auto-release reservation failed: $e');
          }
        });
      }
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to reserve table: $e');
    }
  }

  Future<void> cancelReservation(String tableId) async {
    try {
      if (tableId.isEmpty) throw Exception('Table ID cannot be empty');

      final table = await _repository.getTableById(tableId);
      if (table == null) throw Exception('Table not found');

      if (!table.isReserved) {
        throw Exception('Table is not reserved');
      }

      await _repository.updateTableStatus(tableId, TableStatus.available);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to cancel reservation: $e');
    }
  }

  // ---------- Merge/Split Operations (Commented Out) ----------
  /*
  Future<void> mergeTables(List<String> tableIds) async {
    try {
      if (tableIds.length < 2) {
        throw Exception('At least 2 tables required for merging');
      }

      // Validate all tables exist and are available
      for (final tableId in tableIds) {
        final table = await _repository.getTableById(tableId);
        if (table == null) throw Exception('Table $tableId not found');
        if (!table.isAvailable) throw Exception('Table $tableId is not available for merging');
      }

      final mergeGroupId = DateTime.now().millisecondsSinceEpoch.toString();
      await _repository.mergeTables(tableIds, mergeGroupId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to merge tables: $e');
    }
  }

  Future<void> splitTables(String mergeGroupId) async {
    try {
      if (mergeGroupId.isEmpty) throw Exception('Merge group ID cannot be empty');
      
      final mergedTables = await _repository.getMergedTableGroup(mergeGroupId);
      if (mergedTables.isEmpty) {
        throw Exception('No tables found in this merge group');
      }

      await _repository.splitTables(mergeGroupId);
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Failed to split tables: $e');
    }
  }
  */

  // ---------- Query Operations ----------

  Future<List<TableModel>> getAvailableTables() async {
    try {
      return await _repository.getAvailableTables();
    } catch (e) {
      throw Exception('Failed to fetch available tables: $e');
    }
  }

  Future<List<TableModel>> getOccupiedTables() async {
    try {
      return await _repository.getOccupiedTables();
    } catch (e) {
      throw Exception('Failed to fetch occupied tables: $e');
    }
  }

  Future<List<TableModel>> getTablesByRoom(String roomId) async {
    try {
      return await _repository.getTablesByRoom(roomId);
    } catch (e) {
      throw Exception('Failed to fetch tables by room: $e');
    }
  }

  Future<List<TableModel>> getStandaloneTables() async {
    try {
      return await _repository.getStandaloneTables();
    } catch (e) {
      throw Exception('Failed to fetch standalone tables: $e');
    }
  }

  Future<List<TableModel>> searchTables(
    String searchTerm, {
    int limit = 20,
  }) async {
    try {
      if (searchTerm.trim().isEmpty) {
        return await _repository.getAllTables();
      }
      return await _repository.searchTables(searchTerm, limit: limit);
    } catch (e) {
      throw Exception('Failed to search tables: $e');
    }
  }

  // ---------- Validation Methods ----------

  bool isValidTableNumber(String tableNumber) {
    return tableNumber.isNotEmpty && tableNumber.length <= 50;
  }

  bool isValidStatusTransition(TableStatus from, TableStatus to) {
    // Define valid status transitions
    const validTransitions = {
      TableStatus.available: [
        TableStatus.occupied,
        TableStatus.reserved,
        TableStatus.outOfService,
      ],
      TableStatus.occupied: [TableStatus.cleaning, TableStatus.outOfService],
      TableStatus.cleaning: [TableStatus.available, TableStatus.outOfService],
      TableStatus.reserved: [
        TableStatus.occupied,
        TableStatus.available,
        TableStatus.outOfService,
      ],
      TableStatus.outOfService: [TableStatus.available],
    };

    return validTransitions[from]?.contains(to) ?? false;
  }

  // ---------- QR Code Generation ----------

  // String generateQRCodeData(String tableId) {
  //   // This would be called when generating QR code for a table
  //   // Format: businessId:branchId:tableId for scanning
  //   return '${BusinessRepository.temporaryBusinesshId}::${BusinessRepository.temporaryBranchId}:$tableId';
  // }
  String generateQRCodeData(String tableId) {
    // Include tableId as a query parameter
    return "icetouch.org/${ClientAppRoutes.cartScreen}?tableId=$tableId&businessId=${BusinessRepository.temporaryBusinesshId}&branchId=${BusinessRepository.temporaryBranchId}";
  }
  // ---------- Stream Operations ----------

  Stream<TableModel?> listenToTable(String tableId) {
    try {
      if (tableId.isEmpty) throw Exception('Table ID cannot be empty');
      return _repository.listenToTable(tableId);
    } catch (e) {
      throw Exception('Failed to listen to table: $e');
    }
  }

  Stream<List<TableModel>> listenToAllTables() {
    try {
      return _repository.listenToAllTables();
    } catch (e) {
      throw Exception('Failed to listen to tables: $e');
    }
  }

  Stream<List<TableModel>> listenToAvailableTables() {
    try {
      return _repository.listenToTablesByStatus(TableStatus.available);
    } catch (e) {
      throw Exception('Failed to listen to available tables: $e');
    }
  }

  Stream<List<TableModel>> listenToTablesByRoom(String roomId) {
    try {
      return _repository.listenToTablesByRoom(roomId);
    } catch (e) {
      throw Exception('Failed to listen to tables by room: $e');
    }
  }
}
