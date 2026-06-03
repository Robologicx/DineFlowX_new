import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineOrderSyncStatus {
  final int pendingOrders;
  final DateTime? lastSyncAt;
  final bool isSyncing;

  const OfflineOrderSyncStatus({
    required this.pendingOrders,
    required this.lastSyncAt,
    required this.isSyncing,
  });
}

class OfflineOrderQueueService {
  OfflineOrderQueueService._();

  static final OfflineOrderQueueService instance = OfflineOrderQueueService._();

  static const String _storageKey = 'offline_order_queue_v1';
  static const String _lastSyncStorageKey = 'offline_order_queue_last_sync_v1';
  static const Duration _retryInterval = Duration(seconds: 20);

  static final ValueNotifier<OfflineOrderSyncStatus> statusNotifier =
      ValueNotifier(
        const OfflineOrderSyncStatus(
          pendingOrders: 0,
          lastSyncAt: null,
          isSyncing: false,
        ),
      );

  SharedPreferences? _prefs;
  Timer? _retryTimer;
  StreamSubscription<dynamic>? _connectivitySubscription;
  bool _isStarted = false;
  bool _isProcessing = false;
  List<Map<String, dynamic>> _queue = [];
  DateTime? _lastSyncAt;

  Future<void> start() async {
    if (_isStarted) return;

    _prefs = await SharedPreferences.getInstance();
    _loadQueue();
    final lastSyncMillis = _prefs?.getInt(_lastSyncStorageKey);
    if (lastSyncMillis != null) {
      _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }
    _emitStatus();

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      unawaited(processQueue());
    });

    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      dynamic result,
    ) {
      if (_hasConnection(result)) {
        unawaited(processQueue());
      }
    });

    _isStarted = true;
    unawaited(processQueue());
  }

  Future<bool> hasInternetConnection() async {
    final dynamic result = await Connectivity().checkConnectivity();
    return _hasConnection(result);
  }

  Future<void> enqueueOrder({
    required String businessId,
    required String branchId,
    required OrderModel order,
  }) async {
    await start();

    final localOrderId = order.orderId.trim().isEmpty
        ? 'offline_${DateTime.now().microsecondsSinceEpoch}'
        : order.orderId;

    final task = <String, dynamic>{
      'id': '${DateTime.now().microsecondsSinceEpoch}_$localOrderId',
      'businessId': businessId,
      'branchId': branchId,
      'orderDocId': localOrderId,
      'orderPayload': _toSerializableOrderPayload(order),
      'attempts': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    _queue.add(task);
    await _persistQueue();
    _emitStatus();
  }

  Future<void> processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

    final online = await hasInternetConnection();
    if (!online) return;

    _isProcessing = true;
    _emitStatus();
    try {
      final pendingTasks = List<Map<String, dynamic>>.from(_queue);

      for (final task in pendingTasks) {
        final success = await _processSingleTask(task);
        if (success) {
          _queue.removeWhere((element) => element['id'] == task['id']);
        } else {
          final index = _queue.indexWhere((e) => e['id'] == task['id']);
          if (index != -1) {
            final attempts = (_queue[index]['attempts'] as int? ?? 0) + 1;
            _queue[index]['attempts'] = attempts;
            _queue[index]['lastAttemptAt'] =
                DateTime.now().millisecondsSinceEpoch;
          }
        }
      }

      await _persistQueue();
      _emitStatus();
    } finally {
      _isProcessing = false;
      _emitStatus();
    }
  }

  Future<bool> _processSingleTask(Map<String, dynamic> task) async {
    try {
      final businessId = task['businessId'] as String;
      final branchId = task['branchId'] as String;
      final orderDocId = task['orderDocId'] as String;
      final orderPayload = Map<String, dynamic>.from(
        task['orderPayload'] as Map,
      );

      final createdAtMs = orderPayload.remove('createdAtMs') as int;
      final updatedAtMs = orderPayload.remove('updatedAtMs') as int;

      orderPayload['createdAt'] = Timestamp.fromMillisecondsSinceEpoch(
        createdAtMs,
      );
      orderPayload['updatedAt'] = Timestamp.fromMillisecondsSinceEpoch(
        updatedAtMs,
      );

      await FirebaseFirestore.instance
          .collection('businesses')
          .doc(businessId)
          .collection('branches')
          .doc(branchId)
          .collection('orders')
          .doc(orderDocId)
          .set(orderPayload, SetOptions(merge: true));

      _lastSyncAt = DateTime.now();
      await _prefs?.setInt(
        _lastSyncStorageKey,
        _lastSyncAt!.millisecondsSinceEpoch,
      );

      return true;
    } catch (e) {
      debugPrint('Offline order sync failed: $e');
      return false;
    }
  }

  Map<String, dynamic> _toSerializableOrderPayload(OrderModel order) {
    return {
      'userId': order.userId,
      'userName': order.userName,
      'userPhoneNo': order.userPhoneNo,
      'orderType': order.orderType.toString().split('.').last,
      'items': order.items.map((item) => item.toMap()).toList(),
      'totalAmount': order.totalAmount,
      'orderStatus': order.orderStatus.toString().split('.').last,
      'createdAtMs': order.createdAt.millisecondsSinceEpoch,
      'updatedAtMs': order.updatedAt.millisecondsSinceEpoch,
      'deliveryAddress': order.deliveryAddress,
      'deliveryLocation': order.deliveryLocation != null
          ? {
              'lat': order.deliveryLocation!.latitude,
              'lng': order.deliveryLocation!.longitude,
            }
          : null,
      'diningTable': order.diningTable?.toMap(),
      'waiterId': order.waiterId,
      'waiterName': order.waiterName,
      'additionalNotes': order.additionalNotes,
    };
  }

  void _loadQueue() {
    final raw = _prefs?.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _queue = [];
      return;
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      _queue = decoded
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    } catch (_) {
      _queue = [];
    }
  }

  Future<void> _persistQueue() async {
    final payload = jsonEncode(_queue);
    await _prefs?.setString(_storageKey, payload);
  }

  bool _hasConnection(dynamic result) {
    if (result is ConnectivityResult) {
      return result != ConnectivityResult.none;
    }
    if (result is List<ConnectivityResult>) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    return false;
  }

  void _emitStatus() {
    statusNotifier.value = OfflineOrderSyncStatus(
      pendingOrders: _queue.length,
      lastSyncAt: _lastSyncAt,
      isSyncing: _isProcessing,
    );
  }
}
