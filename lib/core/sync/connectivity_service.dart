import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  bool _isStarted = false;

  Future<void> start() async {
    if (_isStarted) return;

    final current = await Connectivity().checkConnectivity();
    isOnlineNotifier.value = _hasConnection(current);

    Connectivity().onConnectivityChanged.listen((dynamic ev) {
      isOnlineNotifier.value = _hasConnection(ev);
    });

    _isStarted = true;
  }

  bool _hasConnection(dynamic value) {
    if (value is ConnectivityResult) {
      return value != ConnectivityResult.none;
    }
    if (value is List<ConnectivityResult>) {
      return value.any((e) => e != ConnectivityResult.none);
    }
    return false;
  }
}
