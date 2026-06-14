import 'dart:html' as html;

import 'package:flutter/services.dart';
import 'package:hotel_management_system/data/models/order_model.dart';

import 'order_alert_service.dart';

OrderAlertPlatform createOrderAlertPlatform() => _WebOrderAlertPlatform();

class _WebOrderAlertPlatform implements OrderAlertPlatform {
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
  }

  @override
  Future<void> notifyNewOrder(OrderModel order) async {
    await initialize();
    await SystemSound.play(SystemSoundType.alert);

    final permission = html.Notification.permission;
    if (permission == 'denied') {
      return;
    }

    if (permission == 'default') {
      final result = await html.Notification.requestPermission();
      if (result != 'granted') {
        return;
      }
    }

    html.Notification(_titleFor(order), body: _bodyFor(order));
  }

  String _titleFor(OrderModel order) {
    if (_isQrDiningOrder(order)) {
      return 'New QR Dining Order';
    }
    if (_isOnlineDeliveryOrder(order)) {
      return 'New Online Delivery Order';
    }
    return 'New Order';
  }

  String _bodyFor(OrderModel order) {
    if (_isQrDiningOrder(order)) {
      final tableNumber = order.diningTable?.tableNumber ?? 'Unknown table';
      return '$tableNumber • ${order.userName}';
    }
    if (_isOnlineDeliveryOrder(order)) {
      return '${order.userName} • Rs ${order.totalAmount.toStringAsFixed(2)}';
    }
    return '${order.userName} • Rs ${order.totalAmount.toStringAsFixed(2)}';
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
}
