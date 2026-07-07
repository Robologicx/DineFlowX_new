import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/category_model.dart';
import 'package:hotel_management_system/data/models/menu_model.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/category_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/menu_state_and_notifier.dart';
import 'package:image_picker/image_picker.dart';

class CategoryManagementScreen extends ConsumerStatefulWidget {
  final String? menuId; // Optional: filter by specific menu
  final String? menuName; // For display purposes

  const CategoryManagementScreen({super.key, this.menuId, this.menuName});

  @override
  ConsumerState<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState
    extends ConsumerState<CategoryManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedMenuFilter;
  late String businessId;
  late String branchId;

  @override
  void initState() {
    super.initState();
    businessId = ref.read(userProvider).selectedUser!.primarybusinessId;
    branchId = ref.read(userProvider).selectedUser!.primaryBranchId;

    // Load categories when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final CategoryNotifier notifier = ref.read(
        categoryProvider((branchId: branchId, businessId: businessId)).notifier,
      );

      if (widget.menuId != null) {
        _selectedMenuFilter = widget.menuId;
      }

      // Keep provider state as full category set.
      // Screen-level filtering is applied locally via _selectedMenuFilter.
      notifier.loadAllCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<CategoryModel> _filterCategories(List<CategoryModel> categories) {
    var filtered = categories;

    // Filter by selected menu if any
    if (_selectedMenuFilter != null && _selectedMenuFilter!.isNotEmpty) {
      filtered = filtered
          .where((category) => category.menuId == _selectedMenuFilter)
          .toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (category) => category.name.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(
      categoryProvider((branchId: branchId, businessId: businessId)),
    );
    final CategoryNotifier notifier = ref.read(
      categoryProvider((branchId: branchId, businessId: businessId)).notifier,
    );
    final menuState = ref.watch(
      menuProvider((branchId: branchId, businessId: businessId)),
    );

    final user = ref.read(userProvider.notifier);
    bool canCreateCategory = user.hasPermissionOfCurrentUser(
      Permissions.createCategory,
    );
    bool canEditCategory = user.hasPermissionOfCurrentUser(
      Permissions.updateCategory,
    );
    bool canDeleteCategory = user.hasPermissionOfCurrentUser(
      Permissions.deleteCategory,
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.menuName != null
              ? '${widget.menuName} Categories'
              : 'Category Management',
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (canCreateCategory)
            IconButton(
              onPressed: () => _showCreateCategoryDialog(
                context,
                menuState.menus,
                notifier,
                businessId,
                branchId,
              ),
              icon: const Icon(Icons.add),
              tooltip: 'Add Category',
            ),
          IconButton(
            onPressed: () => _refreshCategories(notifier),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Search Bar
                SearchBar(
                  controller: _searchController,
                  hintText: 'Search categories...',
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

                // Menu Filter (only show if not filtering by specific menu)
                if (widget.menuId == null) ...[
                  const SizedBox(height: 12),
                  _buildMenuFilter(menuState.menus, colorScheme, notifier),
                ],
              ],
            ),
          ),

          // Content Area
          Expanded(
            child: _buildContent(
              categoryState,
              menuState.menus,
              colorScheme,
              notifier,
              menuState,
              canCreateCategory,
              canEditCategory,
              canDeleteCategory,
              businessId,
              branchId,
            ),
          ),
        ],
      ),
      floatingActionButton: canCreateCategory
          ? FloatingActionButton.extended(
              onPressed: () => _showCreateCategoryDialog(
                context,
                menuState.menus,
                notifier,
                businessId,
                branchId,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Add Category'),
            )
          : null,
    );
  }

  Widget _buildMenuFilter(
    List<MenuModel> menus,
    ColorScheme colorScheme,
    CategoryNotifier notifier,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String?>(
        value: _selectedMenuFilter,
        hint: const Text('Filter by Menu'),
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Menus'),
          ),
          ...menus.map(
            (menu) => DropdownMenuItem<String>(
              value: menu.id,
              child: Text(menu.name),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() => _selectedMenuFilter = value);
        },
      ),
    );
  }

  Widget _buildContent(
    CategoryState state,
    List<MenuModel> menus,
    ColorScheme colorScheme,
    CategoryNotifier notifier,
    MenuState menuState,
    bool canCreateCategory,
    bool canUpdateCategory,
    bool canDeleteCategory,
    String businessId,
    String branchId,
  ) {
    if (state.isLoading && state.categories.isEmpty) {
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
              'Error loading categories',
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
              onPressed: () => _refreshCategories(notifier),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredCategories = _filterCategories(state.categories);

    if (filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.category,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No categories found'
                  : 'No categories available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms'
                  : 'Get started by adding your first category',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (_searchQuery.isEmpty && canCreateCategory) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showCreateCategoryDialog(
                  context,
                  menus,
                  notifier,
                  businessId,
                  branchId,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refreshCategories(notifier),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout
          if (constraints.maxWidth > 1200) {
            // Desktop: 4 columns
            return _buildGridView(
              filteredCategories,
              menus,
              notifier,
              menuState,
              4,
              canDeleteCategory,
              canUpdateCategory,
            );
          } else if (constraints.maxWidth > 800) {
            // Tablet: 3 columns
            return _buildGridView(
              filteredCategories,
              menus,
              notifier,
              menuState,
              3,
              canDeleteCategory,
              canUpdateCategory,
            );
          } else {
            // Mobile: List view
            return _buildListView(
              filteredCategories,
              menus,
              state.isLoading,
              notifier,
              menuState,
              canDeleteCategory,
              canUpdateCategory,
            );
          }
        },
      ),
    );
  }

  Widget _buildListView(
    List<CategoryModel> categories,
    List<MenuModel> menus,
    bool isLoading,
    CategoryNotifier notifier,
    MenuState menuState,
    bool canDeleteCategory,
    bool canUpdateCategory,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: categories.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == categories.length && isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final category = categories[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildCategoryCard(
            category,
            menus,
            menuState,
            notifier,
            canDeleteCategory,
            canUpdateCategory,
            isListView: true,
          ),
        );
      },
    );
  }

  Widget _buildGridView(
    List<CategoryModel> categories,
    List<MenuModel> menus,
    CategoryNotifier notifier,
    MenuState menuState,
    int crossAxisCount,
    bool canDeleteCategory,
    bool canUpdateCategory,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.9,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) => _buildCategoryCard(
        categories[index],
        menus,
        menuState,
        notifier,
        canDeleteCategory,
        canUpdateCategory,
      ),
    );
  }

  Widget _buildCategoryCard(
    CategoryModel category,
    List<MenuModel> menus,
    MenuState state,
    CategoryNotifier notifier,
    bool canDeleteCategory,
    bool canUpdateCategory, {
    bool isListView = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final menuName = menus
        .firstWhere(
          (menu) => menu.id == category.menuId,
          orElse: () => MenuModel(
            id: '',
            name: 'Unknown Menu',
            isActive: false,
            createdBy: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .name;

    if (isListView) {
      return Dismissible(
        key: Key(category.id),
        background: _buildSwipeBackground(
          Colors.blue,
          Icons.edit,
          'Edit',
          isLeft: true,
        ),
        secondaryBackground: canDeleteCategory
            ? _buildSwipeBackground(colorScheme.error, Icons.delete, 'Delete')
            : null,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            if (canUpdateCategory) {
              _showEditCategoryDialog(context, category, menus, notifier);
            }
            return false;
          } else if (direction == DismissDirection.endToStart) {
            if (canDeleteCategory) {
              return await _showDeleteConfirmation(context, category, notifier);
            }
          }
          return false;
        },
        child: _buildCategoryListTile(
          category,
          menuName,
          theme,
          colorScheme,
          state,
          notifier,
          canDeleteCategory,
          canUpdateCategory,
        ),
      );
    } else {
      return _buildCategoryGridCard(
        category,
        menuName,
        theme,
        colorScheme,
        state,
        notifier,
        canDeleteCategory,
        canUpdateCategory,
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

  Widget _buildCategoryListTile(
    CategoryModel category,
    String menuName,
    ThemeData theme,
    ColorScheme colorScheme,
    MenuState state,
    CategoryNotifier notifier,
    bool canDeleteCategory,
    bool canUpdateCategory,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildCategoryImage(category.imageUrl, size: 56),
        title: Text(
          category.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                menuName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Created: ${_formatDate(category.createdAt)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => _buildPopupMenuItems(
            category,
            menuName,
            state,
            notifier,
            canDeleteCategory,
            canUpdateCategory,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryGridCard(
    CategoryModel category,
    String menuName,
    ThemeData theme,
    ColorScheme colorScheme,
    MenuState state,
    CategoryNotifier notifier,
    bool canDeleteCategory,
    bool canUpdateCategory,
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
              child: _buildCategoryImage(category.imageUrl),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      menuName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _formatDate(category.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) => _buildPopupMenuItems(
                          category,
                          menuName,
                          state,
                          notifier,
                          canDeleteCategory,
                          canUpdateCategory,
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

  Widget _buildCategoryImage(String? imageUrl, {double? size}) {
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
        Icons.category,
        size: size != null ? size * 0.4 : 48,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }

  List<PopupMenuEntry> _buildPopupMenuItems(
    CategoryModel category,
    String menuName,
    MenuState state,
    CategoryNotifier notifier,
    bool canUpdateCategory,
    bool canDeleteCategory,
  ) {
    return [
      if (canUpdateCategory)
        PopupMenuItem(
          value: 'edit',
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () =>
              _showEditCategoryDialog(context, category, state.menus, notifier),
        ),
      if (canDeleteCategory)
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
          onTap: () => _showDeleteConfirmation(context, category, notifier),
        ),
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _refreshCategories(CategoryNotifier notifier) async {
    await notifier.loadAllCategories();
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    CategoryModel category,
    CategoryNotifier notifier,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Category'),
            content: Text(
              'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  notifier.deleteCategory(category.id);
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

  void _showCreateCategoryDialog(
    BuildContext context,
    List<MenuModel> menus,
    CategoryNotifier notifier,
    String businessId,
    String branchId,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(
        title: 'Create Category',
        menus: menus,
        initialMenuId:
            widget.menuId, // Pre-select menu if coming from menu screen
        onSave: (name, menuId, imageUrl, imageBytes, imageExtension) async {
          final category = CategoryModel(
            id: DateTime.now().millisecondsSinceEpoch
                .toString(), // Temporary ID
            name: name,
            menuId: menuId,
            imageUrl: imageUrl,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await notifier.addCategory(
            category,
            imageBytes,
            imageExtension,
            businessId,
            branchId,
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(
    BuildContext context,
    CategoryModel category,
    List<MenuModel> menus,
    CategoryNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CategoryFormDialog(
        title: 'Edit Category',
        menus: menus,
        initialName: category.name,
        initialMenuId: category.menuId,
        initialImageUrl: category.imageUrl,
        onSave: (name, menuId, imageUrl, imageFile, imageBytes) async {
          await notifier.updateCategory(category.id, {
            'name': name,
            'menuId': menuId,
            'imageUrl': imageUrl,
          });
        },
      ),
    );
  }
}

class CategoryFormDialog extends StatefulWidget {
  final String title;
  final List<MenuModel> menus;
  final String? initialName;
  final String? initialMenuId;
  final String? initialImageUrl;

  final Future<void> Function(
    String name,
    String menuId,
    String? imageUrl,
    Uint8List? imageBytes,
    String imageExtension,
  )
  onSave;

  const CategoryFormDialog({
    super.key,
    required this.title,
    required this.menus,
    required this.onSave,
    this.initialName,
    this.initialMenuId,
    this.initialImageUrl,
  });

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _imageUrlController;
  String? _selectedMenuId;
  Uint8List? bytes;
  String extension = '';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _imageUrlController = TextEditingController(text: widget.initialImageUrl);
    _selectedMenuId = widget.initialMenuId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePicker = ImagePicker();
    final activeMenus = widget.menus.where((menu) => menu.isActive).toList();

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
                  labelText: 'Category Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a category name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedMenuId,
                decoration: const InputDecoration(
                  labelText: 'Select Menu',
                  border: OutlineInputBorder(),
                ),
                items: activeMenus
                    .map(
                      (menu) => DropdownMenuItem(
                        value: menu.id,
                        child: Text(menu.name),
                      ),
                    )
                    .toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a menu';
                  }
                  return null;
                },
                onChanged: (value) => setState(() => _selectedMenuId = value),
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
                      _selectedMenuId!,
                      _imageUrlController.text.trim().isEmpty
                          ? null
                          : _imageUrlController.text.trim(),
                      bytes,
                      extension,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Category saved successfully.'),
                      ),
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isSaving = false);
                    final message = e.toString().contains('already exists')
                        ? 'Category already exists.'
                        : 'Failed to save category: $e';
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

// Extension to add copyWith method to CategoryModel (add this to your model file)
extension CategoryModelExtension on CategoryModel {
  CategoryModel copyWith({
    String? id,
    String? name,
    String? menuId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      menuId: menuId ?? this.menuId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
