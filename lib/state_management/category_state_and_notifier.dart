import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/category_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/repositories/category_repository.dart';
import 'package:hotel_management_system/data/services/category_service.dart';

class CategoryState {
  final List<CategoryModel> categories;
  final CategoryModel? selectedCategory;
  final bool isLoading;
  final String? error;

  const CategoryState({
    this.categories = const [],
    this.selectedCategory,
    this.isLoading = false,
    this.error,
  });

  CategoryState copyWith({
    List<CategoryModel>? categories,
    CategoryModel? selectedCategory,
    bool? isLoading,
    String? error,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final CategoryService _service;

  CategoryNotifier(this._service) : super(const CategoryState());

  Future<List<CategoryModel>> loadAllCategories() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _service.getAllCategories();
      state = state.copyWith(categories: categories, isLoading: false);
      return categories;
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
      return [];
    }
  }

  Future<void> loadCategoriesByMenu(String menuId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final categories = await _service.getCategoriesByMenu(menuId);
      state = state.copyWith(categories: categories, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadCategoryById(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final category = await _service.getCategoryById(id);
      state = state.copyWith(selectedCategory: category, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> addCategory(
    CategoryModel category,
    Uint8List imageBytes,
    String fileExtension,
    String businessId,
    String branchId,
  ) async {
    try {
      await _service.addCategory(
        category,
        imageBytes,
        fileExtension,
        businessId,
        branchId,
      );
      state = state.copyWith(categories: [...state.categories, category]);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    try {
      await _service.updateCategory(id, data);
      final updatedCategories = state.categories.map((c) {
        if (c.id == id) {
          return c.copyWith(
            name: data['name'] ?? c.name,
            menuId: data['menuId'] ?? c.menuId,
          );
        }
        return c;
      }).toList();

      state = state.copyWith(categories: updatedCategories);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      await _service.deleteCategory(id);
      state = state.copyWith(
        categories: state.categories.where((c) => c.id != id).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final categoryNotifierprovideer = Provider<CategoryRepository>((ref) {
  return CategoryRepository(
    branchId: BusinessRepository.temporaryBranchId,
    businessId: BusinessRepository.temporaryBusinesshId,
  );
});
