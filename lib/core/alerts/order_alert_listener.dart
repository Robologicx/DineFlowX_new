import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/core/alerts/order_alert_service.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/table_state_and_notifier.dart';

class OrderAlertListener extends ConsumerStatefulWidget {
  const OrderAlertListener({super.key});

  @override
  ConsumerState<OrderAlertListener> createState() => _OrderAlertListenerState();
}

class _OrderAlertListenerState extends ConsumerState<OrderAlertListener> {
  final Set<String> _knownOrderIds = <String>{};
  final Set<String> _alertedOrderIds = <String>{};
  String? _scopeKey;

  @override
  Widget build(BuildContext context) {
    final selectedUser = ref.watch(userProvider).selectedUser;
    if (selectedUser == null) {
      _resetScope();
      return const SizedBox.shrink();
    }

    final businessId = selectedUser.primarybusinessId.isNotEmpty
        ? selectedUser.primarybusinessId
        : BusinessRepository.temporaryBusinesshId;
    final branchId = selectedUser.primaryBranchId.isNotEmpty
        ? selectedUser.primaryBranchId
        : BusinessRepository.temporaryBranchId;

    final scopeKey = '$businessId::$branchId';
    if (_scopeKey != scopeKey) {
      _resetScope();
      _scopeKey = scopeKey;
    }

    final tableNotifier = ref.read(
      tableProvider((businessId: businessId, branchId: branchId)).notifier,
    );

    final ordersAsync = ref.watch(
      todayOrdersStreamProvider((
        businessId: businessId,
        branchId: branchId,
        tableNotifier: tableNotifier,
      )),
    );

    ref.listen<AsyncValue<List<OrderModel>>>(
      todayOrdersStreamProvider((
        businessId: businessId,
        branchId: branchId,
        tableNotifier: tableNotifier,
      )),
      (previous, next) {
        final orders = next.valueOrNull;
        if (orders == null) {
          return;
        }

        if (previous?.valueOrNull == null && _knownOrderIds.isEmpty) {
          _knownOrderIds.addAll(orders.map((order) => order.orderId));
          return;
        }

        _handleNewOrders(orders);
      },
    );

    final currentOrders = ordersAsync.valueOrNull;
    if (currentOrders != null && _knownOrderIds.isEmpty) {
      _knownOrderIds.addAll(currentOrders.map((order) => order.orderId));
    }

    return const SizedBox.shrink();
  }

  void _handleNewOrders(List<OrderModel> orders) {
    final seenNow = orders.map((order) => order.orderId).toSet();
    final newOrders = orders.where((order) {
      final isNew = !_knownOrderIds.contains(order.orderId);
      return isNew && _isAttentionOrder(order) && _isRecent(order);
    }).toList();

    _knownOrderIds
      ..clear()
      ..addAll(seenNow);

    if (newOrders.isEmpty) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final order in newOrders) {
        if (_alertedOrderIds.add(order.orderId)) {
          unawaited(OrderAlertService.instance.notifyNewOrder(order));
        }
      }
    });
  }

  bool _isRecent(OrderModel order) {
    const recentWindow = Duration(minutes: 5);
    return DateTime.now().difference(order.createdAt) < recentWindow;
  }

  bool _isAttentionOrder(OrderModel order) {
    return _isQrDiningOrder(order) || _isOnlineDeliveryOrder(order);
  }

  bool _isQrDiningOrder(OrderModel order) {
    final waiterId = (order.waiterId ?? '').toLowerCase();
    final waiterName = (order.waiterName ?? '').toLowerCase();
    return order.orderType == OrderType.dining &&
        (waiterId.startsWith('qr_') || waiterName.contains('qr code'));
  }

  bool _isOnlineDeliveryOrder(OrderModel order) {
    return order.orderType == OrderType.delivery &&
        (order.userId ?? '').trim().isNotEmpty;
  }

  void _resetScope() {
    _scopeKey = null;
    _knownOrderIds.clear();
    _alertedOrderIds.clear();
  }
}
