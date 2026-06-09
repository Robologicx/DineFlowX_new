import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import 'package:hotel_management_system/data/models/close_day_report.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/repositories/expense_repository.dart';
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

  DocumentReference<Map<String, dynamic>> get _operationsSettingsRef =>
      FirebaseFirestore.instance
          .collection('businesses')
          .doc(_businessId)
          .collection('branches')
          .doc(_branchId)
          .collection('settings')
          .doc('operations');

  final String _businessId;
  final String _branchId;
  final TableNotifier? _tableNotifier;
  static const Duration _statusUpdateWait = Duration(milliseconds: 1200);

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

  String _businessDayIdFromStart(DateTime startAt) {
    final y = startAt.year.toString().padLeft(4, '0');
    final m = startAt.month.toString().padLeft(2, '0');
    final d = startAt.day.toString().padLeft(2, '0');
    final h = startAt.hour.toString().padLeft(2, '0');
    final min = startAt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d-$h$min';
  }

  Future<DateTime?> _getCurrentDayStartAtFromStore() async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'settings',
      documentId: 'operations',
    );

    final localStart = _toDateTime(localDoc?['currentDayStartAt']);
    if (localStart != null) {
      return localStart;
    }

    final remoteDoc = await _operationsSettingsRef.get();
    if (!remoteDoc.exists) return null;
    return _toDateTime(remoteDoc.data()?['currentDayStartAt']);
  }

  Future<DateTime> ensureCurrentDayStartAt() async {
    final existing = await _getCurrentDayStartAtFromStore();
    if (existing != null) {
      return existing;
    }

    final now = DateTime.now();
    final nowUtc = now.toUtc();
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/settings/operations',
      data: {
        'currentDayStartAt': nowUtc,
        'currentBusinessDayId': _businessDayIdFromStart(nowUtc),
        'updatedAt': nowUtc,
      },
      merge: true,
    );
    return nowUtc;
  }

  Future<List<OrderModel>> _getOrdersInRange({
    required DateTime start,
    required DateTime end,
  }) async {
    final localOrders = await _getLocalOrders();
    if (localOrders.isNotEmpty) {
      final filtered = localOrders.where((order) {
        return !order.createdAt.isBefore(start) &&
            !order.createdAt.isAfter(end);
      }).toList();
      filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return filtered;
    }

    final snapshot = await _ordersRef
        .where('createdAt', isGreaterThanOrEqualTo: start)
        .where('createdAt', isLessThanOrEqualTo: end)
        .get();

    return snapshot.docs
        .map(_safeOrderFromDoc)
        .whereType<OrderModel>()
        .toList();
  }

  Future<CloseDayReport> _buildCloseDayReport({
    required DateTime dayStartAt,
    required DateTime dayClosedAt,
  }) async {
    final orders = await _getOrdersInRange(start: dayStartAt, end: dayClosedAt);
    final expenses = await ExpenseRepository(
      businessId: _businessId,
      branchId: _branchId,
    ).getExpensesByDateRange(startDate: dayStartAt, endDate: dayClosedAt);

    final completedOrders = orders
        .where((o) => o.orderStatus == OrderStatus.completed)
        .length;
    final pendingOrders = orders
        .where((o) => o.orderStatus == OrderStatus.pending)
        .length;
    final inProgressOrders = orders
        .where((o) => o.orderStatus == OrderStatus.inProgress)
        .length;
    final cancelledOrders = orders
        .where((o) => o.orderStatus == OrderStatus.cancelled)
        .length;
    final refundedOrders = orders
        .where((o) => o.orderStatus == OrderStatus.refunded)
        .length;

    final revenueOrders = orders.where((o) {
      return o.orderStatus == OrderStatus.completed ||
          o.orderStatus == OrderStatus.pending ||
          o.orderStatus == OrderStatus.inProgress;
    });

    final totalAmount = revenueOrders.fold<double>(
      0.0,
      (runningTotal, order) => runningTotal + order.totalAmount,
    );
    final totalExpenses = expenses.fold<double>(
      0.0,
      (runningTotal, expense) => runningTotal + expense.amount,
    );
    final cashInHandAfterExpenses = totalAmount - totalExpenses;

    return CloseDayReport(
      dayStartAt: dayStartAt,
      dayClosedAt: dayClosedAt,
      totalOrders: orders.length,
      completedOrders: completedOrders,
      pendingOrders: pendingOrders,
      inProgressOrders: inProgressOrders,
      cancelledOrders: cancelledOrders,
      refundedOrders: refundedOrders,
      totalAmount: totalAmount,
      totalExpenses: totalExpenses,
      cashInHandAfterExpenses: cashInHandAfterExpenses,
      profitOrLoss: cashInHandAfterExpenses,
    );
  }

  Future<CloseDayReport> closeCurrentDay({String? closedBy}) async {
    final currentDayStartAt = await _getCurrentDayStartAtFromStore();
    final nowUtc = DateTime.now().toUtc();

    final dayStartAt = currentDayStartAt ?? nowUtc;
    final report = await _buildCloseDayReport(
      dayStartAt: dayStartAt,
      dayClosedAt: nowUtc,
    );

    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/settings/operations',
      data: {
        'lastDayClosedAt': nowUtc,
        'lastDayClosedBy': closedBy,
        'currentDayStartAt': nowUtc,
        'currentBusinessDayId': _businessDayIdFromStart(nowUtc),
        'updatedAt': nowUtc,
      },
      merge: true,
    );

    return report;
  }

  Stream<DateTime> currentDayStartAtStream() {
    return Stream<DateTime>.multi((controller) {
      StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? sub;
      bool isCancelled = false;

      Future<void> emitFallback() async {
        if (isCancelled) return;
        final value = await ensureCurrentDayStartAt();
        if (isCancelled) return;
        controller.add(value);
      }

      sub = _operationsSettingsRef.snapshots().listen(
        (snapshot) async {
          final startAt = _toDateTime(snapshot.data()?['currentDayStartAt']);
          if (startAt != null) {
            controller.add(startAt);
            return;
          }
          await emitFallback();
        },
        onError: (_) async {
          await emitFallback();
        },
      );

      unawaited(emitFallback());

      controller.onCancel = () {
        isCancelled = true;
        sub?.cancel();
      };
    }).distinct((a, b) => a.millisecondsSinceEpoch == b.millisecondsSinceEpoch);
  }

  Future<List<OrderModel>> _getLocalOrders() async {
    final rows = await OfflineLocalReadService.instance.getBranchCollection(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'orders',
    );

    return rows
        .where(_looksLikeFullOrderDocument)
        .map(
          (row) =>
              OrderModel.fromMap(row, (row['__documentId'] ?? '').toString()),
        )
        .toList();
  }

  bool _looksLikeFullOrderDocument(Map<String, dynamic> row) {
    final id = (row['__documentId'] ?? '').toString();
    if (id.isEmpty) return false;

    // Guard against partial local stubs created by previous merge-write bugs.
    const requiredKeys = [
      'orderType',
      'items',
      'totalAmount',
      'orderStatus',
      'createdAt',
      'updatedAt',
    ];
    for (final key in requiredKeys) {
      if (!row.containsKey(key) || row[key] == null) return false;
    }

    return true;
  }

  List<OrderModel> _mergeOrdersPreferLocal({
    required List<OrderModel> local,
    required List<OrderModel> remote,
  }) {
    final merged = <String, OrderModel>{};

    for (final order in remote) {
      merged[order.orderId] = order;
    }
    for (final order in local) {
      merged[order.orderId] = order;
    }

    final list = merged.values.toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<OrderModel>> _fetchRemoteAllOrders() async {
    final snapshot = await _ordersRef
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map(_safeOrderFromDoc)
        .whereType<OrderModel>()
        .toList();
  }

  Stream<List<OrderModel>> _hybridOrdersStream({
    required Query<Map<String, dynamic>> remoteQuery,
    required List<OrderModel> Function(List<OrderModel> local) localSelector,
  }) {
    return Stream.multi((controller) {
      List<OrderModel> latestRemote = <OrderModel>[];
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? remoteSub;
      Timer? localTick;
      bool isCancelled = false;

      Future<void> emitMerged() async {
        if (isCancelled) return;
        final local = await _getLocalOrders();
        if (isCancelled) return;
        final selectedLocal = localSelector(local);
        final merged = _mergeOrdersPreferLocal(
          local: selectedLocal,
          remote: latestRemote,
        );
        controller.add(merged);
      }

      localTick = Timer.periodic(const Duration(seconds: 1), (_) {
        unawaited(emitMerged());
      });

      remoteSub = remoteQuery.snapshots().listen(
        (snapshot) {
          latestRemote = snapshot.docs
              .map(_safeOrderFromDoc)
              .whereType<OrderModel>()
              .toList();
          unawaited(emitMerged());
        },
        onError: (_) {
          // Keep local polling active even if remote listener errors.
        },
      );

      unawaited(emitMerged());

      controller.onCancel = () {
        isCancelled = true;
        localTick?.cancel();
        remoteSub?.cancel();
      };
    });
  }

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

  Future<void> _assertBusinessEnabled() async {
    final businessDoc = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(_businessId)
        .get();

    final data = businessDoc.data() ?? const <String, dynamic>{};
    final status = (data['status'] ?? 'active').toString().toLowerCase();
    final isActiveField = data['isActive'];
    final isDeleted = data['isDeleted'] == true || status == 'deleted';
    final isSuspended =
        status == 'suspended' || status == 'disabled' || isActiveField == false;

    if (isDeleted || isSuspended) {
      throw StateError(
        'Your business is disabled. Please contact DineFlowX team.',
      );
    }
  }

  /// Create a new order
  Future<void> createOrder(OrderModel order) async {
    await _assertBusinessEnabled();

    final currentDayStartAt = await ensureCurrentDayStartAt();
    final businessDayId = _businessDayIdFromStart(currentDayStartAt);

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
    orderMap['businessDayId'] = businessDayId;
    orderMap['businessDayStartAt'] = currentDayStartAt;

    // write the modified map (was using order.toMap() before)
    final orderDocRef = _ordersRef.doc();
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/orders/${orderDocRef.id}',
      data: orderMap,
      merge: false,
    );

    //////////////////////////////updat e table status /////////////////////////
    ///
    // If dining order, mark table as occupied
    if (order.orderType == OrderType.dining && order.diningTable != null) {
      try {
        await updateDiningTableStatus(
          orderDocRef.id,
          order.diningTable!,
          OrderStatus.inProgress,
        ).timeout(_statusUpdateWait);
      } on TimeoutException {
        unawaited(
          updateDiningTableStatus(
            orderDocRef.id,
            order.diningTable!,
            OrderStatus.inProgress,
          ).catchError((e) {
            debugPrint('Dining table status update deferred: $e');
          }),
        );
      } catch (e) {
        unawaited(
          updateDiningTableStatus(
            orderDocRef.id,
            order.diningTable!,
            OrderStatus.inProgress,
          ).catchError((err) {
            debugPrint('Dining table status update deferred: $err');
          }),
        );
        debugPrint('Dining table status immediate attempt failed: $e');
      }
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
      final localOrders = await _getLocalOrders();
      try {
        final remoteOrders = await _fetchRemoteAllOrders();
        return _mergeOrdersPreferLocal(
          local: localOrders,
          remote: remoteOrders,
        );
      } catch (_) {
        localOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return localOrders;
      }
    } catch (e, st) {
      debugPrint("🔥 Error fetching orders: $e");
      debugPrint(st.toString());
      return [];
    }
  }

  /// Get all orders as a real-time stream
  Stream<List<OrderModel>> getAllOrdersStream() {
    return _hybridOrdersStream(
      remoteQuery: _ordersRef.orderBy('createdAt', descending: true),
      localSelector: (local) => local,
    );
  }

  /// Get today's orders as a real-time stream for better performance.
  Stream<List<OrderModel>> getTodayOrdersStream() {
    return getCurrentBusinessDayOrdersStream();
  }

  Stream<List<OrderModel>> getCurrentBusinessDayOrdersStream() {
    return Stream.multi((controller) {
      StreamSubscription<DateTime>? dayStartSub;
      StreamSubscription<List<OrderModel>>? ordersSub;
      bool isCancelled = false;
      DateTime? activeStart;

      void resubscribeOrders(DateTime dayStartAt) {
        if (isCancelled) return;

        if (activeStart != null &&
            activeStart!.millisecondsSinceEpoch ==
                dayStartAt.millisecondsSinceEpoch) {
          return;
        }

        activeStart = dayStartAt;
        ordersSub?.cancel();
        ordersSub = _hybridOrdersStream(
          remoteQuery: _ordersRef
              .where('createdAt', isGreaterThanOrEqualTo: dayStartAt)
              .orderBy('createdAt', descending: true),
          localSelector: (local) => local
              .where(
                (order) =>
                    !order.createdAt.toUtc().isBefore(dayStartAt.toUtc()),
              )
              .toList(),
        ).listen(controller.add, onError: controller.addError);
      }

      dayStartSub = currentDayStartAtStream().listen(
        resubscribeOrders,
        onError: controller.addError,
      );

      controller.onCancel = () {
        isCancelled = true;
        ordersSub?.cancel();
        dayStartSub?.cancel();
      };
    });
  }

  /// Get order by Statuses
  Future<List<OrderModel>?> getOrdersByStatus(
    List<OrderStatus> orderStatuses,
  ) async {
    if (orderStatuses.isEmpty) return null;

    final set = orderStatuses.toSet();
    final localOrders = await _getLocalOrders();
    final localFiltered = localOrders
        .where((order) => set.contains(order.orderStatus))
        .toList();

    try {
      final list = await _ordersRef
          .where(
            'orderStatus',
            whereIn: orderStatuses
                .map((e) => e.toString().split('.').last)
                .toList(),
          )
          .get();

      final remoteFiltered = list.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();

      final merged = _mergeOrdersPreferLocal(
        local: localFiltered,
        remote: remoteFiltered,
      );
      return merged.isEmpty ? null : merged;
    } catch (_) {
      localFiltered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return localFiltered.isEmpty ? null : localFiltered;
    }
  }

  /// Get order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'orders',
      documentId: orderId,
    );
    if (localDoc != null) {
      return OrderModel.fromMap(localDoc, orderId);
    }

    final doc = await _ordersRef.doc(orderId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    return OrderModel.fromMap(data, doc.id);
  }

  /// Get all orders for a user
  Future<List<OrderModel>> getOrdersByUser(String userId) async {
    final localOrders = await _getLocalOrders();
    final localFiltered = localOrders
        .where((order) => (order.userId ?? '') == userId)
        .toList();

    try {
      final querySnapshot = await _ordersRef
          .where('userId', isEqualTo: userId)
          .get();

      final remoteFiltered = querySnapshot.docs
          .map((doc) => OrderModel.fromMap(doc.data(), doc.id))
          .toList();
      return _mergeOrdersPreferLocal(
        local: localFiltered,
        remote: remoteFiltered,
      );
    } catch (_) {
      localFiltered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return localFiltered;
    }
  }

  /// Update order status
  Future<void> updateOrderStatus(String orderId, OrderStatus status) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/orders/$orderId',
      data: {
        'orderStatus': status.toString().split('.').last,
        'updatedAt': DateTime.now(),
      },
      merge: true,
    );
  }

  /// Change dining table number (for waiters/admins)
  Future<void> updateDiningTable(String orderId, TableModel table) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/orders/$orderId',
      data: {'diningTable': table.toMap(), 'updatedAt': DateTime.now()},
      merge: true,
    );
  }

  Future<void> updateDiningTableStatus(
    String orderId,
    TableModel table,
    OrderStatus orderStatus,
  ) async {
    final tableStatus =
        (orderStatus == OrderStatus.completed ||
            orderStatus == OrderStatus.cancelled ||
            orderStatus == OrderStatus.refunded)
        ? TableStatus.available
        : TableStatus.occupied;

    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/diningTables/${table.id}',
      data: {
        'id': table.id,
        'businessId': table.businessId,
        'branchId': table.branchId,
        'status': tableStatus.name,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      merge: true,
    );

    if (_tableNotifier != null) {
      unawaited(_tableNotifier.loadAllTables());
    }
  }

  /// ✅ Assign waiter to an order (for admin/owner)
  Future<void> assignWaiter(
    String orderId,
    String waiterId,
    String waiterName,
  ) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/orders/$orderId',
      data: {
        'waiterId': waiterId,
        'waiterName': waiterName,
        'updatedAt': DateTime.now(),
      },
      merge: true,
    );
  }

  /// Delete an order (optional, for admin/owner only)
  Future<void> deleteOrder(String orderId) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/orders/$orderId',
    );
  }
}
