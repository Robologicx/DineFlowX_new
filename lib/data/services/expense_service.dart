import 'package:hotel_management_system/data/models/expense_model.dart';
import 'package:hotel_management_system/data/repositories/expense_repository.dart';

class ExpenseService {
  final ExpenseRepository _repository;

  ExpenseService(this._repository);

  Future<List<ExpenseModel>> getAllExpenses() {
    return _repository.getAllExpenses();
  }

  Future<List<ExpenseModel>> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _repository.getExpensesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<ExpenseModel> addExpense(ExpenseModel expense) {
    return _repository.addExpense(expense);
  }

  Future<void> updateExpense(ExpenseModel expense) {
    return _repository.updateExpense(expense);
  }

  Future<void> deleteExpense(String expenseId) {
    return _repository.deleteExpense(expenseId);
  }

  Future<double> getTotalExpenses({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final expenses = await getExpensesByDateRange(
      startDate: startDate,
      endDate: endDate,
    );
    return expenses.fold<double>(0.0, (sum, item) => sum + item.amount);
  }
}
