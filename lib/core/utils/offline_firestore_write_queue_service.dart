import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:hotel_management_system/core/local/isar_collections.dart';
import 'package:hotel_management_system/core/local/isar_database_service.dart';
import 'package:hotel_management_system/core/sync/connectivity_service.dart';

class OfflineFirestoreWriteSyncStatus {
  final int pendingWrites;
  final DateTime? lastSyncAt;
  final bool isSyncing;

  const OfflineFirestoreWriteSyncStatus({
    required this.pendingWrites,
    required this.lastSyncAt,
    required this.isSyncing,
  });
}

class OfflineFirestoreWriteQueueService {
  OfflineFirestoreWriteQueueService._();

  static final OfflineFirestoreWriteQueueService instance =
      OfflineFirestoreWriteQueueService._();

  static const Duration _retryInterval = Duration(seconds: 20);

  static final ValueNotifier<OfflineFirestoreWriteSyncStatus> statusNotifier =
      ValueNotifier(
        const OfflineFirestoreWriteSyncStatus(
          pendingWrites: 0,
          lastSyncAt: null,
          isSyncing: false,
        ),
      );

  Timer? _retryTimer;
  bool _isStarted = false;
  bool _isProcessing = false;
  DateTime? _lastSyncAt;
  int _pendingWrites = 0;

  Future<void> start() async {
    if (_isStarted) return;

    if (kIsWeb) {
      await ConnectivityService.instance.start();
      _isStarted = true;
      _emitStatus();
      return;
    }

    await IsarDatabaseService.instance.initialize();
    await ConnectivityService.instance.start();
    await _loadStatusFromDb();
    _emitStatus();

    _retryTimer?.cancel();
    _retryTimer = Timer.periodic(_retryInterval, (_) {
      unawaited(processQueue());
    });

    ConnectivityService.instance.isOnlineNotifier.addListener(() {
      if (ConnectivityService.instance.isOnlineNotifier.value) {
        unawaited(processQueue());
      }
    });

    _isStarted = true;
    unawaited(processQueue());
  }

  Future<bool> hasInternetConnection() async {
    await ConnectivityService.instance.start();
    return ConnectivityService.instance.isOnlineNotifier.value;
  }

  Future<void> enqueueSet({
    required String documentPath,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    if (kIsWeb) {
      final docRef = FirebaseFirestore.instance.doc(documentPath);
      if (merge) {
        await docRef.set(data, SetOptions(merge: true));
      } else {
        await docRef.set(data);
      }
      return;
    }

    await start();

    await _upsertLocalCache(
      documentPath: documentPath,
      data: data,
      merge: merge,
    );
    await _enqueue(
      operationType: 'set',
      documentPath: documentPath,
      payload: data,
      merge: merge,
    );
    _pendingWrites = _pendingWrites + 1;
    _emitStatus();

    unawaited(processQueue());
  }

  Future<void> enqueueDelete({required String documentPath}) async {
    if (kIsWeb) {
      await FirebaseFirestore.instance.doc(documentPath).delete();
      return;
    }

    await start();

    await _markDeletedInLocalCache(documentPath);
    await _enqueue(operationType: 'delete', documentPath: documentPath);
    _pendingWrites = _pendingWrites + 1;
    _emitStatus();

    unawaited(processQueue());
  }

  Future<bool> setOrQueue({
    required String documentPath,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    if (kIsWeb) {
      try {
        final docRef = FirebaseFirestore.instance.doc(documentPath);
        if (merge) {
          await docRef.set(data, SetOptions(merge: true));
        } else {
          await docRef.set(data);
        }
        return true;
      } catch (_) {
        return false;
      }
    }

    await start();

    await _upsertLocalCache(
      documentPath: documentPath,
      data: data,
      merge: merge,
    );
    final hasInternet = await hasInternetConnection();
    if (hasInternet) {
      try {
        final docRef = FirebaseFirestore.instance.doc(documentPath);
        if (merge) {
          await docRef.set(data, SetOptions(merge: true));
        } else {
          await docRef.set(data);
        }
        await _markLocalPending(documentPath: documentPath, pending: false);
        return true;
      } catch (_) {
        await enqueueSet(documentPath: documentPath, data: data, merge: merge);
        return false;
      }
    }

    await enqueueSet(documentPath: documentPath, data: data, merge: merge);
    return false;
  }

  Future<bool> deleteOrQueue({required String documentPath}) async {
    if (kIsWeb) {
      try {
        await FirebaseFirestore.instance.doc(documentPath).delete();
        return true;
      } catch (_) {
        return false;
      }
    }

    await start();

    await _markDeletedInLocalCache(documentPath);

    final hasInternet = await hasInternetConnection();
    if (hasInternet) {
      try {
        await FirebaseFirestore.instance.doc(documentPath).delete();
        await _markLocalPending(documentPath: documentPath, pending: false);
        return true;
      } catch (_) {
        await enqueueDelete(documentPath: documentPath);
        return false;
      }
    }

    await enqueueDelete(documentPath: documentPath);
    return false;
  }

  Future<void> processQueue() async {
    if (kIsWeb) return;
    if (_isProcessing) return;

    final pendingTasks = await _pendingTasks();
    if (pendingTasks.isEmpty) return;

    final online = await hasInternetConnection();
    if (!online) return;

    _isProcessing = true;
    _emitStatus();
    try {
      for (final task in pendingTasks) {
        final success = await _processSingleTask(task);
        if (success) {
          await _deleteTask(task.opId);
          if (_pendingWrites > 0) {
            _pendingWrites = _pendingWrites - 1;
          }
        } else {
          await _incrementAttempts(task);
        }
      }
      _emitStatus();
    } finally {
      _isProcessing = false;
      _emitStatus();
    }
  }

  Future<bool> _processSingleTask(SyncQueueOperation task) async {
    try {
      final operation = task.operationType;
      final documentPath = task.documentPath;
      final docRef = FirebaseFirestore.instance.doc(documentPath);

      if (operation == 'delete') {
        await docRef.delete();
        await _markLocalPending(documentPath: documentPath, pending: false);
      } else {
        final merge = task.merge;
        final data =
            _restoreFromStorage(jsonDecode(task.payloadJson ?? '{}'))
                as Map<String, dynamic>;
        if (merge) {
          await docRef.set(data, SetOptions(merge: true));
        } else {
          await docRef.set(data);
        }
        await _markLocalPending(documentPath: documentPath, pending: false);
      }

      _lastSyncAt = DateTime.now();
      await _saveStatusToDb();

      return true;
    } catch (e) {
      debugPrint('Offline Firestore write sync failed: $e');
      return false;
    }
  }

  Future<void> _loadStatusFromDb() async {
    if (kIsWeb) {
      _pendingWrites = 0;
      _lastSyncAt = null;
      return;
    }
    final isar = IsarDatabaseService.instance.db;
    final status = await isar.syncStatusSnapshots
        .filter()
        .keyEqualTo('offline_firestore_write_queue')
        .findFirst();
    if (status?.lastSyncAtMs != null) {
      _lastSyncAt = DateTime.fromMillisecondsSinceEpoch(status!.lastSyncAtMs!);
    }
    _pendingWrites = status?.pendingWrites ?? 0;
  }

  Future<void> _saveStatusToDb() async {
    if (kIsWeb) return;
    final isar = IsarDatabaseService.instance.db;
    await isar.writeTxn(() async {
      final snapshot = SyncStatusSnapshot()
        ..key = 'offline_firestore_write_queue'
        ..pendingWrites = _pendingWrites
        ..lastSyncAtMs = _lastSyncAt?.millisecondsSinceEpoch
        ..isSyncing = _isProcessing
        ..updatedAtMs = DateTime.now().millisecondsSinceEpoch;
      await isar.syncStatusSnapshots.put(snapshot);
    });
  }

  Future<void> _enqueue({
    required String operationType,
    required String documentPath,
    Map<String, dynamic>? payload,
    bool merge = true,
  }) async {
    final isar = IsarDatabaseService.instance.db;
    final op = SyncQueueOperation()
      ..opId = '${DateTime.now().microsecondsSinceEpoch}_$documentPath'
      ..operationType = operationType
      ..documentPath = documentPath
      ..payloadJson = payload == null
          ? null
          : jsonEncode(_normalizeForStorage(payload))
      ..merge = merge
      ..createdAtMs = DateTime.now().millisecondsSinceEpoch
      ..updatedAtMs = DateTime.now().millisecondsSinceEpoch
      ..attempts = 0;

    await isar.writeTxn(() async {
      await isar.syncQueueOperations.put(op);
    });
  }

  Future<List<SyncQueueOperation>> _pendingTasks() async {
    final isar = IsarDatabaseService.instance.db;
    return isar.syncQueueOperations.where().sortByCreatedAtMs().findAll();
  }

  Future<void> _deleteTask(String opId) async {
    final isar = IsarDatabaseService.instance.db;
    final task = await isar.syncQueueOperations
        .filter()
        .opIdEqualTo(opId)
        .findFirst();
    if (task == null) return;
    await isar.writeTxn(() async {
      await isar.syncQueueOperations.delete(task.isarId);
    });
  }

  Future<void> _incrementAttempts(SyncQueueOperation task) async {
    final isar = IsarDatabaseService.instance.db;
    task.attempts = task.attempts + 1;
    task.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
    await isar.writeTxn(() async {
      await isar.syncQueueOperations.put(task);
    });
  }

  Future<void> _upsertLocalCache({
    required String documentPath,
    required Map<String, dynamic> data,
    required bool merge,
  }) async {
    final parsed = _parsePath(documentPath);
    if (parsed == null) return;
    final isar = IsarDatabaseService.instance.db;

    await isar.writeTxn(() async {
      if (parsed.scope == _PathScope.business) {
        final existing = await isar.localBusinessRecords
            .filter()
            .documentIdEqualTo(parsed.documentId)
            .findFirst();

        final mergedPayload = _mergeLocalPayload(
          existingPayloadJson: existing?.payloadJson,
          incomingData: data,
          merge: merge,
        );

        final record = existing ?? LocalBusinessRecord()
          ..documentId = parsed.documentId;
        record.payloadJson = jsonEncode(_normalizeForStorage(mergedPayload));
        record.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
        record.isDeleted = false;
        record.pendingSync = true;
        await isar.localBusinessRecords.put(record);
      } else if (parsed.scope == _PathScope.branch) {
        final existing = await isar.localBranchScopedRecords
            .filter()
            .uniqueKeyEqualTo(parsed.uniqueKey)
            .findFirst();

        final mergedPayload = _mergeLocalPayload(
          existingPayloadJson: existing?.payloadJson,
          incomingData: data,
          merge: merge,
        );

        final record = existing ?? LocalBranchScopedRecord()
          ..uniqueKey = parsed.uniqueKey
          ..businessId = parsed.businessId!
          ..branchId = parsed.branchId!
          ..collectionName = parsed.collectionName!
          ..documentId = parsed.documentId;
        record.payloadJson = jsonEncode(_normalizeForStorage(mergedPayload));
        record.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
        record.isDeleted = false;
        record.pendingSync = true;
        await isar.localBranchScopedRecords.put(record);
      } else {
        final existing = await isar.localGlobalRecords
            .filter()
            .uniqueKeyEqualTo(parsed.uniqueKey)
            .findFirst();

        final mergedPayload = _mergeLocalPayload(
          existingPayloadJson: existing?.payloadJson,
          incomingData: data,
          merge: merge,
        );

        final record = existing ?? LocalGlobalRecord()
          ..uniqueKey = parsed.uniqueKey
          ..collectionName = parsed.collectionName ?? ''
          ..documentId = parsed.documentId;
        record.payloadJson = jsonEncode(_normalizeForStorage(mergedPayload));
        record.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
        record.isDeleted = false;
        record.pendingSync = true;
        await isar.localGlobalRecords.put(record);
      }
    });
  }

  Map<String, dynamic> _mergeLocalPayload({
    required String? existingPayloadJson,
    required Map<String, dynamic> incomingData,
    required bool merge,
  }) {
    if (!merge || existingPayloadJson == null || existingPayloadJson.isEmpty) {
      return Map<String, dynamic>.from(incomingData);
    }

    try {
      final existingRaw = jsonDecode(existingPayloadJson);
      final existing = _restoreFromStorage(existingRaw);
      if (existing is! Map) {
        return Map<String, dynamic>.from(incomingData);
      }

      return _deepMergeMaps(
        Map<String, dynamic>.from(existing),
        Map<String, dynamic>.from(incomingData),
      );
    } catch (_) {
      return Map<String, dynamic>.from(incomingData);
    }
  }

  Map<String, dynamic> _deepMergeMaps(
    Map<String, dynamic> base,
    Map<String, dynamic> updates,
  ) {
    final result = Map<String, dynamic>.from(base);
    updates.forEach((key, value) {
      final existingValue = result[key];
      if (existingValue is Map && value is Map) {
        result[key] = _deepMergeMaps(
          Map<String, dynamic>.from(existingValue),
          Map<String, dynamic>.from(value),
        );
      } else {
        result[key] = value;
      }
    });
    return result;
  }

  Future<void> _markDeletedInLocalCache(String documentPath) async {
    final parsed = _parsePath(documentPath);
    if (parsed == null) return;
    final isar = IsarDatabaseService.instance.db;
    await isar.writeTxn(() async {
      if (parsed.scope == _PathScope.business) {
        final existing = await isar.localBusinessRecords
            .filter()
            .documentIdEqualTo(parsed.documentId)
            .findFirst();
        if (existing == null) return;
        existing.isDeleted = true;
        existing.pendingSync = true;
        existing.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
        await isar.localBusinessRecords.put(existing);
      } else if (parsed.scope == _PathScope.branch) {
        final existing = await isar.localBranchScopedRecords
            .filter()
            .uniqueKeyEqualTo(parsed.uniqueKey)
            .findFirst();
        if (existing == null) return;
        existing.isDeleted = true;
        existing.pendingSync = true;
        existing.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
        await isar.localBranchScopedRecords.put(existing);
      } else {
        final existing = await isar.localGlobalRecords
            .filter()
            .uniqueKeyEqualTo(parsed.uniqueKey)
            .findFirst();
        if (existing == null) return;
        existing.isDeleted = true;
        existing.pendingSync = true;
        existing.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
        await isar.localGlobalRecords.put(existing);
      }
    });
  }

  Future<void> _markLocalPending({
    required String documentPath,
    required bool pending,
  }) async {
    final parsed = _parsePath(documentPath);
    if (parsed == null) return;
    final isar = IsarDatabaseService.instance.db;
    await isar.writeTxn(() async {
      if (parsed.scope == _PathScope.business) {
        final existing = await isar.localBusinessRecords
            .filter()
            .documentIdEqualTo(parsed.documentId)
            .findFirst();
        if (existing == null) return;
        existing.pendingSync = pending;
        existing.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
        await isar.localBusinessRecords.put(existing);
      } else if (parsed.scope == _PathScope.branch) {
        final existing = await isar.localBranchScopedRecords
            .filter()
            .uniqueKeyEqualTo(parsed.uniqueKey)
            .findFirst();
        if (existing == null) return;
        existing.pendingSync = pending;
        existing.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
        await isar.localBranchScopedRecords.put(existing);
      } else {
        final existing = await isar.localGlobalRecords
            .filter()
            .uniqueKeyEqualTo(parsed.uniqueKey)
            .findFirst();
        if (existing == null) return;
        existing.pendingSync = pending;
        existing.updatedAtMs = DateTime.now().millisecondsSinceEpoch;
        await isar.localGlobalRecords.put(existing);
      }
    });
  }

  _ParsedPath? _parsePath(String documentPath) {
    final parts = documentPath.split('/');
    if (parts.length == 2 && parts[0] == 'businesses') {
      return _ParsedPath(
        scope: _PathScope.business,
        uniqueKey: documentPath,
        documentId: parts[1],
      );
    }

    if (parts.length >= 6 &&
        parts[0] == 'businesses' &&
        parts[2] == 'branches') {
      return _ParsedPath(
        scope: _PathScope.branch,
        uniqueKey: documentPath,
        documentId: parts[5],
        businessId: parts[1],
        branchId: parts[3],
        collectionName: parts[4],
      );
    }

    if (parts.length == 2) {
      return _ParsedPath(
        scope: _PathScope.global,
        uniqueKey: documentPath,
        documentId: parts[1],
        collectionName: parts[0],
      );
    }

    return null;
  }

  dynamic _normalizeForStorage(dynamic value) {
    if (value == null) return null;

    if (value is DateTime) {
      return {'__type': 'datetime', 'value': value.millisecondsSinceEpoch};
    }

    if (value is Timestamp) {
      return {'__type': 'timestamp', 'value': value.millisecondsSinceEpoch};
    }

    if (value is Map) {
      final map = <String, dynamic>{};
      value.forEach((key, mapValue) {
        map[key.toString()] = _normalizeForStorage(mapValue);
      });
      return map;
    }

    if (value is List) {
      return value.map(_normalizeForStorage).toList();
    }

    return value;
  }

  dynamic _restoreFromStorage(dynamic value) {
    if (value == null) return null;

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final type = map['__type'];
      if (type == 'datetime') {
        return DateTime.fromMillisecondsSinceEpoch(map['value'] as int);
      }
      if (type == 'timestamp') {
        return Timestamp.fromMillisecondsSinceEpoch(map['value'] as int);
      }

      final restored = <String, dynamic>{};
      map.forEach((key, mapValue) {
        restored[key] = _restoreFromStorage(mapValue);
      });
      return restored;
    }

    if (value is List) {
      return value.map(_restoreFromStorage).toList();
    }

    return value;
  }

  void _emitStatus() {
    statusNotifier.value = OfflineFirestoreWriteSyncStatus(
      pendingWrites: _pendingWrites,
      lastSyncAt: _lastSyncAt,
      isSyncing: _isProcessing,
    );
    if (!kIsWeb) {
      unawaited(_saveStatusToDb());
    }
  }
}

enum _PathScope { business, branch, global }

class _ParsedPath {
  _ParsedPath({
    required this.scope,
    required this.uniqueKey,
    required this.documentId,
    this.businessId,
    this.branchId,
    this.collectionName,
  });

  final _PathScope scope;
  final String uniqueKey;
  final String documentId;
  final String? businessId;
  final String? branchId;
  final String? collectionName;
}
