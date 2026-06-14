import 'package:flutter/services.dart';
import 'package:hotel_management_system/data/models/order_model.dart';

import 'order_alert_service.dart';

OrderAlertPlatform createOrderAlertPlatform() => _NativeOrderAlertPlatform();

class _NativeOrderAlertPlatform implements OrderAlertPlatform {
  static const MethodChannel _channel = MethodChannel(
    'dineflowx.notifications',
  );

  @override
  Future<void> initialize() async {
    return;
  }

  @override
  Future<void> notifyNewOrder(OrderModel order) async {
    await initialize();
    try {
      await SystemSound.play(SystemSoundType.alert);
      await _channel.invokeMethod<void>(
        'showNewOrderNotification',
        <String, Object>{'title': _titleFor(order), 'body': _bodyFor(order)},
      );
    } catch (_) {
      // Keep order processing resilient even if notification display fails.
    }
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
