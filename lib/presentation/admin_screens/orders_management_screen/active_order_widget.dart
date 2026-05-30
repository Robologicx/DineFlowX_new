// active_orders_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class ActiveOrdersWidget extends ConsumerStatefulWidget {
  final String businessId;
  final String branchId;
  final int maxOrders;
  final VoidCallback? onViewAll;

  const ActiveOrdersWidget({
    super.key,
    required this.businessId,
    required this.branchId,
    this.maxOrders = 5,
    this.onViewAll,
  });

  @override
  ConsumerState<ActiveOrdersWidget> createState() => _ActiveOrdersWidgetState();
}

class _ActiveOrdersWidgetState extends ConsumerState<ActiveOrdersWidget> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadActiveOrders();
    });
  }

  void _loadActiveOrders() {
    final tableNotifier = ref.read(
      tableProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    final orderNotifier = ref.read(
      orderProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
        tableNotifier: tableNotifier,
      )).notifier,
    );

    // Load only active orders (pending, inProgress, ready)
    orderNotifier.loadOrdersByStatus([
      OrderStatus.pending,
      OrderStatus.inProgress,
      OrderStatus.ready,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final tableNotifier = ref.read(
      tableProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    final orderState = ref.watch(
      orderProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
        tableNotifier: tableNotifier,
      )),
    );

    final activeOrders = orderState.orders.take(widget.maxOrders).toList();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.receipt_long,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Active Orders',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (widget.onViewAll != null)
                  TextButton(
                    onPressed: widget.onViewAll,
                    child: const Text('View All'),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Content
          if (orderState.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (orderState.error != null)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Error loading orders',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          else if (activeOrders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No active orders',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: activeOrders.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = activeOrders[index];
                return _buildOrderTile(order);
              },
            ),
          // Footer
          if (activeOrders.isNotEmpty && widget.onViewAll != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              child: Center(
                child: TextButton.icon(
                  onPressed: widget.onViewAll,
                  icon: const Icon(Icons.open_in_new),
                  label: Text('View All Orders (${orderState.orders.length})'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderTile(OrderModel order) {
    final statusColor = _getStatusColor(order.orderStatus);

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getOrderTypeIcon(order.orderType),
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(
        'Order #${order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(order.userName, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getStatusText(order.orderStatus),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${order.items.length} items',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            'Rs ${order.totalAmount.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          Text(
            _formatTime(order.createdAt),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
      onTap: widget.onViewAll,
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.grey;
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

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
