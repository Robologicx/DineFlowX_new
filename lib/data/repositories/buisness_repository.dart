import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import 'package:hotel_management_system/data/models/buisness_model.dart';

class BusinessRepository {
  static String temporaryBranchId = 'branch1';
  static String temporaryBusinesshId = 'business1';
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore
      .instance
      .collection('businesses');

  List<BusinessModel> _mergeBusinessesPreferLocal({
    required List<BusinessModel> local,
    required List<BusinessModel> remote,
  }) {
    final merged = <String, BusinessModel>{};
    for (final item in remote) {
      merged[item.id] = item;
    }
    for (final item in local) {
      final existing = merged[item.id];
      if (existing == null) {
        merged[item.id] = item;
        continue;
      }

      final localUpdatedAt = item.updatedAt.millisecondsSinceEpoch;
      final remoteUpdatedAt = existing.updatedAt.millisecondsSinceEpoch;
      final preferLocal = localUpdatedAt >= remoteUpdatedAt;
      final timestampsEqual = localUpdatedAt == remoteUpdatedAt;

      var selected = preferLocal ? item : existing;
      final other = preferLocal ? existing : item;

      // Only use fallback filling when snapshots have equal freshness.
      // This prevents a stale non-empty local logo/title from overriding
      // an intentional newer clear/update from remote.
      if ((selected.logoUrl == null || selected.logoUrl!.trim().isEmpty) &&
          other.logoUrl != null &&
          other.logoUrl!.trim().isNotEmpty &&
          timestampsEqual) {
        selected = selected.copyWith(logoUrl: other.logoUrl);
      }

      if (selected.title.trim().isEmpty &&
          other.title.trim().isNotEmpty &&
          timestampsEqual) {
        selected = selected.copyWith(title: other.title);
      }

      merged[item.id] = selected;
    }
    return merged.values.toList(growable: false);
  }

  bool _isSameBusinessSnapshot(BusinessModel? a, BusinessModel? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return a == b;

    return a.id == b.id &&
        a.title == b.title &&
        a.logoUrl == b.logoUrl &&
        a.currencyCode == b.currencyCode &&
        a.ownerId == b.ownerId &&
        a.isActive == b.isActive &&
        a.isDeleted == b.isDeleted &&
        a.updatedAt.millisecondsSinceEpoch ==
            b.updatedAt.millisecondsSinceEpoch;
  }

  Stream<List<BusinessModel>> _hybridBusinessesStream({String? ownerId}) {
    return Stream.multi((controller) {
      List<BusinessModel> latestRemote = const [];
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? remoteSub;
      Timer? localTick;
      bool isCancelled = false;

      Future<void> emitMerged() async {
        if (isCancelled) return;
        final localRows = await OfflineLocalReadService.instance
            .getBusinessCollection();
        if (isCancelled) return;

        var local = localRows
            .map(
              (doc) => BusinessModel.fromMap(
                doc,
                (doc['__documentId'] ?? '').toString(),
              ),
            )
            .toList(growable: false);

        if (ownerId != null) {
          local = local
              .where((b) => b.ownerId == ownerId && b.isDeleted == false)
              .toList(growable: false);
        }

        controller.add(
          _mergeBusinessesPreferLocal(local: local, remote: latestRemote),
        );
      }

      localTick = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(emitMerged());
      });

      Query<Map<String, dynamic>> q = _col;
      if (ownerId != null) {
        q = q
            .where('ownerId', isEqualTo: ownerId)
            .where('isDeleted', isEqualTo: false);
      }

      remoteSub = q.snapshots().listen(
        (snap) {
          latestRemote = snap.docs
              .map((d) => BusinessModel.fromMap(d.data(), d.id))
              .toList(growable: false);
          unawaited(emitMerged());
        },
        onError: (_) {
          // Keep local polling alive even if remote stream fails.
        },
      );

      unawaited(emitMerged());

      controller.onCancel = () {
        isCancelled = true;
        localTick?.cancel();
        remoteSub?.cancel();
      };
    });
  }

  Future<void> createBusiness(BusinessModel b) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'businesses/${b.id}',
      data: b.toMap(),
      merge: false,
    );
  }

  Future<BusinessModel?> getBusinessById(String id) async {
    final localDoc = await OfflineLocalReadService.instance.getBusinessDocument(
      id,
    );
    if (localDoc != null) {
      return BusinessModel.fromMap(localDoc, id);
    }

    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return BusinessModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateBusiness(BusinessModel b) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'businesses/${b.id}',
      data: b.toMap(),
      merge: true,
    );
  }

  Future<void> deleteBusiness(String id) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath: 'businesses/$id',
    );
  }

  /// Soft delete: mark isDeleted and set deletedAt timestamp
  Future<void> softDeleteBusiness(String id) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'businesses/$id',
      data: {
        'isDeleted': true,
        'deletedAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      merge: true,
    );
  }

  /// Get all businesses for a specific owner (non-deleted)
  Future<List<BusinessModel>> getBusinessesByOwner(String ownerId) async {
    final q = await _col
        .where('ownerId', isEqualTo: ownerId)
        .where('isDeleted', isEqualTo: false)
        .get();

    return q.docs
        .map((d) => BusinessModel.fromMap(d.data(), d.id))
        .toList(growable: false);
  }

  /// Get businesses by status (active/inactive)
  Future<List<BusinessModel>> getBusinessesByStatus(bool isActive) async {
    final q = await _col.where('isActive', isEqualTo: isActive).get();
    return q.docs.map((d) => BusinessModel.fromMap(d.data(), d.id)).toList();
  }

  /// Admin: get all businesses; includeDeleted toggles filter
  Future<List<BusinessModel>> getAllBusinesses({
    bool includeDeleted = false,
  }) async {
    final localRows = await OfflineLocalReadService.instance
        .getBusinessCollection();
    final local = localRows
        .map(
          (doc) => BusinessModel.fromMap(
            doc,
            (doc['__documentId'] ?? '').toString(),
          ),
        )
        .toList(growable: false);

    try {
      final q = includeDeleted
          ? await _col.get()
          : await _col.where('isDeleted', isEqualTo: false).get();
      final remote = q.docs
          .map((d) => BusinessModel.fromMap(d.data(), d.id))
          .toList(growable: false);
      final merged = _mergeBusinessesPreferLocal(local: local, remote: remote);
      if (includeDeleted) return merged;
      return merged.where((b) => b.isDeleted == false).toList(growable: false);
    } catch (_) {
      if (includeDeleted) return local;
      return local.where((b) => b.isDeleted == false).toList(growable: false);
    }
  }

  /// Search by title (case-insensitive prefix search)
  /// Note: Firestore doesn't support full text search — this does prefix matching
  Future<List<BusinessModel>> searchByTitle(
    String titlePrefix, {
    int limit = 20,
  }) async {
    final prefix = titlePrefix.trim().toLowerCase();
    if (prefix.isEmpty) return [];

    // This requires your documents to also store a field 'title_lower' (lowercase title) to be indexed.
    final q = await _col
        .where('title_lower', isGreaterThanOrEqualTo: prefix)
        .where('title_lower', isLessThanOrEqualTo: '$prefix\uf8ff')
        .limit(limit)
        .get();

    return q.docs.map((d) => BusinessModel.fromMap(d.data(), d.id)).toList();
  }

  /// Pagination: fetch page with limit and optional startAfter millis timestamp
  Future<List<BusinessModel>> getBusinessesPage({
    int limit = 20,
    int? startAfterMillis,
  }) async {
    Query<Map<String, dynamic>> q = _col
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit);
    if (startAfterMillis != null) {
      final snapshot = await _col
          .where('createdAt', isEqualTo: startAfterMillis)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        q = q.startAfterDocument(snapshot.docs.first);
      }
    }

    final res = await q.get();
    return res.docs.map((d) => BusinessModel.fromMap(d.data(), d.id)).toList();
  }

  /// Streams
  Stream<BusinessModel?> listenToBusiness(String id) {
    return _hybridBusinessesStream()
        .map((rows) {
          for (final b in rows) {
            if (b.id == id) return b;
          }
          return null;
        })
        .distinct(_isSameBusinessSnapshot);
  }

  Stream<List<BusinessModel>> listenToOwnerBusinesses(String ownerId) {
    return _hybridBusinessesStream(ownerId: ownerId);
  }
}
