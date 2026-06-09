class CloseDayReport {
  final DateTime dayStartAt;
  final DateTime dayClosedAt;
  final int totalOrders;
  final int completedOrders;
  final int pendingOrders;
  final int inProgressOrders;
  final int cancelledOrders;
  final int refundedOrders;
  final double totalAmount;
  final double totalExpenses;
  final double cashInHandAfterExpenses;
  final double profitOrLoss;

  const CloseDayReport({
    required this.dayStartAt,
    required this.dayClosedAt,
    required this.totalOrders,
    required this.completedOrders,
    required this.pendingOrders,
    required this.inProgressOrders,
    required this.cancelledOrders,
    required this.refundedOrders,
    required this.totalAmount,
    required this.totalExpenses,
    required this.cashInHandAfterExpenses,
    required this.profitOrLoss,
  });
}
