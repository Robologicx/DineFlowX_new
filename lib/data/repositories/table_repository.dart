import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/models/table_model.dart';

class TableRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _businessId;
  final String _branchId;

  TableRepository({required String businessId, required String branchId})
    : _businessId = businessId,
      _branchId = branchId;

  CollectionReference get _tablesRef => _firestore
      .collection('businesses')
      .doc(_businessId)
      .collection('branches')
      .doc(_branchId)
      .collection('diningTables');

  // ---------- CRUD Operations ----------

  Future<void> createTable(TableModel table) async {
    final String newId = _tablesRef.doc().id;
    final map = table.toMap();
    map['id'] = newId;
    await _tablesRef.doc(newId).set(map);
  }

  Future<TableModel?> getTableById(String tableId) async {
    final doc = await _tablesRef.doc(tableId).get();
    if (!doc.exists) return null;
    return TableModel.fromFirestore(doc);
  }

  Future<void> updateTable(TableModel table) async {
    await _tablesRef.doc(table.id).update(table.toMap());
  }

  Future<void> deleteTable(String tableId) async {
    await _tablesRef.doc(tableId).delete();
  }

  // ---------- Query Operations ----------
  Future<List<TableModel>> getAllTables() async {
    try {
      final data = await _tablesRef.get();
      print(data.docs.length);
      if (data.docs.isEmpty) return [];
      return data.docs
          .map((doc) => TableModel.fromFirestore(doc))
          .toList(growable: false);
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
      final query = await _tablesRef
          .where('status', isEqualTo: status.name)
          .orderBy('tableNumber')
          .get();
      return query.docs
          .map((doc) => TableModel.fromFirestore(doc))
          .toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  Future<List<TableModel>> getTablesByRoom(String roomId) async {
    try {
      final query = await _tablesRef
          .where('roomId', isEqualTo: roomId)
          .orderBy('tableNumber')
          .get();
      return query.docs
          .map((doc) => TableModel.fromFirestore(doc))
          .toList(growable: false);
    } catch (e) {
      return [];
    }
  }

  Future<List<TableModel>> getStandaloneTables() async {
    try {
      final query = await _tablesRef
          .where('roomId', isNull: true)
          .orderBy('tableNumber')
          .get();
      return query.docs
          .map((doc) => TableModel.fromFirestore(doc))
          .toList(growable: false);
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
      final query = await _tablesRef
          .where('tableNumber_lower', isGreaterThanOrEqualTo: prefix)
          .where('tableNumber_lower', isLessThanOrEqualTo: '$prefix\uf8ff')
          .limit(limit)
          .get();

      return query.docs.map((doc) => TableModel.fromFirestore(doc)).toList();
    } catch (e) {
      return [];
    }
  }

  // ---------- Table Management Operations ----------
  Future<void> updateTableStatus(String tableId, TableStatus status) async {
    await _tablesRef.doc(tableId).update({
      'status': status.name,
      'updatedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> assignTableToRoom(String tableId, String? roomId) async {
    await _tablesRef.doc(tableId).update({
      'roomId': roomId,
      'updatedAt': DateTime.now().toIso8601String(),
    });
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
    return _tablesRef.doc(tableId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TableModel.fromFirestore(doc);
    });
  }

  Stream<List<TableModel>> listenToAllTables() {
    return _tablesRef
        .orderBy('tableNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TableModel.fromFirestore(doc))
              .toList(growable: false),
        );
  }

  Stream<List<TableModel>> listenToTablesByStatus(TableStatus status) {
    return _tablesRef
        .where('status', isEqualTo: status.name)
        .orderBy('tableNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TableModel.fromFirestore(doc))
              .toList(growable: false),
        );
  }

  Stream<List<TableModel>> listenToTablesByRoom(String roomId) {
    return _tablesRef
        .where('roomId', isEqualTo: roomId)
        .orderBy('tableNumber')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => TableModel.fromFirestore(doc))
              .toList(growable: false),
        );
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
