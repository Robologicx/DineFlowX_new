// Waiter Assignment Dialog
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/user_model.dart';

class WaiterAssignmentDialog extends ConsumerStatefulWidget {
  final OrderModel order;
  final Function(String, String) onAssign;

  const WaiterAssignmentDialog({
    super.key,
    required this.order,
    required this.onAssign,
  });

  @override
  ConsumerState<WaiterAssignmentDialog> createState() =>
      _WaiterAssignmentDialogState();
}

class _WaiterAssignmentDialogState
    extends ConsumerState<WaiterAssignmentDialog> {
  String? _selectedWaiterId;
  String? _selectedWaiterName;
  List<UserModel> _waiters = [];

  @override
  void initState() {
    super.initState();
    _selectedWaiterId = widget.order.waiterId;
    _loadWaiters();
  }

  Future<void> _loadWaiters() async {
    // Mock waiters data - replace with actual service call to load WAITERS DATA-------------------//
    setState(() {
      _waiters = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Assign Waiter'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            initialValue: _selectedWaiterId,
            decoration: const InputDecoration(
              labelText: 'Select Waiter',
              border: OutlineInputBorder(),
            ),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No Waiter Assigned'),
              ),
              ..._waiters.map(
                (waiter) => DropdownMenuItem<String>(
                  value: waiter.uid,
                  child: Text(waiter.name),
                ),
              ),
            ],
            onChanged: (value) => setState(() => _selectedWaiterId = value),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (_selectedWaiterId != null) {
              widget.onAssign(_selectedWaiterId!, _selectedWaiterName!);
            }
            Navigator.of(context).pop();
          },
          child: const Text('Assign'),
        ),
      ],
    );
  }
}
