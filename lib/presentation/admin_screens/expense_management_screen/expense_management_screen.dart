import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/core/utils/currency_formatter.dart';
import 'package:hotel_management_system/data/models/expense_model.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/currency_provider.dart';
import 'package:hotel_management_system/state_management/expense_sync_providers.dart';

class ExpenseManagementScreen extends ConsumerStatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  ConsumerState<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState
    extends ConsumerState<ExpenseManagementScreen> {
  // null = show all days; _filterMonth = true = this month; _filterDate = specific day
  DateTime? _filterDate;
  bool _filterMonth = false;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  DateTime _businessDayStart(DateTime value) {
    final local = value.toLocal();
    final fourAmToday = DateTime(local.year, local.month, local.day, 4);
    return local.isBefore(fourAmToday)
        ? fourAmToday.subtract(const Duration(days: 1))
        : fourAmToday;
  }

  bool _isSameBusinessDay(DateTime a, DateTime b) {
    final aStart = _businessDayStart(a);
    final bStart = _businessDayStart(b);
    return aStart.year == bStart.year &&
        aStart.month == bStart.month &&
        aStart.day == bStart.day &&
        aStart.hour == bStart.hour;
  }

  String _dayLabel(DateTime date) {
    final currentBusinessDay = _businessDayStart(DateTime.now());
    if (_isSameBusinessDay(date, currentBusinessDay)) return 'Today';
    if (_isSameBusinessDay(
      date,
      currentBusinessDay.subtract(const Duration(days: 1)),
    )) {
      return 'Yesterday';
    }
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _timeLabel(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $ampm';
  }

  String _dateFmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).selectedUser;
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final params = (
      businessId: user.primarybusinessId,
      branchId: user.primaryBranchId,
    );

    final expensesAsyncValue = ref.watch(
      realtimeExpensesProvider((params.businessId, params.branchId)),
    );

    final connectivityAsyncValue = ref.watch(connectivityStatusProvider);
    final currencyCode = ref.watch(tenantCurrencyCodeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(
                realtimeExpensesProvider((params.businessId, params.branchId)),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseDialog(context, params),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: Column(
        children: [
          // Offline indicator
          connectivityAsyncValue.when(
            data: (isOnline) {
              if (!isOnline) {
                return Container(
                  width: double.infinity,
                  color: Colors.orange,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.cloud_off, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Offline mode - Local data only',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Day filter chips
          _buildDateFilterBar(context),
          Expanded(
            child: _buildBody(
              context,
              expensesAsyncValue,
              currencyCode,
              params,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar(BuildContext context) {
    final now = DateTime.now();
    final today = _businessDayStart(now);
    final yesterday = today.subtract(const Duration(days: 1));

    final isAll = !_filterMonth && _filterDate == null;
    final isThisMonth = _filterMonth;
    final isToday =
        !_filterMonth && _filterDate != null && _isSameDay(_filterDate!, today);
    final isYesterday =
        !_filterMonth &&
        _filterDate != null &&
        _isSameDay(_filterDate!, yesterday);
    final isCustomDay =
        !_filterMonth && _filterDate != null && !isToday && !isYesterday;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: isAll,
              onSelected: (_) => setState(() {
                _filterDate = null;
                _filterMonth = false;
              }),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: Text('${_monthNames[now.month - 1]} ${now.year}'),
              selected: isThisMonth,
              onSelected: (_) => setState(() {
                _filterMonth = true;
                _filterDate = null;
              }),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Today'),
              selected: isToday,
              onSelected: (_) => setState(() {
                _filterDate = today;
                _filterMonth = false;
              }),
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Yesterday'),
              selected: isYesterday,
              onSelected: (_) => setState(() {
                _filterDate = yesterday;
                _filterMonth = false;
              }),
            ),
            const SizedBox(width: 8),
            ActionChip(
              avatar: Icon(
                Icons.calendar_today,
                size: 16,
                color: isCustomDay
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.primary,
              ),
              label: Text(isCustomDay ? _dateFmt(_filterDate!) : 'Pick Day'),
              backgroundColor: isCustomDay
                  ? Theme.of(context).colorScheme.primary
                  : null,
              labelStyle: isCustomDay
                  ? TextStyle(color: Theme.of(context).colorScheme.onPrimary)
                  : null,
              onPressed: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _filterDate ?? now,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _filterDate = DateTime(
                      picked.year,
                      picked.month,
                      picked.day,
                      4,
                    );
                    _filterMonth = false;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<List<ExpenseModel>> expensesAsyncValue,
    String currencyCode,
    ({String businessId, String branchId}) params,
  ) {
    return expensesAsyncValue.when(
      data: (allExpenses) {
        final now = DateTime.now();

        // Apply filter
        final List<ExpenseModel> expenses;
        String filterLabel;
        if (_filterMonth) {
          expenses = allExpenses
              .where(
                (e) =>
                    e.expenseDate.year == now.year &&
                    e.expenseDate.month == now.month,
              )
              .toList();
          filterLabel = '${_monthNames[now.month - 1]} ${now.year}';
        } else if (_filterDate != null) {
          expenses = allExpenses
              .where((e) => _isSameBusinessDay(e.expenseDate, _filterDate!))
              .toList();
          filterLabel = _dayLabel(_filterDate!);
        } else {
          expenses = allExpenses;
          filterLabel = '';
        }

        if (expenses.isEmpty) {
          return Center(
            child: Text(
              filterLabel.isEmpty
                  ? 'No expenses added yet.'
                  : 'No expenses for $filterLabel.',
            ),
          );
        }

        final total = expenses.fold<double>(0, (sum, e) => sum + e.amount);

        // Group by business day start key (4 AM boundary)
        final grouped = <DateTime, List<ExpenseModel>>{};
        for (final expense in expenses) {
          final key = _businessDayStart(expense.expenseDate);
          grouped.putIfAbsent(key, () => []).add(expense);
        }

        // Newest day first
        final sortedKeys = grouped.keys.toList()
          ..sort((a, b) => b.compareTo(a));

        return Column(
          children: [
            // Overall total banner
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(12, 12, 12, 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Total${filterLabel.isNotEmpty ? ' · $filterLabel' : ''}: ${CurrencyFormatter.formatAmount(total, currencyCode: currencyCode)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: sortedKeys.length,
                itemBuilder: (context, dayIndex) {
                  final key = sortedKeys[dayIndex];
                  final dayExpenses = List<ExpenseModel>.from(grouped[key]!)
                    ..sort((a, b) => b.expenseDate.compareTo(a.expenseDate));
                  final dayTotal = dayExpenses.fold<double>(
                    0,
                    (s, e) => s + e.amount,
                  );
                  final dayDate = key;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header row
                      Container(
                        width: double.infinity,
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dayLabel(dayDate),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              CurrencyFormatter.formatAmount(
                                dayTotal,
                                currencyCode: currencyCode,
                              ),
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      // Expenses for this day
                      ...dayExpenses.map(
                        (expense) => Column(
                          children: [
                            ListTile(
                              title: Text(expense.title),
                              subtitle: Text(
                                expense.category +
                                    (expense.note != null &&
                                            expense.note!.isNotEmpty
                                        ? ' · ${expense.note}'
                                        : ''),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        CurrencyFormatter.formatAmount(
                                          expense.amount,
                                          currencyCode: currencyCode,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _timeLabel(expense.expenseDate),
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.outline,
                                            ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    tooltip: 'Delete expense',
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                    onPressed: () async {
                                      await _confirmDeleteExpense(
                                        context,
                                        params,
                                        expense,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              onTap: () => _openExpenseDialog(
                                context,
                                params,
                                existing: expense,
                              ),
                              onLongPress: () async {
                                await _confirmDeleteExpense(
                                  context,
                                  params,
                                  expense,
                                );
                              },
                            ),
                            const Divider(height: 1, indent: 16, endIndent: 16),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load expenses: $error'),
        ),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
    );
  }

  Future<void> _confirmDeleteExpense(
    BuildContext context,
    ({String businessId, String branchId}) params,
    ExpenseModel expense,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense'),
        content: Text('Delete "${expense.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;
    await ref.read(expenseProvider(params).notifier).deleteExpense(expense.id);
  }

  Future<void> _openExpenseDialog(
    BuildContext context,
    ({String businessId, String branchId}) params, {
    ExpenseModel? existing,
  }) async {
    var title = existing?.title ?? '';
    var category = existing?.category ?? 'General';
    var amountText = existing != null ? existing.amount.toStringAsFixed(2) : '';
    var note = existing?.note ?? '';
    DateTime selectedDateTime = existing?.expenseDate ?? DateTime.now();
    TimeOfDay selectedTime = TimeOfDay(
      hour: selectedDateTime.hour,
      minute: selectedDateTime.minute,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setStateDialog) => AlertDialog(
            title: Text(existing == null ? 'Add Expense' : 'Edit Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    initialValue: title,
                    onChanged: (v) => title = v,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: category,
                    onChanged: (v) => category = v,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: amountText,
                    onChanged: (v) => amountText = v,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    initialValue: note,
                    onChanged: (v) => note = v,
                    decoration: const InputDecoration(labelText: 'Note'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  // Date picker row
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_dateFmt(selectedDateTime))),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: dialogContext,
                            initialDate: selectedDateTime,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedDateTime = DateTime(
                                picked.year,
                                picked.month,
                                picked.day,
                                selectedTime.hour,
                                selectedTime.minute,
                              );
                            });
                          }
                        },
                        child: const Text('Date'),
                      ),
                    ],
                  ),
                  // Time picker row
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showTimePicker(
                            context: dialogContext,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedTime = picked;
                              selectedDateTime = DateTime(
                                selectedDateTime.year,
                                selectedDateTime.month,
                                selectedDateTime.day,
                                picked.hour,
                                picked.minute,
                              );
                            });
                          }
                        },
                        child: const Text('Time'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSaving
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isSaving
                    ? null
                    : () async {
                        final amount = double.tryParse(amountText.trim());
                        if (title.trim().isEmpty ||
                            amount == null ||
                            amount <= 0) {
                          return;
                        }

                        setStateDialog(() => isSaving = true);
                        var didSave = false;
                        try {
                          final now = DateTime.now();
                          final payload = ExpenseModel(
                            id: existing?.id ?? '',
                            title: title.trim(),
                            category: category.trim().isEmpty
                                ? 'General'
                                : category.trim(),
                            amount: amount,
                            note: note.trim().isEmpty ? null : note.trim(),
                            expenseDate: selectedDateTime,
                            createdAt: existing?.createdAt ?? now,
                            updatedAt: now,
                          );

                          if (existing == null) {
                            await ref
                                .read(expenseProvider(params).notifier)
                                .addExpense(payload);
                          } else {
                            await ref
                                .read(expenseProvider(params).notifier)
                                .updateExpense(payload);
                          }

                          didSave = true;
                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        } finally {
                          if (!didSave && ctx.mounted) {
                            setStateDialog(() => isSaving = false);
                          }
                        }
                      },
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          ),
        );
      },
    );
  }
}
