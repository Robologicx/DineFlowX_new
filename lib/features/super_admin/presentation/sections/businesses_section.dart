import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/features/super_admin/application/super_admin_providers.dart';
import 'package:hotel_management_system/features/super_admin/domain/entities/super_admin_entities.dart';

enum OrdersTimePeriod { last7Days, last30Days, last90Days, thisMonth, thisYear }

class BusinessesSection extends ConsumerStatefulWidget {
  const BusinessesSection({super.key});

  @override
  ConsumerState<BusinessesSection> createState() => _BusinessesSectionState();
}

class _BusinessesSectionState extends ConsumerState<BusinessesSection> {
  String _search = '';
  OrdersTimePeriod _ordersTimePeriod = OrdersTimePeriod.last30Days;

  String _timePeriodLabel(OrdersTimePeriod period) {
    switch (period) {
      case OrdersTimePeriod.last7Days:
        return 'Last 7 Days';
      case OrdersTimePeriod.last30Days:
        return 'Last 30 Days';
      case OrdersTimePeriod.last90Days:
        return 'Last 90 Days';
      case OrdersTimePeriod.thisMonth:
        return 'This Month';
      case OrdersTimePeriod.thisYear:
        return 'This Year';
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessesAsync = ref.watch(businessesProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Business Management',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              SizedBox(
                width: 320,
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search by business, owner, email...',
                  ),
                  onChanged: (value) =>
                      setState(() => _search = value.trim().toLowerCase()),
                ),
              ),
              SizedBox(
                width: 220,
                child: DropdownButtonFormField<OrdersTimePeriod>(
                  initialValue: _ordersTimePeriod,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.calendar_month_outlined),
                    labelText: 'Orders Time Period',
                  ),
                  items: OrdersTimePeriod.values
                      .map(
                        (period) => DropdownMenuItem<OrdersTimePeriod>(
                          value: period,
                          child: Text(_timePeriodLabel(period)),
                        ),
                      )
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _ordersTimePeriod = value);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: businessesAsync.when(
              data: (items) {
                final filtered = items
                    .where((b) {
                      if (_search.isEmpty) return true;
                      return b.businessName.toLowerCase().contains(_search) ||
                          b.ownerName.toLowerCase().contains(_search) ||
                          b.email.toLowerCase().contains(_search) ||
                          b.businessId.toLowerCase().contains(_search);
                    })
                    .toList(growable: false);

                return _BusinessesDataTable(
                  items: filtered,
                  ordersTimePeriod: _ordersTimePeriod,
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Failed to load businesses: $e'),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilledButton.icon(
                          onPressed: () => ref.invalidate(businessesProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Refresh'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (Navigator.of(context).canPop()) {
                              Navigator.of(context).pop();
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded),
                          label: const Text('Back'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessesDataTable extends ConsumerWidget {
  const _BusinessesDataTable({
    required this.items,
    required this.ordersTimePeriod,
  });

  final List<BusinessTenantSummary> items;
  final OrdersTimePeriod ordersTimePeriod;

  String _timePeriodLabel(OrdersTimePeriod period) {
    switch (period) {
      case OrdersTimePeriod.last7Days:
        return 'Last 7 Days';
      case OrdersTimePeriod.last30Days:
        return 'Last 30 Days';
      case OrdersTimePeriod.last90Days:
        return 'Last 90 Days';
      case OrdersTimePeriod.thisMonth:
        return 'This Month';
      case OrdersTimePeriod.thisYear:
        return 'This Year';
    }
  }

  DateTime _periodStart(OrdersTimePeriod period) {
    final now = DateTime.now();
    switch (period) {
      case OrdersTimePeriod.last7Days:
        return now.subtract(const Duration(days: 7));
      case OrdersTimePeriod.last30Days:
        return now.subtract(const Duration(days: 30));
      case OrdersTimePeriod.last90Days:
        return now.subtract(const Duration(days: 90));
      case OrdersTimePeriod.thisMonth:
        return DateTime(now.year, now.month, 1);
      case OrdersTimePeriod.thisYear:
        return DateTime(now.year, 1, 1);
    }
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  Stream<({Map<String, int> periodCounts, Map<String, int> lifecycleCounts})>
  _ordersCountByBusinessStream() {
    final periodStart = _periodStart(ordersTimePeriod);
    final now = DateTime.now();
    final businessById = <String, BusinessTenantSummary>{
      for (final business in items) business.businessId: business,
    };

    final createdDates = items
        .map((e) => e.createdAt)
        .whereType<DateTime>()
        .toList(growable: false);

    var queryStart = periodStart;
    if (createdDates.isNotEmpty) {
      final earliestCreated = createdDates.reduce(
        (a, b) => a.isBefore(b) ? a : b,
      );
      if (earliestCreated.isBefore(queryStart)) {
        queryStart = earliestCreated;
      }
    }

    return FirebaseFirestore.instance
        .collectionGroup('orders')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(queryStart),
        )
        .snapshots()
        .map((snapshot) {
          final periodCounts = <String, int>{};
          final lifecycleCounts = <String, int>{};

          for (final doc in snapshot.docs) {
            final parts = doc.reference.path.split('/');
            if (parts.length < 2 || parts.first != 'businesses') continue;

            final businessId = parts[1];
            final business = businessById[businessId];
            if (business == null) continue;

            final createdAt = _asDateTime(doc.data()['createdAt']);
            if (createdAt == null) continue;

            if (!createdAt.isBefore(periodStart) && !createdAt.isAfter(now)) {
              periodCounts[businessId] = (periodCounts[businessId] ?? 0) + 1;
            }

            final lifecycleStart = business.createdAt ?? DateTime(2000, 1, 1);
            final lifecycleEnd =
                business.expiryDate != null &&
                    business.expiryDate!.isBefore(now)
                ? business.expiryDate!
                : now;

            if (!createdAt.isBefore(lifecycleStart) &&
                !createdAt.isAfter(lifecycleEnd)) {
              lifecycleCounts[businessId] =
                  (lifecycleCounts[businessId] ?? 0) + 1;
            }
          }

          return (periodCounts: periodCounts, lifecycleCounts: lifecycleCounts);
        });
  }

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final year = value.year.toString();
    return '$day/$month/$year';
  }

  ({String label, Color color, IconData icon}) _subscriptionIndicator(
    DateTime? expiry,
  ) {
    if (expiry == null) {
      return (
        label: 'No expiry set',
        color: Colors.blueGrey,
        icon: Icons.event_busy_outlined,
      );
    }

    final now = DateTime.now();
    final daysLeft = expiry.difference(now).inDays;
    if (daysLeft < 0) {
      return (label: 'Time Up', color: Colors.red, icon: Icons.warning_amber);
    }
    if (daysLeft <= 7) {
      return (
        label: 'Expires in $daysLeft day(s)',
        color: Colors.deepOrange,
        icon: Icons.timer_off_outlined,
      );
    }
    if (daysLeft <= 30) {
      return (
        label: '$daysLeft day(s) left',
        color: Colors.orange,
        icon: Icons.schedule,
      );
    }

    return (
      label: '$daysLeft day(s) left',
      color: Colors.green,
      icon: Icons.verified_outlined,
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'suspended':
      case 'disabled':
        return Colors.orange;
      case 'deleted':
        return Colors.red;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _showEditBusinessDialog(
    BuildContext context,
    WidgetRef ref,
    BusinessTenantSummary business,
  ) async {
    final nameController = TextEditingController(text: business.businessName);
    final ownerController = TextEditingController(text: business.ownerName);
    final emailController = TextEditingController(text: business.email);
    final phoneController = TextEditingController(text: business.phone);
    final cityController = TextEditingController(text: business.city);
    final countryController = TextEditingController(text: business.country);
    final industryController = TextEditingController(
      text: business.industryType,
    );

    var selectedPlan = business.subscriptionPlan;
    DateTime? selectedExpiry = business.expiryDate;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Business Details'),
              content: SizedBox(
                width: 540,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: ownerController,
                        decoration: const InputDecoration(
                          labelText: 'Owner Name',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Owner Email',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Owner Phone',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: industryController,
                        decoration: const InputDecoration(
                          labelText: 'Industry',
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: countryController,
                        decoration: const InputDecoration(labelText: 'Country'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: cityController,
                        decoration: const InputDecoration(labelText: 'City'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedPlan,
                        decoration: const InputDecoration(
                          labelText: 'Package Plan',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Trial',
                            child: Text('Trial'),
                          ),
                          DropdownMenuItem(
                            value: 'Basic',
                            child: Text('Basic'),
                          ),
                          DropdownMenuItem(
                            value: 'Premium',
                            child: Text('Premium'),
                          ),
                          DropdownMenuItem(
                            value: 'Enterprise',
                            child: Text('Enterprise'),
                          ),
                          DropdownMenuItem(
                            value: 'Custom',
                            child: Text('Custom'),
                          ),
                        ],
                        onChanged: (value) {
                          setDialogState(() {
                            selectedPlan = value ?? selectedPlan;
                          });
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Expiry Date: ${_formatDate(selectedExpiry)}',
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: selectedExpiry ?? now,
                                firstDate: DateTime(now.year - 2),
                                lastDate: DateTime(now.year + 10),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  selectedExpiry = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                    23,
                                    59,
                                    59,
                                  );
                                });
                              }
                            },
                            icon: const Icon(Icons.event_outlined),
                            label: const Text('Set Expiry'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final repo = ref.read(superAdminRepositoryProvider);
                    await repo.updateBusiness(
                      business.businessId,
                      businessName: nameController.text,
                      ownerName: ownerController.text,
                      ownerEmail: emailController.text,
                      ownerPhone: phoneController.text,
                      industryType: industryController.text,
                      country: countryController.text,
                      city: cityController.text,
                      subscriptionPlan: selectedPlan,
                      subscriptionExpiry: selectedExpiry,
                    );

                    if (context.mounted) {
                      Navigator.of(dialogContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Business details updated successfully.',
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (items.isEmpty) {
      return const Card(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('No businesses found.'),
          ),
        ),
      );
    }

    return StreamBuilder<
      ({Map<String, int> periodCounts, Map<String, int> lifecycleCounts})
    >(
      stream: _ordersCountByBusinessStream(),
      builder: (context, snapshot) {
        final periodCounts =
            snapshot.data?.periodCounts ?? const <String, int>{};
        final lifecycleCounts =
            snapshot.data?.lifecycleCounts ?? const <String, int>{};

        return Card(
          clipBehavior: Clip.antiAlias,
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final b = items[index];
              final isActive = b.status.toLowerCase() == 'active';
              final subscription = _subscriptionIndicator(b.expiryDate);
              final statusColor = _statusColor(b.status);
              final ordersInPeriod = periodCounts[b.businessId] ?? 0;
              final lifecycleOrders = lifecycleCounts[b.businessId] ?? 0;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.storefront_outlined),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            b.businessName.isNotEmpty
                                ? b.businessName
                                : b.businessId,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Text(
                            'Orders (${_timePeriodLabel(ordersTimePeriod)}): $ordersInPeriod',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            await _showEditBusinessDialog(context, ref, b);
                          },
                          icon: const Icon(Icons.edit_outlined),
                          label: const Text('Edit'),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: () async {
                            final repo = ref.read(superAdminRepositoryProvider);
                            if (isActive) {
                              await repo.suspendBusiness(b.businessId);
                            } else {
                              await repo.activateBusiness(b.businessId);
                            }

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isActive
                                        ? 'Business disabled successfully.'
                                        : 'Business enabled successfully.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: Icon(
                            isActive
                                ? Icons.pause_circle_outline
                                : Icons.play_arrow,
                          ),
                          label: Text(isActive ? 'Disable' : 'Enable'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          avatar: const Icon(
                            Icons.workspace_premium_outlined,
                            size: 16,
                            color: Colors.indigo,
                          ),
                          label: Text('Package: ${b.subscriptionPlan}'),
                        ),
                        Chip(
                          avatar: Icon(
                            Icons.flag_circle_outlined,
                            size: 16,
                            color: statusColor,
                          ),
                          label: Text('Status: ${b.status}'),
                        ),
                        Chip(
                          avatar: Icon(
                            subscription.icon,
                            size: 16,
                            color: subscription.color,
                          ),
                          label: Text(subscription.label),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.receipt_long_outlined,
                            size: 16,
                            color: Colors.blue,
                          ),
                          label: Text(
                            'Orders (${_timePeriodLabel(ordersTimePeriod)}): $ordersInPeriod',
                          ),
                        ),
                        Chip(
                          avatar: const Icon(
                            Icons.summarize_outlined,
                            size: 16,
                            color: Colors.teal,
                          ),
                          label: Text(
                            'Total Orders (Start -> Current/Expiry): $lifecycleOrders',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID: ${b.businessId}  |  Owner: ${b.ownerName}  |  Email: ${b.email}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Created: ${_formatDate(b.createdAt)}  |  Expiry: ${_formatDate(b.expiryDate)}  |  Branches: ${b.branches}  |  Users: ${b.users}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
