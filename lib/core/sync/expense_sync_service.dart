import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hotel_management_system/core/sync/connectivity_service.dart';
import 'package:hotel_management_system/data/models/expense_model.dart';

/// Real-time sync service for expenses with cloud-first strategy
/// - Prefers cloud reads when online
/// - Falls back to local when offline
/// - Syncs local cache with cloud changes automatically
class ExpenseSyncService {
  final String businessId;
  final String branchId;
  final FirebaseFirestore _firestore;

  StreamSubscription<QuerySnapshot>? _realtimeSubscription;
  final ValueNotifier<List<ExpenseModel>> _expensesNotifier = ValueNotifier([]);
  final ValueNotifier<bool> _isLoadingNotifier = ValueNotifier(false);
  final ValueNotifier<String?> _errorNotifier = ValueNotifier(null);

  bool _isInitialized = false;
  bool _isConnected = false;

  ExpenseSyncService({
    required this.businessId,
    required this.branchId,
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  // Public getters
  ValueNotifier<List<ExpenseModel>> get expensesNotifier => _expensesNotifier;
  ValueNotifier<bool> get isLoadingNotifier => _isLoadingNotifier;
  ValueNotifier<String?> get errorNotifier => _errorNotifier;

  List<ExpenseModel> get currentExpenses => _expensesNotifier.value;

  Stream<List<ExpenseModel>> get expensesStream =>
      _createStream(_expensesNotifier);

  bool get isInitialized => _isInitialized;

  /// Initialize and start listening to cloud expenses in real-time
  Future<void> initialize() async {
    if (_isInitialized) return;

    await ConnectivityService.instance.start();

    // Load initial data from cloud
    await _loadInitialExpenses();

    // Set up connectivity listener
    ConnectivityService.instance.isOnlineNotifier.addListener(
      _onConnectivityChanged,
    );

    // Set up real-time listener if online
    if (ConnectivityService.instance.isOnlineNotifier.value) {
      _startRealtimeSync();
    }

    _isInitialized = true;
  }

  /// Load initial expenses from cloud
  Future<void> _loadInitialExpenses() async {
    _isLoadingNotifier.value = true;
    _errorNotifier.value = null;

    try {
      final isOnline = ConnectivityService.instance.isOnlineNotifier.value;

      if (isOnline) {
        // Try cloud first
        await _loadFromCloud();
      } else {
        _expensesNotifier.value = [];
      }
    } catch (e) {
      debugPrint('Error loading initial expenses: $e');
      _errorNotifier.value = e.toString();
      _expensesNotifier.value = [];
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  /// Load expenses from Firestore cloud
  Future<void> _loadFromCloud() async {
    final snapshot = await _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('expenses')
        .orderBy('expenseDate', descending: true)
        .get();

    final expenses = snapshot.docs
        .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
        .toList();

    _expensesNotifier.value = expenses;
  }

  /// Start real-time listener for cloud expenses
  void _startRealtimeSync() {
    _isConnected = true;

    // Cancel previous subscription
    _realtimeSubscription?.cancel();

    _realtimeSubscription = _firestore
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('expenses')
        .orderBy('expenseDate', descending: true)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              final expenses = snapshot.docs
                  .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
                  .toList();

              _expensesNotifier.value = expenses;
              _errorNotifier.value = null;
            } catch (e) {
              debugPrint('Error syncing expenses: $e');
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
      // Just came online - start real-time sync and reload from cloud
      _startRealtimeSync();
      _loadFromCloud().catchError((e) {
        debugPrint('Error reloading expenses when coming online: $e');
      });
    } else if (!isNowOnline && _isConnected) {
      // Just went offline - stop real-time listener
      _stopRealtimeSync();
    }
  }

  /// Refresh expenses from cloud
  Future<void> refresh() async {
    if (!ConnectivityService.instance.isOnlineNotifier.value) {
      return;
    }

    _isLoadingNotifier.value = true;
    try {
      await _loadFromCloud();
    } catch (e) {
      debugPrint('Error refreshing expenses: $e');
      _errorNotifier.value = e.toString();
    } finally {
      _isLoadingNotifier.value = false;
    }
  }

  /// Get expenses by date range from current list
  List<ExpenseModel> getExpensesByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) {
    return _expensesNotifier.value
        .where(
          (expense) =>
              !expense.expenseDate.isBefore(startDate) &&
              !expense.expenseDate.isAfter(endDate),
        )
        .toList();
  }

  /// Get current business day expenses
  List<ExpenseModel> getCurrentBusinessDayExpenses(
    DateTime businessDayStartAt,
  ) {
    final businessDayEndAt = businessDayStartAt.add(const Duration(days: 1));

    return _expensesNotifier.value.where((expense) {
      final marker = expense.businessDayStartAt;
      if (marker != null) {
        return marker.millisecondsSinceEpoch ==
            businessDayStartAt.millisecondsSinceEpoch;
      }
      return !expense.expenseDate.isBefore(businessDayStartAt) &&
          expense.expenseDate.isBefore(businessDayEndAt);
    }).toList();
  }

  /// Create a stream from value notifier
  Stream<T> _createStream<T>(ValueNotifier<T> notifier) {
    final controller = StreamController<T>.broadcast();
    controller.add(notifier.value);

    void listener() {
      controller.add(notifier.value);
    }

    notifier.addListener(listener);

    controller.onCancel = () {
      notifier.removeListener(listener);
    };

    return controller.stream;
  }

  /// Dispose and clean up
  void dispose() {
    _realtimeSubscription?.cancel();
    ConnectivityService.instance.isOnlineNotifier.removeListener(
      _onConnectivityChanged,
    );
    _expensesNotifier.dispose();
    _isLoadingNotifier.dispose();
    _errorNotifier.dispose();
  }
}
