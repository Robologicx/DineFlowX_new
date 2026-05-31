import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/menu_model.dart';
import 'package:hotel_management_system/data/services/menu_service.dart';

class MenuState {
  final List<MenuModel> menus;
  final MenuModel? selectedMenu;
  final bool isLoading;
  final String? error;

  const MenuState({
    this.menus = const [],
    this.selectedMenu,
    this.isLoading = false,
    this.error,
  });

  MenuState copyWith({
    List<MenuModel>? menus,
    MenuModel? selectedMenu,
    bool? isLoading,
    String? error,
  }) {
    return MenuState(
      menus: menus ?? this.menus,
      selectedMenu: selectedMenu ?? this.selectedMenu,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MenuNotifier extends StateNotifier<MenuState> {
  final MenuService _service;

  MenuNotifier(this._service) : super(const MenuState());

  Future<void> loadAllMenus() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final menus = await _service.fetchAllMenus();
      state = state.copyWith(menus: menus, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  void listenMenusStream() {
    state = state.copyWith(isLoading: true, error: null);
    _service.menusStream().listen(
      (menus) {
        state = state.copyWith(menus: menus, isLoading: false);
      },
      onError: (e) {
        state = state.copyWith(error: e.toString(), isLoading: false);
      },
    );
  }

  Future<void> loadMenuById(String menuId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final menu = await _service.fetchMenuById(menuId);
      state = state.copyWith(selectedMenu: menu, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> createMenu({
    required String name,
    String? description,
    String? imageUrl,
    required String createdBy,
  }) async {
    try {
      await _service.createMenu(
        name: name,
        description: description,
        imageUrl: imageUrl,
        createdBy: createdBy,
      );
      await loadAllMenus();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateMenu(MenuModel menu) async {
    try {
      await _service.editMenu(menu);
      await loadAllMenus();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteMenu(String menuId) async {
    try {
      await _service.removeMenu(menuId);
      state = state.copyWith(
        menus: state.menus.where((m) => m.id != menuId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> toggleMenuActiveStatus(String menuId, bool isActive) async {
    try {
      await _service.toggleMenuActiveStatus(menuId, isActive);
      await loadAllMenus();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
