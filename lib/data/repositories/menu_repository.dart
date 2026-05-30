import 'package:cloud_firestore/cloud_firestore.dart';
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

  /// Add a new menu to Firestore
  Future<void> addMenu(MenuModel menu) async {
    await _menuCollection.doc(menu.id).set(menu.toMap());
  }

  /// Update an existing menu
  Future<void> updateMenu(MenuModel menu) async {
    await _menuCollection.doc(menu.id).update(menu.toMap());
  }

  /// Delete a menu by ID
  Future<void> deleteMenu(String menuId) async {
    await _menuCollection.doc(menuId).delete();
  }

  /// Get a single menu by ID
  Future<MenuModel?> getMenuById(String menuId) async {
    final doc = await _menuCollection.doc(menuId).get();
    if (doc.exists) {
      return MenuModel.fromMap(doc.id, doc.data() as Map<String, dynamic>);
    }
    return null;
  }

  // toggle menu active status
  Future<void> toggleMenuActiveStatus(String menuId, bool isActive) async {
    await _menuCollection.doc(menuId).update({'isActive': isActive});
  }

  /// Get all menus as a stream (real-time updates)
  Stream<List<MenuModel>> getMenusStream() {
    return _menuCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  /// Get all menus once (no real-time updates)
  Future<List<MenuModel>> getAllMenus() async {
    final snapshot = await _menuCollection.get();
    return snapshot.docs
        .map((doc) => MenuModel.fromMap(doc.id, doc.data()))
        .toList();
  }
}
