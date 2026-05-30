import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/models/buisness_model.dart';

class BusinessRepository {
  static String temporaryBranchId = 'branch1';
  static String temporaryBusinesshId = 'business1';
  final CollectionReference<Map<String, dynamic>> _col = FirebaseFirestore
      .instance
      .collection('businesses');

  Future<void> createBusiness(BusinessModel b) async {
    await _col.doc(b.id).set(b.toMap());
  }

  Future<BusinessModel?> getBusinessById(String id) async {
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return BusinessModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> updateBusiness(BusinessModel b) async {
    await _col.doc(b.id).update(b.toMap());
  }

  Future<void> deleteBusiness(String id) async {
    await _col.doc(id).delete();
  }

  /// Soft delete: mark isDeleted and set deletedAt timestamp
  Future<void> softDeleteBusiness(String id) async {
    await _col.doc(id).update({
      'isDeleted': true,
      'deletedAt': DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
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
    final q = includeDeleted
        ? await _col.get()
        : await _col.where('isDeleted', isEqualTo: false).get();
    return q.docs.map((d) => BusinessModel.fromMap(d.data(), d.id)).toList();
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
    return _col.doc(id).snapshots().map((doc) {
      if (!doc.exists) return null;
      return BusinessModel.fromMap(doc.data()!, doc.id);
    });
  }

  Stream<List<BusinessModel>> listenToOwnerBusinesses(String ownerId) {
    return _col
        .where('ownerId', isEqualTo: ownerId)
        .where('isDeleted', isEqualTo: false)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BusinessModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }
}
