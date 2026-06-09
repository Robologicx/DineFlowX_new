// sales_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
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

  DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final ms = int.tryParse(value);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  Future<DateTime?> getCurrentBusinessDayStartAt() async {
    final remoteDoc = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('settings')
        .doc('operations')
        .get(const GetOptions(source: Source.server));

    if (!remoteDoc.exists) return null;
    return _toDateTime(remoteDoc.data()?['currentDayStartAt']);
  }

  /// Get orders by date range and status
  Future<List<OrderModel>> getOrdersByDateRange({
    required DateTime startDate,
    required DateTime endDate,
    List<OrderStatus>? statuses,
  }) async {
    try {
      Query query = _ordersCollection
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate);

      final snapshot = await query.get(const GetOptions(source: Source.server));

      final allOrdersInRange = snapshot.docs
          .map(
            (doc) =>
                OrderModel.fromMap(doc.data() as Map<String, dynamic>, doc.id),
          )
          .toList();

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

  Future<List<OrderModel>> getOrdersForBusinessDayStart({
    required DateTime businessDayStartAt,
    List<OrderStatus>? statuses,
  }) async {
    try {
      final snapshot = await _ordersCollection
          .where('businessDayStartAt', isEqualTo: businessDayStartAt)
          .get(const GetOptions(source: Source.server));

      if (snapshot.docs.isNotEmpty) {
        final all = snapshot.docs
            .map(
              (doc) => OrderModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ),
            )
            .toList();
        if (statuses == null || statuses.isEmpty) return all;
        return all
            .where((order) => statuses.contains(order.orderStatus))
            .toList();
      }

      // Fallback for older orders that were created before businessDayStartAt tagging.
      return getOrdersByDateRange(
        startDate: businessDayStartAt,
        endDate: DateTime.now(),
        statuses: statuses,
      );
    } catch (e) {
      throw Exception('Failed to fetch business-day orders: $e');
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
      Query query = _ordersCollection
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate);

      final snapshot = await query.get(const GetOptions(source: Source.server));

      if (status == null) {
        return snapshot.docs.length;
      }

      final statusString = status.toString().split('.').last;

      return snapshot.docs.where((doc) {
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
      final snapshot = await _ordersCollection
          .where('orderStatus', whereIn: ['pending', 'inProgress', 'ready'])
          .get(const GetOptions(source: Source.server));

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
