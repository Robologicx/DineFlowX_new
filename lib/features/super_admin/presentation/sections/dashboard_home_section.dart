import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/features/super_admin/application/super_admin_providers.dart';
import 'package:hotel_management_system/features/super_admin/presentation/widgets/kpi_card.dart';
import 'package:hotel_management_system/features/super_admin/presentation/widgets/simple_trend_chart.dart';

class DashboardHomeSection extends ConsumerWidget {
  const DashboardHomeSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kpiAsync = ref.watch(platformKpiProvider);
    final ordersTrendAsync = ref.watch(monthlyOrdersTrendProvider);
    final revenueTrendAsync = ref.watch(monthlyRevenueTrendProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Platform Command Center',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          'Real-time enterprise visibility across all tenants, subscriptions, and revenue streams.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        kpiAsync.when(
          data: (kpi) => LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 1400
                  ? 4
                  : constraints.maxWidth > 980
                  ? 3
                  : constraints.maxWidth > 680
                  ? 2
                  : 1;

              return GridView.count(
                crossAxisCount: columns,
                childAspectRatio: 2.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                children: [
                  KpiCard(
                    title: 'Total Businesses',
                    value: '${kpi.totalBusinesses}',
                    icon: Icons.apartment_rounded,
                  ),
                  KpiCard(
                    title: 'Active Businesses',
                    value: '${kpi.activeBusinesses}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  KpiCard(
                    title: 'Suspended Businesses',
                    value: '${kpi.suspendedBusinesses}',
                    icon: Icons.block_rounded,
                  ),
                  KpiCard(
                    title: 'Expired Subscriptions',
                    value: '${kpi.expiredSubscriptions}',
                    icon: Icons.warning_amber_rounded,
                  ),
                  KpiCard(
                    title: 'Total Branches',
                    value: '${kpi.totalBranches}',
                    icon: Icons.hub_rounded,
                  ),
                  KpiCard(
                    title: 'Total Staff Users',
                    value: '${kpi.totalStaffUsers}',
                    icon: Icons.groups_rounded,
                  ),
                  KpiCard(
                    title: 'Orders Today',
                    value: '${kpi.totalOrdersToday}',
                    icon: Icons.today_rounded,
                  ),
                  KpiCard(
                    title: 'Orders This Month',
                    value: '${kpi.totalOrdersThisMonth}',
                    icon: Icons.calendar_month_rounded,
                  ),
                  KpiCard(
                    title: 'Revenue This Month',
                    value:
                        'Rs. ${kpi.totalRevenueThisMonth.toStringAsFixed(2)}',
                    icon: Icons.currency_rupee_rounded,
                  ),
                  KpiCard(
                    title: 'Revenue This Year',
                    value: 'Rs. ${kpi.totalRevenueThisYear.toStringAsFixed(2)}',
                    icon: Icons.monetization_on_outlined,
                  ),
                  KpiCard(
                    title: 'Platform Growth %',
                    value: '${kpi.platformGrowthPercent.toStringAsFixed(1)}%',
                    icon: Icons.trending_up_rounded,
                  ),
                  KpiCard(
                    title: 'Avg Orders / Business',
                    value: kpi.averageOrdersPerBusiness.toStringAsFixed(1),
                    icon: Icons.analytics_outlined,
                  ),
                  KpiCard(
                    title: 'Avg Revenue / Business',
                    value:
                        'Rs. ${kpi.averageRevenuePerBusiness.toStringAsFixed(2)}',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                ],
              );
            },
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Failed to load KPIs: $e'),
            ),
          ),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stacked = constraints.maxWidth < 900;
            final ordersWidget = ordersTrendAsync.when(
              data: (points) => SimpleTrendChart(
                title: 'Monthly Orders Growth',
                points: points,
              ),
              loading: () => const Card(
                child: SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: SizedBox(
                  height: 220,
                  child: Center(child: Text('Error: $e')),
                ),
              ),
            );

            final revenueWidget = revenueTrendAsync.when(
              data: (points) => SimpleTrendChart(
                title: 'Monthly Revenue Growth',
                points: points,
                lineColor: Colors.teal,
              ),
              loading: () => const Card(
                child: SizedBox(
                  height: 220,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => Card(
                child: SizedBox(
                  height: 220,
                  child: Center(child: Text('Error: $e')),
                ),
              ),
            );

            if (stacked) {
              return Column(
                children: [
                  ordersWidget,
                  const SizedBox(height: 12),
                  revenueWidget,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: ordersWidget),
                const SizedBox(width: 12),
                Expanded(child: revenueWidget),
              ],
            );
          },
        ),
      ],
    );
  }
}
