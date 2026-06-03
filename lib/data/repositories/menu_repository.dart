import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import '../models/menu_model.dart';

class MenuRepository {
  MenuRepository({required String businessId, required String branchId})
    : _businessId = businessId,
      _branchId = branchId;
  // Reference to the nested categories collection
  CollectionReference<Map<String, dynamic>> get _menuCollection =>
      FirebaseFirestore.instance
          .collection('businesses')
          .doc(_businessId)
          .collection('branches')
          .doc(_branchId)
          .collection('menus');

  final String _businessId;
  final String _branchId;

  List<MenuModel> _mergeMenusPreferLocal({
    required List<MenuModel> local,
    required List<MenuModel> remote,
  }) {
    final merged = <String, MenuModel>{};
    for (final menu in remote) {
      merged[menu.id] = menu;
    }
    for (final menu in local) {
      merged[menu.id] = menu;
    }
    return merged.values.toList(growable: false);
  }

  Stream<List<MenuModel>> _hybridMenusStream() {
    return Stream.multi((controller) {
      List<MenuModel> latestRemote = const [];
      StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? remoteSub;
      Timer? localTick;
      bool isCancelled = false;

      Future<void> emitMerged() async {
        if (isCancelled) return;
        final localRows = await OfflineLocalReadService.instance
            .getBranchCollection(
              businessId: _businessId,
              branchId: _branchId,
              collectionName: 'menus',
            );
        if (isCancelled) return;

        final local = localRows
            .map(
              (doc) => MenuModel.fromMap(
                (doc['__documentId'] ?? '').toString(),
                doc,
              ),
            )
            .toList(growable: false);
        controller.add(
          _mergeMenusPreferLocal(local: local, remote: latestRemote),
        );
      }

      localTick = Timer.periodic(const Duration(seconds: 2), (_) {
        unawaited(emitMerged());
      });

      remoteSub = _menuCollection.snapshots().listen(
        (snapshot) {
          latestRemote = snapshot.docs
              .map((doc) => MenuModel.fromMap(doc.id, doc.data()))
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

  /// Add a new menu to Firestore
  Future<void> addMenu(MenuModel menu) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/menus/${menu.id}',
      data: menu.toMap(),
      merge: false,
    );
  }

  /// Update an existing menu
  Future<void> updateMenu(MenuModel menu) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/menus/${menu.id}',
      data: menu.toMap(),
      merge: true,
    );
  }

  /// Delete a menu by ID
  Future<void> deleteMenu(String menuId) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath: 'businesses/$_businessId/branches/$_branchId/menus/$menuId',
    );
  }

  /// Get a single menu by ID
  Future<MenuModel?> getMenuById(String menuId) async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'menus',
      documentId: menuId,
    );
    if (localDoc != null) {
      return MenuModel.fromMap(menuId, localDoc);
    }

    final doc = await _menuCollection.doc(menuId).get();
    if (doc.exists) {
      return MenuModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // toggle menu active status
  Future<void> toggleMenuActiveStatus(String menuId, bool isActive) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath: 'businesses/$_businessId/branches/$_branchId/menus/$menuId',
      data: {'isActive': isActive},
      merge: true,
    );
  }

  /// Get all menus as a stream (real-time updates)
  Stream<List<MenuModel>> getMenusStream() {
    return _hybridMenusStream();
  }

  /// Get all menus once (no real-time updates)
  Future<List<MenuModel>> getAllMenus() async {
    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'menus',
        );
    final local = localRows
        .map(
          (doc) =>
              MenuModel.fromMap((doc['__documentId'] ?? '').toString(), doc),
        )
        .toList(growable: false);

    try {
      final snapshot = await _menuCollection.get();
      final remote = snapshot.docs
          .map((doc) => MenuModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
      return _mergeMenusPreferLocal(local: local, remote: remote);
    } catch (_) {
      return local;
    }
  }
}
