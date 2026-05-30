import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/order_model.dart';

/// A clean, in-memory CartNotifier that does not persist to Hive.
/// Data resets when the app reloads (stateless web behavior).
class CartNotifier extends StateNotifier<List<OrderItem>> {
  CartNotifier() : super([]);

  /// Add or update an item in the cart
  void addToCart(OrderItem item) {
    final index = state.indexWhere((i) => i.productId == item.productId);

    if (index >= 0) {
      // If item already exists, increase quantity
      final updated = [...state];
      updated[index] = OrderItem(
        productId: item.productId,
        productName: item.productName,
        price: item.price,
        quantity: updated[index].quantity + item.quantity,
      );
      state = updated;
    } else {
      // Add new item
      state = [...state, item];
    }
  }

  /// Remove one product entirely
  void removeFromCart(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  /// Clear all items in cart
  void clearCart() {
    state = [];
  }

  /// Update a specific item (e.g. quantity change)
  void updateItem(OrderItem updatedItem) {
    state = [
      for (final item in state)
        if (item.productId == updatedItem.productId) updatedItem else item,
    ];
  }

  /// Calculate total amount of all cart items
  double get totalAmount =>
      state.fold(0.0, (sum, item) => sum + (item.price * item.quantity));
}

/// Riverpod provider (global cart state)
final cartProvider = StateNotifierProvider<CartNotifier, List<OrderItem>>(
  (ref) => CartNotifier(),
);
