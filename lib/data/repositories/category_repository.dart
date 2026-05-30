import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Create category
  Future<void> addCategory(CategoryModel category) async {
    await categoriesRef.add(category.toMap());
  }

  /// Get all categories
  Future<List<CategoryModel>> getCategories() async {
    final querySnapshot = await categoriesRef.get();
    return querySnapshot.docs
        .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Get categories for a specific menu
  Future<List<CategoryModel>> getCategoriesByMenu(String menuId) async {
    final querySnapshot = await categoriesRef
        .where('menuId', isEqualTo: menuId)
        .get();
    return querySnapshot.docs
        .map((doc) => CategoryModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  /// Get single category
  Future<CategoryModel?> getCategoryById(String id) async {
    final doc = await categoriesRef.doc(id).get();
    if (doc.exists) {
      return CategoryModel.fromMap(doc.id, doc.data()!);
    }
    return null;
  }

  /// Update category
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    await categoriesRef.doc(id).update(data);
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    await categoriesRef.doc(id).delete();
  }
}
