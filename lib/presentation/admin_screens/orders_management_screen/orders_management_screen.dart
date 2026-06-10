import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:hotel_management_system/data/models/close_day_report.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/services/thermal_printer_service.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/create_order_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/order_detail_dialog.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/order_status_update_dialog.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/order_waiter_assignment_dialog.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/table_selection_dialog.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/order_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/table_state_and_notifier.dart';

// Role-based permission service

class OrderManagementScreen extends ConsumerStatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  ConsumerState<OrderManagementScreen> createState() =>
      _OrderManagementScreenState();
}

class _OrderManagementScreenState extends ConsumerState<OrderManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  OrderStatus? _selectedStatusFilter;
  OrderType? _selectedTypeFilter;
  late OrderNotifier _orderNotifier;
  late String businessId = BusinessRepository.temporaryBusinesshId;
  late String branchId = BusinessRepository.temporaryBranchId;
  late TableNotifier tableNotifier;
  bool canCreateOrder = false;
  bool canEditOrder = false;
  bool canDeleteOrder = false;
  // everyone can update order status by default as there's no customer roles.
  bool canUpdateStatus = true;
  bool canAssignWaiter = false;
  bool canChangeDiningTable = false;
  bool canViewAllOrders = false;
  bool _showAllOrders = false;
  bool _isClosingDay = false;

  Set<OrderStatus> _selectedStatuses = {
    OrderStatus.pending,
    OrderStatus.inProgress,
    OrderStatus.ready,
  }; // Default active orders

  // State for the periodic blinking effect
  Timer? _blinkTimer;
  // State to control the on/off phase of the blink animation
  bool _isBlinking = false;

  @override
  void initState() {
    super.initState();

    final currentUser = ref.read(userProvider).selectedUser;
    businessId =
        currentUser?.primarybusinessId ??
        BusinessRepository.temporaryBusinesshId;
    branchId =
        currentUser?.primaryBranchId ?? BusinessRepository.temporaryBranchId;

    tableNotifier = ref.read(
      tableProvider((businessId: businessId, branchId: branchId)).notifier,
    );

    _orderNotifier = ref.read(
      orderProvider((
        businessId: businessId,
        branchId: branchId,
        tableNotifier: tableNotifier,
      )).notifier,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _blinkTimer?.cancel();
    super.dispose();
  }

  // 🌟 NEW HELPER: Check if an order should be in the blink window (1 minute)
  bool _isOrderWithinBlinkWindow(OrderModel order) {
    const blinkDuration = Duration(minutes: 1);
    final now = DateTime.now();
    final difference = now.difference(order.createdAt);

    // Order is in the window if it's less than 1 minute old AND it's one of the currently filtered statuses
    return difference < blinkDuration &&
        (_selectedStatuses.isEmpty ||
            _selectedStatuses.contains(order.orderStatus));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentDayStartAtAsync = ref.watch(
      currentDayStartAtProvider((
        branchId: branchId,
        businessId: businessId,
        tableNotifier: tableNotifier,
      )),
    );
    final ordersAsync = _showAllOrders
        ? ref.watch(
            allOrdersStreamProvider((
              branchId: branchId,
              businessId: businessId,
              tableNotifier: tableNotifier,
            )),
          )
        : ref.watch(
            todayOrdersStreamProvider((
              branchId: branchId,
              businessId: businessId,
              tableNotifier: tableNotifier,
            )),
          );

    final orderState = ordersAsync.when(
      data: (orders) => OrderState(orders: orders),
      loading: () => const OrderState(isLoading: true),
      error: (error, _) => OrderState(error: error.toString()),
    );

    // 🌟 REAL-TIME BLINKING LOGIC (1 MINUTE DURATION)

    // 1. Check if any order should be blinking based on its creation time
    final bool shouldBlinkActive = orderState.orders.any(
      _isOrderWithinBlinkWindow,
    );

    if (shouldBlinkActive && (_blinkTimer == null || !_blinkTimer!.isActive)) {
      // We have orders that need to blink, but the global periodic timer is not running. Start it.

      // 2. Start a *periodic* timer to toggle the blink state every 500ms
      _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
        // Check if any order is still in the 1-minute window
        final anyStillBlinking = orderState.orders.any(
          _isOrderWithinBlinkWindow,
        );

        if (!anyStillBlinking) {
          // No orders are left in the 1-minute window. Stop the timer.
          timer.cancel();
          if (mounted) {
            setState(() {
              _isBlinking = false;
            });
          }
        } else {
          // Still in the window, toggle the blink state
          if (mounted) {
            setState(() {
              _isBlinking = !_isBlinking;
            });
          }
        }
      });

      // 3. Immediately set state to start the first blink cycle (starts 'on')
      if (mounted) {
        setState(() {
          _isBlinking = true;
        });
      }
    } else if (!shouldBlinkActive &&
        _blinkTimer != null &&
        _blinkTimer!.isActive) {
      // No orders should blink, but the timer is still running. Stop it immediately.
      _blinkTimer!.cancel();
      if (mounted) {
        setState(() {
          _isBlinking = false;
        });
      }
    }

    final userNotifier = ref.read(userProvider.notifier);
    canCreateOrder = userNotifier.hasPermissionOfCurrentUser(
      Permissions.createOrder,
    );
    canEditOrder = userNotifier.hasPermissionOfCurrentUser(
      Permissions.updateOrder,
    );
    canDeleteOrder = userNotifier.hasPermissionOfCurrentUser(
      Permissions.deleteOrder,
    );

    canUpdateStatus = userNotifier.hasPermissionOfCurrentUser(
      Permissions.updateOrderStatus,
    );

    canAssignWaiter = userNotifier.hasPermissionOfCurrentUser(
      Permissions.assignOrderWaiter,
    );
    canChangeDiningTable = userNotifier.hasPermissionOfCurrentUser(
      Permissions.changeDiningTable,
    );
    canViewAllOrders =
        userNotifier.hasPermissionOfCurrentUser(Permissions.viewOrderHistory) &&
        userNotifier.hasPermissionOfCurrentUser(Permissions.viewActiveOrders);

    return Scaffold(
      appBar: AppBar(
        title: Text('Orders Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isClosingDay ? null : _handleCloseDay,
            icon: const Icon(Icons.event_busy),
            tooltip: 'Close Day',
          ),
          TextButton.icon(
            onPressed: _toggleOrderScope,
            icon: Icon(_showAllOrders ? Icons.today : Icons.history),
            label: Text(_showAllOrders ? 'Today Orders' : 'All Orders'),
          ),
          if (canCreateOrder)
            IconButton(
              onPressed: () => _showCreateOrderDialog(context),
              icon: const Icon(Icons.add),
              tooltip: 'Create Order',
            ),
          IconButton(
            onPressed: () => _refreshOrders(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: currentDayStartAtAsync.when(
                data: (startAt) => Text(
                  'Current Business Day: ${_formatBusinessDayDateTime(startAt.toLocal())}',
                  style: theme.textTheme.bodySmall,
                ),
                loading: () => Text(
                  'Current Business Day: loading...',
                  style: theme.textTheme.bodySmall,
                ),
                error: (_, __) => Text(
                  'Current Business Day: unavailable',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
          ),
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(0),
                  child: Column(
                    children: [
                      // Search Bar
                      SearchBar(
                        controller: _searchController,
                        hintText: 'Search orders...',
                        leading: const Icon(Icons.search),
                        trailing: _searchQuery.isNotEmpty
                            ? [
                                IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                              ]
                            : null,
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                      const SizedBox(height: 16),

                      // Status filters are for daily operational view only.
                      if (!_showAllOrders) ...[
                        _buildStatusChipFilter(colorScheme),
                        const SizedBox(height: 12),
                      ],

                      // Type Filter (keep as is or make it chips too)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Text(
                              'Type: ',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(width: 8),
                            ...OrderType.values.map((type) {
                              final isSelected = _selectedTypeFilter == type;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  selected: isSelected,
                                  label: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      _buildTypeIcon(type, size: 16),
                                      const SizedBox(width: 6),
                                      Text(_getTypeText(type)),
                                    ],
                                  ),
                                  onSelected: (selected) {
                                    setState(() {
                                      _selectedTypeFilter = selected
                                          ? type
                                          : null;
                                    });
                                  },
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content Area
          Expanded(child: _buildContent(orderState, colorScheme)),
        ],
      ),
      floatingActionButton: canCreateOrder
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateOrderDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('New Order'),
            )
          : null,
    );
  }

  String _formatBusinessDayDateTime(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  Future<void> _handleCloseDay() async {
    final shouldClose =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Close Day'),
              content: const Text(
                'This will close the current business day and start a new one. Continue?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Close Day'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldClose || !mounted) return;

    final selectedUser = ref.read(userProvider).selectedUser;
    setState(() => _isClosingDay = true);
    try {
      final closeDayRequest = (
        businessId: businessId,
        branchId: branchId,
        tableNotifier: tableNotifier,
        closedBy: selectedUser?.uid,
      );
      ref.invalidate(closeCurrentDayReportProvider(closeDayRequest));
      final report = await ref.read(
        closeCurrentDayReportProvider(closeDayRequest).future,
      );

      if (!mounted) return;
      await _showCloseDayReportDialog(report);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to close day: $e')));
    } finally {
      if (mounted) {
        setState(() => _isClosingDay = false);
      }
    }
  }

  String _fmtMoney(double value) => value.toStringAsFixed(2);

  Future<void> _showCloseDayReportDialog(CloseDayReport report) async {
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Day Closed Report'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Start: ${_formatBusinessDayDateTime(report.dayStartAt.toLocal())}',
                  ),
                  Text(
                    'Closed: ${_formatBusinessDayDateTime(report.dayClosedAt.toLocal())}',
                  ),
                  const SizedBox(height: 12),
                  Text('Total Orders: ${report.totalOrders}'),
                  Text('Completed: ${report.completedOrders}'),
                  Text('Pending: ${report.pendingOrders}'),
                  Text('In Progress: ${report.inProgressOrders}'),
                  Text('Cancelled: ${report.cancelledOrders}'),
                  Text('Refunded: ${report.refundedOrders}'),
                  const Divider(height: 24),
                  Text('Total Amount: Rs ${_fmtMoney(report.totalAmount)}'),
                  Text('Total Expenses: Rs ${_fmtMoney(report.totalExpenses)}'),
                  Text(
                    'Cash In Hand After Expense: Rs ${_fmtMoney(report.cashInHandAfterExpenses)}',
                  ),
                  Text('Profit / Loss: Rs ${_fmtMoney(report.profitOrLoss)}'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final pdf = pw.Document();
                pdf.addPage(
                  pw.Page(
                    pageFormat: PdfPageFormat.a4,
                    build: (context) {
                      return pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Close Day Report',
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(height: 12),
                          pw.Text(
                            'Start: ${_formatBusinessDayDateTime(report.dayStartAt.toLocal())}',
                          ),
                          pw.Text(
                            'Closed: ${_formatBusinessDayDateTime(report.dayClosedAt.toLocal())}',
                          ),
                          pw.SizedBox(height: 12),
                          pw.Text('Total Orders: ${report.totalOrders}'),
                          pw.Text('Completed: ${report.completedOrders}'),
                          pw.Text('Pending: ${report.pendingOrders}'),
                          pw.Text('In Progress: ${report.inProgressOrders}'),
                          pw.Text('Cancelled: ${report.cancelledOrders}'),
                          pw.Text('Refunded: ${report.refundedOrders}'),
                          pw.SizedBox(height: 12),
                          pw.Text(
                            'Total Amount: Rs ${_fmtMoney(report.totalAmount)}',
                          ),
                          pw.Text(
                            'Total Expenses: Rs ${_fmtMoney(report.totalExpenses)}',
                          ),
                          pw.Text(
                            'Cash In Hand After Expense: Rs ${_fmtMoney(report.cashInHandAfterExpenses)}',
                          ),
                          pw.Text(
                            'Profit / Loss: Rs ${_fmtMoney(report.profitOrLoss)}',
                          ),
                        ],
                      );
                    },
                  ),
                );

                await Printing.layoutPdf(
                  onLayout: (format) async => pdf.save(),
                );
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('Download PDF'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatusChipFilter(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Filter by Status',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            // Quick filter buttons
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatuses = {
                    OrderStatus.pending,
                    OrderStatus.inProgress,
                    OrderStatus.ready,
                  };
                });
              },
              icon: const Icon(Icons.access_time, size: 16),
              label: const Text('Active'),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedStatuses = {
                    OrderStatus.completed,
                    OrderStatus.cancelled,
                    OrderStatus.refunded,
                  };
                });
              },
              icon: const Icon(Icons.history, size: 16),
              label: const Text('History'),
            ),
            if (_selectedStatuses.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  setState(() => _selectedStatuses.clear());
                  // FIX: If filters are cleared, blinking should stop
                  if (_blinkTimer != null && _blinkTimer!.isActive) {
                    _blinkTimer?.cancel();
                    setState(() {
                      _isBlinking = false;
                    });
                  }
                },
                icon: const Icon(Icons.clear, size: 16),
                label: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: OrderStatus.values.map((status) {
            final isSelected = _selectedStatuses.contains(status);
            final statusColor = _getStatusColorForChip(status);

            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: statusColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(_getStatusText(status)),
                ],
              ),
              selectedColor: statusColor.withAlpha(50),
              checkmarkColor: statusColor,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedStatuses.add(status);
                  } else {
                    _selectedStatuses.remove(status);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getStatusColorForChip(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.inProgress:
        return Colors.blue;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.completed:
        return Colors.teal;
      case OrderStatus.cancelled:
        return Colors.red;
      case OrderStatus.refunded:
        return Colors.grey;
    }
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    var filtered = List<OrderModel>.from(orders);

    // In "All Orders" mode always show complete history regardless of status.
    if (!_showAllOrders && _selectedStatuses.isNotEmpty) {
      filtered = filtered
          .where((order) => _selectedStatuses.contains(order.orderStatus))
          .toList();
    }

    // Legacy single status dropdown filter.
    if (!_showAllOrders && _selectedStatusFilter != null) {
      filtered = filtered
          .where((order) => order.orderStatus == _selectedStatusFilter)
          .toList();
    }

    // Filter by type
    if (_selectedTypeFilter != null) {
      filtered = filtered
          .where((order) => order.orderType == _selectedTypeFilter)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (order) =>
                order.orderId.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                order.userName.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                (order.diningTable?.tableNumber.toLowerCase().contains(
                      _searchQuery.toLowerCase(),
                    ) ??
                    false),
          )
          .toList();
    }

    return filtered;
  }

  Widget _buildStatusFilter(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<OrderStatus?>(
        value: _selectedStatusFilter,
        hint: const Text('Filter by Status'),
        underline: const SizedBox(),
        items: [
          const DropdownMenuItem<OrderStatus?>(
            value: null,
            child: Text('All Status'),
          ),
          ...OrderStatus.values.map(
            (status) => DropdownMenuItem<OrderStatus>(
              value: status,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatusIndicator(size: 12),
                  const SizedBox(width: 8),
                  Text(_getStatusText(status)),
                ],
              ),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _selectedStatusFilter = value),
      ),
    );
  }

  Widget _buildTypeFilter(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<OrderType?>(
        value: _selectedTypeFilter,
        hint: const Text('Filter by Type'),
        underline: const SizedBox(),
        items: [
          const DropdownMenuItem<OrderType?>(
            value: null,
            child: Text('All Types'),
          ),
          ...OrderType.values.map(
            (type) => DropdownMenuItem<OrderType>(
              value: type,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypeIcon(type, size: 16),
                  const SizedBox(width: 8),
                  Text(_getTypeText(type)),
                ],
              ),
            ),
          ),
        ],
        onChanged: (value) => setState(() => _selectedTypeFilter = value),
      ),
    );
  }

  Widget _buildContent(OrderState state, ColorScheme colorScheme) {
    if (state.isLoading && state.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading orders',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _refreshOrders(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredOrders = _filterOrders(state.orders);

    // SORT: Latest order should be at the top
    filteredOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (filteredOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.receipt_long,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No orders found'
                  : 'No orders available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms or filters'
                  : _showAllOrders
                  ? 'No orders found for selected filters'
                  : 'No orders for today',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refreshOrders(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamic columns based on available width and desired min card width
          final maxWidth = constraints.maxWidth;
          const double minCardWidth =
              340; // adjust to taste (smaller => more columns)
          int columns = (maxWidth / minCardWidth).floor();
          if (columns < 1) columns = 1;
          if (columns > 4) columns = 4; // cap columns if you want

          // For single column use list view to get full-width cards on narrow screens
          if (columns == 1) {
            return _buildListView(filteredOrders, state.isLoading);
          }

          // Choose cardHeight to suit your UI; it's ignored if you rely on childAspectRatio
          final double cardHeight = 300;

          return _buildFixedGridView(
            filteredOrders,
            crossAxisCount: columns,
            cardHeight: cardHeight,
          );
        },
      ),
    );
  }

  Widget _buildListView(List<OrderModel> orders, bool isLoading) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: orders.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == orders.length && isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final order = orders[index];
        // 🌟 Use the timestamp check for 'isNew'
        final isNew = _isOrderWithinBlinkWindow(order);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildOrderCard(order, isListView: true, isNew: isNew),
        );
      },
    );
  }
  /*
  Widget _buildGridView(List<OrderModel> orders, int crossAxisCount) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 250, // Adjust as needed
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        // 🌟 Use the timestamp check for 'isNew'
        final isNew = _isOrderWithinBlinkWindow(order);
        return _buildOrderCard(order, isNew: isNew);
      },
    );
  }
*/

  /*  // ...existing code...
  /// Responsive wrap grid: cards will use up to [maxCardWidth] and grow vertically
  /// to fit their content instead of being constrained to a fixed grid cell height.
  Widget _buildResponsiveWrapGrid(List<OrderModel> orders,
      {double maxCardWidth = 360}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(builder: (context, constraints) {
        // compute available width and decide item width if you want fixed columns
        // but we allow Wrap to flow items naturally up to maxCardWidth.
        return Wrap(
          spacing: 16,
          runSpacing: 16,
          alignment: WrapAlignment.start,
          children: orders.map((order) {
            // ConstrainedBox ensures cards don't grow too wide on very large screens
            return ConstrainedBox(
              constraints: BoxConstraints(
                // ensure a reasonable minimum so very narrow cards look ok
                minWidth: 220,
                // allow card to grow to maxCardWidth
                maxWidth: maxCardWidth,
              ),
              child: _buildOrderCard(
                order,
                // treat as grid item (not list)
                isListView: false,
                // pass isNew if you compute it earlier; compute here if needed
                isNew: _isOrderWithinBlinkWindow(order),
              ),
            );
          }).toList(),
        );
      }),
    );
  }
// ...existing code...
*/
  /// Fixed grid view: cards have fixed height and uniform size.

  // ...existing code...
  /// Dynamic grid view: cards size based on content, with lazy loading
  Widget _buildFixedGridView(
    List<OrderModel> orders, {
    required int crossAxisCount,
    required double cardHeight,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8, // Reduced from 0.75 - makes cards wider/shorter
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        final isNew = _isOrderWithinBlinkWindow(order);
        return _buildOrderCard(order, isListView: false, isNew: isNew);
      },
    );
  }
  // ...existing code...

  Widget _buildOrderCard(
    OrderModel order, {
    bool isListView = false,
    bool isNew = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Check if this specific card should be actively blinking
    // Blinking only occurs if the order is new AND the global periodic timer is in the 'on' state.
    final bool isBlinkingNow = isNew && _isBlinking;

    // Calculate color based on the blinking state
    Color cardColor = isBlinkingNow
        ? colorScheme.primary.withOpacity(
            0.25, // Strong highlight when 'on'
          )
        : isNew
        ? colorScheme.primary.withOpacity(
            0.05,
          ) // Subtle background when 'off' (or base highlight)
        : colorScheme.surface;

    // Use AnimatedContainer for smooth transitions
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: isBlinkingNow
            ? Border.all(
                color: colorScheme.primary,
                width: 3, // Thicker border when 'on'
              )
            : isNew
            ? Border.all(
                color: colorScheme.primary.withOpacity(0.5),
                width: 1, // Thin border when 'off'
              )
            : Border.all(
                color: colorScheme.outline.withOpacity(0.5),
                width: 0.5,
              ),
        boxShadow: isBlinkingNow
            ? [
                BoxShadow(
                  color: colorScheme.primary.withOpacity(0.5),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showOrderDetails(context, order),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // Order Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'User: ${order.userName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => _buildPopupMenuItems(order),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Order Info Row
              Row(
                children: [
                  _buildTypeIcon(order.orderType),
                  const SizedBox(width: 4),
                  Text(
                    _getTypeText(order.orderType),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  _buildStatusChip(order.orderStatus, colorScheme),
                ],
              ),

              const SizedBox(height: 8),

              // Order Details
              if (order.orderType == OrderType.dining &&
                  order.diningTable != null) ...[
                Text(
                  'Table: ${order.diningTable!.tableNumber} Room: ${order.diningTable!.roomId ?? ''}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
              ],

              if (order.orderType == OrderType.delivery &&
                  order.deliveryAddress != null) ...[
                Text(
                  'Address: ${order.deliveryAddress}',
                  style: theme.textTheme.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
              ],

              if (order.waiterId != null) ...[
                Text(
                  'Waiter: ${order.waiterId}',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
              ],

              // Items Summary
              Text(
                '${order.items.length} item${order.items.length > 1 ? 's' : ''}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 8),

              // Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDateTime(order.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${order.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status, ColorScheme colorScheme) {
    Color backgroundColor;
    Color textColor;
    Color iconColor;

    switch (status) {
      case OrderStatus.pending:
        backgroundColor = Colors.orange.shade100;
        iconColor = Colors.orange;
        break;
      case OrderStatus.inProgress:
        backgroundColor = Colors.blue.shade100;
        iconColor = Colors.blue;
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.green.shade100;
        iconColor = Colors.green;
        break;
      case OrderStatus.completed:
        backgroundColor = Colors.teal.shade100;
        iconColor = Colors.teal;
        break;
      case OrderStatus.cancelled:
        backgroundColor = Colors.red.shade100;
        iconColor = Colors.red;
        break;
      case OrderStatus.refunded:
        backgroundColor = Colors.grey.shade100;
        iconColor = Colors.grey;
        break;
    }
    textColor = Colors.black45;

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
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: _buildStatusIndicator(size: 8, iconColor: iconColor),
    );
  }

  Widget _buildStatusIndicator({
    double size = 8,
    Color iconColor = Colors.black,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: iconColor, shape: BoxShape.circle),
    );
  }

  Widget _buildTypeIcon(OrderType type, {double size = 20}) {
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

    return Icon(iconData, size: size);
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

  List<PopupMenuEntry> _buildPopupMenuItems(OrderModel order) {
    final items = <PopupMenuEntry>[];

    // Status Update (Admin, Owner, Waiter)
    if (canUpdateStatus) {
      items.add(
        PopupMenuItem(
          value: 'status',
          child: const ListTile(
            leading: Icon(Icons.update),
            title: Text('Update Status'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _showStatusUpdateDialog(context, order),
        ),
      );
      items.add(
        PopupMenuItem(
          value: 'print',
          child: const ListTile(
            leading: Icon(Icons.print),
            title: Text('Print'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () async {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                duration: Duration(seconds: 2),
                backgroundColor: Colors.green,
                content: Text('Printing Receipt...'),
              ),
            );
            await ThermalPrinterService().printOrderLAN(
              order,
              type: '',
              businessId: businessId,
              branchId: branchId,
            );
          },
        ),
      );
    }

    // Assign Waiter (Admin, Owner only)
    if (canAssignWaiter && order.orderType == OrderType.dining) {
      items.add(
        PopupMenuItem(
          value: 'waiter',
          child: const ListTile(
            leading: Icon(Icons.person_add),
            title: Text('Assign Waiter'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _showWaiterAssignmentDialog(context, order),
        ),
      );
    }

    // Change Table (Admin, Owner only)
    if (canChangeDiningTable && order.orderType == OrderType.dining) {
      items.add(
        PopupMenuItem(
          value: 'table',
          child: const ListTile(
            leading: Icon(Icons.table_restaurant),
            title: Text('Change Table'),
            contentPadding: EdgeInsets.zero,
          ),

          onTap: () =>
              _showTableChangeDialog(context, order, order.diningTable!),
        ),
      );
    }

    // Edit Order (Admin, Owner only)
    if (canEditOrder) {
      items.add(
        PopupMenuItem(
          value: 'edit',
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit Order'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _showEditOrderDialog(context, order),
        ),
      );
    }

    // Delete Order (Admin, Owner only)
    if (canDeleteOrder) {
      items.add(
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete Order',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () {
            _showDeleteConfirmation(context, order);
          },
        ),
      );
    }

    return items;
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final amPm = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $amPm';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Future<void> _refreshOrders() async {
    ref.invalidate(
      todayOrdersStreamProvider((
        branchId: branchId,
        businessId: businessId,
        tableNotifier: tableNotifier,
      )),
    );
    ref.invalidate(
      allOrdersStreamProvider((
        branchId: branchId,
        businessId: businessId,
        tableNotifier: tableNotifier,
      )),
    );
  }

  void _toggleOrderScope() {
    setState(() {
      _showAllOrders = !_showAllOrders;

      if (_showAllOrders) {
        _selectedStatuses.clear();
        _selectedStatusFilter = null;
      } else {
        _selectedStatuses = {
          OrderStatus.pending,
          OrderStatus.inProgress,
          OrderStatus.ready,
        };
      }
    });
    _refreshOrders();
  }

  void _showOrderDetails(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => OrderDetailsDialog(
        order: order,
        canAssignWaiter: canAssignWaiter,
        canDeleteOrder: canDeleteOrder,
        canCreateOrder: canCreateOrder,
        canUpdateOrder: canEditOrder,
        canUpdateStatus: canUpdateStatus,
      ),
    );
  }

  void _showStatusUpdateDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => StatusUpdateDialog(
        order: order,
        onUpdate: (status) {
          _orderNotifier.updateOrderStatus(order, status, order.diningTable);
          _refreshOrders();
        },
      ),
    );
  }

  void _showWaiterAssignmentDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (context) => WaiterAssignmentDialog(
        order: order,
        onAssign: (waiterId, waiterName) {
          _orderNotifier.assignWaiter(order.orderId, waiterId, waiterName);
        },
      ),
    );
  }

  void _showTableChangeDialog(
    BuildContext context,
    OrderModel order,
    TableModel table,
  ) {
    showDialog(
      context: context,
      builder: (context) => TableSelectionDialog(
        businessId: businessId,
        branchId: branchId,
        currentTable: table, // Optional
        onTableSelected: (selectedTable) {
          // Handle table selection
          print('Selected: ${selectedTable.tableNumber}');
        },
      ),
    );
  }

  void _showEditOrderDialog(BuildContext context, OrderModel order) {
    // Implementation for edit order dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit Order functionality - To be implemented'),
      ),
    );
  }

  void _showCreateOrderDialog(BuildContext context) async {
    // Implementation for create order dialog
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateOrderScreen(branchId: branchId, businessId: businessId),
      ),
    );
    _refreshOrders();
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    OrderModel order,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Order'),
            content: Text(
              'Are you sure you want to delete order #${order.orderId.length > 8 ? order.orderId.substring(0, 8) : order.orderId}? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => {Navigator.of(context).pop(false)},
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  _orderNotifier.deleteOrder(order.orderId);
                  _refreshOrders();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }
}

class InfoRow {
  final String label;
  final String value;

  InfoRow({required this.label, required this.value});
}
// // Table Change Dialog (Commented out)
// class TableChangeDialog extends StatefulWidget {
// // ... (Omitted for brevity)
// }

// // Table Change Dialog
// class TableChangeDialog extends StatefulWidget {
//   final OrderModel order;
//   final Function(String tableNo, String? roomName) onUpdate;

//   const TableChangeDialog({
//     super.key,
//     required this.order,
//     required this.onUpdate,
//   });

//   @override
//   State<TableChangeDialog> createState() => _TableChangeDialogState();
// }

// class _TableChangeDialogState extends State<TableChangeDialog> {
//   final _formKey = GlobalKey<FormState>();
//   final _customTableController = TextEditingController();
//   final _customRoomController = TextEditingController();

//   String? _selectedTable;
//   String? _selectedRoom;
//   bool _showCustomTable = false;
//   bool _showCustomRoom = false;

//   // Mock data - replace with actual data from your service
//   final List<String> _availableTables = [
//     'T1',
//     'T2',
//     'T3',
//     'T4',
//     'T5',
//     'T6',
//     'T7',
//     'T8',
//     'T9',
//     'T10',
//     'VIP1',
//     'VIP2',
//     'VIP3',
//     'BAR1',
//     'BAR2',
//     'BAR3',
//   ];

//   final List<String> _availableRooms = [
//     'Main Hall',
//     'Private Room 1',
//     'Private Room 2',
//     'VIP Section',
//     'Garden Area',
//     'Terrace',
//     'Bar Area',
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _initializeValues();
//   }

//   void _initializeValues() {
//     // Check if current table is in available tables
//     if (widget.order.diningTable != null) {
//       if (_availableTables.contains(widget.order.diningTable!.tableNumber)) {
//         _selectedTable = widget.order.diningTable!.tableNumber;
//       } else {
//         _selectedTable = 'Other';
//         _showCustomTable = true;
//         _customTableController.text = widget.order.diningTable!.tableNumber;
//       }
//     }

//     // Check if current room is in available rooms
//     // if (widget.order.diningRoomNoOrName != null) {
//     //   if (_availableRooms.contains(widget.order.diningRoomNoOrName)) {
//     //     _selectedRoom = widget.order.diningRoomNoOrName;
//     //   } else {
//     //     _selectedRoom = 'Other';
//     //     _showCustomRoom = true;
//     //     _customRoomController.text = widget.order.diningRoomNoOrName!;
//     //   }
//     // }
//   }

//   @override
//   void dispose() {
//     _customTableController.dispose();
//     _customRoomController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: const Text('Change Table'),
//       content: SizedBox(
//         width: MediaQuery.of(context).size.width * 0.8,
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Table Selection
//               Text(
//                 'Table Number *',
//                 style: Theme.of(context).textTheme.labelLarge,
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<String>(
//                 value: _selectedTable,
//                 decoration: const InputDecoration(
//                   border: OutlineInputBorder(),
//                   hintText: 'Select a table',
//                 ),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Please select a table';
//                   }
//                   if (value == 'Other' &&
//                       _customTableController.text.trim().isEmpty) {
//                     return 'Please enter a custom table number';
//                   }
//                   return null;
//                 },
//                 items: [
//                   ..._availableTables.map(
//                     (table) => DropdownMenuItem<String>(
//                       value: table,
//                       child: Text(table),
//                     ),
//                   ),
//                   const DropdownMenuItem<String>(
//                     value: 'Other',
//                     child: Text('Other (Custom)'),
//                   ),
//                 ],
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedTable = value;
//                     _showCustomTable = value == 'Other';
//                     if (!_showCustomTable) {
//                       _customTableController.clear();
//                     }
//                   });
//                 },
//               ),

//               // Custom Table Input
//               if (_showCustomTable) ...[
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _customTableController,
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(),
//                     labelText: 'Enter table number',
//                     hintText: 'e.g., T11, Corner Table, etc.',
//                   ),
//                   validator: (value) {
//                     if (_selectedTable == 'Other' &&
//                         (value == null || value.trim().isEmpty)) {
//                       return 'Please enter a table number';
//                     }
//                     return null;
//                   },
//                 ),
//               ],

//               const SizedBox(height: 20),

//               // Room Selection
//               Text(
//                 'Room/Area (Optional)',
//                 style: Theme.of(context).textTheme.labelLarge,
//               ),
//               const SizedBox(height: 8),
//               DropdownButtonFormField<String?>(
//                 value: _selectedRoom,
//                 decoration: const InputDecoration(
//                   border: OutlineInputBorder(),
//                   hintText: 'Select a room/area',
//                 ),
//                 items: [
//                   const DropdownMenuItem<String?>(
//                     value: null,
//                     child: Text('No specific room'),
//                   ),
//                   ..._availableRooms.map(
//                     (room) => DropdownMenuItem<String>(
//                       value: room,
//                       child: Text(room),
//                     ),
//                   ),
//                   const DropdownMenuItem<String>(
//                     value: 'Other',
//                     child: Text('Other (Custom)'),
//                   ),
//                 ],
//                 onChanged: (value) {
//                   setState(() {
//                     _selectedRoom = value;
//                     _showCustomRoom = value == 'Other';
//                     if (!_showCustomRoom) {
//                       _customRoomController.clear();
//                     }
//                   });
//                 },
//               ),

//               // Custom Room Input
//               if (_showCustomRoom) ...[
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _customRoomController,
//                   decoration: const InputDecoration(
//                     border: OutlineInputBorder(),
//                     labelText: 'Enter room/area name',
//                     hintText: 'e.g., Balcony, Private Booth, etc.',
//                   ),
//                   validator: (value) {
//                     if (_selectedRoom == 'Other' &&
//                         (value == null || value.trim().isEmpty)) {
//                       return 'Please enter a room/area name';
//                     }
//                     return null;
//                   },
//                 ),
//               ],

//               const SizedBox(height: 16),

//               // Current Assignment Info
//               Container(
//                 padding: const EdgeInsets.all(12),
//                 decoration: BoxDecoration(
//                   color: Theme.of(context).colorScheme.surfaceVariant,
//                   borderRadius: BorderRadius.circular(8),
//                   border: Border.all(
//                     color: Theme.of(context).colorScheme.outline,
//                     width: 0.5,
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Current Assignment:',
//                       style: Theme.of(context).textTheme.labelMedium?.copyWith(
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Table: ${widget.order.diningTableNo ?? 'Not assigned'}',
//                       style: Theme.of(context).textTheme.bodySmall,
//                     ),
//                     Text(
//                       'Room: ${widget.order.diningRoomNoOrName ?? 'Not specified'}',
//                       style: Theme.of(context).textTheme.bodySmall,
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         FilledButton(
//           onPressed: () {
//             if (_formKey.currentState!.validate()) {
//               String finalTableNo;
//               String finalRoomName;

//               // Determine final table number
//               if (_selectedTable == 'Other') {
//                 finalTableNo = _customTableController.text.trim();
//               } else {
//                 finalTableNo = _selectedTable!;
//               }

//               // Determine final room name
//               if (_selectedRoom == null) {
//                 finalRoomName = "";
//               } else if (_selectedRoom == 'Other') {
//                 finalRoomName = _customRoomController.text.trim().isEmpty
//                     ? ""
//                     : _customRoomController.text.trim();
//               } else {
//                 finalRoomName = _selectedRoom!;
//               }

//               widget.onUpdate(finalTableNo, finalRoomName);
//               Navigator.of(context).pop();
//             }
//           },
//           child: const Text('Update'),
//         ),
//       ],
//     );
//   }
// }
