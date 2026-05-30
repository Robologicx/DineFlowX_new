import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/active_order_widget.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/orders_management_screen.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchId = BusinessRepository.temporaryBranchId;
    final businessId = BusinessRepository.temporaryBusinesshId;
    final userState = ref.watch(userProvider);

    // Step 1: handle loading & error states
    if (userState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userState.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Dashboard")),
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
      return const Scaffold(
        body: Center(child: Text('No user information found.')),
      );
    }

    // Step 2: fetch permission map from user object
    final Map<String, dynamic> permissions = user.extraPermissions.isNotEmpty
        ? user.extraPermissions as Map<String, dynamic>
        : {};

    // Helper to check permission
    bool hasPermission(String key) {
      return true; // For demo purposes, allow all
      // if (!permissions.containsKey(key)) return false;
      // final value = permissions[key];
      // return value == true ||
      //     value == 'true'; // covers both bool & string cases
    }

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeHeader(user, businessId, branchId),
            const SizedBox(height: 16),

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
            ),

            // ---- ADMIN / OWNER ----
            if (user.role.name.toLowerCase() == 'owner' ||
                user.role.name.toLowerCase().contains('admin')) ...[
              _sectionTitle('Business Overview'),
              if (hasPermission('view_business_stats')) _buildBusinessStats(),
              if (hasPermission('view_orders')) _buildActiveOrdersSummary(),
              if (hasPermission('view_revenue')) _buildRevenueChart(),
              if (hasPermission('manage_staff')) _buildStaffPerformance(),
              if (hasPermission('manage_inventory')) _buildInventoryAlerts(),
            ],

            // ---- WAITER ----
            if (user.role.name.toLowerCase().contains('admin')) ...[
              _sectionTitle('Waiter Tools'),
              if (hasPermission('view_assigned_orders'))
                _buildMyAssignedOrders(),
              if (hasPermission('create_order_quick')) _buildQuickOrderButton(),
              if (hasPermission('view_active_tables'))
                _buildActiveTablesWidget(),
            ],

            const SizedBox(height: 40),
            _sectionTitle('Quick Actions'),
            _buildQuickActionsRow(),
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
    String branchId,
  ) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.profileImageUrl != null
              ? NetworkImage(user.profileImageUrl!)
              : null,
        ),
        title: Text('Welcome, ${user.name}'),
        subtitle: Text(
          'Role: ${user.role.name}\nBusiness: $businessId | Branch: $branchId',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  // ---------- Placeholder Widgets (replace with actual UI) ----------

  Widget _buildBusinessStats() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Business Stats',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8),
            Text('Total sales: —'),
            Text('Orders today: —'),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveOrdersSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text('Active Orders'),
            SizedBox(height: 6),
            Text('— list / count —'),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    return Card(
      child: SizedBox(
        height: 160,
        child: Center(child: Text('Revenue Chart (placeholder)')),
      ),
    );
  }

  Widget _buildStaffPerformance() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text('Staff Performance'),
            SizedBox(height: 6),
            Text('— top performers —'),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryAlerts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text('Inventory Alerts'),
            SizedBox(height: 6),
            Text('— low stock —'),
          ],
        ),
      ),
    );
  }

  Widget _buildMyAssignedOrders() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text('My Assigned Orders'),
            SizedBox(height: 6),
            Text('— orders for this waiter —'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickOrderButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to quick order
        },
        icon: const Icon(Icons.add_shopping_cart),
        label: const Text('Create Quick Order'),
      ),
    );
  }

  Widget _buildActiveTablesWidget() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text('Active Tables'),
            SizedBox(height: 6),
            Text('— table statuses —'),
          ],
        ),
      ),
    );
  }

  Widget _buildMyOrders() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text('My Orders'),
            SizedBox(height: 6),
            Text('— past & current orders —'),
          ],
        ),
      ),
    );
  }

  Widget _buildFavorites() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text('Favorites'),
            SizedBox(height: 6),
            Text('— favorite products —'),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseMenu() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: const [
            Text('Browse Menu'),
            SizedBox(height: 6),
            Text('— menu browsing —'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsRow() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () {},
            child: const Text('New Order'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(onPressed: () {}, child: const Text('Reports')),
        ),
      ],
    );
  }
}
