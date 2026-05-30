// Status Update Dialog
import 'package:flutter/material.dart';
import 'package:hotel_management_system/data/models/order_model.dart';

class StatusUpdateDialog extends StatefulWidget {
  final OrderModel order;
  final Function(OrderStatus) onUpdate;

  const StatusUpdateDialog({
    super.key,
    required this.order,
    required this.onUpdate,
  });

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  OrderStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.orderStatus;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Update Order Status'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: OrderStatus.values.map((status) {
          return RadioListTile<OrderStatus>(
            title: Text(_getStatusText(status)),
            value: status,
            groupValue: _selectedStatus,
            onChanged: (value) => setState(() => _selectedStatus = value),
            secondary: _buildStatusIndicator(status),
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed:
              _selectedStatus != null &&
                  _selectedStatus != widget.order.orderStatus
              ? () {
                  widget.onUpdate(_selectedStatus!);
                  Navigator.of(context).pop();
                }
              : null,
          child: const Text('Update'),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(OrderStatus status) {
    Color color;

    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.inProgress:
        color = Colors.blue;
        break;
      case OrderStatus.completed:
        color = Colors.green;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
      case OrderStatus.refunded:
        color = Colors.grey;
        break;
      case OrderStatus.ready:
        color = Colors.yellow;
        break;
    }

    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
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
}
