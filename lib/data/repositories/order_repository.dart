import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/state_management/table_state_and_notifier.dart';

class OrderRepository {
  OrderRepository({
    required String businessId,
    required String branchId,
    required TableNotifier? tableNotifier,
  }) : _businessId = businessId,
       _branchId = branchId,
       _tableNotifier = tableNotifier;
  CollectionReference<Map<String, dynamic>> get _ordersRef => FirebaseFirestore
      .instance
      .collection('businesses')
      .doc(_businessId)
      .collection('branches')
      .doc(_branchId)
      .collection('orders');

  final String _businessId;
  final String _branchId;
  final TableNotifier? _tableNotifier;

  OrderModel? _safeOrderFromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    try {
      final data = doc.data();
      if (data.isEmpty) return null;
      return OrderModel.fromMap(data, doc.id);
    } catch (e) {
      debugPrint('Skipping malformed order document ${doc.id}: $e');
      return null;
    }
  }

  /// Create a new order
  Future<void> createOrder(OrderModel order) async {
    final Map<String, dynamic> orderMap = order.toMap();

    List<Map<String, dynamic>> mapOfOrderItems;
    if (order.items.isNotEmpty) {
      mapOfOrderItems = order.items.map((item) => item.toMap()).toList();
    } else {
      mapOfOrderItems = [];
    }

    // ensure serialized items are used
    orderMap['items'] = mapOfOrderItems;

    ////take away order should be completed directly//////
    if (order.orderType == OrderType.takeaway) {
      orderMap['orderStatus'] = OrderStatus.completed
          .toString()
          .split('.')
          .last;
      orderMap['diningTable'] = null;
      orderMap['waiterId'] = null;
      orderMap['waiterName'] = null;
    }

    // timestamps
    orderMap['createdAt'] = orderMap['createdAt'] ?? DateTime.now();
    orderMap['updatedAt'] = DateTime.now();

    // write the modified map (was using order.toMap() before)
    await _ordersRef.doc().set(orderMap);

    //////////////////////////////updat e table status /////////////////////////
    ///
    // If dining order, mark table as occupied
    if (order.orderType == OrderType.dining && order.diningTable != null) {
      // Get the docId from the ref (adjust if your firestore returns differently)
      final docId = _ordersRef.doc().id;
      await updateDiningTableStatus(
        docId,
        order.diningTable!,
        OrderStatus.inProgress,
      );
    }
    //////////////////update table status end/////////////////////////

    // await _ordersRef.doc().set({
    //   'userId': order.userId,
    //   'orderType': order.orderType.toString().split('.').last,
    //   'items': mapOfOrderItems,
    //   'totalAmount': order.totalAmount,
    //   'orderStatus': order.orderStatus.toString().split('.').last,
    //   'createdAt': order.createdAt,
    //   'updatedAt': order.updatedAt,
    //   'deliveryAddress': order.deliveryAddress,
    //   'deliveryLocation': order.deliveryLocation != null
    //       ? {
    //           'lat': order.deliveryLocation!.latitude,
    //           'lng': order.deliveryLocation!.longitude,
    //         }
    //       : null,
    //   'diningTable': order.diningTable?.toMap(),
    //   'waiterId': order.waiterId, // ✅ added waiter assignment
    //   'waiterName': order.waiterName,
    // });
  }

  /// Get all orders
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final snapshot = await _ordersRef.get();

      if (snapshot.docs.isEmpty) return [];

      final ordersList = snapshot.docs
          .where((doc) => doc.data().isNotEmpty) // ✅ Skip null documents
          .map((doc) {
            final data = doc.data();
            return OrderModel.fromMap(data, doc.id);
          })
          .toList();

      return ordersList;
    } catch (e, st) {
      debugPrint("🔥 Error fetching orders: $e");
      debugPrint(st.toString());
      return [];
    }
  }

  /// Get all orders as a real-time stream
  Stream<List<OrderModel>> getAllOrdersStream() {
    return _ordersRef.orderBy('createdAt', descending: true).snapshots().map((
      snapshot,
    ) {
      final orders = snapshot.docs
          .map(_safeOrderFromDoc)
          .whereType<OrderModel>()
          .toList();
      return orders;
    });
  }

  /// Get today's orders as a real-time stream for better performance.
  Stream<List<OrderModel>> getTodayOrdersStream() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startOfNextDay = startOfDay.add(const Duration(days: 1));

    return _ordersRef
        .where('createdAt', isGreaterThanOrEqualTo: startOfDay)
        .where('createdAt', isLessThan: startOfNextDay)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(_safeOrderFromDoc)
              .whereType<OrderModel>()
              .toList();
        });
  }

  /// Get order by Statuses
  Future<List<OrderModel>?> getOrdersByStatus(
    List<OrderStatus> orderStatuses,
  ) async {
    if (orderStatuses.isEmpty) return null;
    final list = await _ordersRef
        .where(
          'orderStatus',
          whereIn: orderStatuses
              .map((e) => e.toString().split('.').last)
              .toList(),
        )
        .get();

    if (list.docs.isEmpty) return null;
    List<OrderModel> orders = [];

    for (var doc in list.docs) {
      orders.add(OrderModel.fromMap(doc.data(), doc.id));
    }
    return orders;
  }

  /// Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    return OrderModel.fromMap(data, doc.id);
  }

  /// Get all orders for a user
  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    final querySnapshot = await _ordersRef
        .where('userId', isEqualTo: userId)
        .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      return OrderModel.fromMap(data, doc.id);
    }).toList();
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await _ordersRef.doc(orderId).update({
      'orderStatus': status.toString().split('.').last,
      'updatedAt': DateTime.now(),
    });
  }

  /// Change dining table number (for waiters/admins)
  Future<void> updateDiningTable(String orderId, TableModel table) async {
    await _ordersRef.doc(orderId).update({
      'diningTable': table.toMap(),
      'updatedAt': DateTime.now(),
    });
  }

  Future<void> updateDiningTableStatus(
    String orderId,
    TableModel table,
    OrderStatus orderStatus,
  ) async {
    if (orderStatus == OrderStatus.completed ||
        orderStatus == OrderStatus.cancelled ||
        orderStatus == OrderStatus.refunded) {
      _tableNotifier?.releaseTable(table.id);
    } else {
      _tableNotifier?.occupyTable(table.id);
    }
    // await _ordersRef.doc(orderId).update({
    //   'diningTable': table.toMap(),
    //   'updatedAt': DateTime.now(),
    // });
  }

  /// ✅ Assign waiter to an order (for admin/owner)
  Future<void> assignWaiter(
    String orderId,
    String waiterId,
    String waiterName,
  ) async {
    await _ordersRef.doc(orderId).update({
      'waiterId': waiterId,
      'waiterName': waiterName,
      'updatedAt': DateTime.now(),
    });
  }

  /// Delete an order (optional, for admin/owner only)
  Future<void> deleteOrder(String orderId) async {
    await _ordersRef.doc(orderId).delete();
  }
}
