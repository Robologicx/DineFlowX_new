import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/menu_model.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/menu_state_and_notifier.dart';
import 'package:image_picker/image_picker.dart';

class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() =>
      _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _menuNotifier.loadAllMenus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  MenuNotifier get _menuNotifier {
    final user = ref.read(userProvider).selectedUser!;
    return ref.read(
      menuProvider((
        branchId: user.primaryBranchId,
        businessId: user.primarybusinessId,
      )).notifier,
    );
  }

  List<MenuModel> _filterMenus(List<MenuModel> menus) {
    if (_searchQuery.isEmpty) return menus;
    return menus
        .where(
          (menu) =>
              menu.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              (menu.description?.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ??
                  false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).selectedUser;
    final userNotifier = ref.read(userProvider.notifier);

    if (user == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final menuState = ref.watch(
      menuProvider((
        branchId: user.primaryBranchId,
        businessId: user.primarybusinessId,
      )),
    );

    bool canCreateMenu = userNotifier.hasPermissionOfCurrentUser(
      Permissions.createMenu,
    );
    bool canDeleteMenu = userNotifier.hasPermissionOfCurrentUser(
      Permissions.deleteMenu,
    );
    bool canUpdateMenu = userNotifier.hasPermissionOfCurrentUser(
      Permissions.updateMenu,
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (canCreateMenu)
            IconButton(
              onPressed: () => _showCreateMenuDialog(context),
              icon: const Icon(Icons.add),
              tooltip: 'Add Menu',
            ),
          IconButton(
            onPressed: () => _menuNotifier.loadAllMenus(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search menus...',
              leading: const Icon(Icons.search),
              trailing: _searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      ),
                    ]
                  : null,
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(
              menuState,
              colorScheme,
              canCreateMenu,
              canDeleteMenu,
              canUpdateMenu,
            ),
          ),
        ],
      ),
      floatingActionButton: canCreateMenu
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateMenuDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Menu'),
            )
          : null,
    );
  }

  Widget _buildContent(
    MenuState state,
    ColorScheme colorScheme,
    bool canCreateMenu,
    bool canDeleteMenu,
    bool canUpdateMenu,
  ) {
    if (state.isLoading && state.menus.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Error loading menus',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _menuNotifier.loadAllMenus(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredMenus = _filterMenus(state.menus);

    if (filteredMenus.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty
                  ? Icons.search_off
                  : Icons.restaurant_menu,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty ? 'No menus found' : 'No menus available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Get started by adding your first menu',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_searchQuery.isEmpty && canCreateMenu) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showCreateMenuDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Add Menu'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _menuNotifier.loadAllMenus(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout
          if (constraints.maxWidth > 1200) {
            // Desktop: 3 columns
            return _buildGridView(
              filteredMenus,
              3,
              canDeleteMenu,
              canUpdateMenu,
            );
          } else if (constraints.maxWidth > 800) {
            // Tablet: 2 columns
            return _buildGridView(
              filteredMenus,
              2,
              canDeleteMenu,
              canUpdateMenu,
            );
          } else {
            // Mobile: List view
            return _buildListView(
              filteredMenus,
              state.isLoading,
              canDeleteMenu,
              canUpdateMenu,
            );
          }
        },
      ),
    );
  }

  Widget _buildListView(
    List<MenuModel> menus,
    bool isLoading,
    bool canDeleteMenu,
    bool canUpdateMenu,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: menus.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == menus.length && isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final menu = menus[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildMenuCard(
            menu,
            canDeleteMenu,
            canUpdateMenu,
            isListView: true,
          ),
        );
      },
    );
  }

  Widget _buildGridView(
    List<MenuModel> menus,
    int crossAxisCount,
    bool canDeleteMenu,
    bool canUpdateMenu,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: menus.length,
      itemBuilder: (context, index) =>
          _buildMenuCard(menus[index], canDeleteMenu, canUpdateMenu),
    );
  }

  Widget _buildMenuCard(
    MenuModel menu,
    bool canDeleteMenu,
    bool canUpdateMenu, {
    bool isListView = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isListView) {
      return Dismissible(
        key: Key(menu.id),
        background: _buildSwipeBackground(
          Colors.blue,
          Icons.edit,
          'Edit',
          isLeft: true,
        ),
        secondaryBackground: canDeleteMenu
            ? _buildSwipeBackground(colorScheme.error, Icons.delete, 'Delete')
            : null,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            if (canUpdateMenu) {
              _showEditMenuDialog(context, menu);
            }
            return false;
          } else if (direction == DismissDirection.endToStart) {
            if (canDeleteMenu) {
              return await _showDeleteConfirmation(context, menu);
            }
          }
          return false;
        },
        child: _buildMenuListTile(
          menu,
          theme,
          colorScheme,
          canDeleteMenu,
          canUpdateMenu,
        ),
      );
    } else {
      return _buildMenuGridCard(
        menu,
        theme,
        colorScheme,
        canDeleteMenu,
        canUpdateMenu,
      );
    }
  }

  Widget _buildSwipeBackground(
    Color color,
    IconData icon,
    String text, {
    bool isLeft = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuListTile(
    MenuModel menu,
    ThemeData theme,
    ColorScheme colorScheme,
    bool canDeleteMenu,
    bool canUpdateMenu,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildMenuImage(menu.imageUrl, size: 56),
        title: Row(
          children: [
            Expanded(
              child: Text(
                menu.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildStatusChip(menu.isActive, colorScheme),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (menu.description != null) ...[
              const SizedBox(height: 4),
              Text(
                menu.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(menu.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) =>
              _buildPopupMenuItems(menu, canUpdateMenu, canDeleteMenu),
        ),
      ),
    );
  }

  Widget _buildMenuGridCard(
    MenuModel menu,
    ThemeData theme,
    ColorScheme colorScheme,
    bool canDeleteMenu,
    bool canUpdateMenu,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                color: colorScheme.surfaceContainerHighest,
              ),
              child: _buildMenuImage(menu.imageUrl),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          menu.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusChip(menu.isActive, colorScheme),
                    ],
                  ),
                  if (menu.description != null) ...[
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        menu.description!,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDate(menu.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => _buildPopupMenuItems(
                          menu,
                          canUpdateMenu,
                          canDeleteMenu,
                        ),
                        child: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuImage(String? imageUrl, {double? size}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size != null ? 8 : 12),
        child: Image.network(
          imageUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderImage(size),
        ),
      );
    }
    return _buildPlaceholderImage(size);
  }

  Widget _buildPlaceholderImage(double? size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size != null ? 8 : 12),
      ),
      child: Icon(
        Icons.restaurant_menu,
        size: size != null ? size * 0.4 : 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildStatusChip(bool isActive, ColorScheme colorScheme) {
    return Chip(
      label: Text(
        isActive ? 'Active' : 'Inactive',
        style: TextStyle(
          fontSize: 12,
          color: isActive ? colorScheme.onPrimary : colorScheme.onSecondary,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isActive ? colorScheme.primary : colorScheme.secondary,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  List<PopupMenuEntry> _buildPopupMenuItems(
    MenuModel menu,
    bool canUpdateMenu,
    bool canDeleteMenu,
  ) {
    return [
      if (canUpdateMenu)
        PopupMenuItem(
          value: 'edit',
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _showEditMenuDialog(context, menu),
        ),
      if (canUpdateMenu)
        PopupMenuItem(
          value: 'toggle',
          child: ListTile(
            leading: Icon(
              menu.isActive ? Icons.visibility_off : Icons.visibility,
            ),
            title: Text(menu.isActive ? 'Deactivate' : 'Activate'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _toggleMenuStatus(menu),
        ),
      if (canDeleteMenu)
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading: Icon(
              Icons.delete,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _showDeleteConfirmation(context, menu),
        ),
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _toggleMenuStatus(MenuModel menu) {
    _menuNotifier.toggleMenuActiveStatus(menu.id, !menu.isActive);
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    MenuModel menu,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Menu'),
            content: Text(
              'Are you sure you want to delete "${menu.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  _menuNotifier.deleteMenu(menu.id);
                  Navigator.of(context).pop(true);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showCreateMenuDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MenuFormDialog(
        title: 'Create Menu',
        onSave:
            (
              name,
              description,
              imageUrl,
              Uint8List? imageBytes,
              String imageExtension,
            ) async {
              await _menuNotifier.createMenu(
                name: name,
                description: description,
                imageUrl: imageUrl,
                createdBy: 'current_user_id', // Replace with actual user ID
              );
            },
      ),
    );
  }

  void _showEditMenuDialog(BuildContext context, MenuModel menu) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MenuFormDialog(
        title: 'Edit Menu',
        initialName: menu.name,
        initialDescription: menu.description,
        initialImageUrl: menu.imageUrl,
        onSave:
            (
              name,
              description,
              imageUrl,
              Uint8List? imageBytes,
              String imageExtension,
            ) async {
              final updatedMenu = MenuModel(
                id: menu.id,
                name: name,
                description: description,
                imageUrl: imageUrl,
                isActive: menu.isActive,
                createdBy: menu.createdBy,
                createdAt: menu.createdAt,
                updatedAt: DateTime.now(),
              );
              await _menuNotifier.updateMenu(updatedMenu);
            },
      ),
    );
  }
}

// MenuFormDialog remains the same as in your original code
class MenuFormDialog extends StatefulWidget {
  final String title;
  final String? initialName;
  final String? initialDescription;
  final String? initialImageUrl;

  final Future<void> Function(
    String name,
    String? description,
    String? imageUrl,
    Uint8List? imageBytes,
    String imageExtension,
  )
  onSave;

  const MenuFormDialog({
    super.key,
    required this.title,
    required this.onSave,
    this.initialName,
    this.initialDescription,
    this.initialImageUrl,
  });

  @override
  State<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _imageUrlController;
  Uint8List? bytes;
  String extension = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _imageUrlController = TextEditingController(text: widget.initialImageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePicker = ImagePicker();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Menu Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a menu name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imageUrlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL (Optional)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.hasScheme) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Pick image
                    final XFile? image = await imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                    );

                    if (image != null) {
                      // Get bytes
                      bytes = await image.readAsBytes();
                      extension = image.name.split('.').last;
                    }
                  } catch (e) {
                    print('Error: $e');
                  }
                },
                child: const Text('Pick Product Image'),
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
        FilledButton(
          onPressed: _isSaving
              ? null
              : () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isSaving = true);
                  try {
                    await widget.onSave(
                      _nameController.text.trim(),
                      _descriptionController.text.trim().isEmpty
                          ? null
                          : _descriptionController.text.trim(),
                      _imageUrlController.text.trim().isEmpty
                          ? null
                          : _imageUrlController.text.trim(),
                      bytes,
                      extension,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menu saved successfully.')),
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isSaving = false);
                    final message = e.toString().contains('already exists')
                        ? 'Menu already exists.'
                        : 'Failed to save menu: $e';
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(message)));
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hotel_management_system/data/models/menu_model.dart';
// import 'package:hotel_management_system/state_management/app_providers.dart';
// import 'package:hotel_management_system/state_management/menu_state_and_notifier.dart';

// // Dummy permission service
// class PermissionService {
//   static bool canCreateMenu() => true; // Replace with actual logic
//   static bool canEditMenu() => true; // Replace with actual logic
//   static bool canDeleteMenu() => true; // Replace with actual logic
//   static bool canToggleMenuStatus() => true; // Replace with actual logic
// }

// class MenuManagementScreen extends ConsumerStatefulWidget {
//   const MenuManagementScreen({super.key});

//   @override
//   ConsumerState<MenuManagementScreen> createState() =>
//       _MenuManagementScreenState();
// }

// class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   final menuNotifierProvider = menuProvider;
//   String _searchQuery = '';
//   // will be initialized in initState
//   late MenuNotifier _menuNotifier;
//   late String businessId;
//   late String branchId;

//   @override
//   void initState() {
//     super.initState();
//     // Load menus when screen initializes
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       businessId = ref.read(userProvider).selectedUser!.primarybusinessId;
//       branchId = ref.read(userProvider).selectedUser!.primaryBranchId;
//       _menuNotifier = ref.read(
//         menuProvider((branchId: branchId, businessId: businessId)).notifier,
//       );
//       _menuNotifier.loadAllMenus();
//       _menuNotifier.loadAllMenus();
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   List<MenuModel> _filterMenus(List<MenuModel> menus) {
//     if (_searchQuery.isEmpty) return menus;
//     return menus
//         .where(
//           (menu) =>
//               menu.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
//               (menu.description?.toLowerCase().contains(
//                     _searchQuery.toLowerCase(),
//                   ) ??
//                   false),
//         )
//         .toList();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final menuState = ref.watch(
//       menuNotifierProvider((branchId: branchId, businessId: businessId)),
//     );
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Menu Management'),
//         centerTitle: true,
//         elevation: 0,
//         actions: [
//           if (PermissionService.canCreateMenu())
//             IconButton(
//               onPressed: () => _showCreateMenuDialog(context),
//               icon: const Icon(Icons.add),
//               tooltip: 'Add Menu',
//             ),
//           IconButton(
//             onPressed: () => _menuNotifier.loadAllMenus(),
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Search Bar
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: SearchBar(
//               controller: _searchController,
//               hintText: 'Search menus...',
//               leading: const Icon(Icons.search),
//               trailing: _searchQuery.isNotEmpty
//                   ? [
//                       IconButton(
//                         onPressed: () {
//                           _searchController.clear();
//                           setState(() => _searchQuery = '');
//                         },
//                         icon: const Icon(Icons.clear),
//                       ),
//                     ]
//                   : null,
//               onChanged: (value) => setState(() => _searchQuery = value),
//             ),
//           ),

//           // Content Area
//           Expanded(child: _buildContent(menuState, colorScheme)),
//         ],
//       ),
//       floatingActionButton: PermissionService.canCreateMenu()
//           ? FloatingActionButton.extended(
//               onPressed: () => _showCreateMenuDialog(context),
//               icon: const Icon(Icons.add),
//               label: const Text('Add Menu'),
//             )
//           : null,
//     );
//   }

//   Widget _buildContent(MenuState state, ColorScheme colorScheme) {
//     if (state.isLoading && state.menus.isEmpty) {
//       return const Center(child: CircularProgressIndicator());
//     }

//     if (state.error != null) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.error_outline, size: 64, color: colorScheme.error),
//             const SizedBox(height: 16),
//             Text(
//               'Error loading menus',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               state.error!,
//               textAlign: TextAlign.center,
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//             ),
//             const SizedBox(height: 16),
//             FilledButton.icon(
//               onPressed: () => _menuNotifier.loadAllMenus(),
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }

//     final filteredMenus = _filterMenus(state.menus);

//     if (filteredMenus.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _searchQuery.isNotEmpty
//                   ? Icons.search_off
//                   : Icons.restaurant_menu,
//               size: 64,
//               color: colorScheme.onSurfaceVariant,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               _searchQuery.isNotEmpty ? 'No menus found' : 'No menus available',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _searchQuery.isNotEmpty
//                   ? 'Try adjusting your search terms'
//                   : 'Get started by adding your first menu',
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//             ),
//             if (_searchQuery.isEmpty && PermissionService.canCreateMenu()) ...[
//               const SizedBox(height: 16),
//               FilledButton.icon(
//                 onPressed: () => _showCreateMenuDialog(context),
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Menu'),
//               ),
//             ],
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: () => _menuNotifier.loadAllMenus(),
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           // Responsive layout
//           if (constraints.maxWidth > 1200) {
//             // Desktop: 3 columns
//             return _buildGridView(filteredMenus, 3);
//           } else if (constraints.maxWidth > 800) {
//             // Tablet: 2 columns
//             return _buildGridView(filteredMenus, 2);
//           } else {
//             // Mobile: List view
//             return _buildListView(filteredMenus, state.isLoading);
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildListView(List<MenuModel> menus, bool isLoading) {
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       itemCount: menus.length + (isLoading ? 1 : 0),
//       itemBuilder: (context, index) {
//         if (index == menus.length && isLoading) {
//           return const Center(
//             child: Padding(
//               padding: EdgeInsets.all(16),
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }

//         final menu = menus[index];
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 8),
//           child: _buildMenuCard(menu, isListView: true),
//         );
//       },
//     );
//   }

//   Widget _buildGridView(List<MenuModel> menus, int crossAxisCount) {
//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: crossAxisCount,
//         childAspectRatio: 0.8,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//       ),
//       itemCount: menus.length,
//       itemBuilder: (context, index) => _buildMenuCard(menus[index]),
//     );
//   }

//   Widget _buildMenuCard(MenuModel menu, {bool isListView = false}) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     if (isListView) {
//       return Dismissible(
//         key: Key(menu.id),
//         background: _buildSwipeBackground(
//           Colors.blue,
//           Icons.edit,
//           'Edit',
//           isLeft: true,
//         ),
//         secondaryBackground: PermissionService.canDeleteMenu()
//             ? _buildSwipeBackground(colorScheme.error, Icons.delete, 'Delete')
//             : null,
//         confirmDismiss: (direction) async {
//           if (direction == DismissDirection.startToEnd) {
//             if (PermissionService.canEditMenu()) {
//               _showEditMenuDialog(context, menu);
//             }
//             return false;
//           } else if (direction == DismissDirection.endToStart) {
//             if (PermissionService.canDeleteMenu()) {
//               return await _showDeleteConfirmation(context, menu);
//             }
//           }
//           return false;
//         },
//         child: _buildMenuListTile(menu, theme, colorScheme),
//       );
//     } else {
//       return _buildMenuGridCard(menu, theme, colorScheme);
//     }
//   }

//   Widget _buildSwipeBackground(
//     Color color,
//     IconData icon,
//     String text, {
//     bool isLeft = false,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(12),
//       ),
//       alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
//       padding: const EdgeInsets.symmetric(horizontal: 20),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(icon, color: Colors.white, size: 28),
//           const SizedBox(height: 4),
//           Text(
//             text,
//             style: const TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.bold,
//               fontSize: 12,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuListTile(
//     MenuModel menu,
//     ThemeData theme,
//     ColorScheme colorScheme,
//   ) {
//     return Card(
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(16),
//         leading: _buildMenuImage(menu.imageUrl, size: 56),
//         title: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 menu.name,
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             _buildStatusChip(menu.isActive, colorScheme),
//           ],
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             if (menu.description != null) ...[
//               const SizedBox(height: 4),
//               Text(
//                 menu.description!,
//                 maxLines: 2,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//             const SizedBox(height: 8),
//             Text(
//               'Created: ${_formatDate(menu.createdAt)}',
//               style: theme.textTheme.bodySmall?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//             ),
//           ],
//         ),
//         trailing: PopupMenuButton(
//           itemBuilder: (context) => _buildPopupMenuItems(menu),
//         ),
//       ),
//     );
//   }

//   Widget _buildMenuGridCard(
//     MenuModel menu,
//     ThemeData theme,
//     ColorScheme colorScheme,
//   ) {
//     return Card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 3,
//             child: Container(
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 borderRadius: const BorderRadius.vertical(
//                   top: Radius.circular(12),
//                 ),
//                 color: colorScheme.surfaceVariant,
//               ),
//               child: _buildMenuImage(menu.imageUrl),
//             ),
//           ),
//           Expanded(
//             flex: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Expanded(
//                         child: Text(
//                           menu.name,
//                           style: theme.textTheme.titleMedium?.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       _buildStatusChip(menu.isActive, colorScheme),
//                     ],
//                   ),
//                   if (menu.description != null) ...[
//                     const SizedBox(height: 4),
//                     Expanded(
//                       child: Text(
//                         menu.description!,
//                         style: theme.textTheme.bodySmall,
//                         maxLines: 2,
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ],
//                   const Spacer(),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         _formatDate(menu.createdAt),
//                         style: theme.textTheme.bodySmall?.copyWith(
//                           color: colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                       PopupMenuButton(
//                         itemBuilder: (context) => _buildPopupMenuItems(menu),
//                         child: Icon(
//                           Icons.more_vert,
//                           color: colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildMenuImage(String? imageUrl, {double? size}) {
//     if (imageUrl != null && imageUrl.isNotEmpty) {
//       return ClipRRect(
//         borderRadius: BorderRadius.circular(size != null ? 8 : 12),
//         child: Image.network(
//           imageUrl,
//           width: size,
//           height: size,
//           fit: BoxFit.cover,
//           errorBuilder: (context, error, stackTrace) =>
//               _buildPlaceholderImage(size),
//         ),
//       );
//     }
//     return _buildPlaceholderImage(size);
//   }

//   Widget _buildPlaceholderImage(double? size) {
//     return Container(
//       width: size,
//       height: size,
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surfaceVariant,
//         borderRadius: BorderRadius.circular(size != null ? 8 : 12),
//       ),
//       child: Icon(
//         Icons.restaurant_menu,
//         size: size != null ? size * 0.4 : 48,
//         color: Theme.of(context).colorScheme.onSurfaceVariant,
//       ),
//     );
//   }

//   Widget _buildStatusChip(bool isActive, ColorScheme colorScheme) {
//     return Chip(
//       label: Text(
//         isActive ? 'Active' : 'Inactive',
//         style: TextStyle(
//           fontSize: 12,
//           color: isActive ? colorScheme.onPrimary : colorScheme.onSecondary,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: isActive ? colorScheme.primary : colorScheme.secondary,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     );
//   }

//   List<PopupMenuEntry> _buildPopupMenuItems(MenuModel menu) {
//     return [
//       if (PermissionService.canEditMenu())
//         PopupMenuItem(
//           value: 'edit',
//           child: const ListTile(
//             leading: Icon(Icons.edit),
//             title: Text('Edit'),
//             contentPadding: EdgeInsets.zero,
//           ),
//           onTap: () => _showEditMenuDialog(context, menu),
//         ),
//       if (PermissionService.canToggleMenuStatus())
//         PopupMenuItem(
//           value: 'toggle',
//           child: ListTile(
//             leading: Icon(
//               menu.isActive ? Icons.visibility_off : Icons.visibility,
//             ),
//             title: Text(menu.isActive ? 'Deactivate' : 'Activate'),
//             contentPadding: EdgeInsets.zero,
//           ),
//           onTap: () => _toggleMenuStatus(menu),
//         ),
//       if (PermissionService.canDeleteMenu())
//         PopupMenuItem(
//           value: 'delete',
//           child: ListTile(
//             leading: Icon(
//               Icons.delete,
//               color: Theme.of(context).colorScheme.error,
//             ),
//             title: Text(
//               'Delete',
//               style: TextStyle(color: Theme.of(context).colorScheme.error),
//             ),
//             contentPadding: EdgeInsets.zero,
//           ),
//           onTap: () => _showDeleteConfirmation(context, menu),
//         ),
//     ];
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   void _toggleMenuStatus(MenuModel menu) {
//     _menuNotifier.toggleMenuActiveStatus(menu.id, !menu.isActive);
//   }

//   Future<bool> _showDeleteConfirmation(
//     BuildContext context,
//     MenuModel menu,
//   ) async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Delete Menu'),
//             content: Text(
//               'Are you sure you want to delete "${menu.name}"? This action cannot be undone.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('Cancel'),
//               ),
//               FilledButton(
//                 onPressed: () {
//                   _menuNotifier.deleteMenu(menu.id);
//                   Navigator.of(context).pop(true);
//                 },
//                 style: FilledButton.styleFrom(
//                   backgroundColor: Theme.of(context).colorScheme.error,
//                 ),
//                 child: const Text('Delete'),
//               ),
//             ],
//           ),
//         ) ??
//         false;
//   }

//   void _showCreateMenuDialog(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (context) => MenuFormDialog(
//         title: 'Create Menu',
//         onSave: (name, description, imageUrl) {
//           _menuNotifier.createMenu(
//             name: name,
//             description: description,
//             imageUrl: imageUrl,
//             createdBy: 'current_user_id', // Replace with actual user ID
//           );
//         },
//       ),
//     );
//   }

//   void _showEditMenuDialog(BuildContext context, MenuModel menu) {
//     showDialog(
//       context: context,
//       builder: (context) => MenuFormDialog(
//         title: 'Edit Menu',
//         initialName: menu.name,
//         initialDescription: menu.description,
//         initialImageUrl: menu.imageUrl,
//         onSave: (name, description, imageUrl) {
//           final updatedMenu = MenuModel(
//             id: menu.id,
//             name: name,
//             description: description,
//             imageUrl: imageUrl,
//             isActive: menu.isActive,
//             createdBy: menu.createdBy,
//             createdAt: menu.createdAt,
//             updatedAt: DateTime.now(),
//           );
//           _menuNotifier.updateMenu(updatedMenu);
//         },
//       ),
//     );
//   }
// }

// class MenuFormDialog extends StatefulWidget {
//   final String title;
//   final String? initialName;
//   final String? initialDescription;
//   final String? initialImageUrl;
//   final Function(String name, String? description, String? imageUrl) onSave;

//   const MenuFormDialog({
//     super.key,
//     required this.title,
//     required this.onSave,
//     this.initialName,
//     this.initialDescription,
//     this.initialImageUrl,
//   });

//   @override
//   State<MenuFormDialog> createState() => _MenuFormDialogState();
// }

// class _MenuFormDialogState extends State<MenuFormDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late final TextEditingController _nameController;
//   late final TextEditingController _descriptionController;
//   late final TextEditingController _imageUrlController;

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.initialName);
//     _descriptionController = TextEditingController(
//       text: widget.initialDescription,
//     );
//     _imageUrlController = TextEditingController(text: widget.initialImageUrl);
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _imageUrlController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(widget.title),
//       content: SizedBox(
//         width: MediaQuery.of(context).size.width * 0.8,
//         child: Form(
//           key: _formKey,
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextFormField(
//                 controller: _nameController,
//                 decoration: const InputDecoration(
//                   labelText: 'Menu Name',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value == null || value.trim().isEmpty) {
//                     return 'Please enter a menu name';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _descriptionController,
//                 decoration: const InputDecoration(
//                   labelText: 'Description (Optional)',
//                   border: OutlineInputBorder(),
//                 ),
//                 maxLines: 3,
//               ),
//               const SizedBox(height: 16),
//               TextFormField(
//                 controller: _imageUrlController,
//                 decoration: const InputDecoration(
//                   labelText: 'Image URL (Optional)',
//                   border: OutlineInputBorder(),
//                 ),
//                 validator: (value) {
//                   if (value != null && value.isNotEmpty) {
//                     final uri = Uri.tryParse(value);
//                     if (uri == null || !uri.hasScheme) {
//                       return 'Please enter a valid URL';
//                     }
//                   }
//                   return null;
//                 },
//               ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: () => Navigator.of(context).pop(),
//           child: const Text('Cancel'),
//         ),
//         FilledButton(
//           onPressed: () {
//             if (_formKey.currentState!.validate()) {
//               widget.onSave(
//                 _nameController.text.trim(),
//                 _descriptionController.text.trim().isEmpty
//                     ? null
//                     : _descriptionController.text.trim(),
//                 _imageUrlController.text.trim().isEmpty
//                     ? null
//                     : _imageUrlController.text.trim(),
//               );
//               Navigator.of(context).pop();
//             }
//           },
//           child: const Text('Save'),
//         ),
//       ],
//     );
//   }
// }
