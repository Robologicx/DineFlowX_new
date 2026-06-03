import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';

class FirestoreToIsarMigrationService {
  FirestoreToIsarMigrationService._();

  static final FirestoreToIsarMigrationService instance =
      FirestoreToIsarMigrationService._();

  Future<void> migrateBranchData({
    required String businessId,
    required String branchId,
  }) async {
    final collections = <String>[
      'menus',
      'categories',
      'products',
      'orders',
      'diningTables',
      'rooms',
      'expenses',
    ];

    for (final collection in collections) {
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('businesses')
            .doc(businessId)
            .collection('branches')
            .doc(branchId)
            .collection(collection)
            .get();

        for (final doc in snapshot.docs) {
          await OfflineFirestoreWriteQueueService.instance.setOrQueue(
            documentPath:
                'businesses/$businessId/branches/$branchId/$collection/${doc.id}',
            data: doc.data(),
            merge: false,
          );
        }
      } catch (e) {
        debugPrint('Branch migration failed for $collection: $e');
      }
    }
  }

  Future<void> migrateBusinesses() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('businesses')
          .get();
      for (final doc in snapshot.docs) {
        await OfflineFirestoreWriteQueueService.instance.setOrQueue(
          documentPath: 'businesses/${doc.id}',
          data: doc.data(),
          merge: false,
        );
      }
    } catch (e) {
      debugPrint('Business migration failed: $e');
    }
  }
}
