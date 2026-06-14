import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/core/sync/expense_sync_service.dart';
import 'package:hotel_management_system/data/models/expense_model.dart';

/// Stream provider for real-time expenses
/// Provides a stream of expenses that updates automatically when data changes
final realtimeExpensesProvider =
    StreamProvider.family<List<ExpenseModel>, (String, String)>((
      ref,
      params,
    ) async* {
      final (businessId, branchId) = params;

      try {
        // Initialize sync service directly (no watching other providers)
        final syncService = ExpenseSyncService(
          businessId: businessId,
          branchId: branchId,
        );
        await syncService.initialize();

        // Setup disposal
        ref.onDispose(() {
          syncService.dispose();
        });

        // Yield current expenses
        yield syncService.currentExpenses;

        // Listen to stream changes
        await for (final expenses in syncService.expensesStream) {
          yield expenses;
        }
      } catch (e) {
        throw Exception('Real-time expense sync error: $e');
      }
    });

/// Provider for expenses by date range (real-time)
final realtimeExpensesByDateRangeProvider =
    StreamProvider.family<
      List<ExpenseModel>,
      (String, String, DateTime, DateTime)
    >((ref, params) async* {
      final (businessId, branchId, startDate, endDate) = params;

      try {
        // Initialize sync service directly
        final syncService = ExpenseSyncService(
          businessId: businessId,
          branchId: branchId,
        );
        await syncService.initialize();

        // Setup disposal
        ref.onDispose(() {
          syncService.dispose();
        });

        // Yield initial filtered expenses
        yield syncService.getExpensesByDateRange(
          startDate: startDate,
          endDate: endDate,
        );

        // Listen to stream and filter by date range
        await for (final allExpenses in syncService.expensesStream) {
          final filtered = allExpenses
              .where(
                (expense) =>
                    !expense.expenseDate.isBefore(startDate) &&
                    !expense.expenseDate.isAfter(endDate),
              )
              .toList();
          yield filtered;
        }
      } catch (e) {
        throw Exception('Real-time expense sync error: $e');
      }
    });

/// Provider for current business day expenses (real-time)
final realtimeCurrentBusinessDayExpensesProvider =
    StreamProvider.family<List<ExpenseModel>, (String, String, DateTime)>((
      ref,
      params,
    ) async* {
      final (businessId, branchId, businessDayStartAt) = params;

      try {
        // Initialize sync service directly
        final syncService = ExpenseSyncService(
          businessId: businessId,
          branchId: branchId,
        );
        await syncService.initialize();

        // Setup disposal
        ref.onDispose(() {
          syncService.dispose();
        });

        // Yield initial business day expenses
        yield syncService.getCurrentBusinessDayExpenses(businessDayStartAt);

        // Listen to stream and filter by business day
        await for (final allExpenses in syncService.expensesStream) {
          yield syncService.getCurrentBusinessDayExpenses(businessDayStartAt);
        }
      } catch (e) {
        throw Exception('Real-time expense sync error: $e');
      }
    });

/// Provider for total expenses by date range (real-time)
final realtimeTotalExpensesProvider =
    StreamProvider.family<double, (String, String, DateTime, DateTime)>((
      ref,
      params,
    ) async* {
      final (businessId, branchId, startDate, endDate) = params;

      try {
        // Initialize sync service directly
        final syncService = ExpenseSyncService(
          businessId: businessId,
          branchId: branchId,
        );
        await syncService.initialize();

        // Setup disposal
        ref.onDispose(() {
          syncService.dispose();
        });

        // Yield initial total
        final initialExpenses = syncService.getExpensesByDateRange(
          startDate: startDate,
          endDate: endDate,
        );
        final initialTotal = initialExpenses.fold<double>(
          0.0,
          (sum, item) => sum + item.amount,
        );
        yield initialTotal;

        // Listen to stream and calculate total
        await for (final allExpenses in syncService.expensesStream) {
          final filtered = allExpenses
              .where(
                (expense) =>
                    !expense.expenseDate.isBefore(startDate) &&
                    !expense.expenseDate.isAfter(endDate),
              )
              .toList();
          final total = filtered.fold<double>(
            0.0,
            (sum, item) => sum + item.amount,
          );
          yield total;
        }
      } catch (e) {
        throw Exception('Real-time expense total sync error: $e');
      }
    });
