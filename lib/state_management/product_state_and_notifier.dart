import 'dart:typed_data';

import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/services/image_storage_service.dart';
import 'package:hotel_management_system/data/services/product_service.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:riverpod/riverpod.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/data/repositories/product_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Repository Provider
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    businessId: BusinessRepository.temporaryBusinesshId,
    branchId: BusinessRepository.temporaryBranchId,
  );
});

// Service Provider
final productServiceProvider = Provider<ProductService>((ref) {
  final ProductRepository repo = ref.read(productRepositoryProvider);
  final StorageService storageRepo = ref.read(storageServiceProvider);
  return ProductService(repository: repo, storageService: storageRepo);
});

// Product List Provider (all products)
// final productListProvider = FutureProvider<List<ProductModel>>((ref) async {
//   final service = ref.read(productServiceProvider);
//   return service.getAllProducts();
// });

// Product by ID Provider
final productByIdProvider = FutureProvider.family<ProductModel?, String>((
  ref,
  productId,
) async {
  final service = ref.read(productServiceProvider);
  return service.getProductById(productId);
});

// Products by Category Provider
final productsByCategoryProvider =
    FutureProvider.family<List<ProductModel>, String>((ref, categoryId) async {
      final service = ref.read(productServiceProvider);
      return service.getProductsByCategory(categoryId);
    });

// Filtered Products by Search Query
// final filteredProductsProvider = FutureProvider.family<List<ProductModel>, String>((ref, query) async {
//   final service = ref.read(productServiceProvider);
//   final products = await service.getAllProducts();

//   return products
//       .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
//       .toList();
// });

// Favourite Products Provider (list of productIds)
// final favouriteProductsProvider = FutureProvider.family<List<ProductModel>, List<String>>(
//         (ref, productIds) async {
//   final service = ref.read(productServiceProvider);
//   return service.getFavouriteProducts(productIds);
// });

class ProductState {
  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final bool isLoading;
  final String? error;

  const ProductState({
    this.products = const [],
    this.selectedProduct,
    this.isLoading = false,
    this.error,
  });

  ProductState copyWith({
    List<ProductModel>? products,
    ProductModel? selectedProduct,
    bool? isLoading,
    String? error,
  }) {
    return ProductState(
      products: products ?? this.products,
      selectedProduct: selectedProduct ?? this.selectedProduct,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProductNotifier extends StateNotifier<ProductState> {
  final ProductService _service;

  ProductNotifier(this._service) : super(const ProductState());

  Future<void> loadAllProducts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await _service
          .getAllProducts(); // Add this method to your service
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> toggleProductAvailability(
    String productId,
    bool isAvailable,
  ) async {
    try {
      final product = state.products.firstWhere(
        (p) => p.productId == productId,
      );
      final updatedProduct = product.copyWith(
        isAvailable: isAvailable,
        updatedAt: DateTime.now(),
      );
      await updateProduct(updatedProduct);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> loadProductsByCategory(String categoryId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final products = await _service.getProductsByCategory(categoryId);
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> loadProductById(String productId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final product = await _service.getProductById(productId);
      state = state.copyWith(selectedProduct: product, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<ProductModel> createProduct(
    ProductModel product,
    String businessId,
    String branchId,
    Uint8List? imageBytes,
    String? fileExtension,
  ) async {
    try {
      final savedProduct = await _service.createProduct(
        product,
        businessId,
        branchId,
        imageBytes,
        fileExtension,
      );
      await loadAllProducts();
      return savedProduct;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> updateProduct(ProductModel product) async {
    try {
      await _service.updateProduct(product);
      final updatedList = state.products
          .map((p) => p.productId == product.productId ? product : p)
          .toList();
      state = state.copyWith(products: updatedList);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateProductWithImage({
    required ProductModel product,
    required Uint8List? imageBytes,
    required String? imageExtension,
    required String businessId,
    required String branchId,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      ProductModel updatedProduct;

      // If new image is provided, update the image
      if (imageBytes != null &&
          imageBytes.isNotEmpty &&
          imageExtension != null) {
        updatedProduct = await _service.updateProductImage(
          product: product,
          newImageBytes: imageBytes,
          businessId: businessId,
          branchId: branchId,
          fileExtension: imageExtension,
          oldImageUrl: product.imageUrl,
        );
      } else {
        // Just update the product without changing image
        updatedProduct = product.copyWith(updatedAt: DateTime.now());
        await _service.updateProduct(updatedProduct);
      }

      // Update local state with the UPDATED product (with new image URL)
      final updatedList = state.products
          .map(
            (p) => p.productId == updatedProduct.productId ? updatedProduct : p,
          )
          .toList();

      state = state.copyWith(products: updatedList, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to update product: $e',
        isLoading: false,
      );
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId, String productImageUrl) async {
    try {
      await _service.deleteProduct(productId, productImageUrl);
      state = state.copyWith(
        products: state.products
            .where((p) => p.productId != productId)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

// ...existing code...

// ProductNotifier Provider - add this at the end of the file
final productNotifierProvider =
    StateNotifierProvider<ProductNotifier, ProductState>((ref) {
      final service = ref.read(productServiceProvider);
      return ProductNotifier(service);
    });
