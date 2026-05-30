// table_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class TableDialog extends ConsumerStatefulWidget {
  final String businessId;
  final String branchId;
  final TableModel? table;
  final Function(TableModel?) onSaved;

  const TableDialog({
    super.key,
    required this.businessId,
    required this.branchId,
    this.table,
    required this.onSaved,
  });

  @override
  ConsumerState<TableDialog> createState() => _TableDialogState();
}

class _TableDialogState extends ConsumerState<TableDialog> {
  final _formKey = GlobalKey<FormState>();
  final _tableNumberController = TextEditingController();
  final _seatsController = TextEditingController();
  final _locationHintController = TextEditingController();

  late TableStatus _selectedStatus;
  String? _selectedRoomId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.table != null) {
      _tableNumberController.text = widget.table!.tableNumber;
      _seatsController.text = widget.table!.seats.toString();
      _locationHintController.text = widget.table!.locationHint ?? '';
      _selectedStatus = widget.table!.status;
      _selectedRoomId = widget.table!.roomId;
    } else {
      _selectedStatus = TableStatus.available;
      _seatsController.text = '4';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final roomNotifier = ref.read(
        roomProvider((
          businessId: widget.businessId,
          branchId: widget.branchId,
        )).notifier,
      );
      roomNotifier.setBusinessContext(widget.businessId, widget.branchId);
      roomNotifier.loadAllRooms();
    });
  }

  @override
  void dispose() {
    _tableNumberController.dispose();
    _seatsController.dispose();
    _locationHintController.dispose();
    super.dispose();
  }

  Future<void> _saveTable() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final table = TableModel(
      id: widget.table?.id ?? '',
      businessId: widget.businessId,
      branchId: widget.branchId,
      tableNumber: _tableNumberController.text.trim(),
      roomId: _selectedRoomId,
      seats: int.parse(_seatsController.text),
      status: _selectedStatus,
      locationHint: _locationHintController.text.trim().isEmpty
          ? null
          : _locationHintController.text.trim(),
      mergeGroupId: widget.table?.mergeGroupId,
      createdAt: widget.table?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSaved(table);
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final roomsState = ref.watch(
      roomProvider((businessId: widget.businessId, branchId: widget.branchId)),
    );

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    widget.table == null ? 'Create Table' : 'Edit Table',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _tableNumberController,
                        decoration: InputDecoration(
                          labelText: 'Table Number *',
                          hintText: 'e.g., T1, Table-A1',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Table number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _seatsController,
                        decoration: InputDecoration(
                          labelText: 'Number of Seats *',
                          hintText: 'Maximum capacity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Number of seats is required';
                          }
                          final seats = int.tryParse(value);
                          if (seats == null || seats <= 0) {
                            return 'Enter valid number of seats';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<TableStatus>(
                        isExpanded: true,
                        initialValue: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: TableStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Row(
                              children: [
                                Icon(
                                  _getStatusIcon(status),
                                  size: 16,
                                  color: _getStatusColor(status),
                                ),
                                const SizedBox(width: 8),
                                Text(_formatStatus(status)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      DropdownButtonFormField<String?>(
                        isExpanded: true,
                        initialValue: _selectedRoomId,
                        decoration: InputDecoration(
                          labelText: 'Assign to Room',
                          hintText: 'Optional',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: roomsState.isLoading
                            ? [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Loading rooms...'),
                                ),
                              ]
                            : [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('Standalone (No Room)'),
                                ),
                                ...roomsState.rooms.map((room) {
                                  return DropdownMenuItem(
                                    value: room.id,
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.meeting_room,
                                          size: 16,
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            room.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                        onChanged: roomsState.isLoading
                            ? null
                            : (value) {
                                setState(() => _selectedRoomId = value);
                              },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _locationHintController,
                        decoration: InputDecoration(
                          labelText: 'Location Hint',
                          hintText: 'e.g., Near window',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),

                      Text(
                        '* Required fields',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveTable,
                    child: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(widget.table == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Colors.green;
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.reserved:
        return Colors.orange;
      case TableStatus.cleaning:
        return Colors.blue;
      case TableStatus.outOfService:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return Icons.check_circle;
      case TableStatus.occupied:
        return Icons.people;
      case TableStatus.reserved:
        return Icons.event;
      case TableStatus.cleaning:
        return Icons.cleaning_services;
      case TableStatus.outOfService:
        return Icons.block;
    }
  }

  String _formatStatus(TableStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }
}
