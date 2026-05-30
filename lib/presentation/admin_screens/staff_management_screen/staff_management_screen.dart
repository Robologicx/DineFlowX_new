import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/presentation/admin_screens/staff_management_screen/add_edit_staff_dialog.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class StaffManagementScreen extends ConsumerStatefulWidget {
  const StaffManagementScreen({super.key});

  @override
  ConsumerState<StaffManagementScreen> createState() =>
      _StaffManagementScreenState();
}

class _StaffManagementScreenState extends ConsumerState<StaffManagementScreen> {
  String businessId = BusinessRepository.temporaryBusinesshId;
  String branchId = BusinessRepository.temporaryBranchId;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(userProvider.notifier)
          .loadAllStaffMembers(businessId: businessId, branchId: branchId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);

    ref.listen(userProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management'), elevation: 0),
      body: user.isLoading
          ? const Center(child: CircularProgressIndicator())
          : user.users.isEmpty
          ? _buildEmptyState(context)
          : _buildStaffContent(
              context,
              user.users,
              userNotifier.hasPermissionOfCurrentUser(Permissions.updateStaff),
              userNotifier.hasPermissionOfCurrentUser(Permissions.deleteStaff),
            ),
      floatingActionButton:
          userNotifier.hasPermissionOfCurrentUser(Permissions.createStaff)
          ? FloatingActionButton.extended(
              onPressed: () => _showAddEditDialog(context, null),
              icon: const Icon(Icons.person_add),
              label: const Text('Add Staff'),
            )
          : null,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No staff members yet',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first staff member to get started',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffContent(
    BuildContext context,
    List<UserModel> staffMembers,
    bool hasEditPermission,
    bool hasDeletePermission,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;

        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: availableWidth > 1200 ? 32 : 16,
              vertical: 16,
            ),
            child: _buildStaffTable(
              context,
              staffMembers,
              availableWidth,
              hasEditPermission,
              hasDeletePermission,
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffTable(
    BuildContext context,
    List<UserModel> staffMembers,
    double availableWidth,
    bool hasEditPermission,
    bool hasDeletePermission,
  ) {
    return Card(
      child: Column(
        children: [
          _buildTableHeader(context, availableWidth),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: staffMembers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) => _buildStaffRow(
              context,
              staffMembers[index],
              availableWidth,
              hasEditPermission,
              hasDeletePermission,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(BuildContext context, double availableWidth) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: availableWidth > 1200 ? 20 : 12,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell(context, 'Name')),
          Expanded(flex: 3, child: _buildHeaderCell(context, 'Email')),
          if (availableWidth > 600)
            Expanded(flex: 2, child: _buildHeaderCell(context, 'Phone')),
          Expanded(flex: 2, child: _buildHeaderCell(context, 'Role')),
          SizedBox(
            width: availableWidth > 600 ? 120 : 80,
            child: Align(
              alignment: Alignment.centerRight,
              child: _buildHeaderCell(context, 'Actions'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(BuildContext context, String text) {
    return Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildStaffRow(
    BuildContext context,
    UserModel staff,
    double availableWidth,
    bool hasEditPermission,
    bool hasDeletePermission,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: availableWidth > 1200 ? 20 : 12,
        vertical: 12,
      ),
      child: Row(
        children: [
          // Name with Avatar
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: availableWidth > 800 ? 22 : 18,
                  backgroundImage: staff.profileImageUrl != null
                      ? NetworkImage(staff.profileImageUrl!)
                      : null,
                  child: staff.profileImageUrl == null
                      ? Text(
                          staff.name.isNotEmpty
                              ? staff.name[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: availableWidth > 800 ? 16 : 14,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                SizedBox(width: availableWidth > 800 ? 12 : 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name.isNotEmpty ? staff.name : 'Pending',
                        style: Theme.of(context).textTheme.bodyLarge,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (availableWidth < 600)
                        Text(
                          staff.email,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Email
          Expanded(
            flex: 3,
            child: Text(
              staff.email,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Phone (hidden on small screens)
          if (availableWidth > 600)
            Expanded(
              flex: 2,
              child: Text(
                staff.phoneNumber ?? '-',
                style: Theme.of(context).textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // Role
          Expanded(
            flex: 2,
            child: Chip(
              label: Text(
                staff.role.name,
                style: TextStyle(fontSize: availableWidth > 800 ? 12 : 11),
              ),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),

          // Actions
          SizedBox(
            width: availableWidth > 600 ? 120 : 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                hasEditPermission
                    ? IconButton(
                        icon: Icon(
                          Icons.edit,
                          size: availableWidth > 800 ? 20 : 18,
                        ),
                        onPressed: () => _showAddEditDialog(context, staff),
                        tooltip: 'Edit',
                        constraints: BoxConstraints(
                          minWidth: availableWidth > 600 ? 48 : 40,
                          minHeight: availableWidth > 600 ? 48 : 40,
                        ),
                      )
                    : SizedBox.shrink(),
                hasDeletePermission
                    ? IconButton(
                        icon: Icon(
                          Icons.delete,
                          size: availableWidth > 800 ? 20 : 18,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context, staff),
                        tooltip: 'Delete',
                        constraints: BoxConstraints(
                          minWidth: availableWidth > 600 ? 48 : 40,
                          minHeight: availableWidth > 600 ? 48 : 40,
                        ),
                      )
                    : SizedBox.shrink(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAddEditDialog(BuildContext context, UserModel? staff) {
    if (staff != null) {
      ref.read(userProvider.notifier).setTempStaffMember(staff);
    } else {
      ref.read(userProvider.notifier).clearTempStaffMember();
    }
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddEditStaffDialog(
        businessId: businessId,
        branchId: branchId,
        staff: staff,
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserModel staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff Member'),
        content: Text(
          'Are you sure you want to remove ${staff.name.isNotEmpty ? staff.name : staff.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final success = await ref
                  .read(userProvider.notifier)
                  .deleteStaffMember(
                    uid: staff.uid,
                    businessId: businessId,
                    branchId: branchId,
                  );

              if (mounted) {
                Navigator.pop(context);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Staff member removed successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
