import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsersSection extends ConsumerStatefulWidget {
  const UsersSection({super.key});

  @override
  ConsumerState<UsersSection> createState() => _UsersSectionState();
}

class _UsersSectionState extends ConsumerState<UsersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _search = '';
  String _roleFilter = 'all';
  String _statusFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Management',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Manage users across businesses with filters and quick access controls.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SizedBox(
                width: 320,
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search by name, email, uid, business...',
                  ),
                  onChanged: (value) {
                    setState(() => _search = value.trim().toLowerCase());
                  },
                ),
              ),
              SizedBox(
                width: 180,
                child: DropdownButtonFormField<String>(
                  initialValue: _roleFilter,
                  decoration: const InputDecoration(
                    labelText: 'Role',
                    prefixIcon: Icon(Icons.badge_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All roles')),
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'client', child: Text('Client')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _roleFilter = value);
                  },
                ),
              ),
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  initialValue: _statusFilter,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All statuses')),
                    DropdownMenuItem(value: 'active', child: Text('Active')),
                    DropdownMenuItem(
                      value: 'suspended',
                      child: Text('Suspended'),
                    ),
                    DropdownMenuItem(value: 'deleted', child: Text('Deleted')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _statusFilter = value);
                  },
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _search = '';
                    _roleFilter = 'all';
                    _statusFilter = 'all';
                  });
                },
                icon: const Icon(Icons.clear_all_rounded),
                label: const Text('Reset Filters'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text('Failed to load users: ${snapshot.error}'),
                  );
                }

                final docs = snapshot.data?.docs ?? const [];
                final rows =
                    docs
                        .map(_fromDoc)
                        .whereType<_UserRow>()
                        .where(_matchesFilters)
                        .toList(growable: false)
                      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

                if (rows.isEmpty) {
                  return const Center(
                    child: Text('No users found for current filters.'),
                  );
                }

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: const [
                        DataColumn(label: Text('Name')),
                        DataColumn(label: Text('Email')),
                        DataColumn(label: Text('Role')),
                        DataColumn(label: Text('Business')),
                        DataColumn(label: Text('Branch')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Updated')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: rows
                          .map((row) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(row.name),
                                      Text(
                                        row.uid,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                DataCell(Text(row.email)),
                                DataCell(Text(row.role)),
                                DataCell(Text(row.businessId)),
                                DataCell(Text(row.branchId)),
                                DataCell(_statusChip(row.status)),
                                DataCell(Text(_formatDate(row.updatedAt))),
                                DataCell(
                                  PopupMenuButton<String>(
                                    onSelected: (value) =>
                                        _handleAction(value, row),
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'deactivate',
                                        child: Text('Deactivate Access'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'activate',
                                        child: Text('Activate Access'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete User'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'details',
                                        child: Text('View Details'),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  _UserRow? _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final roleName = (data['roleName'] ?? data['role'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final isStaff = data['isStaffMember'] == true;

    final role = roleName.isNotEmpty
        ? roleName
        : isStaff
        ? 'staff'
        : 'client';

    final isDeleted = data['isDeleted'] == true || data['deletedAt'] != null;
    final isSuspended =
        data['isSuspended'] == true || data['isActive'] == false;

    final status = isDeleted
        ? 'deleted'
        : isSuspended
        ? 'suspended'
        : 'active';

    return _UserRow(
      uid: doc.id,
      name: (data['name'] ?? '').toString().trim().isEmpty
          ? 'Unnamed'
          : (data['name'] ?? '').toString().trim(),
      email: (data['email'] ?? '').toString(),
      role: role,
      businessId: (data['primarybusinessId'] ?? '').toString(),
      branchId: (data['primaryBranchId'] ?? '').toString(),
      status: status,
      updatedAt:
          _toDateTime(data['updatedAt']) ??
          _toDateTime(data['createdAt']) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  bool _matchesFilters(_UserRow row) {
    final roleMatch = _roleFilter == 'all' || row.role == _roleFilter;
    final statusMatch = _statusFilter == 'all' || row.status == _statusFilter;

    if (!roleMatch || !statusMatch) return false;

    if (_search.isEmpty) return true;

    return row.name.toLowerCase().contains(_search) ||
        row.email.toLowerCase().contains(_search) ||
        row.uid.toLowerCase().contains(_search) ||
        row.businessId.toLowerCase().contains(_search) ||
        row.branchId.toLowerCase().contains(_search);
  }

  DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  String _formatDate(DateTime date) {
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '${date.year}-$mm-$dd';
  }

  Widget _statusChip(String status) {
    Color color;
    switch (status) {
      case 'deleted':
        color = Colors.red;
        break;
      case 'suspended':
        color = Colors.orange;
        break;
      default:
        color = Colors.green;
    }

    return Chip(
      label: Text(status),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.35)),
    );
  }

  Future<void> _handleAction(String action, _UserRow row) async {
    try {
      if (action == 'deactivate') {
        final confirmed = await _confirmAction(
          title: 'Deactivate user',
          message:
              'This will disable login for ${row.email.isEmpty ? row.uid : row.email}. Continue?',
        );
        if (!confirmed) return;

        final callable = FirebaseFunctions.instance.httpsCallable(
          'togglePlatformUserActivation',
        );
        await callable.call(<String, dynamic>{
          'uid': row.uid,
          'isActive': false,
        });
      } else if (action == 'activate') {
        final callable = FirebaseFunctions.instance.httpsCallable(
          'togglePlatformUserActivation',
        );
        await callable.call(<String, dynamic>{
          'uid': row.uid,
          'isActive': true,
        });
      } else if (action == 'delete') {
        final confirmed = await _confirmAction(
          title: 'Delete user permanently',
          message:
              'This deletes the user from all branches and root records, and they cannot login again. Continue?',
        );
        if (!confirmed) return;

        final callable = FirebaseFunctions.instance.httpsCallable(
          'deletePlatformUser',
        );
        await callable.call(<String, dynamic>{'uid': row.uid});
      } else if (action == 'details') {
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('User Details'),
              content: SelectableText(
                'UID: ${row.uid}\n'
                'Name: ${row.name}\n'
                'Email: ${row.email}\n'
                'Role: ${row.role}\n'
                'Business: ${row.businessId}\n'
                'Branch: ${row.branchId}\n'
                'Status: ${row.status}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            );
          },
        );
      }

      if (!mounted) return;
      if (action != 'details') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User action completed successfully.')),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      final message = e.message ?? e.code;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: $message')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
    }
  }

  Future<bool> _confirmAction({
    required String title,
    required String message,
  }) async {
    if (!mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );

    return result == true;
  }
}

class _UserRow {
  const _UserRow({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.businessId,
    required this.branchId,
    required this.status,
    required this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String role;
  final String businessId;
  final String branchId;
  final String status;
  final DateTime updatedAt;
}
