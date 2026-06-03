import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:hotel_management_system/core/local/isar_collections.dart';
import 'package:hotel_management_system/core/local/isar_database_service.dart';

class OfflineLocalReadService {
  OfflineLocalReadService._();

  static final OfflineLocalReadService instance = OfflineLocalReadService._();

  Future<Map<String, dynamic>?> getBranchDocument({
    required String businessId,
    required String branchId,
    required String collectionName,
    required String documentId,
  }) async {
    if (kIsWeb) return null;
    await IsarDatabaseService.instance.initialize();
    final uniqueKey =
        'businesses/$businessId/branches/$branchId/$collectionName/$documentId';
    final record = await IsarDatabaseService
        .instance
        .db
        .localBranchScopedRecords
        .filter()
        .uniqueKeyEqualTo(uniqueKey)
        .findFirst();
    if (record == null || record.isDeleted) return null;
    return _decodePayload(record.payloadJson);
  }

  Future<List<Map<String, dynamic>>> getBranchCollection({
    required String businessId,
    required String branchId,
    required String collectionName,
  }) async {
    if (kIsWeb) return <Map<String, dynamic>>[];
    await IsarDatabaseService.instance.initialize();
    final rows = await IsarDatabaseService.instance.db.localBranchScopedRecords
        .filter()
        .businessIdEqualTo(businessId)
        .and()
        .branchIdEqualTo(branchId)
        .and()
        .collectionNameEqualTo(collectionName)
        .and()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows.map((e) {
      final map = _decodePayload(e.payloadJson);
      map['__documentId'] = e.documentId;
      return map;
    }).toList();
  }

  Future<Map<String, dynamic>?> getBusinessDocument(String documentId) async {
    if (kIsWeb) return null;
    await IsarDatabaseService.instance.initialize();
    final record = await IsarDatabaseService.instance.db.localBusinessRecords
        .filter()
        .documentIdEqualTo(documentId)
        .findFirst();
    if (record == null || record.isDeleted) return null;
    return _decodePayload(record.payloadJson);
  }

  Future<List<Map<String, dynamic>>> getBusinessCollection() async {
    if (kIsWeb) return <Map<String, dynamic>>[];
    await IsarDatabaseService.instance.initialize();
    final rows = await IsarDatabaseService.instance.db.localBusinessRecords
        .filter()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows.map((e) {
      final map = _decodePayload(e.payloadJson);
      map['__documentId'] = e.documentId;
      return map;
    }).toList();
  }

  Future<Map<String, dynamic>?> getGlobalDocument({
    required String collectionName,
    required String documentId,
  }) async {
    if (kIsWeb) return null;
    await IsarDatabaseService.instance.initialize();
    final uniqueKey = '$collectionName/$documentId';
    final record = await IsarDatabaseService.instance.db.localGlobalRecords
        .filter()
        .uniqueKeyEqualTo(uniqueKey)
        .findFirst();
    if (record == null || record.isDeleted) return null;
    return _decodePayload(record.payloadJson);
  }

  Future<List<Map<String, dynamic>>> getGlobalCollection({
    required String collectionName,
  }) async {
    if (kIsWeb) return <Map<String, dynamic>>[];
    await IsarDatabaseService.instance.initialize();
    final rows = await IsarDatabaseService.instance.db.localGlobalRecords
        .filter()
        .collectionNameEqualTo(collectionName)
        .and()
        .isDeletedEqualTo(false)
        .sortByUpdatedAtMsDesc()
        .findAll();

    return rows.map((e) {
      final map = _decodePayload(e.payloadJson);
      map['__documentId'] = e.documentId;
      return map;
    }).toList();
  }

  Map<String, dynamic> _decodePayload(String payload) {
    final decoded = jsonDecode(payload) as Map<String, dynamic>;
    return _restore(decoded) as Map<String, dynamic>;
  }

  dynamic _restore(dynamic value) {
    if (value == null) return null;

    if (value is Map<String, dynamic>) {
      final type = value['__type'];
      if (type == 'datetime') {
        return DateTime.fromMillisecondsSinceEpoch(value['value'] as int);
      }
      if (type == 'timestamp') {
        return Timestamp.fromMillisecondsSinceEpoch(value['value'] as int);
      }

      final map = <String, dynamic>{};
      value.forEach((key, v) {
        map[key] = _restore(v);
      });
      return map;
    }

    if (value is List) {
      return value.map(_restore).toList();
    }

    return value;
  }
}
