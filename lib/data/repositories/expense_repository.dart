import 'package:cloud_firestore/cloud_firestore.dart';
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

    await docRef.set(toSave.toMap());
    return toSave;
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    await _expensesCollection
        .doc(expense.id)
        .update(expense.copyWith(updatedAt: DateTime.now()).toMap());
  }

  Future<void> deleteExpense(String expenseId) async {
    await _expensesCollection.doc(expenseId).delete();
  }
}
