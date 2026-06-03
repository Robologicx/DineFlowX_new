import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrdersAnalyticsSection extends StatelessWidget {
  const OrdersAnalyticsSection({super.key});

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

          final businesses = businessesSnap.data!.docs;
          final businessNamesById = <String, String>{};
          for (final b in businesses) {
            final title = (b.data()['title'] ?? b.id).toString();
            businessNamesById[b.id] = title.trim().isEmpty ? b.id : title;
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
              final weekStart = todayStart.subtract(
                Duration(days: now.weekday - 1),
              );
              final monthStart = DateTime(now.year, now.month, 1);
              final yearStart = DateTime(now.year, 1, 1);

              var totalToday = 0;
              var totalWeek = 0;
              var totalMonth = 0;
              var totalYear = 0;
              var totalOrdersAll = 0;
              var totalRevenueAll = 0.0;

              final byBusinessCount = <String, int>{};
              final byHour = List<int>.filled(24, 0);
              final byWeekday = List<int>.filled(7, 0); // Mon..Sun

              for (final doc in ordersSnap.data!.docs) {
                final data = doc.data();
                final createdAt = _asDateTime(data['createdAt']);
                if (createdAt == null) continue;

                final parts = doc.reference.path.split('/');
                if (parts.length < 2 || parts.first != 'businesses') {
                  continue;
                }

                final businessId = parts[1];
                final businessName =
                    businessNamesById[businessId] ?? businessId;

                totalOrdersAll += 1;
                totalRevenueAll += _asDouble(data['totalAmount']);

                if (!createdAt.isBefore(todayStart)) {
                  totalToday += 1;
                }
                if (!createdAt.isBefore(weekStart)) {
                  totalWeek += 1;
                }
                if (!createdAt.isBefore(monthStart)) {
                  totalMonth += 1;
                }
                if (!createdAt.isBefore(yearStart)) {
                  totalYear += 1;
                }

                byBusinessCount[businessName] =
                    (byBusinessCount[businessName] ?? 0) + 1;
                byHour[createdAt.hour] = byHour[createdAt.hour] + 1;
                byWeekday[createdAt.weekday - 1] =
                    byWeekday[createdAt.weekday - 1] + 1;
              }

              final businessCount = businesses.length;
              final avgOrdersPerBusiness = businessCount == 0
                  ? 0.0
                  : totalOrdersAll / businessCount;
              final avgOrderValue = totalOrdersAll == 0
                  ? 0.0
                  : totalRevenueAll / totalOrdersAll;

              final topBusinesses = byBusinessCount.entries.toList(
                growable: false,
              )..sort((a, b) => b.value.compareTo(a.value));

              final weekdayLabels = const [
                'Mon',
                'Tue',
                'Wed',
                'Thu',
                'Fri',
                'Sat',
                'Sun',
              ];
              var peakDayLabel = '-';
              var peakDayCount = 0;
              for (var i = 0; i < byWeekday.length; i++) {
                if (byWeekday[i] > peakDayCount) {
                  peakDayCount = byWeekday[i];
                  peakDayLabel = weekdayLabels[i];
                }
              }

              var peakHour = 0;
              var peakHourCount = 0;
              for (var h = 0; h < byHour.length; h++) {
                if (byHour[h] > peakHourCount) {
                  peakHourCount = byHour[h];
                  peakHour = h;
                }
              }
              final peakHourLabel =
                  '${peakHour.toString().padLeft(2, '0')}:00 - ${(peakHour + 1).toString().padLeft(2, '0')}:00';

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

              Widget topBusinessesCard() {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Top Ordering Businesses',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 8),
                        if (topBusinesses.isEmpty)
                          const Text('No orders yet.')
                        else
                          ...topBusinesses
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
                                        '${entry.value} orders',
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

              Widget peaksCard() {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Peak Order Hours & Days',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 10),
                        Text('Peak Day: $peakDayLabel ($peakDayCount orders)'),
                        const SizedBox(height: 6),
                        Text(
                          'Peak Hour: $peakHourLabel ($peakHourCount orders)',
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Orders Analytics',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Live platform-wide orders intelligence and top ordering businesses.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth > 980;
                        final children = [
                          metricTile(
                            'Total Orders Today',
                            '$totalToday',
                            Icons.today_rounded,
                            Colors.blue,
                          ),
                          metricTile(
                            'Total Orders This Week',
                            '$totalWeek',
                            Icons.view_week_rounded,
                            Colors.indigo,
                          ),
                          metricTile(
                            'Total Orders This Month',
                            '$totalMonth',
                            Icons.calendar_month,
                            Colors.deepPurple,
                          ),
                          metricTile(
                            'Total Orders This Year',
                            '$totalYear',
                            Icons.insights_outlined,
                            Colors.teal,
                          ),
                          metricTile(
                            'Average Orders Per Business',
                            avgOrdersPerBusiness.toStringAsFixed(2),
                            Icons.store_mall_directory_rounded,
                            Colors.green,
                          ),
                          metricTile(
                            'Average Order Value',
                            'Rs ${avgOrderValue.toStringAsFixed(2)}',
                            Icons.payments_outlined,
                            Colors.orange,
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
                    topBusinessesCard(),
                    peaksCard(),
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
