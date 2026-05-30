import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/repositories/order_repository.dart';
import 'package:hotel_management_system/data/services/order_service.dart';
import 'package:uuid/uuid.dart';

class OrderState {
  final List<OrderModel> orders;
  final OrderModel? selectedOrder;
  final bool isLoading;
  final String? error;

  const OrderState({
    this.orders = const [],
    this.selectedOrder,
    this.isLoading = false,
    this.error,
  });

  OrderState copyWith({
    List<OrderModel>? orders,
    OrderModel? selectedOrder,
    bool? isLoading,
    String? error,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      selectedOrder: selectedOrder ?? this.selectedOrder,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  final OrderService _service;

  OrderNotifier(this._service) : super(const OrderState());

  Future<void> loadOrdersByUser(String userId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _service.getOrdersByUser(userId);
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadOrderById(String orderId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final order = await _service.getOrderById(orderId);
      state = state.copyWith(selectedOrder: order, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      await _service.createOrder(order);
      // await loadOrdersByUser(order.userId); // refresh list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> createQRCodeOrder({
    required List<OrderItem> items,
    required double totalAmount,
    required String businessId,
    required String branchId,
    required String tableId,
  }) async {
    try {
      // Create a new order for QR code (guest user)
      final order = OrderModel(
        orderId: Uuid().v4(), // You'll need to implement this
        orderStatus: OrderStatus.pending,
        diningTable: TableModel(
          id: tableId,
          businessId: businessId,
          branchId: branchId,
          tableNumber: '',
          seats: 0,
          status: TableStatus.occupied,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        userId: 'guest', // or null, depending on your model
        userName: 'Guest Customer',
        items: items,
        totalAmount: totalAmount,
        orderType: OrderType.dining, // Set as dining order
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        // Add any other required fields for your OrderModel
      );

      // Use your existing createOrder method
      await createOrder(order);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow; // Re-throw to handle in the UI
    }
  }

  Future<void> updateOrderStatus(
    OrderModel order,
    OrderStatus status,
    TableModel? table,
  ) async {
    // this method is responsible for updating order status and dining table status if order type is dining
    try {
      await _service.updateOrderStatus(order.orderId, status);
      if (order.orderType == OrderType.dining && table != null) {
        await _service.updateDiningTableStatus(order.orderId, table, status);
      }
      await loadOrderById(order.orderId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateDiningTable(String orderId, TableModel table) async {
    try {
      await _service.updateDiningTable(orderId, table);
      await loadOrderById(orderId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> assignWaiter(
    String orderId,
    String waiterId,
    String waiterName,
  ) async {
    try {
      await _service.assignWaiter(orderId, waiterId, waiterName);
      await loadOrderById(orderId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteOrder(String orderId) async {
    try {
      await _service.deleteOrder(orderId);
      // await loadOrdersByUser(userId);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  // Real-time listening method
  void listenToOrdersStream([String? userId]) {
    // _service
    //     .ordersStream(userId)
    //     .listen(
    //       (orders) {
    //         state = state.copyWith(orders: orders, isLoading: false);
    //       },
    //       onError: (e) {
    //         state = state.copyWith(error: e.toString(), isLoading: false);
    //       },
    //     );
  }

  Future<void> loadAllOrders() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _service.getAllOrders();
      // sort list by date / time and reverse the order.
      orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      // orders.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadOrdersByStatus(List<OrderStatus> status) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final orders = await _service.getOrdersByStatus(status);
      state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadOrdersByType(OrderType type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // final orders = await _service.getOrdersByType(type);
      // state = state.copyWith(orders: orders, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final orderNotifierProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(
    businessId: BusinessRepository.temporaryBusinesshId,
    branchId: BusinessRepository.temporaryBranchId,
    tableNotifier: null,
  );
});
