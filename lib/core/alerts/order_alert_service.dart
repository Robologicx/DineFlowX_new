import 'package:hotel_management_system/data/models/order_model.dart';

import 'order_alert_service_native.dart'
    if (dart.library.html) 'order_alert_service_web.dart';

class OrderAlertService {
  OrderAlertService._();

  static final OrderAlertService instance = OrderAlertService._();

  final OrderAlertPlatform _platform = createOrderAlertPlatform();

  Future<void> initialize() => _platform.initialize();

  Future<void> notifyNewOrder(OrderModel order) =>
      _platform.notifyNewOrder(order);
}

abstract class OrderAlertPlatform {
  Future<void> initialize();

  Future<void> notifyNewOrder(OrderModel order);
}
