// sales_service.dart
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/sales_model_and_management.dart';
import 'package:hotel_management_system/data/repositories/expense_repository.dart';
import 'package:hotel_management_system/data/repositories/sales_repository.dart';

/// Service handles ONLY business logic
/// Calculations, aggregations, data transformation
/// No direct Firestore access
class SalesService {
  final SalesRepository _repository;
  final ExpenseRepository _expenseRepository;

  SalesService({
    required SalesRepository salesRepository,
    required ExpenseRepository expenseRepository,
  }) : _repository = salesRepository,
       _expenseRepository = expenseRepository;

  Future<(DateTime, DateTime)> getCurrentBusinessDayRange() async {
    final now = DateTime.now();
    final marker = await _repository.getCurrentBusinessDayStartAt();
    if (marker != null) {
      return (marker.toLocal(), now);
    }

    // Backward-compatible fallback if marker is not initialized yet.
    final fourAmToday = DateTime(now.year, now.month, now.day, 4);
    if (now.isBefore(fourAmToday)) {
      return (fourAmToday.subtract(const Duration(days: 1)), now);
    }
    return (fourAmToday, now);
  }

  /// Generate complete sales report for given date range
  Future<SalesReport> generateSalesReport({
    required DateTime startDate,
    required DateTime endDate,
    required ReportPeriod period,
  }) async {
    try {
      // Fetch data from repository
      final completedOrders = await _repository.getCompletedOrders(
        startDate: startDate,
        endDate: endDate,
      );

      // Calculate basic metrics
      final totalRevenue = _calculateTotalRevenue(completedOrders);
      final totalOrders = completedOrders.length;
      final averageOrderValue = _calculateAverageOrderValue(completedOrders);

      // Calculate order type breakdown
      final ordersByType = _calculateOrderTypeBreakdown(completedOrders);

      // Calculate order status breakdown
      final ordersByStatus = await _calculateOrderStatusBreakdown(
        startDate,
        endDate,
      );

      // Calculate top products
      final topProducts = _calculateTopProducts(completedOrders);

      // Calculate additional metrics
      final cancelledOrders = await _repository.getCancelledOrders(
        startDate: startDate,
        endDate: endDate,
      );
      final refundedAmount = _calculateRefundedAmount(cancelledOrders);

      // Generate revenue by day for charts
      final revenueByDay = await _calculateRevenueByDay(startDate, endDate);

      final expenses = await _expenseRepository.getExpensesByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      final totalExpenses = expenses.fold<double>(
        0.0,
        (sum, expense) => sum + expense.amount,
      );
      final profitOrLoss = totalRevenue - totalExpenses;

      return SalesReport(
        totalRevenue: totalRevenue,
        totalOrders: totalOrders,
        averageOrderValue: averageOrderValue,
        ordersByType: ordersByType,
        ordersByStatus: ordersByStatus,
        topProducts: topProducts,
        startDate: startDate,
        endDate: endDate,
        period: period,
        cancelledOrders: cancelledOrders.length,
        refundedAmount: refundedAmount,
        revenueByDay: revenueByDay,
        totalExpenses: totalExpenses,
        profitOrLoss: profitOrLoss,
        // taxAmount: _calculateTax(totalRevenue), // Uncomment when needed
      );
    } catch (e) {
      throw Exception('Failed to generate sales report: $e');
    }
  }

  Future<SalesReport> generateCurrentBusinessDayReport() async {
    final marker = await _repository.getCurrentBusinessDayStartAt();
    if (marker == null) {
      final range = await getCurrentBusinessDayRange();
      return generateSalesReport(
        startDate: range.$1,
        endDate: range.$2,
        period: ReportPeriod.today,
      );
    }

    final completedOrders = await _repository.getOrdersForBusinessDayStart(
      businessDayStartAt: marker,
      statuses: [
        OrderStatus.completed,
        OrderStatus.pending,
        OrderStatus.inProgress,
      ],
    );

    final cancelledOrders = await _repository.getOrdersForBusinessDayStart(
      businessDayStartAt: marker,
      statuses: [OrderStatus.cancelled, OrderStatus.refunded],
    );

    final allCurrentDayOrders = await _repository.getOrdersForBusinessDayStart(
      businessDayStartAt: marker,
    );

    final totalRevenue = _calculateTotalRevenue(completedOrders);
    final totalOrders = completedOrders.length;
    final averageOrderValue = _calculateAverageOrderValue(completedOrders);
    final ordersByType = _calculateOrderTypeBreakdown(completedOrders);
    final topProducts = _calculateTopProducts(completedOrders);
    final refundedAmount = _calculateRefundedAmount(cancelledOrders);

    final ordersByStatus = <OrderStatus, int>{
      for (final status in OrderStatus.values)
        status: allCurrentDayOrders
            .where((order) => order.orderStatus == status)
            .length,
    };

    final expenses = await _expenseRepository.getCurrentBusinessDayExpenses(
      marker,
    );
    final totalExpenses = expenses.fold<double>(
      0.0,
      (sum, expense) => sum + expense.amount,
    );
    final profitOrLoss = totalRevenue - totalExpenses;

    final revenueByDay = <String, double>{
      '${marker.day}/${marker.month}': totalRevenue,
    };

    return SalesReport(
      totalRevenue: totalRevenue,
      totalOrders: totalOrders,
      averageOrderValue: averageOrderValue,
      ordersByType: ordersByType,
      ordersByStatus: ordersByStatus,
      topProducts: topProducts,
      startDate: marker.toLocal(),
      endDate: DateTime.now(),
      period: ReportPeriod.today,
      cancelledOrders: cancelledOrders.length,
      refundedAmount: refundedAmount,
      revenueByDay: revenueByDay,
      totalExpenses: totalExpenses,
      profitOrLoss: profitOrLoss,
    );
  }

  /// Calculate total revenue from completed orders
  double _calculateTotalRevenue(List<OrderModel> orders) {
    return orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  /// Calculate average order value
  double _calculateAverageOrderValue(List<OrderModel> orders) {
    if (orders.isEmpty) return 0.0;
    final total = _calculateTotalRevenue(orders);
    return total / orders.length;
  }

  /// Calculate order type breakdown (Dining, Takeaway, Delivery)
  Map<OrderType, SalesMetric> _calculateOrderTypeBreakdown(
    List<OrderModel> orders,
  ) {
    final totalRevenue = _calculateTotalRevenue(orders);
    final breakdown = <OrderType, SalesMetric>{};

    for (var type in OrderType.values) {
      final typeOrders = orders.where((o) => o.orderType == type).toList();
      final typeRevenue = _calculateTotalRevenue(typeOrders);
      final percentage = totalRevenue > 0
          ? (typeRevenue / totalRevenue) * 100
          : 0.0;

      breakdown[type] = SalesMetric(
        count: typeOrders.length,
        revenue: typeRevenue,
        percentage: percentage,
      );
    }

    return breakdown;
  }

  /// Calculate order status breakdown
  Future<Map<OrderStatus, int>> _calculateOrderStatusBreakdown(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final breakdown = <OrderStatus, int>{};

    for (var status in OrderStatus.values) {
      final count = await _repository.getOrderCount(
        startDate: startDate,
        endDate: endDate,
        status: status,
      );
      breakdown[status] = count;
    }

    return breakdown;
  }

  /// Calculate top selling products
  List<ProductSales> _calculateTopProducts(
    List<OrderModel> orders, {
    int limit = 10,
  }) {
    final productSales = <String, ProductSales>{};

    for (var order in orders) {
      for (var item in order.items) {
        if (productSales.containsKey(item.productId)) {
          final existing = productSales[item.productId]!;
          productSales[item.productId] = ProductSales(
            productId: item.productId,
            productName: item.productName,
            quantitySold: existing.quantitySold + item.quantity,
            revenue: existing.revenue + (item.price * item.quantity),
          );
        } else {
          productSales[item.productId] = ProductSales(
            productId: item.productId,
            productName: item.productName,
            quantitySold: item.quantity,
            revenue: item.price * item.quantity,
          );
        }
      }
    }

    final sortedProducts = productSales.values.toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));

    return sortedProducts.take(limit).toList();
  }

  /// Calculate refunded amount from cancelled/refunded orders
  double _calculateRefundedAmount(List<OrderModel> cancelledOrders) {
    return cancelledOrders
        .where((o) => o.orderStatus == OrderStatus.refunded)
        .fold(0.0, (sum, order) => sum + order.totalAmount);
  }

  /// Calculate revenue by day for chart data
  Future<Map<String, double>> _calculateRevenueByDay(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final ordersByDay = await _repository.getOrdersByDay(
      startDate: startDate,
      endDate: endDate,
    );

    final revenueByDay = <String, double>{};

    for (var entry in ordersByDay.entries) {
      final dateKey = '${entry.key.day}/${entry.key.month}';
      final dayRevenue = _calculateTotalRevenue(entry.value);
      revenueByDay[dateKey] = dayRevenue;
    }

    return revenueByDay;
  }

  /// Calculate tax amount (commented for later use)
  // double _calculateTax(double revenue, {double taxRate = 0.16}) {
  //   return revenue * taxRate;
  // }

  /// Get comparison with previous period
  Future<Map<String, dynamic>> getPeriodComparison({
    required DateTime currentStart,
    required DateTime currentEnd,
  }) async {
    final currentOrders = await _repository.getCompletedOrders(
      startDate: currentStart,
      endDate: currentEnd,
    );

    final periodDuration = currentEnd.difference(currentStart);
    final previousStart = currentStart.subtract(periodDuration);
    final previousEnd = currentStart.subtract(const Duration(seconds: 1));

    final previousOrders = await _repository.getCompletedOrders(
      startDate: previousStart,
      endDate: previousEnd,
    );

    final currentRevenue = _calculateTotalRevenue(currentOrders);
    final previousRevenue = _calculateTotalRevenue(previousOrders);

    final revenueChange = previousRevenue > 0
        ? ((currentRevenue - previousRevenue) / previousRevenue) * 100
        : 0.0;

    final ordersChange = previousOrders.isNotEmpty
        ? ((currentOrders.length - previousOrders.length) /
                  previousOrders.length) *
              100
        : 0.0;

    return {
      'revenueChange': revenueChange,
      'ordersChange': ordersChange,
      'currentRevenue': currentRevenue,
      'previousRevenue': previousRevenue,
      'currentOrders': currentOrders.length,
      'previousOrders': previousOrders.length,
    };
  }

  /// Calculate peak hours (for operational insights)
  Map<int, int> calculatePeakHours(List<OrderModel> orders) {
    final hourlyOrders = <int, int>{};

    for (var order in orders) {
      final hour = order.createdAt.hour;
      hourlyOrders[hour] = (hourlyOrders[hour] ?? 0) + 1;
    }

    return Map.fromEntries(
      hourlyOrders.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
    );
  }

  /// Calculate average preparation time (for dining orders)
  // Future<Duration> calculateAveragePreparationTime(
  //   DateTime startDate,
  //   DateTime endDate,
  // ) async {
  //   // Implementation depends on your order tracking system
  //   // If you track status change timestamps
  // }
}
