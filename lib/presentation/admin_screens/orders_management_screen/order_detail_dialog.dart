// Order Details Dialog
import 'package:flutter/material.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/orders_management_screen.dart';

class OrderDetailsDialog extends StatelessWidget {
  final OrderModel order;
  bool canCreateOrder;
  bool canUpdateOrder;
  bool canDeleteOrder;
  bool canUpdateStatus;
  bool canAssignWaiter;

  OrderDetailsDialog({
    super.key,
    required this.order,
    required this.canCreateOrder,
    required this.canUpdateOrder,
    required this.canDeleteOrder,
    required this.canUpdateStatus,
    required this.canAssignWaiter,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Created: ${_formatFullDateTime(order.createdAt)}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status and Type
                    Row(
                      children: [
                        _buildStatusChip(order.orderStatus, colorScheme),
                        const SizedBox(width: 12),
                        _buildTypeChip(order.orderType, colorScheme),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Customer Info
                    _buildInfoSection('Customer Information', [
                      InfoRow(label: 'User ID', value: order.userId ?? 'N/A'),
                    ], context),

                    const SizedBox(height: 16),

                    // Order Type Specific Info
                    if (order.orderType == OrderType.dining) ...[
                      _buildInfoSection('Dining Information', [
                        if (order.diningTable != null)
                          InfoRow(
                            label: 'Table Number',
                            value: order.diningTable!.tableNumber,
                          ),
                        if (order.diningTable != null)
                          InfoRow(
                            label: 'Room',
                            value: order.diningTable!.roomId!,
                          ),
                        if (order.waiterId != null)
                          InfoRow(label: 'Waiter', value: order.waiterId!),
                      ], context),
                      const SizedBox(height: 16),
                    ],

                    if (order.orderType == OrderType.delivery) ...[
                      _buildInfoSection('Delivery Information', [
                        if (order.deliveryAddress != null)
                          InfoRow(
                            label: 'Address',
                            value: order.deliveryAddress!,
                          ),
                        InfoRow(label: 'Phone', value: order.userPhoneNo!),
                      ], context),
                      const SizedBox(height: 16),
                    ],

                    // Order Items
                    _buildInfoSection('Order Items', [], context),
                    const SizedBox(height: 8),
                    ...order.items.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'Product ID: ${item.productId}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'Qty: ${item.quantity}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  item.price.toStringAsFixed(2),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 20),

                    // Order Summary
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Items:',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${order.items.length}',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Amount:',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                order.totalAmount.toStringAsFixed(2),
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Timestamps
                    _buildInfoSection('Order Timeline', [
                      InfoRow(
                        label: 'Created At',
                        value: _formatFullDateTime(order.createdAt),
                      ),
                      InfoRow(
                        label: 'Last Updated',
                        value: _formatFullDateTime(order.updatedAt),
                      ),
                    ], context),
                  ],
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (canUpdateOrder)
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Show status update dialog
                        },
                        icon: const Icon(Icons.update),
                        label: const Text('Update Status'),
                      ),
                    ),

                  if (canUpdateStatus) const SizedBox(width: 12),

                  if (canAssignWaiter && order.orderType == OrderType.dining)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Show waiter assignment dialog
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Assign Waiter'),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(
    String title,
    List<InfoRow> rows,
    BuildContext context,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    '${row.label}:',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    row.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(OrderStatus status, ColorScheme colorScheme) {
    Color backgroundColor;
    Color textColor = Colors.white;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange;
        break;
      case OrderStatus.inProgress:
        backgroundColor = Colors.blue;
        break;
      case OrderStatus.completed:
        backgroundColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red;
        break;
      case OrderStatus.refunded:
        backgroundColor = Colors.grey;
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.yellow;
        break;
    }

    return Chip(
      label: Text(
        _getStatusText(status),
        style: TextStyle(
          fontSize: 12,
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: backgroundColor,
    );
  }

  Widget _buildTypeChip(OrderType type, ColorScheme colorScheme) {
    return Chip(
      label: Text(
        _getTypeText(type),
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      ),
      backgroundColor: colorScheme.secondaryContainer,
      avatar: _buildTypeIcon(type),
    );
  }

  Widget _buildTypeIcon(OrderType type) {
    IconData iconData;

    switch (type) {
      case OrderType.dining:
        iconData = Icons.restaurant;
        break;
      case OrderType.takeaway:
        iconData = Icons.shopping_bag;
        break;
      case OrderType.delivery:
        iconData = Icons.delivery_dining;
        break;
    }

    return Icon(iconData, size: 16);
  }

  String _getStatusText(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.inProgress:
        return 'In Progress';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
      case OrderStatus.refunded:
        return 'Refunded';
      case OrderStatus.ready:
        return 'Ready';
    }
  }

  String _getTypeText(OrderType type) {
    switch (type) {
      case OrderType.dining:
        return 'Dine In';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.delivery:
        return 'Delivery';
    }
  }

  String _formatFullDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
