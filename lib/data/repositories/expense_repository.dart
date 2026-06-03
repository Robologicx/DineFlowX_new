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
    final toSave = expense.copyWith(
      id: docRef.id,
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
