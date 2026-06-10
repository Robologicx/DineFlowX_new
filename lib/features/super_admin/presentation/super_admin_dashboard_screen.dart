import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/features/super_admin/application/super_admin_providers.dart';
import 'package:hotel_management_system/features/super_admin/presentation/models/super_admin_nav_item.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/announcements_section.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/billing_section.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/businesses_section.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/create_business_wizard_dialog.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/dashboard_home_section.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/module_placeholder_section.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/orders_analytics_section.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/revenue_analytics_section.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/subscriptions_section.dart';
import 'package:hotel_management_system/features/super_admin/presentation/sections/users_section.dart';
import 'package:hotel_management_system/features/super_admin/presentation/widgets/saas_sidebar.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';
import 'package:hotel_management_system/state_management/theme_provider.dart';

class SuperAdminDashboardScreen extends ConsumerStatefulWidget {
  const SuperAdminDashboardScreen({super.key});

  @override
  ConsumerState<SuperAdminDashboardScreen> createState() =>
      _SuperAdminDashboardScreenState();
}

class _SuperAdminDashboardScreenState
    extends ConsumerState<SuperAdminDashboardScreen> {
  SuperAdminSection _current = SuperAdminSection.dashboard;
  final TextEditingController _globalSearchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _globalSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSuperAdminAsync = ref.watch(isRoboLogicxSuperAdminProvider);

    return isSuperAdminAsync.when(
      data: (isSuperAdmin) {
        if (!isSuperAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Access Restricted')),
            body: const Center(
              child: Text(
                'Only RoboLogicx super administrators can access this dashboard.',
              ),
            ),
          );
        }

        return _buildShell(context);
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) =>
          Scaffold(body: Center(child: Text('Authorization error: $e'))),
    );
  }

  Widget _buildShell(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 1200;
    final isLargeTablet = MediaQuery.of(context).size.width >= 860;
    final isCollapsed = MediaQuery.of(context).size.width < 1400;
    final themeState = ref.watch(themeProvider);

    final sidebar = SaasSidebar(
      currentSection: _current,
      onSelect: (section) {
        setState(() => _current = section);
        if (!isDesktop) {
          Navigator.pop(context);
        }
      },
      onLogout: () {
        Navigator.of(context).pushReplacementNamed(AdminAppRoutes.login);
      },
      collapsed: isCollapsed && isDesktop,
    );

    return Scaffold(
      key: _scaffoldKey,
      drawer: isDesktop ? null : Drawer(child: sidebar),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F8FC), Color(0xFFEFF5F9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Row(
          children: [
            if (isDesktop) sidebar,
            Expanded(
              child: Column(
                children: [
                  _topBar(
                    context,
                    isDesktop,
                    isLargeTablet,
                    themeState.themeMode == ThemeMode.dark,
                  ),
                  Expanded(child: _buildSection()),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _current == SuperAdminSection.businesses
          ? FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const CreateBusinessWizardDialog(),
                );
              },
              icon: const Icon(Icons.add_business_rounded),
              label: const Text('Create Business'),
            )
          : null,
    );
  }

  Widget _topBar(
    BuildContext context,
    bool isDesktop,
    bool isLargeTablet,
    bool isDark,
  ) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).scaffoldBackgroundColor.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
          ),
        ),
      ),
      child: Row(
        children: [
          if (!isDesktop)
            IconButton(
              icon: const Icon(Icons.menu_rounded),
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _globalSearchController,
              decoration: const InputDecoration(
                hintText: 'Global search: business, invoice, user, ticket...',
                prefixIcon: Icon(Icons.search_rounded),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            onPressed: () {
              ref
                  .read(themeProvider.notifier)
                  .updateMode(isDark ? ThemeMode.light : ThemeMode.dark);
            },
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
          if (isLargeTablet) ...[
            const SizedBox(width: 6),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Notifications'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSection() {
    switch (_current) {
      case SuperAdminSection.dashboard:
        return const DashboardHomeSection();
      case SuperAdminSection.businesses:
        return const BusinessesSection();
      case SuperAdminSection.subscriptions:
        return const SubscriptionsSection();
      case SuperAdminSection.billing:
        return const BillingSection();
      case SuperAdminSection.ordersAnalytics:
        return const OrdersAnalyticsSection();
      case SuperAdminSection.revenueAnalytics:
        return const RevenueAnalyticsSection();
      case SuperAdminSection.users:
        return const UsersSection();
      case SuperAdminSection.supportTickets:
        return const ModulePlaceholderSection(
          title: 'Support Center',
          description:
              'Track and resolve technical, billing, and subscription support requests.',
          items: [
            'Ticket Queues: Open, In Progress, Resolved, Closed',
            'SLA Escalation',
            'Assigned Agent Tracking',
          ],
        );
      case SuperAdminSection.announcements:
        return const AnnouncementsSection();
      case SuperAdminSection.platformSettings:
        return const ModulePlaceholderSection(
          title: 'Platform Settings',
          description:
              'Configure global platform identity, legal docs, tax, notifications, and billing defaults.',
          items: [
            'Branding & Contact Settings',
            'Currency & Tax Settings',
            'SMTP & Push Notification Settings',
            'Payment Gateway Settings',
            'Trial Period Settings',
          ],
        );
      case SuperAdminSection.auditLogs:
        return const ModulePlaceholderSection(
          title: 'Audit Logs',
          description:
              'Track every platform action and compliance-sensitive event.',
          items: [
            'Business Created / Deleted',
            'Plan Changed',
            'Subscription Renewed',
            'Invoice Generated',
            'Super Admin Login Activity',
          ],
        );
      case SuperAdminSection.systemHealth:
        return const ModulePlaceholderSection(
          title: 'System Health',
          description:
              'Observe core infrastructure and service consumption health.',
          items: [
            'Firestore Usage',
            'Cloud Functions Usage',
            'Storage Usage',
            'Database Reads / Writes',
            'Failed Requests & Active Sessions',
          ],
        );
      case SuperAdminSection.reports:
        return const ModulePlaceholderSection(
          title: 'Reports Center',
          description:
              'Generate and export strategic platform and tenant-level reports.',
          items: [
            'Business Report',
            'Subscription Report',
            'Revenue Report',
            'Orders Report',
            'Growth Report',
            'Export to PDF/Excel/CSV/Print',
          ],
        );
      case SuperAdminSection.backupExport:
        return const ModulePlaceholderSection(
          title: 'Backup & Export',
          description:
              'Run backups and export tenant/platform data for compliance and migration.',
          items: [
            'Scheduled Backup Policies',
            'On-demand Data Export',
            'Tenant-level Data Archival',
          ],
        );
      case SuperAdminSection.superAdmins:
        return const ModulePlaceholderSection(
          title: 'Super Admin Management',
          description:
              'Manage owner/support/billing/analytics/read-only admin roles and access logs.',
          items: [
            'Create/Edit Super Admin',
            'Role Permissions',
            '2FA & Session Controls',
            'Access and Login History',
          ],
        );
      case SuperAdminSection.profile:
        return const ModulePlaceholderSection(
          title: 'Profile',
          description:
              'Manage your super admin account profile and security settings.',
          items: ['Profile Details', 'Password / MFA', 'Session History'],
        );
    }
  }
}
