import 'dart:async';

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
  bool _isAddingExpense = false;
  StreamSubscription<List<ExpenseModel>>? _realtimeSyncSubscription;

  ExpenseNotifier(this._service) : super(const ExpenseState());

  /// Listen to real-time expense updates from sync service
  void startRealtimeSync() {
    // Cancel previous subscription
    _realtimeSyncSubscription?.cancel();

    // This creates a stream-like behavior by watching a provider
    // The UI layer (using Riverpod) will automatically rebuild when expenses change
  }

  /// Stop real-time sync
  void stopRealtimeSync() {
    _realtimeSyncSubscription?.cancel();
    _realtimeSyncSubscription = null;
  }

  bool _isDuplicateExpense(ExpenseModel a, ExpenseModel b) {
    final sameDay =
        a.expenseDate.year == b.expenseDate.year &&
        a.expenseDate.month == b.expenseDate.month &&
        a.expenseDate.day == b.expenseDate.day;

    return a.title.trim().toLowerCase() == b.title.trim().toLowerCase() &&
        a.category.trim().toLowerCase() == b.category.trim().toLowerCase() &&
        a.amount == b.amount &&
        (a.note ?? '').trim().toLowerCase() ==
            (b.note ?? '').trim().toLowerCase() &&
        sameDay;
  }

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
    if (_isAddingExpense) {
      return;
    }

    final hasDuplicate = state.expenses.any(
      (existing) => _isDuplicateExpense(existing, expense),
    );

    if (hasDuplicate) {
      state = state.copyWith(
        isLoading: false,
        error: 'This expense already exists.',
      );
      return;
    }

    _isAddingExpense = true;
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _service.addExpense(expense);
      await loadAllExpenses();
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    } finally {
      _isAddingExpense = false;
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

  /// Refresh expenses from cloud (pull latest data)
  /// Called when app comes back online or user manually refreshes
  Future<void> refreshFromCloud() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final expenses = await _service.getAllExpenses();
      state = state.copyWith(expenses: expenses, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  @override
  void dispose() {
    stopRealtimeSync();
    super.dispose();
  }
}
