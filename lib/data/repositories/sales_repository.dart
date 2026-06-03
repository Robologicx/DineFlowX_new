// sales_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/data/models/order_model.dart';

/// Repository handles ONLY Firestore data access
/// No business logic, no calculations - pure data fetching
class SalesRepository {
  final String businessId;
  final String branchId;
  final FirebaseFirestore _firestore;

  SalesRepository({
    required this.businessId,
    required this.branchId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Helper to get the base collection query
  CollectionReference get _ordersCollection => _firestore
      .collection('businesses')
      .doc(businessId)
      .collection('branches')
      .doc(branchId)
      .collection('orders');

  Stream<T> _pollingStream<T>(
    Future<T> Function() loader, {
    Duration interval = const Duration(seconds: 2),
  }) async* {
    yield await loader();
    yield* Stream.periodic(interval).asyncMap((_) => loader());
  }

  Future<List<OrderModel>> _getLocalOrders() async {
    final rows = await OfflineLocalReadService.instance.getBranchCollection(
      businessId: businessId,
      branchId: branchId,
      collectionName: 'orders',
    );

    return rows
        .map(
          (row) =>
              OrderModel.fromMap(row, (row['__documentId'] ?? '').toString()),
        )
        .toList();
  }

  /// Get orders by date range and status
  Future<List<OrderModel>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    List<OrderStatus>? statuses,
  }) async {
    try {
      final localOrders = await _getLocalOrders();
      if (localOrders.isNotEmpty) {
        final filtered = localOrders.where((order) {
          final inRange =
              order.createdAt.isAfter(
                startDate.subtract(const Duration(milliseconds: 1)),
              ) &&
              order.createdAt.isBefore(
                endDate.add(const Duration(milliseconds: 1)),
              );

          if (!inRange) return false;
          if (statuses == null || statuses.isEmpty) return true;
          return statuses.contains(order.orderStatus);
        }).toList();

        return filtered;
      }

      // 1. Fetch ALL orders in the date range.
      Query query = _ordersCollection
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate);

      final snapshot = await query.get();

      // 2. Map documents to models - FIX APPLIED HERE:
      final allOrdersInRange = snapshot.docs
          .map(
            (doc) => OrderModel.fromMap(
              // Explicitly cast the returned data map
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();

      // 3. Filter by status locally in Dart
      if (statuses == null || statuses.isEmpty) {
        return allOrdersInRange;
      }

      return allOrdersInRange.where((order) {
        return statuses.contains(order.orderStatus);
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders: $e');
    }
  }

  /// Get completed orders only (for revenue calculation)
  Future<List<OrderModel>> getCompletedOrders({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return getOrdersByDateRange(
      startDate: startDate,
      endDate: endDate,
      statuses: [
        OrderStatus.completed,
        OrderStatus.pending,
        OrderStatus.inProgress,
      ],
    );
  }

  /// Get orders by specific order type
  Future<List<OrderModel>> getOrdersByType({
    required DateTime startDate,
    required DateTime endDate,
    required OrderType orderType,
  }) async {
    try {
      // 1. Get all completed orders (which uses the updated date range filter)
      final orders = await getCompletedOrders(
        startDate: startDate,
        endDate: endDate,
      );

      // 2. Filter by order type locally
      return orders.where((order) {
        return order.orderType == orderType;
      }).toList();
    } catch (e) {
      throw Exception('Failed to fetch orders by type: $e');
    }
  }

  /// Get cancelled/refunded orders (for loss analysis)
  Future<List<OrderModel>> getCancelledOrders({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return getOrdersByDateRange(
      startDate: startDate,
      endDate: endDate,
      statuses: [OrderStatus.cancelled, OrderStatus.refunded],
    );
  }

  /// Get total order count in date range
  Future<int> getOrderCount({
    required DateTime startDate,
    required DateTime endDate,
    OrderStatus? status,
  }) async {
    try {
      final localOrders = await _getLocalOrders();
      if (localOrders.isNotEmpty) {
        return localOrders.where((order) {
          final inRange =
              order.createdAt.isAfter(
                startDate.subtract(const Duration(milliseconds: 1)),
              ) &&
              order.createdAt.isBefore(
                endDate.add(const Duration(milliseconds: 1)),
              );
          if (!inRange) return false;
          if (status == null) return true;
          return order.orderStatus == status;
        }).length;
      }

      // Query by date range only
      Query query = _ordersCollection
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate);

      final snapshot = await query.get();

      // Filter count locally
      if (status == null) {
        return snapshot.docs.length;
      }

      final statusString = status.toString().split('.').last;

      return snapshot.docs.where((doc) {
        // FIX APPLIED HERE: Safely access data map and check for null
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) return false;
        return data['orderStatus'] == statusString;
      }).length;
    } catch (e) {
      throw Exception('Failed to get order count: $e');
    }
  }

  /// Stream orders for real-time updates (for dashboard)
  Stream<List<OrderModel>> streamActiveOrders() {
    return _pollingStream(() async {
      final localOrders = await _getLocalOrders();
      if (localOrders.isNotEmpty) {
        final active = localOrders.where((order) {
          return order.orderStatus == OrderStatus.pending ||
              order.orderStatus == OrderStatus.inProgress ||
              order.orderStatus == OrderStatus.ready;
        }).toList();

        active.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return active;
      }

      final snapshot = await _ordersCollection
          .where('orderStatus', whereIn: ['pending', 'inProgress', 'ready'])
          .get();

      return snapshot.docs
          .map(
            (doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();
    });
  }

  /// Get orders grouped by day (for charts)
  Future<Map<DateTime, List<OrderModel>>> getOrdersByDay({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final orders = await getCompletedOrders(
      startDate: startDate,
      endDate: endDate,
    );

    final groupedOrders = <DateTime, List<OrderModel>>{};

    for (var order in orders) {
      final date = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );

      if (!groupedOrders.containsKey(date)) {
        groupedOrders[date] = [];
      }
      groupedOrders[date]!.add(order);
    }

    return groupedOrders;
  }
}
