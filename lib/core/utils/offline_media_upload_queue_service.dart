import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hotel_management_system/data/repositories/images_storage_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineMediaSyncStatus {
  final int pendingUploads;
  final DateTime? lastSyncAt;
  final bool isSyncing;

  const OfflineMediaSyncStatus({
    required this.pendingUploads,
    required this.lastSyncAt,
    required this.isSyncing,
  });

  OfflineMediaSyncStatus copyWith({
    int? pendingUploads,
    DateTime? lastSyncAt,
    bool? isSyncing,
  }) {
    return OfflineMediaSyncStatus(
      pendingUploads: pendingUploads ?? this.pendingUploads,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      isSyncing: isSyncing ?? this.isSyncing,
    );
  }
}

class OfflineMediaUploadQueueService {
  OfflineMediaUploadQueueService._();

  static final OfflineMediaUploadQueueService instance =
      OfflineMediaUploadQueueService._();

  static const String _storageKey = 'offline_media_upload_queue_v1';
  static const String _lastSyncStorageKey =
      'offline_media_upload_queue_last_sync_v1';
  static const Duration _retryInterval = Duration(seconds: 20);

  static final ValueNotifier<OfflineMediaSyncStatus> statusNotifier =
      ValueNotifier(
        const OfflineMediaSyncStatus(
          pendingUploads: 0,
          lastSyncAt: null,
          isSyncing: false,
        ),
      );

  final StorageRepository _storageRepository = StorageRepository();

  SharedPreferences? _prefs;
  Timer? _retryTimer;
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

    _isStarted = true;
    unawaited(processQueue());
  }

  Future<void> enqueueImageUpload({
    required String businessId,
    required String branchId,
    required String collection,
    required String documentId,
    required String folder,
    required Uint8List imageBytes,
    required String fileExtension,
  }) async {
    await start();

    final task = <String, dynamic>{
      'id':
          '${DateTime.now().microsecondsSinceEpoch}_${collection}_$documentId',
      'businessId': businessId,
      'branchId': branchId,
      'collection': collection,
      'documentId': documentId,
      'folder': folder,
      'fileExtension': fileExtension,
      'imageBase64': base64Encode(imageBytes),
      'attempts': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
    };

    _queue.add(task);
    await _persistQueue();
    _emitStatus();
    unawaited(processQueue());
  }

  Future<void> processQueue() async {
    if (_isProcessing || _queue.isEmpty) return;

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
      final imageBytes = base64Decode(task['imageBase64'] as String);

      final uploadedImageUrl = await _storageRepository.uploadFile(
        businessId: task['businessId'] as String,
        branchId: task['branchId'] as String,
        folder: task['folder'] as String,
        bytes: imageBytes,
        fileExtension: task['fileExtension'] as String,
      );

      final docRef = FirebaseFirestore.instance
          .collection('businesses')
          .doc(task['businessId'] as String)
          .collection('branches')
          .doc(task['branchId'] as String)
          .collection(task['collection'] as String)
          .doc(task['documentId'] as String);

      await docRef.set({
        'imageUrl': uploadedImageUrl,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      _lastSyncAt = DateTime.now();
      await _prefs?.setInt(
        _lastSyncStorageKey,
        _lastSyncAt!.millisecondsSinceEpoch,
      );

      debugPrint(
        'Offline media sync success for ${task['collection']}/${task['documentId']}',
      );
      _emitStatus();
      return true;
    } catch (e) {
      debugPrint(
        'Offline media sync retry failed for ${task['collection']}/${task['documentId']}: $e',
      );
      return false;
    }
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

  void _emitStatus() {
    statusNotifier.value = OfflineMediaSyncStatus(
      pendingUploads: _queue.length,
      lastSyncAt: _lastSyncAt,
      isSyncing: _isProcessing,
    );
  }
}
