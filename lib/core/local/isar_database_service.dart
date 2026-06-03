import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import 'isar_collections.dart';

class IsarDatabaseService {
  IsarDatabaseService._();

  static final IsarDatabaseService instance = IsarDatabaseService._();

  Isar? _isar;

  bool get isInitialized => _isar != null;

  Isar get db {
    final value = _isar;
    if (value == null) {
      throw StateError('Isar is not initialized. Call initialize() first.');
    }
    return value;
  }

  Future<void> initialize() async {
    if (_isar != null) return;

    if (kIsWeb) {
      // Isar 3.x has no web runtime support in this project configuration.
      // Keep initialization as a no-op on web and let callers use web fallbacks.
      return;
    }

    final dir = await getApplicationDocumentsDirectory();
    _isar = await Isar.open(
      [
        LocalBusinessRecordSchema,
        LocalBranchScopedRecordSchema,
        LocalGlobalRecordSchema,
        SyncQueueOperationSchema,
        SyncStatusSnapshotSchema,
      ],
      directory: dir.path,
      inspector: false,
    );
  }
}
