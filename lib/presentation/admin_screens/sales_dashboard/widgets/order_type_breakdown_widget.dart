// widgets/order_type_breakdown_widget.dart
import 'package:flutter/material.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/sales_model_and_management.dart';

class OrderTypeBreakdownWidget extends StatelessWidget {
  final Map<OrderType, SalesMetric> ordersByType;

  const OrderTypeBreakdownWidget({super.key, required this.ordersByType});

  @override
  Widget build(BuildContext context) {
    final totalRevenue = ordersByType.values.fold(
      0.0,
      (sum, metric) => sum + metric.revenue,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Order Type Breakdown',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Visual breakdown
            ...ordersByType.entries.map((entry) {
              return _buildOrderTypeItem(
                context,
                orderType: entry.key,
                metric: entry.value,
                totalRevenue: totalRevenue,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderTypeItem(
    BuildContext context, {
    required OrderType orderType,
    required SalesMetric metric,
    required double totalRevenue,
  }) {
    final color = _getOrderTypeColor(orderType);
    final icon = _getOrderTypeIcon(orderType);
    final name = _getOrderTypeName(orderType);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          name,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          '${metric.percentage.toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${metric.count} orders',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          'Rs ${metric.revenue.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: metric.percentage / 100,
            backgroundColor: color.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Color _getOrderTypeColor(OrderType type) {
    switch (type) {
      case OrderType.dining:
        return Colors.blue;
      case OrderType.takeaway:
        return Colors.orange;
      case OrderType.delivery:
        return Colors.green;
    }
  }

  IconData _getOrderTypeIcon(OrderType type) {
    switch (type) {
      case OrderType.dining:
        return Icons.restaurant;
      case OrderType.takeaway:
        return Icons.shopping_bag;
      case OrderType.delivery:
        return Icons.delivery_dining;
    }
  }

  String _getOrderTypeName(OrderType type) {
    switch (type) {
      case OrderType.dining:
        return 'Dine In';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.delivery:
        return 'Delivery';
    }
  }
}
