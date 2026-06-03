import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/core/utils/offline_order_queue_service.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/data/repositories/table_repository.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/product_selection_dialog_for_taking_order.dart';
import 'package:hotel_management_system/presentation/client_screens/cart/check_out_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_shell.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/client_cart_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/direct_dining_state.dart';
import 'package:hotel_management_system/state_management/order_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/tenant_context_provider.dart';
import 'package:uuid/uuid.dart';

class AddToCartScreen extends ConsumerStatefulWidget {
  final String businessId;
  final String branchId;
  final String? tableId;

  const AddToCartScreen({
    super.key,
    required this.businessId,
    required this.branchId,
    this.tableId,
  });

  @override
  ConsumerState<AddToCartScreen> createState() => _AddToCartScreenState();
}

class _AddToCartScreenState extends ConsumerState<AddToCartScreen> {
  void _navigateToClientShell(BuildContext context) {
    try {
      context.replaceNamed(
        ClientAppRoutes.shell,
        queryParameters: {
          'businessId': widget.businessId,
          'branchId': widget.branchId,
          if ((widget.tableId ?? '').trim().isNotEmpty)
            'tableId': widget.tableId!.trim(),
        },
      );
    } catch (_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ClientHomeShell(
            businessId: widget.businessId,
            branchId: widget.branchId,
            tableId: widget.tableId,
          ),
        ),
      );
    }
  }

  void _navigateToCheckout(
    BuildContext context, {
    required List<OrderItem> items,
    required double totalAmount,
  }) {
    try {
      context.goNamed(
        ClientAppRoutes.checkOut,
        extra: {
          'items': items,
          'totalAmount': totalAmount,
          'tableId': _currentTableId,
        },
      );
    } catch (_) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) =>
              CheckOutScreen(items: items, totalAmount: totalAmount),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeDirectDiningState();
  }

  void _initializeDirectDiningState() {
    // Only set direct dining state if tableId is provided (QR code scenario)
    if (widget.tableId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(directDiningProvider.notifier).state = DirectDiningState(
          tableId: widget.tableId,
          businessId: widget.businessId,
          branchId: widget.branchId,
        );
      });
    }
  }

  bool get _isDirectDiningOrder {
    final directDiningState = ref.watch(directDiningProvider);
    return directDiningState.tableId != null;
  }

  String? get _currentTableId {
    final directDiningState = ref.watch(directDiningProvider);
    return directDiningState.tableId;
  }

  void _showProductSelectionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ProductSelectionDialog(
        businessId: widget.businessId,
        branchId: widget.branchId,
        currentOrderItems: ref.read(cartProvider),
        onProductsSelected: (selectedItems) {
          final cartNotifier = ref.read(cartProvider.notifier);
          final currentCart = ref.read(cartProvider);

          for (final newItem in selectedItems) {
            final existingItemIndex = currentCart.indexWhere(
              (item) => item.productId == newItem.productId,
            );

            if (existingItemIndex == -1) {
              cartNotifier.addToCart(newItem);
            } else {
              final updatedItem = currentCart[existingItemIndex].copyWith(
                quantity: newItem.quantity,
              );
              cartNotifier.updateItem(updatedItem);
            }
          }
        },
      ),
    );
  }

  void _handleCompleteOrder(
    BuildContext context,
    WidgetRef ref, {
    required List<OrderItem> items,
    required double totalAmount,
  }) {
    // Defensive check for items and totalAmount
    final safeItems = items.where((item) => item.quantity > 0).toList();
    final safeTotal = safeItems.fold<double>(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    if (safeItems.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cart is empty!')));
      return;
    }

    // Check if user came via QR code scan (has tableId)
    if (_isDirectDiningOrder) {
      // QR code scenario - place order directly from this screen
      _placeDirectOrder(ref, safeItems, safeTotal, context);
    } else {
      // Normal logged-in user - navigate to checkout screen
      _navigateToCheckout(context, items: safeItems, totalAmount: safeTotal);
    }
  }

  Future<void> _placeDirectOrder(
    WidgetRef ref,
    List<OrderItem> items,
    double totalAmount,
    BuildContext context,
  ) async {
    final cartNotifier = ref.read(cartProvider.notifier);

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Placing order...'),
          ],
        ),
      ),
    );

    try {
      // Place order directly for QR code scenario
      await _placeOrderApiCall(items, totalAmount, _currentTableId, ref: ref);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order placed successfully for Table: $_currentTableId!',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Clear cart and navigate back
      cartNotifier.clearCart();

      // Clear direct dining state after successful order
      ref.read(directDiningProvider.notifier).state = const DirectDiningState();

      // Close loading dialog
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        // Navigate back to main screen
        _navigateToClientShell(context);
      }
    } catch (e) {
      // Handle error
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _placeOrderApiCall(
    List<OrderItem> items,
    double totalAmount,
    String? tableId, {
    required WidgetRef ref,
  }) async {
    final tenantContext = ref.read(tenantContextProvider);
    final directDiningState = ref.read(directDiningProvider);
    final effectiveBusinessId = widget.businessId.trim().isNotEmpty
        ? widget.businessId
        : (directDiningState.businessId?.trim().isNotEmpty == true
              ? directDiningState.businessId!
              : tenantContext.businessId);
    final effectiveBranchId = widget.branchId.trim().isNotEmpty
        ? widget.branchId
        : (directDiningState.branchId?.trim().isNotEmpty == true
              ? directDiningState.branchId!
              : tenantContext.branchId);

    final TableModel? table = await TableRepository(
      branchId: effectiveBranchId,
      businessId: effectiveBusinessId,
    ).getTableById(tableId!);
    final order = OrderModel(
      orderId: Uuid().v4(),
      userId: 'guest_${DateTime.now().millisecondsSinceEpoch}',
      userName: 'Guest Customer',
      waiterId: 'QR_${DateTime.now().millisecondsSinceEpoch}',
      waiterName: 'QR code Order',
      orderType: OrderType.dining,
      items: items,
      diningTable: table,
      totalAmount: totalAmount,
      orderStatus: OrderStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final hasInternet = await OfflineOrderQueueService.instance
        .hasInternetConnection();

    // Create order directly using orderNotifierProvider
    if (hasInternet) {
      await ref.read(orderNotifierProvider).createOrder(order);
    } else {
      await OfflineOrderQueueService.instance.enqueueOrder(
        businessId: effectiveBusinessId,
        branchId: effectiveBranchId,
        order: order,
      );
    }
  }

  void _clearDirectDiningAndNavigate(BuildContext context) {
    // Clear direct dining state when going back
    ref.read(directDiningProvider.notifier).state = const DirectDiningState();
    _navigateToClientShell(context);
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);
    final totalAmount = cartNotifier.totalAmount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Cart'),
        leading: IconButton(
          onPressed: () => _clearDirectDiningAndNavigate(context),
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            onPressed: cartItems.isEmpty ? null : cartNotifier.clearCart,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear Cart',
          ),
        ],
      ),
      body: cartItems.isEmpty
          ? _buildEmptyCart(context)
          : _buildCartList(context, cartItems),
      bottomNavigationBar: _buildCartSummary(
        context,
        ref,
        totalAmount,
        items: cartItems,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showProductSelectionDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Products'),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 8),
          Text(
            'No products in cart',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartList(BuildContext context, List<OrderItem> cartItems) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: cartItems.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final item = cartItems[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(item.productName),
          subtitle: Text('Rs ${item.price.toStringAsFixed(2)} each'),
          trailing: Text(
            'Rs ${(item.price * item.quantity).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        );
      },
    );
  }

  Widget _buildCartSummary(
    BuildContext context,
    WidgetRef ref,
    double totalAmount, {
    required List<OrderItem> items,
  }) {
    final bool isCartEmpty = items.isEmpty;
    final bool isQrCodeOrder = _isDirectDiningOrder;

    return Container(
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
          if (isQrCodeOrder) ...[
            Row(
              children: [
                Icon(Icons.qr_code, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Table Number: $_currentTableId',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.restaurant, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Dine-in Order',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ] else ...[
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'Regular Order',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Rs ${totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: isQrCodeOrder ? 'Place Order Now' : 'Proceed to Checkout',
            onTap: isCartEmpty
                ? () {}
                : () => _handleCompleteOrder(
                    context,
                    ref,
                    items: items,
                    totalAmount: totalAmount,
                  ),
          ),
          if (isQrCodeOrder) ...[
            const SizedBox(height: 8),
            Text(
              'Order will be placed directly for table dining',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.green,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
