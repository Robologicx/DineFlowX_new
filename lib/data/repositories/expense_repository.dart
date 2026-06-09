import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import 'package:hotel_management_system/data/models/expense_model.dart';

class ExpenseRepository {
  final String businessId;
  final String branchId;
  final FirebaseFirestore _firestore;

  ExpenseRepository({
    required this.businessId,
    required this.branchId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _expensesCollection =>
      _firestore
          .collection('businesses')
          .doc(businessId)
          .collection('branches')
          .doc(branchId)
          .collection('expenses');

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final ms = int.tryParse(value);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  String _businessDayIdFromStart(DateTime startAt) {
    final y = startAt.year.toString().padLeft(4, '0');
    final m = startAt.month.toString().padLeft(2, '0');
    final d = startAt.day.toString().padLeft(2, '0');
    final h = startAt.hour.toString().padLeft(2, '0');
    final min = startAt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d-$h$min';
  }

  Future<DateTime?> _getCurrentBusinessDayStartAt() async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: businessId,
      branchId: branchId,
      collectionName: 'settings',
      documentId: 'operations',
    );

    final localStart = _toDateTime(localDoc?['currentDayStartAt']);
    if (localStart != null) return localStart;

    final remoteDoc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('settings')
        .doc('operations')
        .get();
    if (!remoteDoc.exists) return null;
    return _toDateTime(remoteDoc.data()?['currentDayStartAt']);
  }

  Future<List<ExpenseModel>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final snapshot = await _expensesCollection
        .where('expenseDate', isGreaterThanOrEqualTo: startDate)
        .where('expenseDate', isLessThanOrEqualTo: endDate)
        .orderBy('expenseDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<List<ExpenseModel>> getAllExpenses() async {
    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: businessId,
          branchId: branchId,
          collectionName: 'expenses',
        );
    if (localRows.isNotEmpty) {
      return localRows
          .map(
            (doc) => ExpenseModel.fromMap(
              doc,
              (doc['__documentId'] ?? '').toString(),
            ),
          )
          .toList();
    }

    final snapshot = await _expensesCollection
        .orderBy('expenseDate', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    final docRef = _expensesCollection.doc(
      expense.id.isEmpty ? null : expense.id,
    );
    final currentDayStartAt =
        await _getCurrentBusinessDayStartAt() ?? DateTime.now().toUtc();
    final toSave = expense.copyWith(
      id: docRef.id,
      businessDayStartAt: currentDayStartAt,
      businessDayId: _businessDayIdFromStart(currentDayStartAt),
      createdAt: expense.createdAt,
      updatedAt: DateTime.now(),
    );

    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$businessId/branches/$branchId/expenses/${docRef.id}',
      data: toSave.toMap(),
      merge: false,
    );
    return toSave;
  }

  Future<List<ExpenseModel>> getCurrentBusinessDayExpenses(
    DateTime businessDayStartAt,
  ) async {
    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: businessId,
          branchId: branchId,
          collectionName: 'expenses',
        );
    if (localRows.isNotEmpty) {
      return localRows
          .map(
            (doc) => ExpenseModel.fromMap(
              doc,
              (doc['__documentId'] ?? '').toString(),
            ),
          )
          .where((expense) {
            final marker = expense.businessDayStartAt;
            if (marker != null) {
              return marker.millisecondsSinceEpoch ==
                  businessDayStartAt.millisecondsSinceEpoch;
            }
            return !expense.expenseDate.isBefore(businessDayStartAt);
          })
          .toList();
    }

    final snapshot = await _expensesCollection
        .where('businessDayStartAt', isEqualTo: businessDayStartAt)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
      expenses.sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
      return expenses;
    }

    final fallbackSnapshot = await _expensesCollection
        .where('expenseDate', isGreaterThanOrEqualTo: businessDayStartAt)
        .orderBy('expenseDate', descending: true)
        .get();
    return fallbackSnapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$businessId/branches/$branchId/expenses/${expense.id}',
      data: expense.copyWith(updatedAt: DateTime.now()).toMap(),
      merge: true,
    );
  }

  Future<void> deleteExpense(String expenseId) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath:
          'businesses/$businessId/branches/$branchId/expenses/$expenseId',
    );
  }
}
