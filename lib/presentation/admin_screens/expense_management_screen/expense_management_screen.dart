import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/expense_model.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/expense_state_and_notifier.dart';

class ExpenseManagementScreen extends ConsumerStatefulWidget {
  const ExpenseManagementScreen({super.key});

  @override
  ConsumerState<ExpenseManagementScreen> createState() =>
      _ExpenseManagementScreenState();
}

class _ExpenseManagementScreenState
    extends ConsumerState<ExpenseManagementScreen> {
  late final ({String businessId, String branchId}) _params;

  @override
  void initState() {
    super.initState();
    final user = ref.read(userProvider).selectedUser;
    if (user != null) {
      _params = (
        businessId: user.primarybusinessId,
        branchId: user.primaryBranchId,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(expenseProvider(_params).notifier).loadAllExpenses();
      });
    }
  }

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
    final expenseState = ref.watch(expenseProvider(params));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(expenseProvider(params).notifier).loadAllExpenses();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openExpenseDialog(context, params),
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
      body: _buildBody(context, expenseState, params),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ExpenseState expenseState,
    ({String businessId, String branchId}) params,
  ) {
    if (expenseState.isLoading && expenseState.expenses.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (expenseState.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load expenses: ${expenseState.error}'),
        ),
      );
    }

    if (expenseState.expenses.isEmpty) {
      return const Center(child: Text('No expenses added yet.'));
    }

    final total = expenseState.expenses.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return Column(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Total Expenses: Rs ${total.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.separated(
            itemCount: expenseState.expenses.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final expense = expenseState.expenses[index];
              return ListTile(
                title: Text(expense.title),
                subtitle: Text(
                  '${expense.category} • ${expense.expenseDate.toString().substring(0, 10)}\n${expense.note ?? ''}',
                ),
                isThreeLine: true,
                trailing: Text(
                  'Rs ${expense.amount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onTap: () =>
                    _openExpenseDialog(context, params, existing: expense),
                onLongPress: () async {
                  await ref
                      .read(expenseProvider(params).notifier)
                      .deleteExpense(expense.id);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openExpenseDialog(
    BuildContext context,
    ({String businessId, String branchId}) params, {
    ExpenseModel? existing,
  }) async {
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final categoryCtrl = TextEditingController(
      text: existing?.category ?? 'General',
    );
    final amountCtrl = TextEditingController(
      text: existing != null ? existing.amount.toStringAsFixed(2) : '',
    );
    final noteCtrl = TextEditingController(text: existing?.note ?? '');
    DateTime selectedDate = existing?.expenseDate ?? DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: Text(existing == null ? 'Add Expense' : 'Edit Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: categoryCtrl,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: amountCtrl,
                    decoration: const InputDecoration(labelText: 'Amount'),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: 'Note'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Date: ${selectedDate.toString().substring(0, 10)}',
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() => selectedDate = picked);
                          }
                        },
                        child: const Text('Pick Date'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount = double.tryParse(amountCtrl.text.trim());
                  if (titleCtrl.text.trim().isEmpty ||
                      amount == null ||
                      amount <= 0) {
                    return;
                  }

                  final now = DateTime.now();
                  final payload = ExpenseModel(
                    id: existing?.id ?? '',
                    title: titleCtrl.text.trim(),
                    category: categoryCtrl.text.trim().isEmpty
                        ? 'General'
                        : categoryCtrl.text.trim(),
                    amount: amount,
                    note: noteCtrl.text.trim().isEmpty
                        ? null
                        : noteCtrl.text.trim(),
                    expenseDate: selectedDate,
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

                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        );
      },
    );

    titleCtrl.dispose();
    categoryCtrl.dispose();
    amountCtrl.dispose();
    noteCtrl.dispose();
  }
}
