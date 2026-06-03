import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class RevenueAnalyticsSection extends StatelessWidget {
  const RevenueAnalyticsSection({super.key});

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final businessesStream = FirebaseFirestore.instance
        .collection('businesses')
        .snapshots();
    final ordersStream = FirebaseFirestore.instance
        .collectionGroup('orders')
        .snapshots();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: businessesStream,
        builder: (context, businessesSnap) {
          if (businessesSnap.hasError) {
            return Center(
              child: Text(
                'Failed to load businesses metadata: ${businessesSnap.error}',
              ),
            );
          }
          if (!businessesSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final businessMeta = <String, Map<String, dynamic>>{};
          for (final doc in businessesSnap.data!.docs) {
            businessMeta[doc.id] = doc.data();
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: ordersStream,
            builder: (context, ordersSnap) {
              if (ordersSnap.hasError) {
                return Center(
                  child: Text('Failed to load orders: ${ordersSnap.error}'),
                );
              }
              if (!ordersSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final now = DateTime.now();
              final todayStart = DateTime(now.year, now.month, now.day);
              final monthStart = DateTime(now.year, now.month, 1);
              final yearStart = DateTime(now.year, 1, 1);
              final prevMonthStart = DateTime(now.year, now.month - 1, 1);
              final prevMonthEnd = DateTime(
                now.year,
                now.month,
                1,
              ).subtract(const Duration(milliseconds: 1));

              double todayRevenue = 0;
              double monthRevenue = 0;
              double yearRevenue = 0;
              double prevMonthRevenue = 0;

              final revenueByPlan = <String, double>{};
              final revenueByCountry = <String, double>{};
              final revenueByBusiness = <String, double>{};
              final ordersByBusiness = <String, int>{};

              for (final orderDoc in ordersSnap.data!.docs) {
                final orderData = orderDoc.data();
                final createdAt = _asDateTime(orderData['createdAt']);
                if (createdAt == null) continue;

                final amount = _asDouble(orderData['totalAmount']);
                if (amount <= 0) continue;

                final pathParts = orderDoc.reference.path.split('/');
                if (pathParts.length < 2 || pathParts.first != 'businesses') {
                  continue;
                }

                final businessId = pathParts[1];
                final meta =
                    businessMeta[businessId] ?? const <String, dynamic>{};
                final plan = (meta['subscriptionPlan'] ?? 'Unknown').toString();
                final country = (meta['country'] ?? 'Unknown').toString();
                final businessName =
                    (meta['title'] ?? businessId).toString().trim().isEmpty
                    ? businessId
                    : (meta['title'] ?? businessId).toString();

                if (!createdAt.isBefore(todayStart)) {
                  todayRevenue += amount;
                }
                if (!createdAt.isBefore(monthStart)) {
                  monthRevenue += amount;
                }
                if (!createdAt.isBefore(yearStart)) {
                  yearRevenue += amount;
                }
                if (!createdAt.isBefore(prevMonthStart) &&
                    !createdAt.isAfter(prevMonthEnd)) {
                  prevMonthRevenue += amount;
                }

                revenueByPlan[plan] = (revenueByPlan[plan] ?? 0) + amount;
                revenueByCountry[country] =
                    (revenueByCountry[country] ?? 0) + amount;
                revenueByBusiness[businessName] =
                    (revenueByBusiness[businessName] ?? 0) + amount;
                ordersByBusiness[businessName] =
                    (ordersByBusiness[businessName] ?? 0) + 1;
              }

              final growthRate = prevMonthRevenue > 0
                  ? ((monthRevenue - prevMonthRevenue) / prevMonthRevenue) * 100
                  : (monthRevenue > 0 ? 100 : 0);

              List<MapEntry<String, double>> sortDesc(Map<String, double> map) {
                final list = map.entries.toList(growable: false)
                  ..sort((a, b) => b.value.compareTo(a.value));
                return list;
              }

              final byPlan = sortDesc(revenueByPlan);
              final byCountry = sortDesc(revenueByCountry);
              final byBusiness = sortDesc(revenueByBusiness);

              Widget metricTile(
                String title,
                String value,
                IconData icon,
                Color color,
              ) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(icon, color: color),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              value,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }

              Widget rankedCard(
                String title,
                List<MapEntry<String, double>> rows,
              ) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (rows.isEmpty)
                          const Text('No data yet.')
                        else
                          ...rows
                              .take(10)
                              .map(
                                (entry) => Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(entry.key)),
                                      Text(
                                        _money(entry.value),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                );
              }

              final growthLabel = '${growthRate.toStringAsFixed(1)}%';
              final growthColor = growthRate >= 0 ? Colors.green : Colors.red;

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Revenue Analytics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live revenue metrics from real order data across all businesses.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 980;
                        final children = [
                          metricTile(
                            'Today Revenue',
                            _money(todayRevenue),
                            Icons.today_rounded,
                            Colors.blue,
                          ),
                          metricTile(
                            'Monthly Revenue',
                            _money(monthRevenue),
                            Icons.calendar_month,
                            Colors.deepPurple,
                          ),
                          metricTile(
                            'Yearly Revenue',
                            _money(yearRevenue),
                            Icons.insights_outlined,
                            Colors.teal,
                          ),
                          metricTile(
                            'Revenue Growth Rate',
                            growthLabel,
                            growthRate >= 0
                                ? Icons.trending_up_rounded
                                : Icons.trending_down_rounded,
                            growthColor,
                          ),
                        ];

                        if (isWide) {
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 3.4,
                            children: children,
                          );
                        }

                        return Column(
                          children: children
                              .map(
                                (child) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: child,
                                ),
                              )
                              .toList(growable: false),
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                    rankedCard('Revenue By Plan', byPlan),
                    rankedCard('Revenue By Country', byCountry),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Revenue By Business',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 8),
                            if (byBusiness.isEmpty)
                              const Text('No data yet.')
                            else
                              ...byBusiness
                                  .take(10)
                                  .map(
                                    (entry) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${entry.key} (Orders: ${ordersByBusiness[entry.key] ?? 0})',
                                            ),
                                          ),
                                          Text(
                                            _money(entry.value),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
