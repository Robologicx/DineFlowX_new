import 'dart:developer';
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/data/models/category_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/product_state_and_notifier.dart';
import 'package:image_picker/image_picker.dart';
import 'package:universal_html/html.dart' as html;
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
  String branchId = BusinessRepository.temporaryBranchId;
  String businessId = BusinessRepository.temporaryBusinesshId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  void _loadInitialData() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(userProvider).selectedUser;
      if (user != null) {
        branchId = user.primaryBranchId;
        businessId = user.primarybusinessId;
      }

      // Load categories
      ref
          .read(
            categoryProvider((
              branchId: branchId,
              businessId: businessId,
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
        productProvider((branchId: branchId, businessId: businessId)).notifier,
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
    final user = ref.read(userProvider).selectedUser;
    final effectiveBranchId = user?.primaryBranchId ?? branchId;
    final effectiveBusinessId = user?.primarybusinessId ?? businessId;
    return ref.read(
      productProvider((
        branchId: effectiveBranchId,
        businessId: effectiveBusinessId,
      )).notifier,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider).selectedUser;
    final effectiveBranchId = user?.primaryBranchId ?? branchId;
    final effectiveBusinessId = user?.primarybusinessId ?? businessId;

    final userNotifier = ref.read(userProvider.notifier);
    if (user != null) {
      widget.canCreateProduct = userNotifier.hasPermissionOfCurrentUser(
        Permissions.createProduct,
      );
      widget.canEditProduct = userNotifier.hasPermissionOfCurrentUser(
        Permissions.updateProduct,
      );
      widget.canDeleteProduct = userNotifier.hasPermissionOfCurrentUser(
        Permissions.deleteProduct,
      );
    } else {
      widget.canCreateProduct = true;
      widget.canEditProduct = true;
      widget.canDeleteProduct = true;
    }

    final productsAsync = ref.watch(
      productProvider((
        branchId: effectiveBranchId,
        businessId: effectiveBusinessId,
      )),
    );

    final categoryState = ref.watch(
      categoryProvider((
        branchId: effectiveBranchId,
        businessId: effectiveBusinessId,
      )),
    );
    final filteredForExport = _filterProducts(productsAsync.products);

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
          PopupMenuButton<String>(
            tooltip: 'Bulk Menu Import/Export',
            icon: const Icon(Icons.table_chart_outlined),
            onSelected: (value) async {
              if (value == 'export') {
                await _exportMenuToExcel(
                  filteredForExport,
                  categoryState.categories,
                );
              } else if (value == 'import') {
                if (!widget.canCreateProduct) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You do not have permission to import menu.',
                      ),
                    ),
                  );
                  return;
                }
                await _importMenuFromExcel(categoryState.categories);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.download_rounded),
                  title: Text('Export Menu (Excel CSV)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (widget.canCreateProduct)
                const PopupMenuItem<String>(
                  value: 'import',
                  child: ListTile(
                    leading: Icon(Icons.upload_file_rounded),
                    title: Text('Import Menu (Excel CSV)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
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

  String _normalizeHeader(String header) {
    return header
        .replaceAll('\ufeff', '')
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');
  }

  String _escapeCsv(String value) {
    final mustQuote =
        value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r');
    if (!mustQuote) return value;
    return '"${value.replaceAll('"', '""')}"';
  }

  String _detectDelimiter(String headerLine) {
    final commaCount = ','.allMatches(headerLine).length;
    final semicolonCount = ';'.allMatches(headerLine).length;
    final tabCount = '\t'.allMatches(headerLine).length;

    if (semicolonCount > commaCount && semicolonCount >= tabCount) {
      return ';';
    }
    if (tabCount > commaCount && tabCount > semicolonCount) {
      return '\t';
    }
    return ',';
  }

  List<String> _parseDelimitedLine(String line, String delimiter) {
    final values = <String>[];
    final buffer = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          buffer.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == delimiter && !inQuotes) {
        values.add(buffer.toString().trim());
        buffer.clear();
      } else {
        buffer.write(char);
      }
    }
    values.add(buffer.toString().trim());
    return values;
  }

  double? _tryParsePrice(String input) {
    final raw = input.trim().toLowerCase();
    if (raw.isEmpty) return null;

    final isPkr =
        raw.contains('pkr') ||
        raw.contains('rs') ||
        raw.contains('rup') ||
        raw.contains('₨');

    final isUsd =
        raw.contains(r'$') ||
        raw.contains('usd') ||
        RegExp(r'^s\s*\d').hasMatch(raw) ||
        RegExp(r'\d\s*s$').hasMatch(raw);

    final decimalCommaMatch = RegExp(r'[-+]?\d[\d.]*,\d+').firstMatch(raw);
    final standardMatch = RegExp(r'[-+]?\d[\d,]*(?:\.\d+)?').firstMatch(raw);

    String? numberText;
    if (decimalCommaMatch != null) {
      numberText = decimalCommaMatch
          .group(0)
          ?.replaceAll('.', '')
          .replaceAll(',', '.');
    } else if (standardMatch != null) {
      numberText = standardMatch.group(0)?.replaceAll(',', '');
    }

    if (numberText == null || numberText.isEmpty) return null;
    var amount = double.tryParse(numberText);
    if (amount == null) return null;

    const usdToPkrRate = 278.0;
    if (isUsd && !isPkr) {
      amount = amount * usdToPkrRate;
    }

    return amount;
  }

  bool _parseAvailability(String value) {
    final normalized = value.toLowerCase();
    if (normalized == 'false' ||
        normalized == '0' ||
        normalized == 'no' ||
        normalized == 'unavailable') {
      return false;
    }
    return true;
  }

  Future<Uint8List?> _pickCsvBytes() async {
    if (kIsWeb) {
      final input = html.FileUploadInputElement()
        ..accept = '.csv'
        ..multiple = false;

      final completer = Completer<Uint8List?>();

      input.onChange.listen((_) {
        final file = input.files?.isNotEmpty == true
            ? input.files!.first
            : null;
        if (file == null) {
          if (!completer.isCompleted) completer.complete(null);
          return;
        }

        final reader = html.FileReader();
        reader.onLoadEnd.listen((_) {
          final result = reader.result;
          if (result is ByteBuffer) {
            if (!completer.isCompleted) {
              completer.complete(result.asUint8List());
            }
            return;
          }
          if (result is Uint8List) {
            if (!completer.isCompleted) completer.complete(result);
            return;
          }
          if (result is String) {
            if (!completer.isCompleted) {
              completer.complete(Uint8List.fromList(utf8.encode(result)));
            }
            return;
          }
          if (!completer.isCompleted) completer.complete(null);
        });
        reader.onError.listen((_) {
          if (!completer.isCompleted) completer.complete(null);
        });
        reader.readAsArrayBuffer(file);
      });

      input.click();
      return Future.any<Uint8List?>([
        completer.future,
        Future<Uint8List?>.delayed(const Duration(seconds: 60), () => null),
      ]);
    }

    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );

    if (picked == null || picked.files.isEmpty) return null;
    return picked.files.single.bytes;
  }

  Future<void> _exportMenuToExcel(
    List<ProductModel> products,
    List<CategoryModel> categories,
  ) async {
    try {
      final categoryNamesById = {for (final c in categories) c.id: c.name};

      final csvRows = <String>[];
      csvRows.add(
        'Name,Description,Price,Category,CategoryId,Available,ImageUrl',
      );

      for (final product in products) {
        final row = [
          _escapeCsv(product.name),
          _escapeCsv(product.description),
          product.price.toString(),
          _escapeCsv(categoryNamesById[product.categoryId] ?? ''),
          _escapeCsv(product.categoryId),
          product.isAvailable.toString(),
          _escapeCsv(product.imageUrl ?? ''),
        ].join(',');
        csvRows.add(row);
      }

      final csvContent = csvRows.join('\n');
      if (csvContent.isEmpty) {
        throw Exception('CSV generation failed.');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'menu_export_$timestamp.csv';
      final data = Uint8List.fromList(utf8.encode(csvContent));

      if (kIsWeb) {
        final blob = html.Blob([data], 'text/csv;charset=utf-8');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save CSV file',
          fileName: fileName,
          type: FileType.custom,
          allowedExtensions: const ['csv'],
          bytes: data,
        );
        if (savePath == null) {
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Export canceled.')));
          return;
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Menu exported: ${products.length} products.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
    }
  }

  Future<void> _importMenuFromExcel(List<CategoryModel> categories) async {
    try {
      final bytes = await _pickCsvBytes();
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Could not read selected file.');
      }

      final csvText = utf8.decode(bytes, allowMalformed: true);
      final lines = csvText
          .split(RegExp(r'\r?\n'))
          .where((line) => line.trim().isNotEmpty)
          .toList(growable: false);
      if (lines.isEmpty) {
        throw Exception('CSV file is empty.');
      }

      final delimiter = _detectDelimiter(lines.first);
      final rows = lines
          .map((line) => _parseDelimitedLine(line, delimiter))
          .toList(growable: false);

      final headerRow = rows.first;
      final headerIndexes = <String, int>{};
      for (var i = 0; i < headerRow.length; i++) {
        final header = _normalizeHeader(headerRow[i]);
        if (header.isNotEmpty) {
          headerIndexes[header] = i;
        }
      }

      int? indexOf(List<String> keys) {
        for (final key in keys) {
          final index = headerIndexes[key];
          if (index != null) return index;
        }
        return null;
      }

      final nameCol = indexOf(['name', 'productname']);
      final priceCol = indexOf(['price', 'rate', 'amount']);
      final categoryCol = indexOf(['category', 'categoryname']);
      final categoryIdCol = indexOf(['categoryid']);
      final descCol = indexOf(['description', 'desc']);
      final availableCol = indexOf(['available', 'isavailable', 'status']);
      final imageCol = indexOf(['imageurl', 'image', 'imagepath']);

      if (nameCol == null ||
          priceCol == null ||
          (categoryCol == null && categoryIdCol == null)) {
        throw Exception(
          'Required columns: Name, Price, and Category or CategoryId.',
        );
      }

      final user = ref.read(userProvider).selectedUser;
      final effectiveBusinessId = user?.primarybusinessId ?? businessId;
      final effectiveBranchId = user?.primaryBranchId ?? branchId;

      final categoryIdByName = {
        for (final c in categories) c.name.trim().toLowerCase(): c.id,
      };
      final categoryIds = categories.map((c) => c.id).toSet();

      String cellAt(List<String> row, int? col) {
        if (col == null || col < 0 || col >= row.length) return '';
        return row[col].trim();
      }

      var successCount = 0;
      var failCount = 0;
      final failures = <String>[];

      for (var rowIndex = 1; rowIndex < rows.length; rowIndex++) {
        final row = rows[rowIndex];
        final name = cellAt(row, nameCol);
        if (name.isEmpty) continue;

        final priceRaw = cellAt(row, priceCol);
        final price = _tryParsePrice(priceRaw);
        if (price == null || price <= 0) {
          failCount++;
          if (failures.length < 5) {
            failures.add('Row ${rowIndex + 1}: invalid price.');
          }
          continue;
        }

        var resolvedCategoryId = '';
        if (categoryIdCol != null) {
          final rawCategoryId = cellAt(row, categoryIdCol);
          if (categoryIds.contains(rawCategoryId)) {
            resolvedCategoryId = rawCategoryId;
          }
        }

        if (resolvedCategoryId.isEmpty && categoryCol != null) {
          final categoryName = cellAt(row, categoryCol).toLowerCase().trim();
          resolvedCategoryId = categoryIdByName[categoryName] ?? '';
        }

        if (resolvedCategoryId.isEmpty) {
          failCount++;
          if (failures.length < 5) {
            failures.add('Row ${rowIndex + 1}: category not found.');
          }
          continue;
        }

        final description = descCol == null ? '' : cellAt(row, descCol);
        final isAvailable = availableCol == null
            ? true
            : _parseAvailability(cellAt(row, availableCol));
        final imageUrl = imageCol == null ? null : cellAt(row, imageCol);

        final product = ProductModel(
          productId: const Uuid().v4(),
          name: name,
          description: description,
          price: price,
          categoryId: resolvedCategoryId,
          imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl,
          isAvailable: isAvailable,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        try {
          await _productNotifier.createProduct(
            product,
            effectiveBusinessId,
            effectiveBranchId,
            null,
            null,
          );
          successCount++;
        } catch (_) {
          failCount++;
          if (failures.length < 5) {
            failures.add('Row ${rowIndex + 1}: failed to save product.');
          }
        }
      }

      await _refreshProducts();
      if (!mounted) return;
      final details = failures.isEmpty ? '' : '\n${failures.join('\n')}';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          content: Text(
            'Import completed. Added: $successCount, Failed: $failCount.$details',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Import failed: $e')));
    }
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
              final effectiveBusinessId = user?.primarybusinessId ?? businessId;
              final effectiveBranchId = user?.primaryBranchId ?? branchId;

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
                effectiveBusinessId,
                effectiveBranchId,
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
              final effectiveBusinessId = user?.primarybusinessId ?? businessId;
              final effectiveBranchId = user?.primaryBranchId ?? branchId;

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
                businessId: effectiveBusinessId,
                branchId: effectiveBranchId,
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
