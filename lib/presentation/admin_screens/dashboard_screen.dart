import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:hotel_management_system/core/utils/offline_media_upload_queue_service.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/data/models/sales_model_and_management.dart'
    show ReportPeriod;
import 'package:hotel_management_system/presentation/admin_screens/expense_management_screen/expense_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/create_order_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/active_order_widget.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/orders_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/sales_dashboard/sales_dashboard_screen.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/current_tenant_business_provider.dart';
import 'package:hotel_management_system/state_management/tenant_context_provider.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key, this.showNavigationBar = true});

  final bool showNavigationBar;

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _reportRequested = false;

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    if (!widget.showNavigationBar) {
      return null;
    }

    return AppBar(
      title: const Text('Dashboard'),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final drawer = ZoomDrawer.of(context);
          if (drawer != null) {
            drawer.toggle();
            return;
          }

          if (Navigator.of(context).canPop()) {
            Navigator.of(context).maybePop();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenantContext = ref.watch(tenantContextProvider);
    final branchId = tenantContext.branchId;
    final businessId = tenantContext.businessId;
    final userState = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);
    final businessAsync = ref.watch(currentTenantBusinessProvider);
    final businessName = businessAsync.maybeWhen(
      data: (business) => business?.title,
      orElse: () => null,
    );
    final businessLogoUrl = businessAsync.maybeWhen(
      data: (business) => business?.logoUrl,
      orElse: () => null,
    );

    // Step 1: handle loading & error states
    if (userState.isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (userState.error != null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Center(
          child: Text(
            'Failed to load user: ${userState.error}',
            style: const TextStyle(color: Colors.red),
          ),
        ),
      );
    }

    final user = userState.selectedUser;

    // If no user found
    if (user == null) {
      return Scaffold(
        appBar: _buildAppBar(context),
        body: Center(child: Text('No user information found.')),
      );
    }

    if (!_reportRequested) {
      _reportRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(
              salesProvider((
                businessId: businessId,
                branchId: branchId,
              )).notifier,
            )
            .generateReport(ReportPeriod.today);
      });
    }

    return Scaffold(
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeHeader(
              user,
              businessId,
              branchId,
              businessName: businessName,
              businessLogoUrl: businessLogoUrl,
            ),
            const SizedBox(height: 8),
            _buildSyncStatusCompact(),
            const SizedBox(height: 16),

            if (userNotifier.hasPermissionOfCurrentUser(
                  Permissions.viewActiveOrders,
                ) ||
                userNotifier.hasPermissionOfCurrentUser(
                  Permissions.viewOrderHistory,
                ))
              ActiveOrdersWidget(
                businessId: businessId,
                branchId: branchId,
                maxOrders: 5,
                onViewAll: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const OrderManagementScreen(),
                    ),
                  );
                },
              )
            else
              const Card(
                child: ListTile(
                  leading: Icon(Icons.lock_outline),
                  title: Text('No permission to view order data'),
                ),
              ),

            // ---- ADMIN / OWNER ----
            if (user.role.name.toLowerCase() == 'owner' ||
                user.role.name.toLowerCase().contains('admin')) ...[
              _sectionTitle('Business Overview'),
              _buildRevenueChart(businessId, branchId),
              const SizedBox(height: 16),
              _sectionTitle('Quick Actions'),
              _buildQuickActionsButtons(context, businessId, branchId),
            ],
            const SizedBox(height: 32),
            const Center(
              child: Column(
                children: [
                  Text(
                    'Powered by RoboLogicX',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'www.robologicx.org',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ---------- Helper UI builders ----------

  Widget _sectionTitle(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    ),
  );

  Widget _buildWelcomeHeader(
    UserModel user,
    String businessId,
    String branchId, {
    String? businessName,
    String? businessLogoUrl,
  }) {
    final normalizedLogoUrl = businessLogoUrl?.trim();
    final fallbackInitial = (businessName ?? user.name).trim().isNotEmpty
        ? (businessName ?? user.name).trim()[0].toUpperCase()
        : 'B';

    final resolvedBusinessName = (businessName ?? '').trim().isNotEmpty
        ? businessName!.trim()
        : businessId;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          foregroundImage:
              (normalizedLogoUrl != null && normalizedLogoUrl.isNotEmpty)
              ? NetworkImage(normalizedLogoUrl)
              : null,
          onForegroundImageError:
              (normalizedLogoUrl != null && normalizedLogoUrl.isNotEmpty)
              ? (_, __) {}
              : null,
          child: Text(fallbackInitial),
        ),
        title: Text('Welcome, ${user.name}'),
        subtitle: Text(
          'Role: ${user.role.name}\nBusiness: $resolvedBusinessName | Branch: $branchId',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildSyncStatusCompact() {
    return Align(
      alignment: Alignment.centerRight,
      child: ValueListenableBuilder<OfflineMediaSyncStatus>(
        valueListenable: OfflineMediaUploadQueueService.statusNotifier,
        builder: (context, status, _) {
          final hasPending = status.pendingUploads > 0;
          final isSyncing = status.isSyncing;

          final Color color = isSyncing
              ? Colors.blue
              : hasPending
              ? Colors.orange
              : Colors.green;

          final String summary = isSyncing
              ? 'Syncing ${status.pendingUploads} pending'
              : hasPending
              ? '${status.pendingUploads} pending uploads'
              : 'All media synced';

          final String lastSyncText = status.lastSyncAt == null
              ? 'Last sync: --'
              : 'Last sync: ${_formatSyncTime(status.lastSyncAt!)}';

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withAlpha(24),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync, size: 14, color: color),
                const SizedBox(width: 6),
                Text(
                  '$summary • $lastSyncText',
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatSyncTime(DateTime value) {
    final now = DateTime.now();
    final sameDay =
        now.year == value.year &&
        now.month == value.month &&
        now.day == value.day;

    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final amPm = value.hour >= 12 ? 'PM' : 'AM';

    if (sameDay) {
      return '$hour:$minute $amPm';
    }

    return '${value.day}/${value.month} $hour:$minute $amPm';
  }

  // ---------- Placeholder Widgets (replace with actual UI) ----------

  Widget _buildRevenueChart(String businessId, String branchId) {
    final salesState = ref.watch(
      salesProvider((businessId: businessId, branchId: branchId)),
    );
    final report = salesState.currentReport;

    if (salesState.isLoading && report == null) {
      return const Card(
        child: SizedBox(
          height: 160,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (salesState.error != null && report == null) {
      return Card(
        child: SizedBox(
          height: 160,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                'Failed to load report values',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
        ),
      );
    }

    final totalRevenue = report?.totalRevenue ?? 0.0;
    final totalExpenses = report?.totalExpenses ?? 0.0;
    final totalOrders = report?.totalOrders ?? 0;
    final profitOrLoss = report?.profitOrLoss ?? (totalRevenue - totalExpenses);
    final isProfit = profitOrLoss >= 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: _metricTile(
                title: 'Total Revenue',
                value: _formatMoney(totalRevenue),
                color: Colors.green,
                icon: Icons.trending_up,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile(
                title: 'Total Expense',
                value: _formatMoney(totalExpenses),
                color: Colors.orange,
                icon: Icons.receipt_long,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile(
                title: 'Total Orders',
                value: totalOrders.toString(),
                color: Colors.blue,
                icon: Icons.shopping_bag,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _metricTile(
                title: isProfit ? 'Profit' : 'Loss',
                value: _formatMoney(profitOrLoss.abs()),
                color: isProfit ? Colors.teal : Colors.red,
                icon: isProfit ? Icons.savings : Icons.trending_down,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricTile({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatMoney(double amount) {
    return 'Rs ${amount.toStringAsFixed(2)}';
  }

  Widget _buildQuickActionsButtons(
    BuildContext context,
    String businessId,
    String branchId,
  ) {
    return Wrap(
      alignment: WrapAlignment.center,
      runAlignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CreateOrderScreen(
                  branchId: branchId,
                  businessId: businessId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.add_shopping_cart),
          label: const Text('New Order'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const SalesDashboardScreen(),
              ),
            );
          },
          icon: const Icon(Icons.bar_chart),
          label: const Text('Report'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ExpenseManagementScreen(),
              ),
            );
          },
          icon: const Icon(Icons.receipt_long),
          label: const Text('Expense'),
        ),
      ],
    );
  }
}
