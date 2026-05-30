import 'dart:typed_data';

import 'package:hotel_management_system/data/services/image_storage_service.dart';

import '../repositories/product_repository.dart';
import '../models/product_model.dart';

class ProductService {
  final ProductRepository _repository;
  final StorageService _storageService;
  ProductService({
    required ProductRepository repository,
    required StorageService storageService,
  }) : _repository = repository,
       _storageService = storageService;
  // By making this parameterized constructor, we can inject different implementations of ProductRepository if needed.
  // Why is this better?
  // ✅ Testability → you can pass a fake/mock repository when writing tests.
  // ✅ Flexibility → you can later swap repositories (API repo, Local DB repo, etc).
  // ✅ Cleaner code → avoids “tight coupling” (service always locked to one repo).

  /// Get a product by its ID
  Future<ProductModel?> getProductById(String productId) async {
    return await _repository.getProductById(productId);
  }

  /// Get user's favorite products (by list of IDs)
  Future<List<ProductModel>> getFavoriteProducts(
    List<String> productIds,
  ) async {
    if (productIds.isEmpty) return [];
    return await _repository.getProductsByIds(productIds);
  }
  // Need to write a function to toggle favorite status

  /// Get all products belonging to a category
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    return await _repository.getProductsByCategory(categoryId);
  }

  /// Admin/Owner can update a product
  Future<void> updateProduct(ProductModel product) async {
    final updatedProduct = product.copyWith(updatedAt: DateTime.now());
    await _repository.updateProduct(updatedProduct);
  }

  Future<ProductModel> updateProductImage({
    required ProductModel product,
    required Uint8List newImageBytes,
    required String businessId,
    required String branchId,
    required String fileExtension,
    required String? oldImageUrl,
  }) async {
    try {
      print('🔄 Starting product image update...');

      // Upload new image
      final newImageUrl = await _storageService.uploadProductImage(
        businessId: businessId,
        branchId: branchId,
        imageBytes: newImageBytes,
        fileExtension: fileExtension,
      );

      print('✅ New image URL: $newImageUrl');

      // Create updated product with new image URL
      final updatedProduct = product.copyWith(
        imageUrl: newImageUrl,
        updatedAt: DateTime.now(),
      );

      // Update in Firestore
      await _repository.updateProduct(updatedProduct);
      print('📝 Product updated in Firestore');

      // Delete old image if exists
      if (oldImageUrl != null &&
          oldImageUrl.isNotEmpty &&
          oldImageUrl != newImageUrl) {
        try {
          await _storageService.deleteProductImage(oldImageUrl);
        } catch (e) {
          print('⚠️ Failed to delete old image: $e');
        }
      }

      return updatedProduct; // Return the updated product
    } catch (e) {
      print('❌ Error in updateProductImage: $e');
      rethrow;
    }
  }

  /// Create new product
  Future<ProductModel> createProduct(
    ProductModel product,
    String businessId,
    String branchId,
    Uint8List? imageBytes,
    String? fileExtension,
  ) async {
    try {
      if (imageBytes != null &&
          imageBytes.isNotEmpty &&
          fileExtension != null &&
          fileExtension.isNotEmpty) {
        // Upload image first
        final imageUrl = await _storageService.uploadProductImage(
          businessId: businessId,
          branchId: branchId,
          imageBytes: imageBytes,
          fileExtension: fileExtension,
        );
        // Create product with image URL
        product = product.copyWith(imageUrl: imageUrl);
      }

      return await _repository.addProduct(product);
    } catch (e) {
      rethrow;
    }
  }

  /// Delete product
  Future<void> deleteProduct(String productId, String imageUrl) async {
    if (imageUrl.isNotEmpty) await _storageService.deleteProductImage(imageUrl);
    await _repository.deleteProduct(productId);
  }

  /// Update product rating after review
  Future<void> updateProductRating(String productId, double newRating) async {
    await _repository.updateProductRating(productId, newRating);
  }

  // ✅ Get all products
  Future<List<ProductModel>> getAllProducts() async {
    return await _repository.getAllProducts();
  }

  // ✅ Get favourite products of a specific user
  //   Future<List<ProductModel>> getFavouriteProducts(UserModel user) async {
  //     final allProducts = await productRepository.getAllProducts();

  //     // filter by favourite product IDs stored in user
  //     return allProducts
  //         .where((product) => user.favouriteProductIds.contains(product.id))
  //         .toList();
  //   }
  // }
}
