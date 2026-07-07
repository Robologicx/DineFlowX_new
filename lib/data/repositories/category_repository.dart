import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';

import '../models/category_model.dart';

class CategoryRepository {
  CategoryRepository({required String businessId, required String branchId})
    : _businessId = businessId,
      _branchId = branchId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  // Reference to the nested categories collection
  CollectionReference<Map<String, dynamic>> get categoriesRef => _firestore
      .collection('businesses')
      .doc(_businessId)
      .collection('branches')
      .doc(_branchId)
      .collection('categories');

  final String _businessId;
  final String _branchId;

  List<CategoryModel> _mergeCategoriesPreferLocal({
    required List<CategoryModel> local,
    required List<CategoryModel> remote,
  }) {
    final merged = <String, CategoryModel>{};
    for (final category in remote) {
      merged[category.id] = category;
    }
    for (final category in local) {
      merged[category.id] = category;
    }
    final list = merged.values.toList(growable: false);
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<List<CategoryModel>> _getLocalCategories() async {
    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'categories',
        );

    return localRows
        .map(
          (doc) => CategoryModel.fromMap(
            (doc['__documentId'] ?? '').toString(),
            doc,
          ),
        )
        .toList(growable: false);
  }

  /// Create category
  Future<CategoryModel> addCategory(CategoryModel category) async {
    final docId = category.id.trim().isEmpty
        ? categoriesRef.doc().id
        : category.id;
    final categoryToSave = category.copyWith(id: docId);
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/categories/$docId',
      data: categoryToSave.toMap(),
      merge: false,
    );
    return categoryToSave;
  }

  /// Get all categories
  Future<List<CategoryModel>> getCategories() async {
    final local = await _getLocalCategories();
    try {
      final querySnapshot = await categoriesRef.get();
      final remote = querySnapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);
      return _mergeCategoriesPreferLocal(local: local, remote: remote);
    } catch (_) {
      if (local.isNotEmpty) {
        return local;
      }

      rethrow;
    }
  }

  /// Get categories for a specific menu
  Future<List<CategoryModel>> getCategoriesByMenu(String menuId) async {
    final local = await _getLocalCategories();
    try {
      final querySnapshot = await categoriesRef
          .where('menuId', isEqualTo: menuId)
          .get();
      final remote = querySnapshot.docs
          .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
          .toList(growable: false);

      final merged = _mergeCategoriesPreferLocal(local: local, remote: remote);
      return merged.where((category) => category.menuId == menuId).toList();
    } catch (_) {
      return local.where((category) => category.menuId == menuId).toList();
    }
  }

  /// Get single category
  Future<CategoryModel?> getCategoryById(String id) async {
    final localDoc = await OfflineLocalReadService.instance.getBranchDocument(
      businessId: _businessId,
      branchId: _branchId,
      collectionName: 'categories',
      documentId: id,
    );
    if (localDoc != null) {
      return CategoryModel.fromMap(id, localDoc);
    }

    final doc = await categoriesRef.doc(id).get();
    if (doc.exists) {
      return CategoryModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Update category
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await OfflineFirestoreWriteQueueService.instance.setOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/categories/$id',
      data: data,
      merge: true,
    );
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
      documentPath:
          'businesses/$_businessId/branches/$_branchId/categories/$id',
    );
  }
}
