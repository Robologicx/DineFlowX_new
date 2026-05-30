// product_selection_dialog.dart

// every product is connected with a category id.
//based on that category id i want to build various sections so that user can easily get product related to some category.
//modify this code to work this way. show a chip group in which each chip is category.
// based on those selections products should be showing up. by default all are selected.
// for getting category notifier we can use ref.read(categoryProvider) then ref.loadAllCategories) then category.name to get category name.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/loading_indicator.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class ProductSelectionDialog extends ConsumerStatefulWidget {
  final String businessId;
  final String branchId;
  final List<OrderItem> currentOrderItems;
  final Function(List<OrderItem> selectedItems) onProductsSelected;

  const ProductSelectionDialog({
    super.key,
    required this.businessId,
    required this.branchId,
    required this.currentOrderItems,
    required this.onProductsSelected,
  });

  @override
  ConsumerState<ProductSelectionDialog> createState() =>
      _ProductSelectionDialogState();
}

class _ProductSelectionDialogState
    extends ConsumerState<ProductSelectionDialog> {
  final TextEditingController _searchController = TextEditingController();
  final Map<String, int> _selectedQuantities = {};
  List<ProductModel> _filteredProducts = [];

  @override
  void initState() {
    super.initState();

    // Pre-fill quantities from current order items
    for (var item in widget.currentOrderItems) {
      _selectedQuantities[item.productId] = item.quantity;
    }

    // Load products
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productNotifier = ref.read(
        productProvider((
          businessId: widget.businessId,
          branchId: widget.branchId,
        )).notifier,
      );
      // productNotifier.setBusinessContext(widget.businessId, widget.branchId);
      productNotifier.loadAllProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    final productState = ref.read(
      productProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )),
    );

    if (query.isEmpty) {
      setState(() {
        _filteredProducts = _getAvailableProducts(productState.products);
      });
    } else {
      setState(() {
        _filteredProducts = _getAvailableProducts(productState.products)
            .where(
              (product) =>
                  product.name.toLowerCase().contains(query.toLowerCase()) ||
                  product.productId.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
      });
    }
  }

  List<ProductModel> _getAvailableProducts(List<ProductModel> products) {
    return products.where((product) => product.isAvailable).toList();
  }

  void _incrementQuantity(String productId) {
    setState(() {
      _selectedQuantities[productId] =
          (_selectedQuantities[productId] ?? 0) + 1;
    });
  }

  void _decrementQuantity(String productId) {
    setState(() {
      final currentQty = _selectedQuantities[productId] ?? 0;
      if (currentQty > 0) {
        _selectedQuantities[productId] = currentQty - 1;
        if (_selectedQuantities[productId] == 0) {
          _selectedQuantities.remove(productId);
        }
      }
    });
  }

  int get _totalSelectedItems {
    return _selectedQuantities.values.fold(0, (sum, qty) => sum + qty);
  }

  double _calculateTotal(List<ProductModel> products) {
    double total = 0.0;
    _selectedQuantities.forEach((productId, quantity) {
      final product = products.firstWhere(
        (p) => p.productId == productId,
        orElse: () => products.first,
      );
      total += product.price * quantity;
    });
    return total;
  }

  void _addToOrder(List<ProductModel> products) {
    final selectedItems = <OrderItem>[];

    _selectedQuantities.forEach((productId, quantity) {
      if (quantity > 0) {
        final product = products.firstWhere(
          (p) => p.productId == productId,
          orElse: () => products.first,
        );

        selectedItems.add(
          OrderItem(
            productId: product.productId,
            productName: product.name,
            quantity: quantity,
            price: product.price,
          ),
        );
      }
    });

    widget.onProductsSelected(selectedItems);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(
      productProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )),
    );

    final availableProducts = _getAvailableProducts(productState.products);
    final displayProducts =
        _filteredProducts.isEmpty && _searchController.text.isEmpty
        ? availableProducts
        : _filteredProducts;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 700,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header with Search
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.shopping_cart,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Select Products',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name or product ID...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearch('');
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                    ),
                    onChanged: _handleSearch,
                  ),
                ],
              ),
            ),

            // Product List
            Expanded(
              child: productState.isLoading
                  ? const LoadingIndicator()
                  : displayProducts.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchController.text.isEmpty
                                ? 'No products available'
                                : 'No products found',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.outline,
                                ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: displayProducts.length,
                      itemBuilder: (context, index) {
                        final product = displayProducts[index];
                        final quantity =
                            _selectedQuantities[product.productId] ?? 0;

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        product.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'ID: ${product.productId}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.outline,
                                            ),
                                      ),
                                      if (product.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          product.description,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primaryContainer,
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              'Rs ${product.price.toStringAsFixed(2)}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                                  ),
                                            ),
                                          ),
                                          if (product.averageRating > 0) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.star,
                                              size: 16,
                                              color: Colors.amber,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              product.averageRating
                                                  .toStringAsFixed(1),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Quantity Controls
                                const SizedBox(width: 12),
                                Column(
                                  children: [
                                    if (quantity == 0)
                                      ElevatedButton.icon(
                                        onPressed: () => _incrementQuantity(
                                          product.productId,
                                        ),
                                        icon: const Icon(Icons.add, size: 18),
                                        label: const Text('Add'),
                                        style: ElevatedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove),
                                              iconSize: 20,
                                              onPressed: () =>
                                                  _decrementQuantity(
                                                    product.productId,
                                                  ),
                                              padding: const EdgeInsets.all(8),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              child: Text(
                                                quantity.toString(),
                                                style: Theme.of(context)
                                                    .textTheme
                                                    .titleMedium
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add),
                                              iconSize: 20,
                                              onPressed: () =>
                                                  _incrementQuantity(
                                                    product.productId,
                                                  ),
                                              padding: const EdgeInsets.all(8),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Summary and Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                border: Border(
                  top: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_totalSelectedItems > 0) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Selected Items: $_totalSelectedItems',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Text(
                              'Total: Rs ${_calculateTotal(availableProducts).toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _totalSelectedItems > 0
                              ? () => _addToOrder(availableProducts)
                              : null,
                          child: const Text('Add to Order'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
