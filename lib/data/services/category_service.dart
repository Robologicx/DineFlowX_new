import 'dart:typed_data';

import 'package:hotel_management_system/data/services/image_storage_service.dart';

import '../models/category_model.dart';
import '../repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _repository;
  final StorageService _storageService;

  CategoryService(this._storageService, this._repository);

  /// Add category with validation
  Future<void> addCategory(
    CategoryModel category,
    Uint8List? imageBytes,
    String fileExtension,
    String businessId,
    String branchId,
  ) async {
    if (category.name.trim().isEmpty) {
      throw Exception("Category name cannot be empty.");
    }
    if (category.menuId.trim().isEmpty) {
      throw Exception("Menu ID is required for a category.");
    }

    final normalizedName = category.name.trim().toLowerCase();
    final existingCategories = await _repository.getCategoriesByMenu(
      category.menuId,
    );
    final duplicateExists = existingCategories.any(
      (existingCategory) =>
          existingCategory.name.trim().toLowerCase() == normalizedName,
    );

    if (duplicateExists) {
      throw Exception('Category already exists in this menu.');
    }

    try {
      if (imageBytes != null && imageBytes.isNotEmpty) {
        // Upload image first
        final imageUrl = await _storageService.uploadProductImage(
          businessId: businessId,
          branchId: branchId,
          imageBytes: imageBytes,
          fileExtension: fileExtension,
        );
        // Create product with image URL
        category = category.copyWith(imageUrl: imageUrl);
      }

      await _repository.addCategory(category);
    } catch (e) {
      rethrow;
    }
  }

  /// Get all categories
  Future<List<CategoryModel>> getAllCategories() {
    return _repository.getCategories();
  }

  /// Get categories for a specific menu
  Future<List<CategoryModel>> getCategoriesByMenu(String menuId) {
    if (menuId.trim().isEmpty) {
      throw Exception("Menu ID cannot be empty.");
    }
    return _repository.getCategoriesByMenu(menuId);
  }

  /// Get single category by ID
  Future<CategoryModel?> getCategoryById(String id) {
    if (id.trim().isEmpty) {
      throw Exception("Category ID cannot be empty.");
    }
    return _repository.getCategoryById(id);
  }

  /// Update category
  Future<void> updateCategory(String id, Map<String, dynamic> data) async {
    if (id.trim().isEmpty) {
      throw Exception("Category ID cannot be empty.");
    }
    final existingCategory = await _repository.getCategoryById(id);
    if (existingCategory == null) {
      throw Exception('Category not found.');
    }

    final updatedName = (data['name'] ?? existingCategory.name).toString();
    final updatedMenuId = (data['menuId'] ?? existingCategory.menuId)
        .toString();

    if (updatedName.trim().isEmpty) {
      throw Exception("Category name cannot be empty.");
    }

    final normalizedName = updatedName.trim().toLowerCase();
    final existingCategories = await _repository.getCategoriesByMenu(
      updatedMenuId,
    );
    final duplicateExists = existingCategories.any(
      (category) =>
          category.id != id &&
          category.name.trim().toLowerCase() == normalizedName,
    );

    if (duplicateExists) {
      throw Exception('Category already exists in this menu.');
    }

    await _repository.updateCategory(id, data);
  }

  Future<void> updateProductImage({
    required CategoryModel category,
    required Uint8List newImageBytes,
    required String businessId,
    required String branchId,
    required String fileExtension,
    required String? oldImageUrl,
  }) async {
    try {
      // Upload new image
      final newImageUrl = await _storageService.uploadCategoryImage(
        businessId: businessId,
        branchId: branchId,
        imageBytes: newImageBytes,
        fileExtension: fileExtension,
      );

      // Update product
      category.copyWith(imageUrl: newImageUrl);
      await _repository.updateCategory(category.id, category.toMap());

      // Delete old image if exists
      if (oldImageUrl != null && oldImageUrl.isNotEmpty) {
        await _storageService.deleteProductImage(oldImageUrl);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete category
  Future<void> deleteCategory(String id) async {
    if (id.trim().isEmpty) {
      throw Exception("Category ID cannot be empty.");
    }
    await _repository.deleteCategory(id);
  }
}
