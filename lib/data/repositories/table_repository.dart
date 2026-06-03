import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import 'package:hotel_management_system/data/models/table_model.dart';

class TableRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _businessId;
  final String _branchId;

  String get businessId => _businessId;
  String get branchId => _branchId;

  TableRepository({required String businessId, required String branchId})
    : _businessId = businessId,
      _branchId = branchId;

  CollectionReference get _tablesRef => _firestore
      .collection('businesses')
      .doc(_businessId)
      .collection('branches')
      .doc(_branchId)
      .collection('diningTables');

  List<TableModel> _mergeTablesPreferLocal({
    required List<TableModel> local,
    required List<TableModel> remote,
  }) {
    final merged = <String, TableModel>{};
    for (final table in remote) {
      merged[table.id] = table;
    }
    for (final table in local) {
      merged[table.id] = table;
    }

    final list = merged.values.toList(growable: false);
    list.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
    return list;
  }

  List<TableModel> _localTablesFromRows(List<Map<String, dynamic>> rows) {
    return rows.map((map) => TableModel.fromMap(map)).toList(growable: false);
  }

  List<TableModel> _applyTableFilter(
    List<TableModel> tables, {
    TableStatus? status,
    String? roomId,
    bool standaloneOnly = false,
  }) {
    Iterable<TableModel> result = tables;
    if (status != null) {
      result = result.where((t) => t.status == status);
    }
    if (standaloneOnly) {
      result = result.where((t) => t.roomId == null || t.roomId!.isEmpty);
    } else if (roomId != null) {
      result = result.where((t) => t.roomId == roomId);
    }
    final list = result.toList(growable: false);
    list.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
    return list;
  }

  Stream<List<TableModel>> _hybridTablesStream({
    TableStatus? status,
    String? roomId,
    bool standaloneOnly = false,
  }) {
    return Stream.multi((controller) {
      List<TableModel> latestRemote = const [];
      StreamSubscription<QuerySnapshot>? remoteSub;
      Timer? localTick;
      bool isCancelled = false;

      Future<void> emitMerged() async {
        if (isCancelled) return;
        final localRows = await OfflineLocalReadService.instance
            .getBranchCollection(
              businessId: _businessId,
              branchId: _branchId,
              collectionName: 'diningTables',
            );
        if (isCancelled) return;

        final localTables = _applyTableFilter(
          _localTablesFromRows(localRows),
          status: status,
          roomId: roomId,
          standaloneOnly: standaloneOnly,
        );
        final remoteTables = _applyTableFilter(
          latestRemote,
          status: status,
          roomId: roomId,
          standaloneOnly: standaloneOnly,
        );
        controller.add(
          _mergeTablesPreferLocal(local: localTables, remote: remoteTables),
        );
      }

      localTick = Timer.periodic(const Duration(seconds: 1), (_) {
        unawaited(emitMerged());
      });

      remoteSub = _tablesRef.snapshots().listen(
        (snapshot) {
          latestRemote = snapshot.docs
              .map((doc) => TableModel.fromFirestore(doc))
              .toList(growable: false);
          unawaited(emitMerged());
        },
        onError: (_) {
          // Keep local polling active even if remote listener errors.
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

  Future<void> createTable(TableModel table) async {
    final String newId = _tablesRef.doc().id;
    final map = table.toMap();
    map['id'] = newId;
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/diningTables/$newId',
      data: map,
      merge: false,
    );
  }

  Future<TableModel?> getTableById(String tableId) async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'diningTables',
      documentId: tableId,
    );
    if (localDoc != null) {
      return TableModel.fromMap({...localDoc, 'id': tableId});
    }

    final doc = await _tablesRef.doc(tableId).get();
    if (!doc.exists) return null;
    return TableModel.fromFirestore(doc);
  }

  Future<void> updateTable(TableModel table) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/diningTables/${table.id}',
      data: table.toMap(),
      merge: true,
    );
  }

  Future<void> deleteTable(String tableId) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/diningTables/$tableId',
    );
  }

  // ---------- Query Operations ----------
  Future<List<TableModel>> getAllTables() async {
    try {
      final localRows = await OfflineLocalReadService.instance
          .getBranchCollection(
            businessId: _businessId,
            branchId: _branchId,
            collectionName: 'diningTables',
          );
      final localTables = _localTablesFromRows(localRows);

      try {
        final data = await _tablesRef.get();
        final remoteTables = data.docs
            .map((doc) => TableModel.fromFirestore(doc))
            .toList(growable: false);
        return _mergeTablesPreferLocal(
          local: localTables,
          remote: remoteTables,
        );
      } catch (_) {
        return _applyTableFilter(localTables);
      }
      // final query = await _tablesRef.orderBy('tableNumber').get();
      // return query.docs
      //     .map((doc) => TableModel.fromFirestore(doc))
      //     .toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  Future<List<TableModel>> getTablesByStatus(TableStatus status) async {
    try {
      final all = await getAllTables();
      return _applyTableFilter(all, status: status);
    } catch (e) {
      return [];
    }
  }

  Future<List<TableModel>> getTablesByRoom(String roomId) async {
    try {
      final all = await getAllTables();
      return _applyTableFilter(all, roomId: roomId);
    } catch (e) {
      return [];
    }
  }

  Future<List<TableModel>> getStandaloneTables() async {
    try {
      final all = await getAllTables();
      return _applyTableFilter(all, standaloneOnly: true);
    } catch (e) {
      return [];
    }
  }

  Future<List<TableModel>> getAvailableTables() async {
    return getTablesByStatus(TableStatus.available);
  }

  Future<List<TableModel>> getOccupiedTables() async {
    return getTablesByStatus(TableStatus.occupied);
  }

  Future<List<TableModel>> searchTables(
    String searchTerm, {
    int limit = 20,
  }) async {
    final prefix = searchTerm.trim().toLowerCase();
    if (prefix.isEmpty) return [];
    try {
      final all = await getAllTables();
      return all
          .where((table) => table.tableNumber.toLowerCase().contains(prefix))
          .take(limit)
          .toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  // ---------- Table Management Operations ----------
  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/diningTables/$tableId',
      data: {
        'status': status.name,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      merge: true,
    );
  }

  Future<void> assignTableToRoom(String tableId, String? roomId) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/diningTables/$tableId',
      data: {'roomId': roomId, 'updatedAt': DateTime.now().toIso8601String()},
      merge: true,
    );
  }

  // ---------- Merge/Split Operations (Commented Out) ----------
  /*
  Future<void> mergeTables(List<String> tableIds, String mergeGroupId) async {
    final batch = _firestore.batch();
    
    for (final tableId in tableIds) {
      final tableRef = _tablesRef.doc(tableId);
      batch.update(tableRef, {
        'mergeGroupId': mergeGroupId,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    
    await batch.commit();
  }

  Future<void> splitTables(String mergeGroupId) async {
    final query = await _tablesRef
        .where('mergeGroupId', isEqualTo: mergeGroupId)
        .get();
    
    final batch = _firestore.batch();
    
    for (final doc in query.docs) {
      batch.update(doc.reference, {
        'mergeGroupId': null,
        'updatedAt': DateTime.now().toIso8601String(),
      });
    }
    
    await batch.commit();
  }

  Future<List<TableModel>> getMergedTableGroup(String mergeGroupId) async {
    final query = await _tablesRef
        .where('mergeGroupId', isEqualTo: mergeGroupId)
        .get();
    
    return query.docs
        .map((doc) => TableModel.fromFirestore(doc))
        .toList();
  }
  */

  // ---------- Stream Operations ----------

  Stream<TableModel?> listenToTable(String tableId) {
    return _hybridTablesStream().map((tables) {
      for (final table in tables) {
        if (table.id == tableId) return table;
      }
      return null;
    });
  }

  Stream<List<TableModel>> listenToAllTables() {
    return _hybridTablesStream();
  }

  Stream<List<TableModel>> listenToTablesByStatus(TableStatus status) {
    return _hybridTablesStream(status: status);
  }

  Stream<List<TableModel>> listenToTablesByRoom(String roomId) {
    return _hybridTablesStream(roomId: roomId);
  }

  // ---------- Validation ----------

  Future<bool> tableExists(String tableId) async {
    final doc = await _tablesRef.doc(tableId).get();
    return doc.exists;
  }

  Future<bool> isTableNumberUnique(String tableNumber) async {
    final query = await _tablesRef
        .where('tableNumber_lower', isEqualTo: tableNumber.toLowerCase())
        .limit(1)
        .get();
    return query.docs.isEmpty;
  }
}
