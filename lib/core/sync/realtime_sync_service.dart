import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hotel_management_system/core/sync/connectivity_service.dart';

/// Generic real-time sync service for any Firestore collection
/// Provides cloud-first read strategy with real-time updates
class RealtimeSyncService<T> {
  final String collectionPath;
  final T Function(Map<String, dynamic>, String) fromMap;
  final FirebaseFirestore _firestore;

  StreamSubscription<QuerySnapshot>? _realtimeSubscription;
  final ValueNotifier<List<T>> _itemsNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _errorNotifier = ValueNotifier(null);

  bool _isInitialized = false;
  bool _isConnected = false;

  RealtimeSyncService({
    required this.collectionPath,
    required this.fromMap,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Public getters
  List<T> get currentItems => _itemsNotifier.value;
  Stream<List<T>> get itemsStream => _createStream();
  ValueNotifier<bool> get isLoadingNotifier => _isLoadingNotifier;
  ValueNotifier<String?> get errorNotifier => _errorNotifier;
  bool get isInitialized => _isInitialized;

  /// Initialize and start real-time listening
  Future<void> initialize() async {
    if (_isInitialized) return;

    await ConnectivityService.instance.start();
    await _loadInitial();

    ConnectivityService.instance.isOnlineNotifier.addListener(
      _onConnectivityChanged,
    );

    if (ConnectivityService.instance.isOnlineNotifier.value) {
      _startRealtimeSync();
    }

    _isInitialized = true;
  }

  /// Load initial items from cloud
  Future<void> _loadInitial() async {
    _isLoadingNotifier.value = true;
    _errorNotifier.value = null;

    try {
      if (ConnectivityService.instance.isOnlineNotifier.value) {
        await _loadFromCloud();
      } else {
        _itemsNotifier.value = [];
      }
    } catch (e) {
      debugPrint('Error loading initial items: $e');
      _errorNotifier.value = e.toString();
      _itemsNotifier.value = [];
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  /// Load items from Firestore cloud
  Future<void> _loadFromCloud() async {
    final snapshot = await _firestore.collection(collectionPath).get();

    final items = snapshot.docs
        .map((doc) => fromMap(doc.data(), doc.id))
        .toList();

    _itemsNotifier.value = items;
  }

  /// Start real-time listener for collection
  void _startRealtimeSync() {
    _isConnected = true;
    _realtimeSubscription?.cancel();

    _realtimeSubscription = _firestore
        .collection(collectionPath)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final items = snapshot.docs
                  .map((doc) => fromMap(doc.data(), doc.id))
                  .toList();

              _itemsNotifier.value = items;
              _errorNotifier.value = null;
            } catch (e) {
              debugPrint('Error syncing items: $e');
              _errorNotifier.value = e.toString();
            }
          },
          onError: (error) {
            debugPrint('Real-time listener error: $error');
            _errorNotifier.value = error.toString();
          },
        );
  }

  /// Stop real-time listener
  void _stopRealtimeSync() {
    _realtimeSubscription?.cancel();
    _realtimeSubscription = null;
    _isConnected = false;
  }

  /// Handle connectivity changes
  void _onConnectivityChanged() {
    final isNowOnline = ConnectivityService.instance.isOnlineNotifier.value;

    if (isNowOnline && !_isConnected) {
      _startRealtimeSync();
      _loadFromCloud().catchError((e) {
        debugPrint('Error reloading when coming online: $e');
      });
    } else if (!isNowOnline && _isConnected) {
      _stopRealtimeSync();
    }
  }

  /// Refresh from cloud
  Future<void> refresh() async {
    if (!ConnectivityService.instance.isOnlineNotifier.value) {
      return;
    }

    _isLoadingNotifier.value = true;
    try {
      await _loadFromCloud();
    } catch (e) {
      debugPrint('Error refreshing: $e');
      _errorNotifier.value = e.toString();
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  /// Create stream from value notifier
  Stream<List<T>> _createStream() {
    final controller = StreamController<List<T>>.broadcast();
    controller.add(_itemsNotifier.value);

    void listener() {
      controller.add(_itemsNotifier.value);
    }

    _itemsNotifier.addListener(listener);

    controller.onCancel = () {
      _itemsNotifier.removeListener(listener);
    };

    return controller.stream;
  }

  /// Dispose and clean up
  void dispose() {
    _realtimeSubscription?.cancel();
    ConnectivityService.instance.isOnlineNotifier.removeListener(
      _onConnectivityChanged,
    );
    _itemsNotifier.dispose();
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
  }
}
