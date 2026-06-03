import 'package:flutter/material.dart';

class SubscriptionsSection extends StatelessWidget {
  const SubscriptionsSection({super.key});

  @override
  Widget build(BuildContext context) {
    const plans = [
      ['Trial', '0', '0', '0', '5', '1', '500', '1024 MB', 'Limited', 'Active'],
      [
        'Basic',
        '2999',
        '29999',
        '0',
        '20',
        '3',
        '5000',
        '5120 MB',
        'Standard',
        'Active',
      ],
      [
        'Premium',
        '6999',
        '69999',
        '0',
        '80',
        '10',
        '50000',
        '20480 MB',
        'Advanced',
        'Active',
      ],
      [
        'Enterprise',
        'Custom',
        'Custom',
        '0',
        'Unlimited',
        'Unlimited',
        'Unlimited',
        'Unlimited',
        'All',
        'Active',
      ],
      [
        'Custom',
        'Custom',
        'Custom',
        '2',
        'Custom',
        'Custom',
        'Custom',
        'Custom',
        'Custom',
        'Active',
      ],
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Subscription Management',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Configure plans, feature limits, and billing behavior for Trial, Basic, Premium, Enterprise, and Custom businesses.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Plan Name')),
              DataColumn(label: Text('Monthly Price')),
              DataColumn(label: Text('Yearly Price')),
              DataColumn(label: Text('Per Order Price')),
              DataColumn(label: Text('Max Users')),
              DataColumn(label: Text('Max Branches')),
              DataColumn(label: Text('Max Orders')),
              DataColumn(label: Text('Storage Limit')),
              DataColumn(label: Text('Features')),
              DataColumn(label: Text('Status')),
            ],
            rows: plans
                .map(
                  (p) => DataRow(
                    cells: p
                        .map((v) => DataCell(Text(v)))
                        .toList(growable: false),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}
