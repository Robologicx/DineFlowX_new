// permissions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/permission_model.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/app_error_widget.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/loading_indicator.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/permission_state_and_notifier.dart';
// import 'package:hotel_management_system/ui/widgets/responsive_layout.dart';
// import 'package:hotel_management_system/ui/widgets/loading_indicator.dart';
// import 'package:hotel_management_system/ui/widgets/error_widget.dart';
// import 'package:hotel_management_system/ui/dialogs/permission_dialog.dart';
// import 'package:hotel_management_system/ui/dialogs/delete_confirmation_dialog.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() => _PermissionsScreenState();
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  final TextEditingController _searchController = TextEditingController();
  late PermissionNotifier _permissionNotifier;
  late PermissionState _permissionState;
  late String businessId;
  late String branchId;
  bool canDeletePermission = false;
  bool canUpdatePermission = false;
  bool canAddPermission = false;

  @override
  void initState() {
    super.initState();

    final user = ref.read(userProvider).selectedUser;
    if (user != null) {
      businessId = user.primarybusinessId;
      branchId = user.primaryBranchId;
      final userNotifier = ref.read(userProvider.notifier);
      canUpdatePermission = userNotifier.hasPermissionOfCurrentUser(
        Permissions.updatePermission,
      );
      canDeletePermission = userNotifier.hasPermissionOfCurrentUser(
        Permissions.deletePermission,
      );
      canAddPermission = userNotifier.hasPermissionOfCurrentUser(
        Permissions.createPermission,
      );
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _permissionNotifier = ref.read(
        permissionProvider((
          branchId: branchId,
          businessId: businessId,
        )).notifier,
      );

      _permissionState = ref.watch(
        permissionProvider((branchId: branchId, businessId: businessId)),
      );

      _permissionNotifier.loadAllCorePermissions();
      _permissionNotifier.loadAllPermissions();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    if (value.isEmpty) {
      _permissionNotifier.loadAllPermissions();
    } else {
      _permissionNotifier.searchPermissions(value);
    }
  }

  void _showPermissionDialog({PermissionModel? permission}) {
    showDialog(
      context: context,
      builder: (context) => PermissionDialog(
        permission: permission,
        onSaved: (permission) {
          if (permission == null) return;

          if (permission.id.isEmpty) {
            _permissionNotifier.createPermission(permission);
          } else {
            _permissionNotifier.updatePermission(permission);
          }
        },
      ),
    );
  }

  void _showDeleteDialog(PermissionModel permission) {
    showDialog(
      context: context,
      builder: (context) => Container(),
      //  DeleteConfirmationDialog(
      //   title: 'Delete Permission',
      //   content: 'Are you sure you want to delete "${permission.name}"?',
      //   onConfirm: () => _notifier.deletePermission(permission.id),
      // ),
    );
  }

  void _showForceDeleteDialog(PermissionModel permission) {
    showDialog(
      context: context,
      builder: (context) => Container(),
      // DeleteConfirmationDialog(
      //   title: 'Force Delete Permission',
      //   content:
      //       'This will remove the permission from all roles and then delete it. Continue?',
      //   onConfirm: () => _notifier.forceDeletePermission(permission.id),
      // ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permissions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _permissionNotifier.loadAllPermissions,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: _permissionNotifier.loadPermissionStats,
            tooltip: 'Statistics',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search permissions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _permissionNotifier.loadAllPermissions();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: _handleSearch,
            ),
          ),

          // Error Display
          if (_permissionState.error != null)
            AppErrorWidget(
              error: _permissionState.error!,
              onDismiss: _permissionNotifier.clearError,
            ),

          // Loading Indicator
          if (_permissionState.isLoading) const LoadingIndicator(),

          // Content
          Expanded(child: _buildContent(_permissionState)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (canAddPermission) _showPermissionDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildContent(PermissionState state) {
    if (state.permissions.isEmpty && !state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No permissions found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _permissionNotifier.loadAllPermissions(),
      child: ListView.builder(
        itemCount: state.permissions.length,
        itemBuilder: (context, index) {
          final permission = state.permissions[index];
          return _buildPermissionCard(permission);
        },
      ),
    );
  }

  Widget _buildPermissionCard(PermissionModel permission) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          permission.isActive ? Icons.lock_open : Icons.lock_outlined,
          color: permission.isActive ? Colors.green : Colors.grey,
        ),
        title: Text(permission.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(permission.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(permission.id),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
                if (permission.isShowingToAllAdmins)
                  const Chip(
                    label: Text('Admin Visible'),
                    backgroundColor: Colors.green,
                  ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                if (canUpdatePermission) {
                  _showPermissionDialog(permission: permission);
                }
              },
              tooltip: 'Edit',
            ),
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                if (canDeletePermission) _showDeleteDialog(permission);
              },
              tooltip: 'Delete',
            ),
          ],
        ),
        onTap: () => _showPermissionDialog(permission: permission),
      ),
    );
  }
}
// permission_dialog.dart

class PermissionDialog extends ConsumerStatefulWidget {
  final PermissionModel? permission;
  final Function(PermissionModel?)? onSaved;

  const PermissionDialog({super.key, this.permission, this.onSaved});

  @override
  ConsumerState<PermissionDialog> createState() => _PermissionDialogState();
}

class _PermissionDialogState extends ConsumerState<PermissionDialog> {
  final _formKey = GlobalKey<FormState>();
  // late TextEditingController _idController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late bool _isActive;
  late bool _isShowingToAllAdmins;

  @override
  void initState() {
    super.initState();
    final permission = widget.permission;
    // _idController = TextEditingController(text: permission?.id ?? '');
    _nameController = TextEditingController(text: permission?.name ?? '');
    _descriptionController = TextEditingController(
      text: permission?.description ?? '',
    );
    _isActive = permission?.isActive ?? true;
    _isShowingToAllAdmins = permission?.isShowingToAllAdmins ?? true;
  }

  @override
  void dispose() {
    // _idController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState?.validate() ?? false) {
      final permission = PermissionModel(
        id: "",
        // id: _idController.text,
        name: _nameController.text,
        description: _descriptionController.text,
        isActive: _isActive,
        isSystemDefined: true,
        category: '',
        isShowingToAllAdmins: _isShowingToAllAdmins,
        createdAt: widget.permission?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );
      widget.onSaved?.call(permission);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.permission != null;

    return AlertDialog(
      title: Text(isEditing ? 'Edit Permission' : 'Create Permission'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isEditing)
                // -------------------------------ID will be generated from the backend , e.g UUID - Firestore Doc ID--------------------//
                // TextFormField(
                //   controller: _idController,
                //   decoration: const InputDecoration(
                //     labelText: 'Permission ID',
                //     hintText: 'e.g., create_order',
                //   ),
                //   validator: (value) {
                //     if (value == null || value.isEmpty) {
                //       return 'Please enter a permission ID';
                //     }
                //     if (!RegExp(r'^[a-z0-9_-]+$').hasMatch(value)) {
                //       return 'Use only lowercase letters, numbers, underscores, and hyphens';
                //     }
                //     return null;
                //   },
                // ),
                const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'e.g., Create Order',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.length > 100) {
                    return 'Name must be less than 100 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Allows creating new orders',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  if (value.length > 500) {
                    return 'Description must be less than 500 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Active'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              SwitchListTile(
                title: const Text('Show to all admins'),
                value: _isShowingToAllAdmins,
                onChanged: (value) =>
                    setState(() => _isShowingToAllAdmins = value),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
