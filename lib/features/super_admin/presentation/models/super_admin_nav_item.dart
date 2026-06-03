import 'package:flutter/material.dart';

enum SuperAdminSection {
  dashboard,
  businesses,
  subscriptions,
  billing,
  ordersAnalytics,
  revenueAnalytics,
  users,
  supportTickets,
  announcements,
  platformSettings,
  auditLogs,
  systemHealth,
  reports,
  backupExport,
  superAdmins,
  profile,
}

class SuperAdminNavItem {
  final SuperAdminSection section;
  final String label;
  final IconData icon;

  const SuperAdminNavItem({
    required this.section,
    required this.label,
    required this.icon,
  });
}

const superAdminNavItems = <SuperAdminNavItem>[
  SuperAdminNavItem(
    section: SuperAdminSection.dashboard,
    label: 'Dashboard',
    icon: Icons.dashboard_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.businesses,
    label: 'Businesses',
    icon: Icons.store_mall_directory_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.subscriptions,
    label: 'Subscriptions',
    icon: Icons.workspace_premium_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.billing,
    label: 'Billing',
    icon: Icons.receipt_long_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.ordersAnalytics,
    label: 'Orders Analytics',
    icon: Icons.shopping_bag_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.revenueAnalytics,
    label: 'Revenue Analytics',
    icon: Icons.stacked_line_chart_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.users,
    label: 'Users',
    icon: Icons.groups_2_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.supportTickets,
    label: 'Support Tickets',
    icon: Icons.support_agent_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.announcements,
    label: 'Announcements',
    icon: Icons.campaign_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.platformSettings,
    label: 'Platform Settings',
    icon: Icons.settings_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.auditLogs,
    label: 'Audit Logs',
    icon: Icons.history_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.systemHealth,
    label: 'System Health',
    icon: Icons.monitor_heart_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.reports,
    label: 'Reports',
    icon: Icons.summarize_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.backupExport,
    label: 'Backup & Export',
    icon: Icons.backup_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.superAdmins,
    label: 'Super Admins',
    icon: Icons.admin_panel_settings_rounded,
  ),
  SuperAdminNavItem(
    section: SuperAdminSection.profile,
    label: 'Profile',
    icon: Icons.account_circle_rounded,
  ),
];
