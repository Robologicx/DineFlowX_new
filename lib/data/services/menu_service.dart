import 'package:uuid/uuid.dart';
import '../models/menu_model.dart';
import '../repositories/menu_repository.dart';

class MenuService {
  final MenuRepository _menuRepository;
  final _uuid = const Uuid();

  MenuService(MenuRepository menuRepository) : _menuRepository = menuRepository;

  /// Create and add a new menu
  Future<void> createMenu({
    required String name,
    String? description,
    String? imageUrl,
    required String createdBy,
  }) async {
    final normalizedName = name.trim().toLowerCase();
    try {
      final existingMenus = await _menuRepository.getAllMenus();
      final duplicateExists = existingMenus.any(
        (menu) => menu.name.trim().toLowerCase() == normalizedName,
      );

      if (duplicateExists) {
        throw Exception('Menu already exists.');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('menu already exists')) {
        rethrow;
      }
      // Offline/no-cache path: allow save and rely on backend sync later.
    }

    final now = DateTime.now();

    final newMenu = MenuModel(
      id: _uuid.v4(),
      name: name,
      description: description,
      imageUrl: imageUrl,
      createdBy: createdBy,
      createdAt: now,
      updatedAt: now,
    );

    await _menuRepository.addMenu(newMenu);
  }

  /// Edit an existing menu
  Future<void> editMenu(MenuModel updatedMenu) async {
    final normalizedName = updatedMenu.name.trim().toLowerCase();
    try {
      final existingMenus = await _menuRepository.getAllMenus();
      final duplicateExists = existingMenus.any(
        (menu) =>
            menu.id != updatedMenu.id &&
            menu.name.trim().toLowerCase() == normalizedName,
      );

      if (duplicateExists) {
        throw Exception('Menu already exists.');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('menu already exists')) {
        rethrow;
      }
      // Offline/no-cache path: allow save and rely on backend sync later.
    }

    final menuWithUpdatedTime = MenuModel(
      id: updatedMenu.id,
      name: updatedMenu.name,
      description: updatedMenu.description,
      imageUrl: updatedMenu.imageUrl,
      createdBy: updatedMenu.createdBy,
      createdAt: updatedMenu.createdAt,
      updatedAt: DateTime.now(),
    );

    await _menuRepository.updateMenu(menuWithUpdatedTime);
  }

  /// Remove a menu by ID
  Future<void> removeMenu(String menuId) async {
    await _menuRepository.deleteMenu(menuId);
  }

  /// Fetch a menu by ID
  Future<MenuModel?> fetchMenuById(String menuId) {
    return _menuRepository.getMenuById(menuId);
  }

  /// Toggle menu active status
  Future<void> toggleMenuActiveStatus(String menuId, bool isActive) async {
    await _menuRepository.toggleMenuActiveStatus(menuId, isActive);
    // Uncomment the above line when the method is implemented in MenuRepository
  }

  /// Get all menus in real-time
  Stream<List<MenuModel>> menusStream() {
    return _menuRepository.getMenusStream();
  }

  /// Get all menus once
  Future<List<MenuModel>> fetchAllMenus() {
    return _menuRepository.getAllMenus();
  }
}
