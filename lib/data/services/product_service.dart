import 'dart:async';
import 'dart:typed_data';

import 'package:hotel_management_system/core/utils/offline_media_upload_queue_service.dart';
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
  static const Duration _quickQueryTimeout = Duration(seconds: 2);
  static const Duration _quickUploadTimeout = Duration(seconds: 4);
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
    final normalizedName = product.name.trim().toLowerCase();
    try {
      final existingProducts = await _repository
          .getProductsByCategory(product.categoryId)
          .timeout(_quickQueryTimeout);
      final duplicateExists = existingProducts.any(
        (existingProduct) =>
            existingProduct.productId != product.productId &&
            existingProduct.name.trim().toLowerCase() == normalizedName,
      );

      if (duplicateExists) {
        throw Exception('Product already exists in this category.');
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('product already exists')) {
        rethrow;
      }
      // Offline/no-cache path: allow save and rely on backend sync later.
    }

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
      final newImageUrl = await _storageService
          .uploadProductImage(
            businessId: businessId,
            branchId: branchId,
            imageBytes: newImageBytes,
            fileExtension: fileExtension,
          )
          .timeout(_quickUploadTimeout);

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
      print('❌ Error in updateProductImage, queued for retry: $e');
      await OfflineMediaUploadQueueService.instance.enqueueImageUpload(
        businessId: businessId,
        branchId: branchId,
        collection: 'products',
        documentId: product.productId,
        folder: 'product_images',
        imageBytes: newImageBytes,
        fileExtension: fileExtension,
      );
      return product;
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
      final normalizedName = product.name.trim().toLowerCase();
      try {
        final existingProducts = await _repository
            .getProductsByCategory(product.categoryId)
            .timeout(_quickQueryTimeout);
        final duplicateExists = existingProducts.any(
          (existingProduct) =>
              existingProduct.name.trim().toLowerCase() == normalizedName,
        );

        if (duplicateExists) {
          throw Exception('Product already exists in this category.');
        }
      } catch (e) {
        if (e.toString().toLowerCase().contains('product already exists')) {
          rethrow;
        }
        // Offline/no-cache path: allow save and rely on backend sync later.
      }

      Uint8List? pendingImageBytes;
      String? pendingExtension;

      if (imageBytes != null &&
          imageBytes.isNotEmpty &&
          fileExtension != null &&
          fileExtension.isNotEmpty) {
        try {
          final imageUrl = await _storageService
              .uploadProductImage(
                businessId: businessId,
                branchId: branchId,
                imageBytes: imageBytes,
                fileExtension: fileExtension,
              )
              .timeout(_quickUploadTimeout);
          product = product.copyWith(imageUrl: imageUrl);
        } catch (e) {
          pendingImageBytes = imageBytes;
          pendingExtension = fileExtension;
          print('Image upload queued for offline retry: $e');
        }
      }

      final createdProduct = await _repository.addProduct(product);

      if (pendingImageBytes != null &&
          pendingImageBytes.isNotEmpty &&
          pendingExtension != null &&
          pendingExtension.isNotEmpty) {
        await OfflineMediaUploadQueueService.instance.enqueueImageUpload(
          businessId: businessId,
          branchId: branchId,
          collection: 'products',
          documentId: createdProduct.productId,
          folder: 'product_images',
          imageBytes: pendingImageBytes,
          fileExtension: pendingExtension,
        );
      }

      return createdProduct;
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
