// table_status_operations.dart
// These operations are COMMENTED OUT as requested
// Uncomment when needed for status management

/*
// Add these methods to your _TablesScreenState class:

void _showStatusManagementDialog(TableModel table) {
  final user = ref.read(userProvider).selectedUser;
  if (!_hasPermission('manage_table_status', user)) {
    _showPermissionDenied();
    return;
  }

  showDialog(
    context: context,
    builder: (context) => TableStatusManagementDialog(
      table: table,
      businessId: businessId,
      branchId: branchId,
    ),
  );
}

// STATUS MANAGEMENT DIALOG
class TableStatusManagementDialog extends ConsumerStatefulWidget {
  final TableModel table;
  final String businessId;
  final String branchId;

  const TableStatusManagementDialog({
    super.key,
    required this.table,
    required this.businessId,
    required this.branchId,
  });

  @override
  ConsumerState<TableStatusManagementDialog> createState() =>
      _TableStatusManagementDialogState();
}

class _TableStatusManagementDialogState
    extends ConsumerState<TableStatusManagementDialog> {
  bool _isLoading = false;

  Future<void> _occupyTable() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(
      tableProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    final success = await notifier.occupyTable(widget.table.id);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table marked as occupied'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _releaseTable() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(
      tableProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    final success = await notifier.releaseTable(widget.table.id);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table released'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _markAvailable() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(
      tableProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    final success = await notifier.markTableAvailable(widget.table.id);
    setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Table marked as available'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Manage ${widget.table.tableNumber}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Status: ${_formatStatus(widget.table.status)}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Seats: ${widget.table.seats}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.people, color: Colors.red),
            title: const Text('Mark as Occupied'),
            onTap: _isLoading ? null : _occupyTable,
          ),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: Colors.orange),
            title: const Text('Release Table'),
            onTap: _isLoading ? null : _releaseTable,
          ),
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Mark as Available'),
            onTap: _isLoading ? null : _markAvailable,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _formatStatus(TableStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }
}
*/
