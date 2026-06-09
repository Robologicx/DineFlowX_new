// sales_model_and_management.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/repositories/expense_repository.dart';
import 'package:hotel_management_system/data/services/sales_service.dart';
import 'package:hotel_management_system/data/repositories/sales_repository.dart';

enum ReportPeriod { today, week, month, sixMonths, year, allTime, custom }

class SalesReport {
  final double totalRevenue;
  final int totalOrders;
  final double averageOrderValue;
  final Map<OrderType, SalesMetric> ordersByType;
  final Map<OrderStatus, int> ordersByStatus;
  final List<ProductSales> topProducts;
  final DateTime startDate;
  final DateTime endDate;
  final ReportPeriod period;

  // Additional metrics (can be null if not calculated)
  final double? taxAmount;
  final double? refundedAmount;
  final int? cancelledOrders;
  final Map<String, double>? revenueByDay; // For charts
  final double totalExpenses;
  final double profitOrLoss;

  SalesReport({
    required this.totalRevenue,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.ordersByType,
    required this.ordersByStatus,
    required this.topProducts,
    required this.startDate,
    required this.endDate,
    required this.period,
    this.taxAmount,
    this.refundedAmount,
    this.cancelledOrders,
    this.revenueByDay,
    this.totalExpenses = 0.0,
    this.profitOrLoss = 0.0,
  });

  SalesReport copyWith({
    double? totalRevenue,
    int? totalOrders,
    double? averageOrderValue,
    Map<OrderType, SalesMetric>? ordersByType,
    Map<OrderStatus, int>? ordersByStatus,
    List<ProductSales>? topProducts,
    DateTime? startDate,
    DateTime? endDate,
    ReportPeriod? period,
    double? taxAmount,
    double? refundedAmount,
    int? cancelledOrders,
    Map<String, double>? revenueByDay,
    double? totalExpenses,
    double? profitOrLoss,
  }) {
    return SalesReport(
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalOrders: totalOrders ?? this.totalOrders,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      ordersByType: ordersByType ?? this.ordersByType,
      ordersByStatus: ordersByStatus ?? this.ordersByStatus,
      topProducts: topProducts ?? this.topProducts,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      period: period ?? this.period,
      taxAmount: taxAmount ?? this.taxAmount,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      cancelledOrders: cancelledOrders ?? this.cancelledOrders,
      revenueByDay: revenueByDay ?? this.revenueByDay,
      totalExpenses: totalExpenses ?? this.totalExpenses,
      profitOrLoss: profitOrLoss ?? this.profitOrLoss,
    );
  }
}

class SalesMetric {
  final int count;
  final double revenue;
  final double percentage;

  SalesMetric({
    required this.count,
    required this.revenue,
    required this.percentage,
  });
}

class ProductSales {
  final String productId;
  final String productName;
  final int quantitySold;
  final double revenue;

  ProductSales({
    required this.productId,
    required this.productName,
    required this.quantitySold,
    required this.revenue,
  });
}

// State class
class SalesState {
  final SalesReport? currentReport;
  final bool isLoading;
  final String? error;
  final ReportPeriod selectedPeriod;
  final DateTime? customStartDate;
  final DateTime? customEndDate;

  const SalesState({
    this.currentReport,
    this.isLoading = false,
    this.error,
    this.selectedPeriod = ReportPeriod.today,
    this.customStartDate,
    this.customEndDate,
  });

  SalesState copyWith({
    SalesReport? currentReport,
    bool? isLoading,
    String? error,
    ReportPeriod? selectedPeriod,
    DateTime? customStartDate,
    DateTime? customEndDate,
  }) {
    return SalesState(
      currentReport: currentReport ?? this.currentReport,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      customStartDate: customStartDate ?? this.customStartDate,
      customEndDate: customEndDate ?? this.customEndDate,
    );
  }
}

// Notifier class
class SalesNotifier extends StateNotifier<SalesState> {
  final SalesService _service;

  SalesNotifier(this._service) : super(const SalesState());

  // Generate report for selected period
  Future<void> generateReport(ReportPeriod period) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedPeriod: period,
    );

    try {
      SalesReport report;
      if (period == ReportPeriod.today) {
        report = await _service.generateCurrentBusinessDayReport();
      } else {
        final dates = _getDateRangeForPeriod(period);
        report = await _service.generateSalesReport(
          startDate: dates.$1,
          endDate: dates.$2,
          period: period,
        );
      }

      state = state.copyWith(currentReport: report, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Generate custom date range report
  Future<void> generateCustomReport(
    DateTime startDate,
    DateTime endDate,
  ) async {
    state = state.copyWith(
      isLoading: true,
      error: null,
      selectedPeriod: ReportPeriod.custom,
      customStartDate: startDate,
      customEndDate: endDate,
    );

    try {
      // Adjust to complete business days (4 AM to 3:59 AM next day)
      final adjustedStart = DateTime(
        startDate.year,
        startDate.month,
        startDate.day,
        4,
        0,
        0,
      );

      // End at 3:59:59 AM of the day AFTER the selected end date
      final adjustedEnd = DateTime(
        endDate.year,
        endDate.month,
        endDate.day + 1,
        3,
        59,
        59,
        999, // 3:59:59.999 AM
      );

      final report = await _service.generateSalesReport(
        startDate: adjustedStart,
        endDate: adjustedEnd,
        period: ReportPeriod.custom,
      );

      state = state.copyWith(currentReport: report, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // Helper to get date range for period
  (DateTime, DateTime) _getDateRangeForPeriod(ReportPeriod period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (period) {
      case ReportPeriod.today:
        // Business day runs from 4:00 AM to 3:59 AM next day
        final fourAmToday = DateTime(now.year, now.month, now.day, 4);

        DateTime startDate;
        DateTime endDate;

        if (now.isBefore(fourAmToday)) {
          // If current time is 12:00 AM - 3:59 AM, business day started yesterday at 4 AM
          startDate = fourAmToday.subtract(const Duration(days: 1));
          endDate = DateTime(
            now.year,
            now.month,
            now.day,
            3,
            59,
            59,
            999,
          ); // Today 3:59 AM
        } else {
          // If current time is 4:00 AM or later, business day started today at 4 AM
          startDate = fourAmToday;
          endDate = DateTime(
            now.year,
            now.month,
            now.day + 1,
            3,
            59,
            59,
            999,
          ); // Tomorrow 3:59 AM
        }

        return (startDate, endDate);

      case ReportPeriod.week:
        // 7 complete business days (4 AM to 3:59 AM cycles)
        final fourAmToday = DateTime(now.year, now.month, now.day, 4);
        DateTime weekStart;
        DateTime weekEnd;

        if (now.isBefore(fourAmToday)) {
          weekStart = fourAmToday.subtract(const Duration(days: 7));
          weekEnd = DateTime(now.year, now.month, now.day, 3, 59, 59, 999);
        } else {
          weekStart = fourAmToday.subtract(const Duration(days: 6));
          weekEnd = DateTime(now.year, now.month, now.day + 1, 3, 59, 59, 999);
        }
        return (weekStart, weekEnd);

      case ReportPeriod.month:
        // Start of the current month at 4 AM
        final monthStart = DateTime(now.year, now.month, 1, 4, 0, 0);

        // End at current moment or end of month business day
        final fourAmToday = DateTime(now.year, now.month, now.day, 4);
        DateTime monthEnd;

        if (now.isBefore(fourAmToday)) {
          monthEnd = DateTime(now.year, now.month, now.day, 3, 59, 59, 999);
        } else {
          monthEnd = DateTime(now.year, now.month, now.day + 1, 3, 59, 59, 999);
        }

        return (monthStart, monthEnd);

      case ReportPeriod.sixMonths:
        // Start 6 months ago at the start of that month at 4 AM
        final sixMonthsStart = DateTime(now.year, now.month - 6, 1, 4, 0, 0);

        final fourAmToday = DateTime(now.year, now.month, now.day, 4);
        DateTime sixMonthsEnd;

        if (now.isBefore(fourAmToday)) {
          sixMonthsEnd = DateTime(now.year, now.month, now.day, 3, 59, 59, 999);
        } else {
          sixMonthsEnd = DateTime(
            now.year,
            now.month,
            now.day + 1,
            3,
            59,
            59,
            999,
          );
        }

        return (sixMonthsStart, sixMonthsEnd);

      case ReportPeriod.year:
        // Start of the current year at 4 AM
        final yearStart = DateTime(now.year, 1, 1, 4, 0, 0);

        final fourAmToday = DateTime(now.year, now.month, now.day, 4);
        DateTime yearEnd;

        if (now.isBefore(fourAmToday)) {
          yearEnd = DateTime(now.year, now.month, now.day, 3, 59, 59, 999);
        } else {
          yearEnd = DateTime(now.year, now.month, now.day + 1, 3, 59, 59, 999);
        }

        return (yearStart, yearEnd);

      case ReportPeriod.allTime:
        // All time from 2020 at 4 AM to current business day end
        final allTimeStart = DateTime(2020, 1, 1, 4, 0, 0);

        final fourAmToday = DateTime(now.year, now.month, now.day, 4);
        DateTime allTimeEnd;

        if (now.isBefore(fourAmToday)) {
          allTimeEnd = DateTime(now.year, now.month, now.day, 3, 59, 59, 999);
        } else {
          allTimeEnd = DateTime(
            now.year,
            now.month,
            now.day + 1,
            3,
            59,
            59,
            999,
          );
        }

        return (allTimeStart, allTimeEnd);

      case ReportPeriod.custom:
        // Custom dates are set in generateCustomReport, but we fall back just in case
        return (state.customStartDate ?? today, state.customEndDate ?? now);
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Reset to initial state
  void reset() {
    state = const SalesState();
  }
}

// Provider definition (Crucial step for Riverpod integration)
final salesProvider =
    StateNotifierProvider.family<
      SalesNotifier,
      SalesState,
      ({String businessId, String branchId})
    >((ref, params) {
      // 1. Create the Repository
      final repository = SalesRepository(
        businessId: params.businessId,
        branchId: params.branchId,
      );

      // 2. Create the Service, injecting repositories
      final expenseRepository = ExpenseRepository(
        businessId: params.businessId,
        branchId: params.branchId,
      );
      final service = SalesService(
        salesRepository: repository,
        expenseRepository: expenseRepository,
      );

      // 3. Return the Notifier, injecting the Service
      return SalesNotifier(service);
    });
