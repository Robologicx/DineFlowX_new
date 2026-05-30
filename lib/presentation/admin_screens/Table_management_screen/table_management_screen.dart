// tables_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/room_model.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/presentation/admin_screens/Table_management_screen/qr_code_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/Table_management_screen/table_dialog.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/app_error_widget.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/loading_indicator.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/room_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/table_state_and_notifier.dart';

class TablesManagementScreen extends ConsumerStatefulWidget {
  const TablesManagementScreen({super.key});

  @override
  ConsumerState<TablesManagementScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends ConsumerState<TablesManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  late TableNotifier _notifier;
  late String businessId;
  late String branchId;
  String _filterStatus = 'all';
  String? _selectedRoomFilter;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).selectedUser!;
    businessId = user.primarybusinessId;
    branchId = user.primaryBranchId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier = ref.read(
        tableProvider((branchId: branchId, businessId: businessId)).notifier,
      );
      // _notifier.setBusinessContext(businessId, branchId);
      _notifier.loadAllTables();

      // Load rooms for filtering
      final roomNotifier = ref.read(
        roomProvider((branchId: branchId, businessId: businessId)).notifier,
      );
      roomNotifier.setBusinessContext(businessId, branchId);
      roomNotifier.loadAllRooms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    if (value.isEmpty) {
      _notifier.loadAllTables();
    } else {
      _notifier.searchTables(value);
    }
  }

  void _handleFilter(String filter) {
    setState(() {
      _filterStatus = filter;
      _selectedRoomFilter = null;
    });

    switch (filter) {
      case 'available':
        _notifier.getAvailableTables();
        break;
      case 'occupied':
        _notifier.getOccupiedTables();
        break;
      case 'standalone':
        _notifier.getStandaloneTables();
        break;
      default:
        _notifier.loadAllTables();
    }
  }

  void _handleRoomFilter(String? roomId) {
    if (roomId == null || roomId.isEmpty) {
      _notifier.loadAllTables();
      setState(() => _selectedRoomFilter = null);
    } else {
      _notifier.getTablesByRoom(roomId);
      setState(() {
        _selectedRoomFilter = roomId;
        _filterStatus = 'room';
      });
    }
  }

  void _showTableDialog({TableModel? table}) {
    // Check permission before opening dialog
    final user = ref.read(userProvider).selectedUser;
    if (!_hasPermission('manage_tables', user)) {
      _showPermissionDenied();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => TableDialog(
        businessId: businessId,
        branchId: branchId,
        table: table,
        onSaved: (table) {
          if (table == null) return;
          if (table.id.isEmpty) {
            _notifier.createTable(table);
          } else {
            _notifier.updateTable(table);
          }
        },
      ),
    );
  }

  void _showDeleteDialog(TableModel table) {
    final user = ref.read(userProvider).selectedUser;
    if (!_hasPermission('delete_tables', user)) {
      _showPermissionDenied();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Table'),
        content: Text(
          'Are you sure you want to delete table "${table.tableNumber}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _notifier.deleteTable(table.id);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToQRScreen() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => QRCodeGenerationScreen()));
  }

  bool _hasPermission(String permission, user) {
    return true;
    // if (user?.role.permissions == null) return false;

    // // Check in role permissions
    // final hasRolePermission = user!.role.permissions.any(
    //   (p) =>
    //       p.id == permission ||
    //       p.name.toLowerCase().contains(permission.toLowerCase()),
    // );

    // // Check in extra permissions
    // final hasExtraPermission = user.extraPermissions.containsKey(permission);

    // return hasRolePermission || hasExtraPermission;
  }

  void _showPermissionDenied() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'You do not have permission to perform this action',
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      tableProvider((branchId: branchId, businessId: businessId)),
    );
    final notifier = ref.read(
      tableProvider((branchId: branchId, businessId: businessId)).notifier,
    );
    final RoomState roomsState = ref.watch(
      roomProvider((branchId: branchId, businessId: businessId)),
    );

    final user = ref.read(userProvider.notifier);
    final hasCreateTablesPermission = user.hasPermissionOfCurrentUser(
      Permissions.createTable,
    );
    final hasUpdateTablesPermission = user.hasPermissionOfCurrentUser(
      Permissions.updateTable,
    );
    final hasDeleteTablesPermission = user.hasPermissionOfCurrentUser(
      Permissions.deleteTable,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tables'),
        actions: [
          user.hasPermissionOfCurrentUser(Permissions.viewQRCodes)
              ? IconButton(
                  icon: const Icon(Icons.qr_code),
                  onPressed: _navigateToQRScreen,
                  tooltip: 'Generate QR Codes',
                )
              : SizedBox.shrink(),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.loadAllTables,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search tables...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        notifier.loadAllTables();
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: _handleSearch,
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterStatus == 'all',
                        onSelected: (selected) {
                          if (selected) _handleFilter('all');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Available'),
                        selected: _filterStatus == 'available',
                        onSelected: (selected) {
                          if (selected) _handleFilter('available');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Occupied'),
                        selected: _filterStatus == 'occupied',
                        onSelected: (selected) {
                          if (selected) _handleFilter('occupied');
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Standalone'),
                        selected: _filterStatus == 'standalone',
                        onSelected: (selected) {
                          if (selected) _handleFilter('standalone');
                        },
                      ),
                      const SizedBox(width: 8),
                      if (roomsState.rooms.isNotEmpty)
                        DropdownButton<String?>(
                          value: _selectedRoomFilter,
                          hint: const Text('Filter by Room'),
                          items: [
                            const DropdownMenuItem(
                              value: null,
                              child: Text('All Rooms'),
                            ),
                            ...roomsState.rooms.map((room) {
                              return DropdownMenuItem(
                                value: room.id,
                                child: Text(room.name),
                              );
                            }),
                          ],
                          onChanged: _handleRoomFilter,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (state.error != null)
            AppErrorWidget(error: state.error!, onDismiss: notifier.clearError),
          if (state.isLoading) const LoadingIndicator(),
          Expanded(
            child: _buildContent(
              state,
              roomsState,
              hasUpdateTablesPermission,
              hasDeleteTablesPermission,
            ),
          ),
        ],
      ),
      floatingActionButton: hasCreateTablesPermission
          ? FloatingActionButton(
              onPressed: () => _showTableDialog(),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildContent(
    TableState state,
    roomState,
    bool hasUpdatePermission,
    bool hasDeletePermission,
  ) {
    if (state.tables.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No tables found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first table to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _notifier.loadAllTables(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Compact grid for waiter view - more tables visible
          int crossAxisCount = 2;
          if (constraints.maxWidth > 1400) {
            crossAxisCount = 8;
          } else if (constraints.maxWidth > 1200) {
            crossAxisCount = 6;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 5;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 400) {
            crossAxisCount = 3;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 0.85,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: state.tables.length,
            itemBuilder: (context, index) {
              final table = state.tables[index];
              return _buildTableCard(
                table,
                roomState,
                hasUpdatePermission,
                hasDeletePermission,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTableCard(
    TableModel table,
    RoomState roomState,
    bool hasUpdatePermission,
    bool hasDeletePermission,
  ) {
    final statusColor = _getStatusColor(table.status);
    RoomModel? room;
    if (table.roomId == null) {
      if (roomState.rooms.isNotEmpty) {
        room = roomState.rooms.firstWhere((r) => r.id == table.roomId);
      }
    }
    //--------------------------------------- Get Room Name---------------------------------------------//

    return Card(
      elevation: 2,
      color: statusColor.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: InkWell(
        onTap: () => _showTableDialog(table: table),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      table.tableNumber,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    _getStatusIcon(table.status),
                    color: statusColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 14,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${table.seats} seats',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const SizedBox(height: 4),

              Row(
                children: [
                  Icon(
                    Icons.meeting_room,
                    size: 14,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  if (room != null)
                    Expanded(
                      child: Text(
                        room.name,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    Expanded(
                      child: Text(
                        "No room assigned",
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),

              if (table.locationHint?.isNotEmpty == true) ...[
                const SizedBox(height: 4),
                Text(
                  table.locationHint!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              Text(
                table.status.name.toUpperCase(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  hasUpdatePermission
                      ? IconButton(
                          icon: const Icon(Icons.edit),
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showTableDialog(table: table),
                        )
                      : SizedBox.shrink(),
                  const SizedBox(width: 4),
                  hasDeletePermission
                      ? IconButton(
                          icon: const Icon(Icons.delete),
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showDeleteDialog(table),
                        )
                      : SizedBox.shrink(),
                ],
              ),
            ],
          ),
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
}
