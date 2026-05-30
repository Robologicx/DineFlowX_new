// widgets/sales_stats_cards.dart
import 'package:flutter/material.dart';

class SalesStatsCards extends StatelessWidget {
  final double totalRevenue;
  final double totalExpenses;
  final double profitOrLoss;
  final int totalOrders;
  final double averageOrderValue;
  final int activeOrders;

  const SalesStatsCards({
    super.key,
    required this.totalRevenue,
    required this.totalExpenses,
    required this.profitOrLoss,
    required this.totalOrders,
    required this.averageOrderValue,
    required this.activeOrders,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive layout
        final crossAxisCount = constraints.maxWidth > 1400
            ? 6
            : constraints.maxWidth > 1000
            ? 3
            : constraints.maxWidth > 800
            ? 2
            : 1;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.8,
          children: [
            _buildStatCard(
              context,
              icon: Icons.payments,
              title: 'Total Revenue',
              value: 'Rs ${totalRevenue.toStringAsFixed(2)}',
              color: Colors.green,
            ),
            _buildStatCard(
              context,
              icon: Icons.money_off,
              title: 'Total Expenses',
              value: 'Rs ${totalExpenses.toStringAsFixed(2)}',
              color: Colors.red,
            ),
            _buildStatCard(
              context,
              icon: profitOrLoss >= 0 ? Icons.trending_up : Icons.trending_down,
              title: 'Profit / Loss',
              value: 'Rs ${profitOrLoss.toStringAsFixed(2)}',
              color: profitOrLoss >= 0 ? Colors.teal : Colors.deepOrange,
            ),
            _buildStatCard(
              context,
              icon: Icons.receipt_long,
              title: 'Total Orders',
              value: totalOrders.toString(),
              color: Colors.blue,
            ),
            _buildStatCard(
              context,
              icon: Icons.trending_up,
              title: 'Avg Order Value',
              value: 'Rs ${averageOrderValue.toStringAsFixed(2)}',
              color: Colors.orange,
            ),
            _buildStatCard(
              context,
              icon: Icons.access_time,
              title: 'Active Orders',
              value: activeOrders.toString(),
              color: Colors.purple,
              subtitle: 'In progress',
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    String? trend,
    bool? trendUp,
    String? subtitle,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                if (trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: (trendUp ?? true)
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          (trendUp ?? true)
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          size: 12,
                          color: (trendUp ?? true) ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: (trendUp ?? true)
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
