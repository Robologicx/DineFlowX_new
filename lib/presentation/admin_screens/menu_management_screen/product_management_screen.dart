import 'dart:developer';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/data/models/category_model.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/product_state_and_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class ProductManagementScreen extends ConsumerStatefulWidget {
  final String? categoryId; // Optional: filter by specific category
  final String? categoryName; // For display purposes
  late bool canCreateProduct = false;
  late bool canEditProduct = false;
  late bool canDeleteProduct = false;

  ProductManagementScreen({super.key, this.categoryId, this.categoryName});

  @override
  ConsumerState<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState
    extends ConsumerState<ProductManagementScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryFilter;
  bool _showAvailableOnly = false;
  List<CategoryModel> _categories = [];
  late String branchId;
  late String businessId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider).selectedUser;
      if (user == null) return;

      branchId = user.primaryBranchId;
      businessId = user.primarybusinessId;

      // Load categories
      ref
          .read(
            categoryProvider((
              branchId: user.primaryBranchId,
              businessId: user.primarybusinessId,
            )).notifier,
          )
          .loadAllCategories()
          .then((categories) {
            setState(() {
              _categories = categories;
            });
          });

      // Load products
      final productNotifier = ref.read(
        productProvider((
          branchId: user.primaryBranchId,
          businessId: user.primarybusinessId,
        )).notifier,
      );

      if (widget.categoryId != null) {
        productNotifier.loadProductsByCategory(widget.categoryId!);
        setState(() {
          _selectedCategoryFilter = widget.categoryId;
        });
      } else {
        productNotifier.loadAllProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> _filterProducts(List<ProductModel> products) {
    var filtered = products;

    // Filter by selected category if any
    if (_selectedCategoryFilter != null &&
        _selectedCategoryFilter!.isNotEmpty) {
      filtered = filtered
          .where((product) => product.categoryId == _selectedCategoryFilter)
          .toList();
    }

    // Filter by availability
    if (_showAvailableOnly) {
      filtered = filtered.where((product) => product.isAvailable).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where(
            (product) =>
                product.name.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ) ||
                product.description.toLowerCase().contains(
                  _searchQuery.toLowerCase(),
                ),
          )
          .toList();
    }

    return filtered;
  }

  ProductNotifier get _productNotifier {
    final user = ref.read(userProvider).selectedUser!;
    return ref.read(
      productProvider((
        branchId: user.primaryBranchId,
        businessId: user.primarybusinessId,
      )).notifier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).selectedUser;

    if (user == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final userNotifier = ref.read(userProvider.notifier);
    widget.canCreateProduct = userNotifier.hasPermissionOfCurrentUser(
      Permissions.createProduct,
    );
    widget.canEditProduct = userNotifier.hasPermissionOfCurrentUser(
      Permissions.updateProduct,
    );
    widget.canDeleteProduct = userNotifier.hasPermissionOfCurrentUser(
      Permissions.deleteProduct,
    );

    final productsAsync = ref.watch(
      productProvider((
        branchId: user.primaryBranchId,
        businessId: user.primarybusinessId,
      )),
    );

    final categoryState = ref.watch(
      categoryProvider((
        branchId: user.primaryBranchId,
        businessId: user.primarybusinessId,
      )),
    );

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.categoryName != null
              ? '${widget.categoryName} Products'
              : 'Product Management',
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          if (widget.canCreateProduct)
            IconButton(
              onPressed: () =>
                  _showCreateProductDialog(context, categoryState.categories),
              icon: const Icon(Icons.add),
              tooltip: 'Add Product',
            ),
          IconButton(
            onPressed: () => _refreshProducts(),
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
                  hintText: 'Search products...',
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

                const SizedBox(height: 12),

                // Filters Row
                Row(
                  children: [
                    // Category Filter (only show if not filtering by specific category)
                    if (widget.categoryId == null) ...[
                      Expanded(
                        child: _buildCategoryFilter(
                          categoryState.categories,
                          colorScheme,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],

                    // Availability Filter
                    FilterChip(
                      label: const Text('Available Only'),
                      selected: _showAvailableOnly,
                      onSelected: (selected) =>
                          setState(() => _showAvailableOnly = selected),
                      avatar: Icon(
                        _showAvailableOnly
                            ? Icons.check_circle
                            : Icons.visibility,
                        size: 18,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content Area
          // Content Area
          Expanded(
            child: _buildContent(
              productsAsync,
              categoryState.categories,
              colorScheme,
            ),
          ),
        ],
      ),
      floatingActionButton: widget.canCreateProduct
          ? FloatingActionButton.extended(
              onPressed: () =>
                  _showCreateProductDialog(context, categoryState.categories),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            )
          : null,
    );
  }

  Widget _buildContent(
    ProductState state,
    List<CategoryModel> categories,
    ColorScheme colorScheme,
  ) {
    if (state.isLoading && state.products.isEmpty) {
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
              'Error loading products',
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
              onPressed: () => _refreshProducts(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredProducts = _filterProducts(state.products);

    if (filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No products found'
                  : 'No products available',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try adjusting your search terms or filters'
                  : 'Get started by adding your first product',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && widget.canCreateProduct) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => _showCreateProductDialog(context, categories),
                icon: const Icon(Icons.add),
                label: const Text('Add Product'),
              ),
            ],
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _refreshProducts(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive layout
          if (constraints.maxWidth > 1200) {
            // Desktop: 3 columns
            return _buildGridView(filteredProducts, categories, 3);
          } else if (constraints.maxWidth > 800) {
            // Tablet: 2 columns
            return _buildGridView(filteredProducts, categories, 2);
          } else {
            // Mobile: List view
            return _buildListView(
              filteredProducts,
              categories,
              state.isLoading,
            );
          }
        },
      ),
    );
  }

  Widget _buildCategoryFilter(
    List<CategoryModel> categories,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outline),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String?>(
        value: _selectedCategoryFilter,
        hint: const Text('Filter by Category'),
        isExpanded: true,
        underline: const SizedBox(),
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('All Categories'),
          ),
          ...categories.map(
            (category) => DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.name),
            ),
          ),
        ],
        onChanged: (value) {
          setState(() => _selectedCategoryFilter = value);
          if (value != null) {
            _productNotifier.loadProductsByCategory(value);
          } else {
            _productNotifier.loadAllProducts();
          }
        },
      ),
    );
  }

  Widget _buildListView(
    List<ProductModel> products,
    List<CategoryModel> categories,
    bool isLoading,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: products.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == products.length && isLoading) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final product = products[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildProductCard(product, categories, isListView: true),
        );
      },
    );
  }

  Widget _buildGridView(
    List<ProductModel> products,
    List<CategoryModel> categories,
    int crossAxisCount,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) =>
          _buildProductCard(products[index], categories),
    );
  }

  Widget _buildProductCard(
    ProductModel product,
    List<CategoryModel> categories, {
    bool isListView = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryName = categories
        .firstWhere(
          (category) => category.id == product.categoryId,
          orElse: () => CategoryModel(
            id: '',
            name: 'Unknown Category',
            menuId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        )
        .name;

    if (isListView) {
      return Dismissible(
        key: Key(product.productId),
        background: _buildSwipeBackground(
          Colors.blue,
          Icons.edit,
          'Edit',
          isLeft: true,
        ),
        secondaryBackground: widget.canDeleteProduct
            ? _buildSwipeBackground(colorScheme.error, Icons.delete, 'Delete')
            : null,
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            if (widget.canEditProduct) {
              _showEditProductDialog(context, product, categories);
            }
            return false;
          } else if (direction == DismissDirection.endToStart) {
            if (widget.canDeleteProduct) {
              return await _showDeleteConfirmation(context, product);
            }
          }
          return false;
        },
        child: _buildProductListTile(product, categoryName, theme, colorScheme),
      );
    } else {
      return _buildProductGridCard(product, categoryName, theme, colorScheme);
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

  Widget _buildProductListTile(
    ProductModel product,
    String categoryName,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildProductImage(product.imageUrl, size: 60),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            _buildAvailabilityChip(product.isAvailable, colorScheme),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              product.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    categoryName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  '\$${product.price.toStringAsFixed(2)}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildRatingDisplay(
                  product.averageRating,
                  product.reviewCount,
                  theme,
                ),
                const Spacer(),
                Text(
                  'Added: ${_formatDate(product.createdAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => _buildPopupMenuItems(product, _categories),
        ),
      ),
    );
  }

  Widget _buildProductGridCard(
    ProductModel product,
    String categoryName,
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    color: colorScheme.surfaceContainerHighest,
                  ),
                  child: _buildProductImage(product.imageUrl),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: _buildAvailabilityChip(
                    product.isAvailable,
                    colorScheme,
                  ),
                ),
              ],
            ),
          ),

          // Product Details
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: theme.textTheme.bodySmall,
                    maxLines: 2,
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
                      categoryName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      PopupMenuButton(
                        itemBuilder: (context) =>
                            _buildPopupMenuItems(product, _categories),
                        child: Icon(
                          Icons.more_vert,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _buildRatingDisplay(
                    product.averageRating,
                    product.reviewCount,
                    theme,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _processGoogleDriveUrl(String url) {
    if (url.contains('drive.google.com')) {
      // Extract file ID from different Google Drive URL formats
      String? fileId;

      // Format 1: https://drive.google.com/file/d/FILE_ID/view
      if (url.contains('/file/d/')) {
        final regex = RegExp(r'/file/d/([a-zA-Z0-9_-]+)');
        final match = regex.firstMatch(url);
        fileId = match?.group(1);
      }
      // Format 2: https://drive.google.com/open?id=FILE_ID
      else if (url.contains('id=')) {
        final regex = RegExp(r'[?&]id=([a-zA-Z0-9_-]+)');
        final match = regex.firstMatch(url);
        fileId = match?.group(1);
      }

      if (fileId != null) {
        // Return as direct download URL
        return 'https://drive.google.com/uc?export=download&id=$fileId';
      }
    }
    return url;
  }

  Widget _buildProductImage(String? imageUrl, {double? size}) {
    if (imageUrl != null && imageUrl.isNotEmpty) {
      final processedUrl = _processGoogleDriveUrl(imageUrl);

      if (processedUrl.startsWith('gs://')) {
        return FutureBuilder<String>(
          future: FirebaseStorage.instance
              .refFromURL(processedUrl)
              .getDownloadURL(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingPlaceholder(size);
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return _buildErrorPlaceholder(size);
            }
            return _buildNetworkImage(snapshot.data!, size);
          },
        );
      }

      return _buildNetworkImage(processedUrl, size);
    }
    return _buildPlaceholderImage(size);
  }

  Widget _buildNetworkImage(String url, double? size) {
    if (kIsWeb) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(size != null ? 8 : 12),
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildLoadingPlaceholder(size);
          },
          errorBuilder: (_, __, ___) => _buildErrorPlaceholder(size),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size != null ? 8 : 12),
      child: CachedNetworkImage(
        imageUrl: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, _) => _buildLoadingPlaceholder(size),
        errorWidget: (context, _, __) => _buildErrorPlaceholder(size),
      ),
    );
  }

  Widget _buildLoadingPlaceholder(double? size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size != null ? 8 : 12),
      ),
      child: Center(
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildErrorPlaceholder(double? size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(size != null ? 8 : 12),
      ),
      child: Center(
        child: Icon(
          Icons.broken_image,
          size: size != null ? size * 0.3 : 32,
          color: Theme.of(context).colorScheme.onErrorContainer,
        ),
      ),
    );
  }

  Widget _buildPlaceholderImage(double? size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(size != null ? 8 : 12),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2,
          size: size != null ? size * 0.4 : 48,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  // Widget _buildProductImage(String? imageUrl, {double? size}) {
  //   if (imageUrl != null && imageUrl.isNotEmpty) {
  //     return ClipRRect(
  //       borderRadius: BorderRadius.circular(size != null ? 8 : 12),
  //       child: CachedNetworkImage(
  //         imageUrl: imageUrl,
  //         width: size,
  //         height: size,
  //         fit: BoxFit.cover,
  //         placeholder: (context, url) => _buildPlaceholderImage(size),
  //         errorWidget: (context, url, error) => Text(error.toString()),
  //       ),
  //     );
  //   }
  //   return _buildPlaceholderImage(size);
  // }

  // Widget _buildPlaceholderImage(double? size) {
  //   return Container(
  //     width: size,
  //     height: size,
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.surfaceVariant,
  //       borderRadius: BorderRadius.circular(size != null ? 8 : 12),
  //     ),
  //     child: Icon(
  //       Icons.inventory_2,
  //       size: size != null ? size * 0.4 : 48,
  //       color: Theme.of(context).colorScheme.onSurfaceVariant,
  //     ),
  //   );
  // }

  Widget _buildAvailabilityChip(bool isAvailable, ColorScheme colorScheme) {
    return Chip(
      label: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: TextStyle(
          fontSize: 12,
          color: isAvailable ? colorScheme.onPrimary : colorScheme.onError,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: isAvailable ? colorScheme.primary : colorScheme.error,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildRatingDisplay(double rating, int reviewCount, ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          size: 14,
          color: rating > 0 ? Colors.amber : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 2),
        Text(
          rating.toStringAsFixed(1),
          style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
        ),
        Text(
          ' ($reviewCount)',
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 10,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  List<PopupMenuEntry> _buildPopupMenuItems(
    ProductModel product,
    List<CategoryModel> categories,
  ) {
    return [
      if (widget.canEditProduct)
        PopupMenuItem(
          value: 'edit',
          child: const ListTile(
            leading: Icon(Icons.edit),
            title: Text('Edit'),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _showEditProductDialog(context, product, categories),
        ),
      if (widget.canEditProduct)
        PopupMenuItem(
          value: 'toggle',
          child: ListTile(
            leading: Icon(
              product.isAvailable ? Icons.visibility_off : Icons.visibility,
            ),
            title: Text(
              product.isAvailable ? 'Mark Unavailable' : 'Mark Available',
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onTap: () => _toggleProductAvailability(product),
        ),
      if (widget.canDeleteProduct)
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
          onTap: () => _showDeleteConfirmation(context, product),
        ),
    ];
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _toggleProductAvailability(ProductModel product) {
    _productNotifier.toggleProductAvailability(
      product.productId,
      !product.isAvailable,
    );
  }

  Future<void> _refreshProducts() async {
    if (widget.categoryId != null) {
      _productNotifier.loadProductsByCategory(widget.categoryId!);
    } else {
      await _productNotifier.loadAllProducts();
    }
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    ProductModel product,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Product'),
            content: Text(
              'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  _productNotifier.deleteProduct(
                    product.productId,
                    product.imageUrl ?? '',
                  );
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

  void _showCreateProductDialog(
    BuildContext context,
    List<CategoryModel> categories,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(
        title: 'Create Product',
        categories: categories,
        initialCategoryId: widget
            .categoryId, // Pre-select category if coming from category screen
        onSave:
            (
              name,
              description,
              price,
              categoryId,
              imageUrl,
              imageBytes,
              imageExtension,
            ) async {
              final user = ref.read(userProvider).selectedUser;
              if (user == null) {
                throw Exception('User not found');
              }

              final product = ProductModel(
                productId: const Uuid().v4(),
                name: name,
                description: description,
                price: price,
                categoryId: categoryId,
                imageUrl: imageUrl,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
              await _productNotifier.createProduct(
                product,
                user.primarybusinessId,
                user.primaryBranchId,
                imageBytes,
                imageExtension,
              );
            },
      ),
    );
  }

  void _showEditProductDialog(
    BuildContext context,
    ProductModel product,
    List<CategoryModel> categories,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductFormDialog(
        title: 'Edit Product',
        categories: categories,
        initialName: product.name,
        initialDescription: product.description,
        initialPrice: product.price,
        initialCategoryId: product.categoryId,
        initialImageUrl: product.imageUrl,
        onSave:
            (
              name,
              description,
              price,
              categoryId,
              imageUrl,
              imageBytes,
              imageExtension,
            ) async {
              // Get user info here where ref is available
              final user = ref.read(userProvider).selectedUser;
              if (user == null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('User not found')));
                return;
              }

              // Create updated product
              final updatedProduct = product.copyWith(
                name: name,
                description: description,
                price: price,
                categoryId: categoryId,
                updatedAt: DateTime.now(),
              );
              // Call update method with user info
              await _productNotifier.updateProductWithImage(
                product: updatedProduct,
                imageBytes: imageBytes,
                imageExtension: imageExtension,
                businessId: user.primarybusinessId, // Pass user info
                branchId: user.primaryBranchId,
              );
            },
      ),
    );
  }
}

// ProductFormDialog remains the same as in your original code
class ProductFormDialog extends StatefulWidget {
  final String title;
  final List<CategoryModel> categories;
  final String? initialName;
  final String? initialDescription;
  final double? initialPrice;
  final String? initialCategoryId;
  final String? initialImageUrl;
  final Future<void> Function(
    String name,
    String description,
    double price,
    String categoryId,
    String? imageUrl,
    Uint8List? imageBytes,
    String? imageExtension,
  )
  onSave;

  const ProductFormDialog({
    super.key,
    required this.title,
    required this.categories,
    required this.onSave,
    this.initialName,
    this.initialDescription,
    this.initialPrice,
    this.initialCategoryId,
    this.initialImageUrl,
  });

  @override
  State<ProductFormDialog> createState() => _ProductFormDialogState();
}

class _ProductFormDialogState extends State<ProductFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _imageUrlController;
  String? _selectedCategoryId;
  Uint8List? bytes;
  String? extension;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
    _priceController = TextEditingController(
      text: widget.initialPrice?.toString(),
    );
    _imageUrlController = TextEditingController(text: widget.initialImageUrl);
    _selectedCategoryId = widget.initialCategoryId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePicker = ImagePicker();
    return AlertDialog(
      title: Text(widget.title),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price (\$)',
                    border: OutlineInputBorder(),
                    prefixText: '\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a price';
                    }
                    final price = double.tryParse(value);
                    if (price == null || price <= 0) {
                      return 'Please enter a valid price greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Select Category',
                    border: OutlineInputBorder(),
                  ),
                  items: widget.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category.id,
                          child: Text(category.name),
                        ),
                      )
                      .toList(),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                  onChanged: (value) =>
                      setState(() => _selectedCategoryId = value),
                ),
                const SizedBox(height: 16),
                if (bytes != null)
                  Container(
                    height: 180,
                    width: 180,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(bytes!, fit: BoxFit.cover),
                    ),
                  ),
                if (bytes != null) const SizedBox(height: 16),
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
                        bytes = await image.readAsBytes();
                        extension = image.name.contains('.')
                            ? image.name.split('.').last.toLowerCase()
                            : 'jpg';
                        setState(() {});
                      }
                    } catch (e) {
                      log('Error: $e');
                    }
                  },
                  child: const Text('Pick Product Image'),
                ),
              ],
            ),
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
                      _descriptionController.text.trim(),
                      double.parse(_priceController.text.trim()),
                      _selectedCategoryId!,
                      _imageUrlController.text.trim().isEmpty
                          ? null
                          : _imageUrlController.text.trim(),
                      bytes,
                      extension,
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Product saved successfully.'),
                      ),
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isSaving = false);
                    final message = e.toString().contains('already exists')
                        ? 'Product already exists.'
                        : 'Failed to save product: $e';
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
// import 'package:hotel_management_system/data/models/product_model.dart';
// import 'package:hotel_management_system/data/models/category_model.dart';
// import 'package:hotel_management_system/state_management/app_providers.dart';
// import 'package:hotel_management_system/state_management/product_state_and_notifier.dart';

// // Dummy permission service for products
// class ProductPermissionService {
//   static bool canCreateProduct() => true;
//   static bool canEditProduct() => true;
//   static bool canDeleteProduct() => true;
//   static bool canToggleProductAvailability() => true;
// }

// class ProductManagementScreen extends ConsumerStatefulWidget {
//   final String? categoryId; // Optional: filter by specific category
//   final String? categoryName; // For display purposes

//   const ProductManagementScreen({
//     super.key,
//     this.categoryId,
//     this.categoryName,
//   });

//   @override
//   ConsumerState<ProductManagementScreen> createState() =>
//       _ProductManagementScreenState();
// }

// class _ProductManagementScreenState
//     extends ConsumerState<ProductManagementScreen> {
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String? _selectedCategoryFilter;
//   bool _showAvailableOnly = false;
//   late ProductNotifier _productNotifier;
//   late List<CategoryModel> _categories;

//   @override
//   Future<void> initState() async {
//     super.initState();
//     _productNotifier = ref.read(
//       productProvider((
//         branchId: ref.read(userProvider).selectedUser!.primaryBranchId,
//         businessId: ref.read(userProvider).selectedUser!.primarybusinessId,
//       )).notifier,
//     );

//     // Load products when screen initializes
//     WidgetsBinding.instance.addPostFrameCallback((_) async {
//       _categories = await ref
//           .read(
//             categoryProvider((
//               branchId: ref.read(userProvider).selectedUser!.primaryBranchId,
//               businessId: ref
//                   .read(userProvider)
//                   .selectedUser!
//                   .primarybusinessId,
//             )).notifier,
//           )
//           .loadAllCategories();

//       if (widget.categoryId != null) {
//         _productNotifier.loadProductsByCategory(widget.categoryId!);
//         _selectedCategoryFilter = widget.categoryId;
//       } else {
//         _productNotifier.loadAllProducts();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   List<ProductModel> _filterProducts(List<ProductModel> products) {
//     var filtered = products;

//     // Filter by selected category if any
//     if (_selectedCategoryFilter != null &&
//         _selectedCategoryFilter!.isNotEmpty) {
//       filtered = filtered
//           .where((product) => product.categoryId == _selectedCategoryFilter)
//           .toList();
//     }

//     // Filter by availability
//     if (_showAvailableOnly) {
//       filtered = filtered.where((product) => product.isAvailable).toList();
//     }

//     // Filter by search query
//     if (_searchQuery.isNotEmpty) {
//       filtered = filtered
//           .where(
//             (product) =>
//                 product.name.toLowerCase().contains(
//                   _searchQuery.toLowerCase(),
//                 ) ||
//                 product.description.toLowerCase().contains(
//                   _searchQuery.toLowerCase(),
//                 ),
//           )
//           .toList();
//     }

//     return filtered;
//   }

//   @override
//   Widget build(BuildContext context) {
//     final productState = ref.watch(
//       productProvider((
//         branchId: ref.read(userProvider).selectedUser!.primaryBranchId,
//         businessId: ref.read(userProvider).selectedUser!.primarybusinessId,
//       )),
//     );
//     final categoryState = ref.watch(
//       categoryProvider((
//         branchId: ref.read(userProvider).selectedUser!.primaryBranchId,
//         businessId: ref.read(userProvider).selectedUser!.primarybusinessId,
//       )),
//     );
//     // final categoryState = ref.watch(categoryProvider);

//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           widget.categoryName != null
//               ? '${widget.categoryName} Products'
//               : 'Product Management',
//         ),
//         centerTitle: true,
//         elevation: 0,
//         actions: [
//           if (ProductPermissionService.canCreateProduct())
//             IconButton(
//               onPressed: () =>
//                   _showCreateProductDialog(context, categoryState.categories),
//               icon: const Icon(Icons.add),
//               tooltip: 'Add Product',
//             ),
//           IconButton(
//             onPressed: () => _refreshProducts(),
//             icon: const Icon(Icons.refresh),
//             tooltip: 'Refresh',
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           // Search and Filter Bar
//           Padding(
//             padding: const EdgeInsets.all(16.0),
//             child: Column(
//               children: [
//                 // Search Bar
//                 SearchBar(
//                   controller: _searchController,
//                   hintText: 'Search products...',
//                   leading: const Icon(Icons.search),
//                   trailing: _searchQuery.isNotEmpty
//                       ? [
//                           IconButton(
//                             onPressed: () {
//                               _searchController.clear();
//                               setState(() => _searchQuery = '');
//                             },
//                             icon: const Icon(Icons.clear),
//                           ),
//                         ]
//                       : null,
//                   onChanged: (value) => setState(() => _searchQuery = value),
//                 ),

//                 const SizedBox(height: 12),

//                 // Filters Row
//                 Row(
//                   children: [
//                     // Category Filter (only show if not filtering by specific category)
//                     if (widget.categoryId == null) ...[
//                       Expanded(
//                         child: _buildCategoryFilter(
//                           categoryState.categories,
//                           colorScheme,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                     ],

//                     // Availability Filter
//                     FilterChip(
//                       label: const Text('Available Only'),
//                       selected: _showAvailableOnly,
//                       onSelected: (selected) =>
//                           setState(() => _showAvailableOnly = selected),
//                       avatar: Icon(
//                         _showAvailableOnly
//                             ? Icons.check_circle
//                             : Icons.visibility,
//                         size: 18,
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),

//           // Content Area
//           Expanded(
//             child: _buildContent(
//               productState,
//               categoryState.categories,
//               colorScheme,
//             ),
//           ),
//         ],
//       ),
//       floatingActionButton: ProductPermissionService.canCreateProduct()
//           ? FloatingActionButton.extended(
//               onPressed: () =>
//                   _showCreateProductDialog(context, categoryState.categories),
//               icon: const Icon(Icons.add),
//               label: const Text('Add Product'),
//             )
//           : null,
//     );
//   }

//   Widget _buildCategoryFilter(
//     List<CategoryModel> categories,
//     ColorScheme colorScheme,
//   ) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         border: Border.all(color: colorScheme.outline),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: DropdownButton<String?>(
//         value: _selectedCategoryFilter,
//         hint: const Text('Filter by Category'),
//         isExpanded: true,
//         underline: const SizedBox(),
//         items: [
//           const DropdownMenuItem<String?>(
//             value: null,
//             child: Text('All Categories'),
//           ),
//           ...categories.map(
//             (category) => DropdownMenuItem<String>(
//               value: category.id,
//               child: Text(category.name),
//             ),
//           ),
//         ],
//         onChanged: (value) {
//           setState(() => _selectedCategoryFilter = value);
//           if (value != null) {
//             _productNotifier.loadProductsByCategory(value);
//           } else {
//             _productNotifier.loadAllProducts();
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildContent(
//     ProductState state,
//     List<CategoryModel> categories,
//     ColorScheme colorScheme,
//   ) {
//     if (state.isLoading && state.products.isEmpty) {
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
//               'Error loading products',
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
//               onPressed: () => _refreshProducts(),
//               icon: const Icon(Icons.refresh),
//               label: const Text('Retry'),
//             ),
//           ],
//         ),
//       );
//     }

//     final filteredProducts = _filterProducts(state.products);

//     if (filteredProducts.isEmpty) {
//       return Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               _searchQuery.isNotEmpty ? Icons.search_off : Icons.inventory_2,
//               size: 64,
//               color: colorScheme.onSurfaceVariant,
//             ),
//             const SizedBox(height: 16),
//             Text(
//               _searchQuery.isNotEmpty
//                   ? 'No products found'
//                   : 'No products available',
//               style: Theme.of(context).textTheme.headlineSmall,
//             ),
//             const SizedBox(height: 8),
//             Text(
//               _searchQuery.isNotEmpty
//                   ? 'Try adjusting your search terms or filters'
//                   : 'Get started by adding your first product',
//               style: Theme.of(context).textTheme.bodyMedium?.copyWith(
//                 color: colorScheme.onSurfaceVariant,
//               ),
//               textAlign: TextAlign.center,
//             ),
//             if (_searchQuery.isEmpty &&
//                 ProductPermissionService.canCreateProduct()) ...[
//               const SizedBox(height: 16),
//               FilledButton.icon(
//                 onPressed: () => _showCreateProductDialog(context, categories),
//                 icon: const Icon(Icons.add),
//                 label: const Text('Add Product'),
//               ),
//             ],
//           ],
//         ),
//       );
//     }

//     return RefreshIndicator(
//       onRefresh: () => _refreshProducts(),
//       child: LayoutBuilder(
//         builder: (context, constraints) {
//           // Responsive layout
//           if (constraints.maxWidth > 1200) {
//             // Desktop: 3 columns
//             return _buildGridView(filteredProducts, categories, 3);
//           } else if (constraints.maxWidth > 800) {
//             // Tablet: 2 columns
//             return _buildGridView(filteredProducts, categories, 2);
//           } else {
//             // Mobile: List view
//             return _buildListView(
//               filteredProducts,
//               categories,
//               state.isLoading,
//             );
//           }
//         },
//       ),
//     );
//   }

//   Widget _buildListView(
//     List<ProductModel> products,
//     List<CategoryModel> categories,
//     bool isLoading,
//   ) {
//     return ListView.builder(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       itemCount: products.length + (isLoading ? 1 : 0),
//       itemBuilder: (context, index) {
//         if (index == products.length && isLoading) {
//           return const Center(
//             child: Padding(
//               padding: EdgeInsets.all(16),
//               child: CircularProgressIndicator(),
//             ),
//           );
//         }

//         final product = products[index];
//         return Padding(
//           padding: const EdgeInsets.only(bottom: 8),
//           child: _buildProductCard(product, categories, isListView: true),
//         );
//       },
//     );
//   }

//   Widget _buildGridView(
//     List<ProductModel> products,
//     List<CategoryModel> categories,
//     int crossAxisCount,
//   ) {
//     return GridView.builder(
//       padding: const EdgeInsets.all(16),
//       gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//         crossAxisCount: crossAxisCount,
//         childAspectRatio: 0.75,
//         crossAxisSpacing: 16,
//         mainAxisSpacing: 16,
//       ),
//       itemCount: products.length,
//       itemBuilder: (context, index) =>
//           _buildProductCard(products[index], categories),
//     );
//   }

//   Widget _buildProductCard(
//     ProductModel product,
//     List<CategoryModel> categories, {
//     bool isListView = false,
//   }) {
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;
//     final categoryName = categories
//         .firstWhere(
//           (category) => category.id == product.categoryId,
//           orElse: () => CategoryModel(
//             id: '',
//             name: 'Unknown Category',
//             menuId: '',
//             createdAt: DateTime.now(),
//             updatedAt: DateTime.now(),
//           ),
//         )
//         .name;

//     if (isListView) {
//       return Dismissible(
//         key: Key(product.productId),
//         background: _buildSwipeBackground(
//           Colors.blue,
//           Icons.edit,
//           'Edit',
//           isLeft: true,
//         ),
//         secondaryBackground: ProductPermissionService.canDeleteProduct()
//             ? _buildSwipeBackground(colorScheme.error, Icons.delete, 'Delete')
//             : null,
//         confirmDismiss: (direction) async {
//           if (direction == DismissDirection.startToEnd) {
//             if (ProductPermissionService.canEditProduct()) {
//               _showEditProductDialog(context, product, categories);
//             }
//             return false;
//           } else if (direction == DismissDirection.endToStart) {
//             if (ProductPermissionService.canDeleteProduct()) {
//               return await _showDeleteConfirmation(context, product);
//             }
//           }
//           return false;
//         },
//         child: _buildProductListTile(product, categoryName, theme, colorScheme),
//       );
//     } else {
//       return _buildProductGridCard(product, categoryName, theme, colorScheme);
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

//   Widget _buildProductListTile(
//     ProductModel product,
//     String categoryName,
//     ThemeData theme,
//     ColorScheme colorScheme,
//   ) {
//     return Card(
//       child: ListTile(
//         contentPadding: const EdgeInsets.all(16),
//         leading: _buildProductImage(product.imageUrl, size: 60),
//         title: Row(
//           children: [
//             Expanded(
//               child: Text(
//                 product.name,
//                 style: theme.textTheme.titleMedium?.copyWith(
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ),
//             _buildAvailabilityChip(product.isAvailable, colorScheme),
//           ],
//         ),
//         subtitle: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const SizedBox(height: 4),
//             Text(
//               product.description,
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: colorScheme.secondaryContainer,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Text(
//                     categoryName,
//                     style: theme.textTheme.bodySmall?.copyWith(
//                       color: colorScheme.onSecondaryContainer,
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                 ),
//                 const Spacer(),
//                 Text(
//                   '\$${product.price.toStringAsFixed(2)}',
//                   style: theme.textTheme.titleMedium?.copyWith(
//                     color: colorScheme.primary,
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Row(
//               children: [
//                 _buildRatingDisplay(
//                   product.averageRating,
//                   product.reviewCount,
//                   theme,
//                 ),
//                 const Spacer(),
//                 Text(
//                   'Added: ${_formatDate(product.createdAt)}',
//                   style: theme.textTheme.bodySmall?.copyWith(
//                     color: colorScheme.onSurfaceVariant,
//                   ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//         trailing: PopupMenuButton(
//           itemBuilder: (context) => _buildPopupMenuItems(product, _categories),
//         ),
//       ),
//     );
//   }

//   Widget _buildProductGridCard(
//     ProductModel product,
//     String categoryName,
//     ThemeData theme,
//     ColorScheme colorScheme,
//   ) {
//     return Card(
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Product Image
//           Expanded(
//             flex: 3,
//             child: Stack(
//               children: [
//                 Container(
//                   width: double.infinity,
//                   decoration: BoxDecoration(
//                     borderRadius: const BorderRadius.vertical(
//                       top: Radius.circular(12),
//                     ),
//                     color: colorScheme.surfaceVariant,
//                   ),
//                   child: _buildProductImage(product.imageUrl),
//                 ),
//                 Positioned(
//                   top: 8,
//                   right: 8,
//                   child: _buildAvailabilityChip(
//                     product.isAvailable,
//                     colorScheme,
//                   ),
//                 ),
//               ],
//             ),
//           ),

//           // Product Details
//           Expanded(
//             flex: 2,
//             child: Padding(
//               padding: const EdgeInsets.all(12),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     product.name,
//                     style: theme.textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     product.description,
//                     style: theme.textTheme.bodySmall,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 6),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       horizontal: 6,
//                       vertical: 2,
//                     ),
//                     decoration: BoxDecoration(
//                       color: colorScheme.secondaryContainer,
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Text(
//                       categoryName,
//                       style: theme.textTheme.bodySmall?.copyWith(
//                         color: colorScheme.onSecondaryContainer,
//                         fontSize: 10,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ),
//                   const Spacer(),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       Text(
//                         '\$${product.price.toStringAsFixed(2)}',
//                         style: theme.textTheme.titleMedium?.copyWith(
//                           color: colorScheme.primary,
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                       PopupMenuButton(
//                         itemBuilder: (context) =>
//                             _buildPopupMenuItems(product, _categories),
//                         child: Icon(
//                           Icons.more_vert,
//                           color: colorScheme.onSurfaceVariant,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 4),
//                   _buildRatingDisplay(
//                     product.averageRating,
//                     product.reviewCount,
//                     theme,
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildProductImage(String? imageUrl, {double? size}) {
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
//         Icons.inventory_2,
//         size: size != null ? size * 0.4 : 48,
//         color: Theme.of(context).colorScheme.onSurfaceVariant,
//       ),
//     );
//   }

//   Widget _buildAvailabilityChip(bool isAvailable, ColorScheme colorScheme) {
//     return Chip(
//       label: Text(
//         isAvailable ? 'Available' : 'Unavailable',
//         style: TextStyle(
//           fontSize: 12,
//           color: isAvailable ? colorScheme.onPrimary : colorScheme.onError,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       backgroundColor: isAvailable ? colorScheme.primary : colorScheme.error,
//       materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
//     );
//   }

//   Widget _buildRatingDisplay(double rating, int reviewCount, ThemeData theme) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(
//           Icons.star,
//           size: 14,
//           color: rating > 0 ? Colors.amber : theme.colorScheme.onSurfaceVariant,
//         ),
//         const SizedBox(width: 2),
//         Text(
//           rating.toStringAsFixed(1),
//           style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
//         ),
//         Text(
//           ' ($reviewCount)',
//           style: theme.textTheme.bodySmall?.copyWith(
//             fontSize: 10,
//             color: theme.colorScheme.onSurfaceVariant,
//           ),
//         ),
//       ],
//     );
//   }

//   List<PopupMenuEntry> _buildPopupMenuItems(
//     ProductModel product,
//     List<CategoryModel> categories,
//   ) {
//     return [
//       if (ProductPermissionService.canEditProduct())
//         PopupMenuItem(
//           value: 'edit',
//           child: const ListTile(
//             leading: Icon(Icons.edit),
//             title: Text('Edit'),
//             contentPadding: EdgeInsets.zero,
//           ),
//           onTap: () => _showEditProductDialog(context, product, categories),
//         ),
//       if (ProductPermissionService.canToggleProductAvailability())
//         PopupMenuItem(
//           value: 'toggle',
//           child: ListTile(
//             leading: Icon(
//               product.isAvailable ? Icons.visibility_off : Icons.visibility,
//             ),
//             title: Text(
//               product.isAvailable ? 'Mark Unavailable' : 'Mark Available',
//             ),
//             contentPadding: EdgeInsets.zero,
//           ),
//           onTap: () => _toggleProductAvailability(product),
//         ),
//       if (ProductPermissionService.canDeleteProduct())
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
//           onTap: () => _showDeleteConfirmation(context, product),
//         ),
//     ];
//   }

//   String _formatDate(DateTime date) {
//     return '${date.day}/${date.month}/${date.year}';
//   }

//   void _toggleProductAvailability(ProductModel product) {
//     _productNotifier.toggleProductAvailability(
//       product.productId,
//       !product.isAvailable,
//     );
//   }

//   Future<void> _refreshProducts() async {
//     if (widget.categoryId != null) {
//       _productNotifier.loadProductsByCategory(widget.categoryId!);
//     } else {
//       await _productNotifier.loadAllProducts();
//     }
//   }

//   Future<bool> _showDeleteConfirmation(
//     BuildContext context,
//     ProductModel product,
//   ) async {
//     return await showDialog<bool>(
//           context: context,
//           builder: (context) => AlertDialog(
//             title: const Text('Delete Product'),
//             content: Text(
//               'Are you sure you want to delete "${product.name}"? This action cannot be undone.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.of(context).pop(false),
//                 child: const Text('Cancel'),
//               ),
//               FilledButton(
//                 onPressed: () {
//                   _productNotifier.deleteProduct(product.productId);
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

//   void _showCreateProductDialog(
//     BuildContext context,
//     List<CategoryModel> categories,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) => ProductFormDialog(
//         title: 'Create Product',
//         categories: categories,
//         initialCategoryId: widget
//             .categoryId, // Pre-select category if coming from category screen
//         onSave: (name, description, price, categoryId, imageUrl) {
//           final product = ProductModel(
//             productId: DateTime.now().millisecondsSinceEpoch
//                 .toString(), // Temporary ID
//             name: name,
//             description: description,
//             price: price,
//             categoryId: categoryId,
//             imageUrl: imageUrl,
//             createdAt: DateTime.now(),
//             updatedAt: DateTime.now(),
//           );
//           _productNotifier.createProduct(product);
//         },
//       ),
//     );
//   }

//   void _showEditProductDialog(
//     BuildContext context,
//     ProductModel product,
//     List<CategoryModel> categories,
//   ) {
//     showDialog(
//       context: context,
//       builder: (context) => ProductFormDialog(
//         title: 'Edit Product',
//         categories: categories,
//         initialName: product.name,
//         initialDescription: product.description,
//         initialPrice: product.price,
//         initialCategoryId: product.categoryId,
//         initialImageUrl: product.imageUrl,
//         onSave: (name, description, price, categoryId, imageUrl) {
//           final updatedProduct = product.copyWith(
//             name: name,
//             description: description,
//             price: price,
//             categoryId: categoryId,
//             imageUrl: imageUrl,
//             updatedAt: DateTime.now(),
//           );
//           _productNotifier.updateProduct(updatedProduct);
//         },
//       ),
//     );
//   }
// }

// class ProductFormDialog extends StatefulWidget {
//   final String title;
//   final List<CategoryModel> categories;
//   final String? initialName;
//   final String? initialDescription;
//   final double? initialPrice;
//   final String? initialCategoryId;
//   final String? initialImageUrl;
//   final Function(
//     String name,
//     String description,
//     double price,
//     String categoryId,
//     String? imageUrl,
//   )
//   onSave;

//   const ProductFormDialog({
//     super.key,
//     required this.title,
//     required this.categories,
//     required this.onSave,
//     this.initialName,
//     this.initialDescription,
//     this.initialPrice,
//     this.initialCategoryId,
//     this.initialImageUrl,
//   });

//   @override
//   State<ProductFormDialog> createState() => _ProductFormDialogState();
// }

// class _ProductFormDialogState extends State<ProductFormDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late final TextEditingController _nameController;
//   late final TextEditingController _descriptionController;
//   late final TextEditingController _priceController;
//   late final TextEditingController _imageUrlController;
//   String? _selectedCategoryId;

//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.initialName);
//     _descriptionController = TextEditingController(
//       text: widget.initialDescription,
//     );
//     _priceController = TextEditingController(
//       text: widget.initialPrice?.toString(),
//     );
//     _imageUrlController = TextEditingController(text: widget.initialImageUrl);
//     _selectedCategoryId = widget.initialCategoryId;
//   }

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _priceController.dispose();
//     _imageUrlController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       title: Text(widget.title),
//       content: SizedBox(
//         width: MediaQuery.of(context).size.width * 0.9,
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 TextFormField(
//                   controller: _nameController,
//                   decoration: const InputDecoration(
//                     labelText: 'Product Name',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Please enter a product name';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _descriptionController,
//                   decoration: const InputDecoration(
//                     labelText: 'Description',
//                     border: OutlineInputBorder(),
//                   ),
//                   maxLines: 3,
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Please enter a description';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _priceController,
//                   decoration: const InputDecoration(
//                     labelText: 'Price (\$)',
//                     border: OutlineInputBorder(),
//                     prefixText: '\$ ',
//                   ),
//                   keyboardType: const TextInputType.numberWithOptions(
//                     decimal: true,
//                   ),
//                   validator: (value) {
//                     if (value == null || value.trim().isEmpty) {
//                       return 'Please enter a price';
//                     }
//                     final price = double.tryParse(value);
//                     if (price == null || price <= 0) {
//                       return 'Please enter a valid price greater than 0';
//                     }
//                     return null;
//                   },
//                 ),
//                 const SizedBox(height: 16),
//                 DropdownButtonFormField<String>(
//                   value: _selectedCategoryId,
//                   decoration: const InputDecoration(
//                     labelText: 'Select Category',
//                     border: OutlineInputBorder(),
//                   ),
//                   items: widget.categories
//                       .map(
//                         (category) => DropdownMenuItem(
//                           value: category.id,
//                           child: Text(category.name),
//                         ),
//                       )
//                       .toList(),
//                   validator: (value) {
//                     if (value == null || value.isEmpty) {
//                       return 'Please select a category';
//                     }
//                     return null;
//                   },
//                   onChanged: (value) =>
//                       setState(() => _selectedCategoryId = value),
//                 ),
//                 const SizedBox(height: 16),
//                 TextFormField(
//                   controller: _imageUrlController,
//                   decoration: const InputDecoration(
//                     labelText: 'Image URL (Optional)',
//                     border: OutlineInputBorder(),
//                   ),
//                   validator: (value) {
//                     if (value != null && value.isNotEmpty) {
//                       final uri = Uri.tryParse(value);
//                       if (uri == null || !uri.hasScheme) {
//                         return 'Please enter a valid URL';
//                       }
//                     }
//                     return null;
//                   },
//                 ),
//               ],
//             ),
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
//                 _descriptionController.text.trim(),
//                 double.parse(_priceController.text.trim()),
//                 _selectedCategoryId!,
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
