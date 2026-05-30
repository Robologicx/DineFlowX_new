// table_selection_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/data/models/room_model.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

// class TableSelectionDialog extends ConsumerStatefulWidget {
//   late List<TableModel> availableTables;
//   final String businessId;
//   final String branchId;
//   final TableModel? currentTable; // For showing current selection
//   final Function(TableModel selectedTable) onTableSelected;

//   TableSelectionDialog({
//     super.key,
//     // required this.availableTables,
//     required this.businessId,
//     required this.branchId,
//     this.currentTable,
//     required this.onTableSelected,
//   });

//   @override
//   ConsumerState<TableSelectionDialog> createState() =>
//       _TableSelectionDialogState();
// }

// class _TableSelectionDialogState extends ConsumerState<TableSelectionDialog> {
//   final _formKey = GlobalKey<FormState>();
//   TableModel? _selectedTable;
//   Map<String, RoomModel> _roomsMap = {};

//   @override
//   void initState() {
//     super.initState();
//     _selectedTable = widget.currentTable;

//     // Load rooms for displaying room names
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       final tableNotifier = ref.read(
//         tableProvider((
//           businessId: widget.businessId,
//           branchId: widget.branchId,
//         )).notifier,
//       );
//       // tableNotifier.setBusinessContext(widget.businessId, widget.branchId);
//       tableNotifier.loadAllTables();

//       final roomNotifier = ref.read(
//         roomProvider((
//           businessId: widget.businessId,
//           branchId: widget.branchId,
//         )).notifier,
//       );
//       roomNotifier.setBusinessContext(widget.businessId, widget.branchId);
//       roomNotifier.loadAllRooms();
//     });
//   }

//   // Filter tables - only show available tables
//   List<TableModel> get _selectableTables {
//     return widget.availableTables
//         .where((table) => table.status == TableStatus.available)
//         .toList();
//   }

//   Color _getStatusColor(TableStatus status) {
//     switch (status) {
//       case TableStatus.occupied:
//         return Colors.red;
//       case TableStatus.reserved:
//         return Colors.orange;
//       case TableStatus.cleaning:
//         return Colors.blue;
//       case TableStatus.outOfService:
//         return Colors.grey;
//       default:
//         return Colors.green;
//     }
//   }

//   String _formatStatus(TableStatus status) {
//     return status.name[0].toUpperCase() + status.name.substring(1);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final roomsState = ref.watch(
//       roomProvider((businessId: widget.businessId, branchId: widget.branchId)),
//     );

//     // Create rooms map for quick lookup
//     if (roomsState.rooms.isNotEmpty) {
//       _roomsMap = {for (var room in roomsState.rooms) room.id: room};
//     }

//     return Dialog(
//       child: ConstrainedBox(
//         constraints: BoxConstraints(
//           maxWidth: 500,
//           maxHeight: MediaQuery.of(context).size.height * 0.7,
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             // Title Bar
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 children: [
//                   Icon(
//                     Icons.table_restaurant,
//                     color: Theme.of(context).colorScheme.primary,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'Select Table',
//                     style: Theme.of(context).textTheme.titleLarge,
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     icon: const Icon(Icons.close),
//                     onPressed: () => Navigator.of(context).pop(),
//                   ),
//                 ],
//               ),
//             ),
//             const Divider(height: 1),

//             // Current Table Info (if exists)
//             if (widget.currentTable != null) ...[
//               Container(
//                 margin: const EdgeInsets.all(16),
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.surfaceVariant,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: Theme.of(context).colorScheme.outline,
//                     width: 0.5,
//                   ),
//                 ),
//                 child: Row(
//                   children: [
//                     Icon(
//                       Icons.info_outline,
//                       size: 20,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Current Table',
//                             style: Theme.of(context).textTheme.labelSmall
//                                 ?.copyWith(fontWeight: FontWeight.bold),
//                           ),
//                           Text(
//                             widget.currentTable!.tableNumber,
//                             style: Theme.of(context).textTheme.bodyMedium,
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ],

//             // Content
//             Expanded(
//               child: _selectableTables.isEmpty
//                   ? Center(
//                       child: Padding(
//                         padding: const EdgeInsets.all(24),
//                         child: Column(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.table_restaurant_outlined,
//                               size: 64,
//                               color: Theme.of(context).colorScheme.outline,
//                             ),
//                             const SizedBox(height: 16),
//                             Text(
//                               'No occupied tables available',
//                               style: Theme.of(context).textTheme.titleMedium
//                                   ?.copyWith(
//                                     color: Theme.of(
//                                       context,
//                                     ).colorScheme.outline,
//                                   ),
//                               textAlign: TextAlign.center,
//                             ),
//                             const SizedBox(height: 8),
//                             Text(
//                               'Only occupied, reserved, or cleaning tables can be selected',
//                               style: Theme.of(context).textTheme.bodySmall
//                                   ?.copyWith(
//                                     color: Theme.of(
//                                       context,
//                                     ).colorScheme.outline,
//                                   ),
//                               textAlign: TextAlign.center,
//                             ),
//                           ],
//                         ),
//                       ),
//                     )
//                   : Form(
//                       key: _formKey,
//                       child: ListView.builder(
//                         padding: const EdgeInsets.all(16),
//                         itemCount: _selectableTables.length,
//                         itemBuilder: (context, index) {
//                           final table = _selectableTables[index];
//                           final room = table.roomId != null
//                               ? _roomsMap[table.roomId]
//                               : null;
//                           final isSelected = _selectedTable?.id == table.id;

//                           return Card(
//                             margin: const EdgeInsets.only(bottom: 8),
//                             elevation: isSelected ? 4 : 1,
//                             color: isSelected
//                                 ? Theme.of(context).colorScheme.primaryContainer
//                                 : null,
//                             child: InkWell(
//                               onTap: () {
//                                 setState(() => _selectedTable = table);
//                               },
//                               borderRadius: BorderRadius.circular(12),
//                               child: Padding(
//                                 padding: const EdgeInsets.all(12),
//                                 child: Row(
//                                   children: [
//                                     // Selection Radio
//                                     Radio<String>(
//                                       value: table.id,
//                                       groupValue: _selectedTable?.id,
//                                       onChanged: (value) {
//                                         setState(() => _selectedTable = table);
//                                       },
//                                     ),
//                                     const SizedBox(width: 12),

//                                     // Table Info
//                                     Expanded(
//                                       child: Column(
//                                         crossAxisAlignment:
//                                             CrossAxisAlignment.start,
//                                         children: [
//                                           Row(
//                                             children: [
//                                               Text(
//                                                 table.tableNumber,
//                                                 style: Theme.of(context)
//                                                     .textTheme
//                                                     .titleMedium
//                                                     ?.copyWith(
//                                                       fontWeight:
//                                                           FontWeight.bold,
//                                                     ),
//                                               ),
//                                               const SizedBox(width: 8),
//                                               Container(
//                                                 padding:
//                                                     const EdgeInsets.symmetric(
//                                                       horizontal: 8,
//                                                       vertical: 2,
//                                                     ),
//                                                 decoration: BoxDecoration(
//                                                   color: _getStatusColor(
//                                                     table.status,
//                                                   ).withOpacity(0.2),
//                                                   borderRadius:
//                                                       BorderRadius.circular(4),
//                                                   border: Border.all(
//                                                     color: _getStatusColor(
//                                                       table.status,
//                                                     ),
//                                                     width: 1,
//                                                   ),
//                                                 ),
//                                                 child: Text(
//                                                   _formatStatus(table.status),
//                                                   style: Theme.of(context)
//                                                       .textTheme
//                                                       .labelSmall
//                                                       ?.copyWith(
//                                                         color: _getStatusColor(
//                                                           table.status,
//                                                         ),
//                                                         fontWeight:
//                                                             FontWeight.bold,
//                                                       ),
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                           const SizedBox(height: 4),
//                                           Row(
//                                             children: [
//                                               Icon(
//                                                 Icons.person,
//                                                 size: 14,
//                                                 color: Theme.of(context)
//                                                     .colorScheme
//                                                     .onSurface
//                                                     .withOpacity(0.6),
//                                               ),
//                                               const SizedBox(width: 4),
//                                               Text(
//                                                 '${table.seats} seats',
//                                                 style: Theme.of(
//                                                   context,
//                                                 ).textTheme.bodySmall,
//                                               ),
//                                               if (room != null) ...[
//                                                 const SizedBox(width: 12),
//                                                 Icon(
//                                                   Icons.meeting_room,
//                                                   size: 14,
//                                                   color: Theme.of(
//                                                     context,
//                                                   ).colorScheme.primary,
//                                                 ),
//                                                 const SizedBox(width: 4),
//                                                 Expanded(
//                                                   child: Text(
//                                                     room.name,
//                                                     style: Theme.of(context)
//                                                         .textTheme
//                                                         .bodySmall
//                                                         ?.copyWith(
//                                                           color: Theme.of(
//                                                             context,
//                                                           ).colorScheme.primary,
//                                                         ),
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                   ),
//                                                 ),
//                                               ] else ...[
//                                                 const SizedBox(width: 12),
//                                                 Text(
//                                                   'Standalone',
//                                                   style: Theme.of(context)
//                                                       .textTheme
//                                                       .bodySmall
//                                                       ?.copyWith(
//                                                         fontStyle:
//                                                             FontStyle.italic,
//                                                         color: Theme.of(
//                                                           context,
//                                                         ).colorScheme.outline,
//                                                       ),
//                                                 ),
//                                               ],
//                                             ],
//                                           ),
//                                           if (table.locationHint?.isNotEmpty ==
//                                               true) ...[
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               table.locationHint!,
//                                               style: Theme.of(context)
//                                                   .textTheme
//                                                   .bodySmall
//                                                   ?.copyWith(
//                                                     color: Theme.of(
//                                                       context,
//                                                     ).colorScheme.outline,
//                                                   ),
//                                             ),
//                                           ],
//                                         ],
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//             ),

//             // Action Buttons
//             const Divider(height: 1),
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => Navigator.of(context).pop(),
//                     child: const Text('Cancel'),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton(
//                     onPressed: _selectedTable == null
//                         ? null
//                         : () {
//                             widget.onTableSelected(_selectedTable!);
//                             Navigator.of(context).pop();
//                           },
//                     child: const Text('Select Table'),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
// table_selection_dialog.dart

class TableSelectionDialog extends ConsumerStatefulWidget {
  final String businessId;
  final String branchId;
  final TableModel? currentTable;
  final Function(TableModel selectedTable) onTableSelected;

  const TableSelectionDialog({
    super.key,
    required this.businessId,
    required this.branchId,
    this.currentTable,
    required this.onTableSelected,
  });

  @override
  ConsumerState<TableSelectionDialog> createState() =>
      _TableSelectionDialogState();
}

class _TableSelectionDialogState extends ConsumerState<TableSelectionDialog> {
  TableModel? _selectedTable;

  @override
  void initState() {
    super.initState();
    _selectedTable = widget.currentTable;

    // Load data when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  void _loadData() {
    // Load tables
    final tableNotifier = ref.read(
      tableProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );
    tableNotifier.loadAllTables();

    // Load rooms
    final roomNotifier = ref.read(
      roomProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )).notifier,
    );
    roomNotifier.setBusinessContext(widget.businessId, widget.branchId);
    roomNotifier.loadAllRooms();
  }

  // Filter tables - only show occupied, reserved, or cleaning tables
  List<TableModel> _getSelectableTables(List<TableModel> allTables) {
    // Filter tables - only show available tables
    return allTables
        .where((table) => table.status == TableStatus.available)
        .toList();
    // if want to show other tables uncomment this.
    // return allTables
    //     .where(
    //       (table) =>
    //           table.status == TableStatus.occupied ||
    //           table.status == TableStatus.reserved ||
    //           table.status == TableStatus.cleaning,
    //     )
    //     .toList();
  }

  Color _getStatusColor(TableStatus status) {
    switch (status) {
      case TableStatus.occupied:
        return Colors.red;
      case TableStatus.reserved:
        return Colors.orange;
      case TableStatus.cleaning:
        return Colors.blue;
      case TableStatus.outOfService:
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  String _formatStatus(TableStatus status) {
    return status.name[0].toUpperCase() + status.name.substring(1);
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading tables...'),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Failed to load tables',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _loadData, child: Text('Retry')),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.table_restaurant_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tables available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Only occupied, reserved, or cleaning tables can be selected',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableList(
    List<TableModel> selectableTables,
    Map<String, RoomModel> roomsMap,
  ) {
    return Form(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: selectableTables.length,
        itemBuilder: (context, index) {
          final table = selectableTables[index];
          final room = table.roomId != null ? roomsMap[table.roomId] : null;
          final isSelected = _selectedTable?.id == table.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            elevation: isSelected ? 4 : 1,
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : null,
            child: InkWell(
              onTap: () {
                setState(() => _selectedTable = table);
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Selection Radio
                    Radio<String>(
                      value: table.id,
                      groupValue: _selectedTable?.id,
                      onChanged: (value) {
                        setState(() => _selectedTable = table);
                      },
                    ),
                    const SizedBox(width: 12),

                    // Table Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                table.tableNumber,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    table.status,
                                  ).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: _getStatusColor(table.status),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  _formatStatus(table.status),
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: _getStatusColor(table.status),
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person,
                                size: 14,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.6),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${table.seats} seats',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (room != null) ...[
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.meeting_room,
                                  size: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    room.name,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(width: 12),
                                Text(
                                  'Standalone',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        fontStyle: FontStyle.italic,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.outline,
                                      ),
                                ),
                              ],
                            ],
                          ),
                          if (table.locationHint?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Text(
                              table.locationHint!,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesState = ref.watch(
      tableProvider((businessId: widget.businessId, branchId: widget.branchId)),
    );
    final roomsState = ref.watch(
      roomProvider((businessId: widget.businessId, branchId: widget.branchId)),
    );

    // Create rooms map for quick lookup
    final roomsMap = {for (var room in roomsState.rooms) room.id: room};

    // Get selectable tables
    final selectableTables = _getSelectableTables(tablesState.tables);

    // Determine content based on state
    Widget content;
    if (tablesState.isLoading || roomsState.isLoading) {
      content = _buildLoadingState();
    } else if (tablesState.error != null) {
      content = _buildErrorState(tablesState.error!);
    } else if (selectableTables.isEmpty) {
      content = _buildEmptyState();
    } else {
      content = _buildTableList(selectableTables, roomsMap);
    }

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 500,
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.table_restaurant,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Select Table',
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

            // Current Table Info (if exists)
            if (widget.currentTable != null) ...[
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Table',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.currentTable!.tableNumber,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Content
            Expanded(child: content),

            // Action Buttons
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selectedTable == null
                        ? null
                        : () {
                            widget.onTableSelected(_selectedTable!);
                            Navigator.of(context).pop();
                          },
                    child: const Text('Select Table'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
