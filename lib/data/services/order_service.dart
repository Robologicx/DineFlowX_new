import 'package:hotel_management_system/data/models/table_model.dart';

import '../repositories/order_repository.dart';
import '../models/order_model.dart';
// Here’s the OrderService class that supports:
// Creating orders
// Getting order(s)
// Updating order status
// Updating dining table
// Assigning waiter
// Deleting orders

class OrderService {
  final OrderRepository _orderRepository;

  OrderService(this._orderRepository);

  /// Create a new order
  Future<void> createOrder(OrderModel order) async {
    if (order.items.isEmpty) {
      throw Exception("Order must contain at least one item.");
    } else {
      await _orderRepository.createOrder(order);
    }
  }

  /// Create a new order
  Future<List<OrderModel>> getAllOrders() async {
    return await _orderRepository.getAllOrders();
  }

  /// Listen all orders in real-time
  Stream<List<OrderModel>> getAllOrdersStream() {
    return _orderRepository.getAllOrdersStream();
  }

  /// Listen today's orders in real-time for lightweight loading.
  Stream<List<OrderModel>> getTodayOrdersStream() {
    return _orderRepository.getTodayOrdersStream();
  }

  /// Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    return await _orderRepository.getOrderById(orderId);
  }

  /// Get order by ID
  Future<List<OrderModel>?> getOrdersByStatus(
    List<OrderStatus> orderStatuses,
  ) async {
    return await _orderRepository.getOrdersByStatus(orderStatuses);
  }

  /// Get all orders for a specific user
  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    return await _orderRepository.getOrdersByUser(userId);
  }

  /// Update the status of an order
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _orderRepository.updateOrderStatus(orderId, status);
  }

  /// Change dining table number (for waiters/admins)
  Future<void> updateDiningTable(String orderId, TableModel table) async {
    await _orderRepository.updateDiningTable(orderId, table);
  }

  /// Change dining table status - ready / cleaning / reserved in table repository.
  Future<void> updateDiningTableStatus(
    String orderId,
    TableModel table,
    OrderStatus status,
  ) async {
    await _orderRepository.updateDiningTableStatus(orderId, table, status);
  }

  /// Assign a waiter to an order (for admin/owner)
  Future<void> assignWaiter(
    String orderId,
    String waiterId,
    String waiterName,
  ) async {
    await _orderRepository.assignWaiter(orderId, waiterId, waiterName);
  }

  /// Delete an order (admin/owner only)
  Future<void> deleteOrder(String orderId) async {
    await _orderRepository.deleteOrder(orderId);
  }
}
