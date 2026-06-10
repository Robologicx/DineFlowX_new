// roles_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/app_error_widget.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/loading_indicator.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/role_state_and_provider.dart';
// import 'package:hotel_management_system/ui/widgets/responsive_layout.dart';
// import 'package:hotel_management_system/ui/widgets/loading_indicator.dart';
// import 'package:hotel_management_system/ui/widgets/error_widget.dart';
// import 'package:hotel_management_system/ui/dialogs/role_dialog.dart';
// import 'package:hotel_management_system/ui/dialogs/delete_confirmation_dialog.dart';

class RolesScreen extends ConsumerStatefulWidget {
  const RolesScreen({super.key});

  @override
  ConsumerState<RolesScreen> createState() => _RolesScreenState();
}

class _RolesScreenState extends ConsumerState<RolesScreen> {
  final TextEditingController _searchController = TextEditingController();
  late RoleNotifier _notifier;
  late String businessId;
  late String branchId;
  bool canDeleteRole = false;
  bool canUpdateRole = false;
  bool canAddRole = false;

  @override
  void initState() {
    super.initState();

    final user = ref.read(userProvider).selectedUser;
    if (user != null) {
      businessId = user.primarybusinessId;
      branchId = user.primaryBranchId;
      final roleName = user.role.name.trim().toLowerCase();
      final isRoleAdmin = roleName == 'owner' || roleName.contains('admin');
      canUpdateRole = isRoleAdmin;
      canDeleteRole = isRoleAdmin;
      canAddRole = isRoleAdmin;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _notifier = ref.read(
        roleProvider((branchId: branchId, businessId: businessId)).notifier,
      );
      _notifier.setBusinessId(businessId);
      _notifier.getAllRolesOfBuisness();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String value) {
    if (value.isEmpty) {
      _notifier.getAllRolesOfBuisness();
    } else {
      _notifier.searchRoles(value);
    }
  }

  // Replace your _showRoleDialog method with this:
  void _showRoleDialog({RoleModel? role}) {
    showDialog(
      context: context,
      builder: (context) => RoleDialog(
        businessId: businessId,
        branchId: branchId,
        role: role,
        onSaved: (role) {
          if (role == null) return;

          if (role.id.isEmpty) {
            _notifier.createRole(role);
          } else {
            _notifier.updateRole(role);
          }
        },
      ),
    );
  }

  // Replace your _showDeleteDialog method with this:
  void _showDeleteDialog(RoleModel role) {
    showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: 'Delete Role',
        content: 'Are you sure you want to delete "${role.name}"?',
        onConfirm: () => _notifier.deleteRole(role.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!canUpdateRole && !canDeleteRole && !canAddRole) {
      return Scaffold(
        appBar: AppBar(title: const Text('Roles')),
        body: const Center(child: Text('Only admin can manage roles.')),
      );
    }

    final state = ref.watch(
      roleProvider((branchId: branchId, businessId: businessId)),
    );
    final notifier = ref.read(
      roleProvider((branchId: branchId, businessId: businessId)).notifier,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Roles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: notifier.getAllRolesOfBuisness,
            tooltip: 'Refresh',
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
                hintText: 'Search roles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    notifier.getAllRolesOfBuisness();
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
          if (state.error != null)
            AppErrorWidget(error: state.error!, onDismiss: notifier.clearError),

          // Loading Indicator
          if (state.isLoading) const LoadingIndicator(),

          // Content
          Expanded(child: _buildContent(state)),
        ],
      ),
      floatingActionButton: canAddRole
          ? FloatingActionButton(
              onPressed: _showRoleDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildContent(RoleState state) {
    if (state.roles.isEmpty && !state.isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.groups_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No roles found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Create your first role to get started',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _notifier.getAllRolesOfBuisness(),
      child: ListView.builder(
        itemCount: state.roles.length,
        itemBuilder: (context, index) {
          final role = state.roles[index];
          return _buildRoleCard(role);
        },
      ),
    );
  }

  Widget _buildRoleCard(RoleModel role) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: const Icon(Icons.groups, color: Colors.blue),
        title: Text(role.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${role.id}'),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                Chip(
                  label: Text('${role.permissions.length} permissions'),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
                Chip(
                  label: Text(role.businessId),
                  backgroundColor: Colors.grey.withOpacity(0.1),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (canUpdateRole)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _showRoleDialog(role: role),
                tooltip: 'Edit',
              ),
            if (canDeleteRole)
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _showDeleteDialog(role),
                tooltip: 'Delete',
              ),
          ],
        ),
        onTap: canUpdateRole ? () => _showRoleDialog(role: role) : null,
      ),
    );
  }
}

// Add these components to your roles_screen.dart file

// 1. RoleDialog Widget - Add this class above your RolesScreen class
class RoleDialog extends ConsumerStatefulWidget {
  final String businessId;
  final String branchId;
  final RoleModel? role;
  final Function(RoleModel?) onSaved;

  const RoleDialog({
    super.key,
    required this.businessId,
    required this.branchId,
    this.role,
    required this.onSaved,
  });

  @override
  ConsumerState<RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends ConsumerState<RoleDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  late Set<String> _selectedPermissions;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPermissions =
        widget.role?.permissions.map((p) => p.id).toSet() ?? {};
    _nameController.text = widget.role?.name ?? '';
    // _descriptionController.text = widget.role?.description ?? '';

    // Load permissions when dialog opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final permissionNotifier = ref.read(
        permissionProvider((
          businessId: widget.businessId,
          branchId: widget.branchId,
        )).notifier,
      );
      permissionNotifier.loadAllPermissions();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveRole() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedPermissions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one permission'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final permissionState = ref.read(
      permissionProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )),
    );

    final selectedPermissionModels = permissionState.permissions
        .where((p) => _selectedPermissions.contains(p.id))
        .toList();

    final role = RoleModel(
      id: widget.role?.id ?? '',
      name: _nameController.text.trim(),
      // description: _descriptionController.text.trim(),
      permissions: selectedPermissionModels,
      businessId: widget.businessId,
      // branchId: widget.branchId,
      createdAt: widget.role?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSaved(role);
    setState(() => _isLoading = false);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final permissionState = ref.watch(
      permissionProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )),
    );

    return AlertDialog(
      title: Text(widget.role == null ? 'Create Role' : 'Edit Role'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Role Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Role Name *',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Role name is required';
                  }
                  if (value.trim().length < 2) {
                    return 'Role name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Permissions Section
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Permissions *',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              if (_selectedPermissions.length ==
                                  permissionState.permissions.length) {
                                _selectedPermissions.clear();
                              } else {
                                _selectedPermissions = permissionState
                                    .permissions
                                    .map((p) => p.id)
                                    .toSet();
                              }
                            });
                          },
                          child: Text(
                            _selectedPermissions.length ==
                                    permissionState.permissions.length
                                ? 'Deselect All'
                                : 'Select All',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (permissionState.isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (permissionState.error != null)
                      Text(
                        'Error loading permissions: ${permissionState.error}',
                        style: const TextStyle(color: Colors.red),
                      )
                    else
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: permissionState.permissions.length,
                            itemBuilder: (context, index) {
                              final permission =
                                  permissionState.permissions[index];
                              return CheckboxListTile(
                                title: Text(permission.name),
                                subtitle: permission.description.isNotEmpty
                                    ? Text(permission.description)
                                    : null,
                                value: _selectedPermissions.contains(
                                  permission.id,
                                ),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      _selectedPermissions.add(permission.id);
                                    } else {
                                      _selectedPermissions.remove(
                                        permission.id,
                                      );
                                    }
                                  });
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                              );
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveRole,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.role == null ? 'Create' : 'Update'),
        ),
      ],
    );
  }
}

// 2. DeleteConfirmationDialog Widget - Add this class as well
class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            onConfirm();
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
