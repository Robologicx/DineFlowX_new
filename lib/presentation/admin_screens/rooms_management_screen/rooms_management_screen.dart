import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/room_model.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/app_error_widget.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/loading_indicator.dart';
import 'package:hotel_management_system/state_management/room_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/user_state_and_notifier.dart';

class RoomsManagementScreen extends ConsumerStatefulWidget {
  const RoomsManagementScreen({super.key});

  @override
  ConsumerState<RoomsManagementScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends ConsumerState<RoomsManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  late RoomNotifier _notifier;
  late String businessId;
  late String branchId;
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    businessId = ref.read(userProvider).selectedUser!.primarybusinessId;
    branchId = ref.read(userProvider).selectedUser!.primaryBranchId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier = ref.read(
        roomProvider((branchId: branchId, businessId: businessId)).notifier,
      );
      _notifier.setBusinessContext(businessId, branchId);
      _notifier.loadAllRooms();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    if (value.isEmpty) {
      _notifier.loadAllRooms();
    } else {
      _notifier.searchRooms(value);
    }
  }

  void _handleFilter(String filter) {
    setState(() => _filterStatus = filter);

    switch (filter) {
      case 'available':
        _notifier.getAvailableRooms();
        break;
      case 'occupied':
        _notifier.getOccupiedRooms();
        break;
      default:
        _notifier.loadAllRooms();
    }
  }

  void _showRoomDialog({RoomModel? room}) {
    showDialog(
      context: context,
      builder: (context) => RoomDialog(
        businessId: businessId,
        branchId: branchId,
        room: room,
        onSaved: (room) {
          if (room == null) return;
          if (room.id.isEmpty) {
            _notifier.createRoom(room);
          } else {
            _notifier.updateRoom(room);
          }
        },
      ),
    );
  }

  void _showDeleteDialog(RoomModel room) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Room'),
        content: Text('Are you sure you want to delete "${room.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _notifier.deleteRoom(room.id);
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

  // void _showTableManagementDialog(RoomModel room) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => TableManagementDialog(
  //       room: room,
  //       businessId: businessId,
  //       branchId: branchId,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      roomProvider((branchId: branchId, businessId: businessId)),
    );
    final notifier = ref.read(
      roomProvider((branchId: branchId, businessId: businessId)).notifier,
    );

    final user = ref.read(userProvider);
    final userNotifier = ref.read(userProvider.notifier);

    if (user.selectedUser == null) {
      return Center(child: Text('No user data available'));
    } else {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Rooms'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: notifier.loadAllRooms,
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
                      hintText: 'Search rooms...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          notifier.loadAllRooms();
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (state.error != null)
              AppErrorWidget(
                error: state.error!,
                onDismiss: notifier.clearError,
              ),
            if (state.isLoading) const LoadingIndicator(),
            Expanded(child: _buildContent(state, userNotifier)),
          ],
        ),
        floatingActionButton:
            userNotifier.hasPermissionOfCurrentUser(Permissions.createRoom)
            ? FloatingActionButton(
                onPressed: () => _showRoomDialog(),
                child: const Icon(Icons.add),
              )
            : null,
      );
    }
  }

  Widget _buildContent(RoomState state, UserNotifier userNotifier) {
    if (state.rooms.isEmpty && !state.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.meeting_room_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No rooms found',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first room to get started',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _notifier.loadAllRooms(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          int crossAxisCount = 1;
          if (constraints.maxWidth > 1200) {
            crossAxisCount = 4;
          } else if (constraints.maxWidth > 800) {
            crossAxisCount = 3;
          } else if (constraints.maxWidth > 600) {
            crossAxisCount = 2;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              childAspectRatio: 1.3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: state.rooms.length,
            itemBuilder: (context, index) {
              final room = state.rooms[index];
              return _buildRoomCard(
                room,
                userNotifier.hasPermissionOfCurrentUser(Permissions.updateRoom),
                userNotifier.hasPermissionOfCurrentUser(Permissions.deleteRoom),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildRoomCard(
    RoomModel room,
    bool hasEditPermission,
    bool hasDeletePermission,
  ) {
    final statusColor = _getStatusColor(room.status);
    final statusIcon = _getStatusIcon(room.status);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showRoomDialog(room: room),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: statusColor.withOpacity(0.15),
              child: Row(
                children: [
                  Icon(statusIcon, size: 16, color: statusColor),
                  const SizedBox(width: 8),
                  Text(
                    _formatStatus(room.status),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _getRoomTypeIcon(room.type),
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (room.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        room.description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${room.currentOccupancy}/${room.capacity}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.table_restaurant,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        // Text(
                        //   '${room.tableIds.length}',
                        //   style: Theme.of(context).textTheme.bodySmall,
                        // ),
                      ],
                    ),
                    if (room.floor != null || room.section != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        [
                          if (room.floor != null) 'Floor ${room.floor}',
                          if (room.section != null) room.section,
                        ].join(' • '),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // IconButton(
                  //   icon: const Icon(Icons.table_restaurant),
                  //   iconSize: 20,
                  //   onPressed: () => _showTableManagementDialog(room),
                  //   tooltip: 'Tables',
                  // ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    iconSize: 20,
                    onPressed: () {
                      if (hasEditPermission) {
                        _showRoomDialog(room: room);
                      }
                    },
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    iconSize: 20,
                    onPressed: () {
                      if (hasDeletePermission) {
                        _showDeleteDialog(room);
                      }
                    },

                    tooltip: 'Delete',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Colors.green;
      case RoomStatus.occupied:
        return Colors.red;
      case RoomStatus.reserved:
        return Colors.orange;
      case RoomStatus.cleaning:
        return Colors.blue;
      case RoomStatus.maintenance:
        return Colors.amber;
      case RoomStatus.outOfService:
        return Theme.of(context).colorScheme.error;
    }
  }

  IconData _getStatusIcon(RoomStatus status) {
    switch (status) {
      case RoomStatus.available:
        return Icons.check_circle;
      case RoomStatus.occupied:
        return Icons.people;
      case RoomStatus.reserved:
        return Icons.event;
      case RoomStatus.cleaning:
        return Icons.cleaning_services;
      case RoomStatus.maintenance:
        return Icons.build;
      case RoomStatus.outOfService:
        return Icons.block;
    }
  }

  IconData _getRoomTypeIcon(RoomType type) {
    switch (type) {
      case RoomType.regular:
        return Icons.meeting_room;
      case RoomType.vip:
        return Icons.stars;
      case RoomType.private:
        return Icons.lock;
    }
  }

  String _formatStatus(RoomStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }
}

class RoomDialog extends StatefulWidget {
  final String businessId;
  final String branchId;
  final RoomModel? room;
  final Function(RoomModel?) onSaved;

  const RoomDialog({
    super.key,
    required this.businessId,
    required this.branchId,
    this.room,
    required this.onSaved,
  });

  @override
  State<RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<RoomDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _capacityController = TextEditingController();
  final _floorController = TextEditingController();
  final _sectionController = TextEditingController();

  late RoomType _selectedType;
  late RoomStatus _selectedStatus;
  List<String> _amenities = [];
  final _amenityController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.room != null) {
      _nameController.text = widget.room!.name;
      _descriptionController.text = widget.room!.description ?? '';
      _capacityController.text = widget.room!.capacity.toString();
      _floorController.text = widget.room!.floor ?? '';
      _sectionController.text = widget.room!.section ?? '';
      _selectedType = widget.room!.type;
      _selectedStatus = widget.room!.status;
      _amenities = List.from(widget.room!.amenities);
    } else {
      _selectedType = RoomType.regular;
      _selectedStatus = RoomStatus.available;
      _capacityController.text = '4';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _floorController.dispose();
    _sectionController.dispose();
    _amenityController.dispose();
    super.dispose();
  }

  void _addAmenity() {
    final amenity = _amenityController.text.trim();
    if (amenity.isNotEmpty && !_amenities.contains(amenity)) {
      setState(() {
        _amenities.add(amenity);
        _amenityController.clear();
      });
    }
  }

  void _removeAmenity(String amenity) {
    setState(() => _amenities.remove(amenity));
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final now = DateTime.now();
    final room = RoomModel(
      id: widget.room?.id ?? '',
      businessId: widget.businessId,
      branchId: widget.branchId,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      type: _selectedType,
      capacity: int.parse(_capacityController.text),
      currentOccupancy: widget.room?.currentOccupancy ?? 0,
      status: _selectedStatus,
      // tableIds: widget.room?.tableIds ?? [],
      amenities: _amenities,
      floor: _floorController.text.trim().isEmpty
          ? null
          : _floorController.text.trim(),
      section: _sectionController.text.trim().isEmpty
          ? null
          : _sectionController.text.trim(),
      createdAt: widget.room?.createdAt ?? now,
      updatedAt: now,
    );

    widget.onSaved(room);
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.room == null ? 'Create Room' : 'Edit Room'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Room Name *',
                    hintText: 'e.g., Main Hall, VIP Room 1',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Room name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional description',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<RoomType>(
                        initialValue: _selectedType,
                        decoration: InputDecoration(
                          labelText: 'Room Type *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: RoomType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(_formatRoomType(type)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedType = value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<RoomStatus>(
                        initialValue: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status *',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: RoomStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(_formatStatus(status)),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _capacityController,
                  decoration: InputDecoration(
                    labelText: 'Capacity *',
                    hintText: 'Maximum people',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Capacity is required';
                    }
                    final capacity = int.tryParse(value);
                    if (capacity == null || capacity <= 0) {
                      return 'Enter valid capacity';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _floorController,
                        decoration: InputDecoration(
                          labelText: 'Floor',
                          hintText: 'e.g., 1st',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _sectionController,
                        decoration: InputDecoration(
                          labelText: 'Section',
                          hintText: 'e.g., East',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Amenities',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _amenityController,
                        decoration: InputDecoration(
                          hintText: 'Add amenity',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onSubmitted: (_) => _addAmenity(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add_circle),
                      onPressed: _addAmenity,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_amenities.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _amenities.map((amenity) {
                      return Chip(
                        label: Text(amenity),
                        onDeleted: () => _removeAmenity(amenity),
                        deleteIcon: const Icon(Icons.close, size: 18),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRoom,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.room == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }

  String _formatRoomType(RoomType type) {
    switch (type) {
      case RoomType.regular:
        return 'Regular';
      case RoomType.vip:
        return 'VIP';
      case RoomType.private:
        return 'Private';
    }
  }

  String _formatStatus(RoomStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }
}

//-------
//----
//----//----
//----
//----
//----
//----
// table_management_dialog.dart
// class TableManagementDialog extends ConsumerStatefulWidget {
//   final RoomModel room;
//   final String businessId;
//   final String branchId;

//   const TableManagementDialog({
//     super.key,
//     required this.room,
//     required this.businessId,
//     required this.branchId,
//   });

//   @override
//   ConsumerState<TableManagementDialog> createState() =>
//       _TableManagementDialogState();
// }

// class _TableManagementDialogState extends ConsumerState<TableManagementDialog> {
//   final _tableIdController = TextEditingController();
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _tableIdController.dispose();
//     super.dispose();
//   }

//   // Future<void> _addTable() async {
//   //   final tableId = _tableIdController.text.trim();
//   //   if (tableId.isEmpty) return;

//   //   if (widget.room.tableIds.contains(tableId)) {
//   //     _showSnackBar('Table already in room', Colors.orange);
//   //     return;
//   //   }

//   //   setState(() => _isLoading = true);
//   //   final notifier = ref.read(
//   //     roomProvider((
//   //       businessId: widget.businessId,
//   //       branchId: widget.branchId,
//   //     )).notifier,
//   //   );

//   //   final success = await notifier.addTableToRoom(widget.room.id, tableId);
//   //   setState(() => _isLoading = false);

//   //   if (success) {
//   //     _tableIdController.clear();
//   //     _showSnackBar('Table added successfully', Colors.green);
//   //   }
//   // }

//   // Future<void> _removeTable(String tableId) async {
//   //   setState(() => _isLoading = true);
//   //   final notifier = ref.read(
//   //     roomProvider((
//   //       businessId: widget.businessId,
//   //       branchId: widget.branchId,
//   //     )).notifier,
//   //   );

//   //   final success = await notifier.removeTableFromRoom(widget.room.id, tableId);
//   //   setState(() => _isLoading = false);

//   //   if (success) {
//   //     _showSnackBar('Table removed successfully', Colors.green);
//   //   }
//   // }

//   void _showSnackBar(String message, Color color) {
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(SnackBar(content: Text(message), backgroundColor: color));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final currentRoom = ref.watch(
//       roomProvider((
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//       )).select((state) => state.currentRoom),
//     );

//     // final tableIds = currentRoom?.tableIds ?? widget.room.tableIds;

//     return AlertDialog(
//       title: Text('Tables in ${widget.room.name}'),
//       content: SizedBox(
//         width: MediaQuery.of(context).size.width * 0.7,
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _tableIdController,
//                     decoration: InputDecoration(
//                       labelText: 'Table ID',
//                       hintText: 'Enter table identifier',
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                     ),
//                     onSubmitted: (_) => _addTable(),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 IconButton(
//                   icon: const Icon(Icons.add_circle),
//                   onPressed: _isLoading ? null : _addTable,
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             if (tableIds.isEmpty)
//               Padding(
//                 padding: const EdgeInsets.all(16),
//                 child: Text(
//                   'No tables assigned',
//                   style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                     color: Theme.of(context).colorScheme.outline,
//                   ),
//                 ),
//               )
//             else
//               Expanded(
//                 child: ListView.builder(
//                   shrinkWrap: true,
//                   itemCount: tableIds.length,
//                   itemBuilder: (context, index) {
//                     final tableId = tableIds[index];
//                     return Card(
//                       child: ListTile(
//                         leading: Icon(
//                           Icons.table_restaurant,
//                           color: Theme.of(context).colorScheme.primary,
//                         ),
//                         title: Text(tableId),
//                         trailing: IconButton(
//                           icon: Icon(
//                             Icons.remove_circle,
//                             color: Theme.of(context).colorScheme.error,
//                           ),
//                           onPressed: _isLoading
//                               ? null
//                               : () => _removeTable(tableId),
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//           ],
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Close'),
//         ),
//       ],
//     );
//   }
// }

// // room_status_operations.dart
// These are the commented-out operations (6-11) that you can uncomment when needed

/* 
// Add these methods to your _RoomsScreenState class:
// Room Status Management
void _showStatusDialog(RoomModel room) {
  showDialog(
    context: context,
    builder: (context) => RoomStatusDialog(
      room: room,
      businessId: businessId,
      branchId: branchId,
    ),
  );
}

// Operation 10-11: Reservation Management
void _showReservationDialog(RoomModel room) {
  showDialog(
    context: context,
    builder: (context) => RoomReservationDialog(
      room: room,
      businessId: businessId,
      branchId: branchId,
    ),
  );
}
*/

// STATUS DIALOG WIDGET
class RoomStatusDialog extends ConsumerStatefulWidget {
  final RoomModel room;
  final String businessId;
  final String branchId;

  const RoomStatusDialog({
    super.key,
    required this.room,
    required this.businessId,
    required this.branchId,
  });

  @override
  ConsumerState<RoomStatusDialog> createState() => _RoomStatusDialogState();
}

class _RoomStatusDialogState extends ConsumerState<RoomStatusDialog> {
  final _occupancyController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _occupancyController.dispose();
    super.dispose();
  }

  Future<void> _setStatus(RoomStatus status) async {
    setState(() => _isLoading = true);
    final notifier = ref.read(
      roomProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    await notifier.setRoomStatus(widget.room.id, status);
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  Future<void> _occupyRoom() async {
    final occupancy = int.tryParse(_occupancyController.text);
    if (occupancy == null ||
        occupancy <= 0 ||
        occupancy > widget.room.capacity) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Enter valid occupancy (1-${widget.room.capacity})'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final notifier = ref.read(
      roomProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    await notifier.occupyRoom(widget.room.id, occupancy);
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  Future<void> _vacateRoom() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(
      roomProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    await notifier.vacateRoom(widget.room.id);
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  Future<void> _markAvailable() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(
      roomProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    await notifier.markRoomAvailable(widget.room.id);
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Manage ${widget.room.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Status: ${widget.room.status.name}'),
            Text(
              'Occupancy: ${widget.room.currentOccupancy}/${widget.room.capacity}',
            ),
            const Divider(height: 24),

            // Quick Actions
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Occupy Room'),
              trailing: SizedBox(
                width: 80,
                child: TextField(
                  controller: _occupancyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Count',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              onTap: _occupyRoom,
            ),
            ListTile(
              leading: const Icon(Icons.exit_to_app),
              title: const Text('Vacate Room'),
              onTap: _vacateRoom,
            ),
            ListTile(
              leading: const Icon(Icons.check_circle),
              title: const Text('Mark Available'),
              onTap: _markAvailable,
            ),
            const Divider(height: 24),

            // Change Status
            Text(
              'Change Status:',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: RoomStatus.values.map((status) {
                return ActionChip(
                  label: Text(status.name),
                  onPressed: _isLoading ? null : () => _setStatus(status),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

// room_status_operations.dart
// These are the commented-out operations (6-11) that you can uncomment when needed

/* 
// Add these methods to your _RoomsScreenState class:

// Operation 6-9: Room Status Management
void _showStatusDialog(RoomModel room) {
  showDialog(
    context: context,
    builder: (context) => RoomStatusDialog(
      room: room,
      businessId: businessId,
      branchId: branchId,
    ),
  );
}

// Operation 10-11: Reservation Management
void _showReservationDialog(RoomModel room) {
  showDialog(
    context: context,
    builder: (context) => RoomReservationDialog(
      room: room,
      businessId: businessId,
      branchId: branchId,
    ),
  );
}
*/

// STATUS DIALOG WIDGET
// RESERVATION DIALOG WIDGET
class RoomReservationDialog extends ConsumerStatefulWidget {
  final RoomModel room;
  final String businessId;
  final String branchId;

  const RoomReservationDialog({
    super.key,
    required this.room,
    required this.businessId,
    required this.branchId,
  });

  @override
  ConsumerState<RoomReservationDialog> createState() =>
      _RoomReservationDialogState();
}

class _RoomReservationDialogState extends ConsumerState<RoomReservationDialog> {
  DateTime? _selectedDateTime;
  int _durationHours = 2;
  bool _isLoading = false;

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          _selectedDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _reserveRoom() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(
      roomProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    final duration = Duration(hours: _durationHours);
    await notifier.reserveRoom(widget.room.id, duration);

    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  Future<void> _cancelReservation() async {
    setState(() => _isLoading = true);
    final notifier = ref.read(
      roomProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );

    await notifier.cancelReservation(widget.room.id);
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Reserve ${widget.room.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: Text(
              _selectedDateTime == null
                  ? 'Select Date & Time'
                  : '${_selectedDateTime!.day}/${_selectedDateTime!.month}/${_selectedDateTime!.year} ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}',
            ),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: _pickDateTime,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Duration: '),
              Expanded(
                child: Slider(
                  value: _durationHours.toDouble(),
                  min: 1,
                  max: 24,
                  divisions: 23,
                  label: '$_durationHours hours',
                  onChanged: (value) {
                    setState(() => _durationHours = value.toInt());
                  },
                ),
              ),
              Text('$_durationHours hrs'),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.room.isReserved)
          TextButton(
            onPressed: _isLoading ? null : _cancelReservation,
            child: const Text('Cancel Reservation'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _reserveRoom,
          child: const Text('Reserve'),
        ),
      ],
    );
  }
}
