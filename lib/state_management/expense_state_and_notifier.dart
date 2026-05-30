import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/expense_model.dart';
import 'package:hotel_management_system/data/services/expense_service.dart';

class ExpenseState {
  final List<ExpenseModel> expenses;
  final bool isLoading;
  final String? error;

  const ExpenseState({
    this.expenses = const [],
    this.isLoading = false,
    this.error,
  });

  ExpenseState copyWith({
    List<ExpenseModel>? expenses,
    bool? isLoading,
    String? error,
  }) {
    return ExpenseState(
      expenses: expenses ?? this.expenses,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ExpenseNotifier extends StateNotifier<ExpenseState> {
  final ExpenseService _service;

  ExpenseNotifier(this._service) : super(const ExpenseState());

  Future<void> loadAllExpenses() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final expenses = await _service.getAllExpenses();
      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final expenses = await _service.getExpensesByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addExpense(ExpenseModel expense) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.addExpense(expense);
      await loadAllExpenses();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> updateExpense(ExpenseModel expense) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.updateExpense(expense);
      await loadAllExpenses();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> deleteExpense(String expenseId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.deleteExpense(expenseId);
      await loadAllExpenses();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}
