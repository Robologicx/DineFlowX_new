import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BillingSection extends StatefulWidget {
  const BillingSection({super.key});

  @override
  State<BillingSection> createState() => _BillingSectionState();
}

class _BillingSectionState extends State<BillingSection> {
  CollectionReference<Map<String, dynamic>> get _businessesRef =>
      FirebaseFirestore.instance.collection('businesses');

  CollectionReference<Map<String, dynamic>> get _paymentsRef =>
      FirebaseFirestore.instance
          .collection('platform')
          .doc('billing_payments')
          .collection('records');

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  DateTime? _asDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _money(double value) => 'Rs ${value.toStringAsFixed(2)}';

  String _formatDate(DateTime? value) {
    if (value == null) return '-';
    final d = value.day.toString().padLeft(2, '0');
    final m = value.month.toString().padLeft(2, '0');
    final y = value.year.toString();
    return '$d/$m/$y';
  }

  double _planFee(String plan) {
    switch (plan.toLowerCase()) {
      case 'trial':
        return 0;
      case 'basic':
        return 5000;
      case 'premium':
        return 12000;
      case 'enterprise':
        return 25000;
      default:
        return 0;
    }
  }

  Future<void> _openRecordPaymentDialog(
    BuildContext context,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> businesses,
  ) async {
    if (businesses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No businesses available.')),
      );
      return;
    }

    var selectedBusinessId = businesses.first.id;
    var selectedStatus = 'Paid';
    var selectedMethod = 'Bank Transfer';
    DateTime paidAt = DateTime.now();

    final amountController = TextEditingController();
    final noteController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text('Record Payment'),
              content: SizedBox(
                width: 520,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: selectedBusinessId,
                        decoration: const InputDecoration(labelText: 'Business'),
                        items: businesses
                            .map(
                              (b) => DropdownMenuItem<String>(
                                value: b.id,
                                child: Text(
                                  (b.data()['title'] ?? b.id).toString(),
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedBusinessId = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(labelText: 'Amount'),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: 'Payment Status',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Paid', child: Text('Paid')),
                          DropdownMenuItem(
                            value: 'Pending',
                            child: Text('Pending'),
                          ),
                          DropdownMenuItem(
                            value: 'Partial',
                            child: Text('Partial'),
                          ),
                          DropdownMenuItem(
                            value: 'Failed',
                            child: Text('Failed'),
                          ),
                          DropdownMenuItem(
                            value: 'Overdue',
                            child: Text('Overdue'),
                          ),
                          DropdownMenuItem(
                            value: 'Refunded',
                            child: Text('Refunded'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedStatus = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        initialValue: selectedMethod,
                        decoration: const InputDecoration(
                          labelText: 'Payment Method',
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Bank Transfer',
                            child: Text('Bank Transfer'),
                          ),
                          DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                          DropdownMenuItem(value: 'Card', child: Text('Card')),
                          DropdownMenuItem(
                            value: 'Online Gateway',
                            child: Text('Online Gateway'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selectedMethod = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text('Paid Date: ${_formatDate(paidAt)}'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: dialogContext,
                                initialDate: paidAt,
                                firstDate: DateTime(2020, 1, 1),
                                lastDate: DateTime(2100, 12, 31),
                              );
                              if (picked != null) {
                                setDialogState(() {
                                  paidAt = DateTime(
                                    picked.year,
                                    picked.month,
                                    picked.day,
                                  );
                                });
                              }
                            },
                            icon: const Icon(Icons.event_outlined),
                            label: const Text('Set Date'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: noteController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                        ),
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
                    final amount = double.tryParse(amountController.text.trim());
                    if (amount == null || amount <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Enter a valid amount.')),
                      );
                      return;
                    }

                    final businessDoc = businesses.firstWhere(
                      (b) => b.id == selectedBusinessId,
                    );
                    final b = businessDoc.data();

                    await _paymentsRef.add({
                      'businessId': selectedBusinessId,
                      'businessName': (b['title'] ?? selectedBusinessId)
                          .toString(),
                      'subscriptionPlan':
                          (b['subscriptionPlan'] ?? 'Unknown').toString(),
                      'amount': amount,
                      'status': selectedStatus,
                      'method': selectedMethod,
                      'paidAt': Timestamp.fromDate(paidAt),
                      'note': noteController.text.trim(),
                      'createdAt': FieldValue.serverTimestamp(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment saved.')),
                      );
                    }
                  },
                  child: const Text('Save Payment'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _businessesRef.snapshots(),
        builder: (context, businessesSnap) {
          if (businessesSnap.hasError) {
            return Center(
              child: Text('Failed to load businesses: ${businessesSnap.error}'),
            );
          }
          if (!businessesSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final businesses = businessesSnap.data!.docs;

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _paymentsRef.orderBy('paidAt', descending: true).snapshots(),
            builder: (context, paymentsSnap) {
              if (paymentsSnap.hasError) {
                return Center(
                  child: Text(
                    'Failed to load payment records: ${paymentsSnap.error}',
                  ),
                );
              }
              if (!paymentsSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final paymentDocs = paymentsSnap.data!.docs;
              final byBusiness =
                  <String, List<QueryDocumentSnapshot<Map<String, dynamic>>>>{};
              for (final p in paymentDocs) {
                final businessId = (p.data()['businessId'] ?? '').toString();
                if (businessId.isEmpty) continue;
                byBusiness
                    .putIfAbsent(businessId, () => <QueryDocumentSnapshot<Map<String, dynamic>>>[])
                    .add(p);
              }

              return ListView(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Billing & Invoicing',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Live payment records for each business.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: () async {
                          await _openRecordPaymentDialog(context, businesses);
                        },
                        icon: const Icon(Icons.add_card_rounded),
                        label: const Text('Record Payment'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...businesses.map((businessDoc) {
                    final businessId = businessDoc.id;
                    final b = businessDoc.data();
                    final businessName = (b['title'] ?? businessId).toString();
                    final plan = (b['subscriptionPlan'] ?? 'Unknown').toString();
                    final expectedFee = _planFee(plan);
                    final records = byBusiness[businessId] ?? const [];

                    final totalPaid = records.fold<double>(0, (acc, r) {
                      final status =
                          (r.data()['status'] ?? '').toString().toLowerCase();
                      if (status == 'paid' || status == 'partial') {
                        return acc + _asDouble(r.data()['amount']);
                      }
                      return acc;
                    });

                    final latestStatus = records.isEmpty
                        ? 'No Payment Record'
                        : (records.first.data()['status'] ?? 'Unknown')
                              .toString();

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    businessName,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                Chip(label: Text('Plan: $plan')),
                                const SizedBox(width: 8),
                                Chip(label: Text('Status: $latestStatus')),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Expected Fee: ${_money(expectedFee)} | Total Paid: ${_money(totalPaid)} | Records: ${records.length}',
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Recent Payments',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            if (records.isEmpty)
                              const Text('No payment records yet.')
                            else
                              ...records.take(5).map((record) {
                                final data = record.data();
                                final amount = _asDouble(data['amount']);
                                final method =
                                    (data['method'] ?? 'Unknown').toString();
                                final status =
                                    (data['status'] ?? 'Unknown').toString();
                                final paidAt = _asDateTime(data['paidAt']);

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 3),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${_formatDate(paidAt)} | $method | $status',
                                        ),
                                      ),
                                      Text(
                                        _money(amount),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
