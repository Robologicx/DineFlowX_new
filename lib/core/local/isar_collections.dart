import 'package:isar/isar.dart';

part 'isar_collections.g.dart';

@collection
class LocalBusinessRecord {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true)
  late String documentId;

  late String payloadJson;
  late int updatedAtMs;
  @Index()
  late bool isDeleted;
  @Index()
  late bool pendingSync;
}

@collection
class LocalBranchScopedRecord {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uniqueKey;

  @Index()
  late String businessId;
  @Index()
  late String branchId;
  @Index()
  late String collectionName;
  @Index()
  late String documentId;

  late String payloadJson;
  late int updatedAtMs;
  @Index()
  late bool isDeleted;
  @Index()
  late bool pendingSync;
}

@collection
class LocalGlobalRecord {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String uniqueKey;

  @Index()
  late String collectionName;
  @Index()
  late String documentId;

  late String payloadJson;
  late int updatedAtMs;
  @Index()
  late bool isDeleted;
  @Index()
  late bool pendingSync;
}

@collection
class SyncQueueOperation {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String opId;

  @Index()
  late String operationType; // set or delete

  @Index()
  late String documentPath;

  String? payloadJson;
  late bool merge;
  late int createdAtMs;
  late int updatedAtMs;
  late int attempts;
}

@collection
class SyncStatusSnapshot {
  Id isarId = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String key;

  late int pendingWrites;
  int? lastSyncAtMs;
  late bool isSyncing;
  late int updatedAtMs;
}
