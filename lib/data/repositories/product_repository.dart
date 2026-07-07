import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/core/local/offline_local_read_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import '../models/product_model.dart';

// whereIn (for favourites) → max 10 IDs per query. If you expect more, I can also code a batched fetch loop.

// updateProductRating uses a transaction → prevents race conditions if multiple users review at the same time.
class ProductRepository {
  ProductRepository({required String businessId, required String branchId})
    : _businessId = businessId,
      _branchId = branchId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference<Object?> get _productsRef => FirebaseFirestore.instance
      .collection('businesses')
      .doc(_businessId)
      .collection('branches')
      .doc(_branchId)
      .collection('products');

  final String _businessId;
  final String _branchId;

  List<ProductModel> _mergeProductsPreferLocal({
    required List<ProductModel> local,
    required List<ProductModel> remote,
  }) {
    final merged = <String, ProductModel>{};
    for (final product in remote) {
      merged[product.productId] = product;
    }
    for (final product in local) {
      merged[product.productId] = product;
    }
    final list = merged.values.toList(growable: false);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<List<ProductModel>> _getLocalProducts() async {
    final localRows = await OfflineLocalReadService.instance
        .getBranchCollection(
          businessId: _businessId,
          branchId: _branchId,
          collectionName: 'products',
        );

    return localRows
        .map(
          (doc) =>
              ProductModel.fromMap(doc, (doc['__documentId'] ?? '').toString()),
        )
        .toList(growable: false);
  }

  /// 1️⃣ Get product by ID
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _productsRef.doc(productId).get();
      if (doc.exists) {
        return ProductModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw Exception("Error fetching product by ID: $e");
    }
  }

  Future<List<ProductModel>> getAllProducts() async {
    final local = await _getLocalProducts();
    try {
      final doc = await _productsRef
          .where('isAvailable', isEqualTo: true)
          .get();
      final remote = doc.docs
          .map(
            (doc) => ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(growable: false);

      final merged = _mergeProductsPreferLocal(local: local, remote: remote);
      return merged.where((product) => product.isAvailable).toList();
    } catch (e) {
      if (local.isNotEmpty) {
        return local.where((product) => product.isAvailable).toList();
      }
      throw Exception("Error fetching all products: $e");
    }
  }

  /// 2️⃣ Get favourite products by list of IDs (max 10 per query)
  Future<List<ProductModel>> getFavouriteProducts(
    List<String> productIds,
  ) async {
    try {
      if (productIds.isEmpty) return [];
      final query = await _productsRef
          .where(FieldPath.documentId, whereIn: productIds.take(10).toList())
          .get();

      return query.docs
          .map(
            (doc) => ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList();
    } catch (e) {
      throw Exception("Error fetching favourite products: $e");
    }
  }

  /// 3️⃣ Get all products by Category ID
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final local = await _getLocalProducts();
    try {
      final query = await _productsRef
          .where('categoryId', isEqualTo: categoryId)
          .where('isAvailable', isEqualTo: true)
          .get();

      final remote = query.docs
          .map(
            (doc) => ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          )
          .toList(growable: false);

      final merged = _mergeProductsPreferLocal(local: local, remote: remote);
      return merged
          .where(
            (product) =>
                product.isAvailable && product.categoryId == categoryId,
          )
          .toList();
    } catch (e) {
      final fallback = local
          .where(
            (product) =>
                product.isAvailable && product.categoryId == categoryId,
          )
          .toList();
      if (fallback.isNotEmpty) {
        return fallback;
      }
      throw Exception("Error fetching products by category: $e");
    }
  }

  /// 4️⃣ Update a product (Admin/Owner only)
  Future<void> updateProduct(ProductModel product) async {
    try {
      final documentPath =
          'businesses/$_businessId/branches/$_branchId/products/${product.productId}';
      await OfflineFirestoreWriteQueueService.instance.setOrQueue(
        documentPath: documentPath,
        data: product.toMap(),
        merge: true,
      );
    } catch (e) {
      throw Exception("Error updating product: $e");
    }
  }

  /// 5️⃣ Update average rating when a review is submitted
  Future<void> updateProductRating(String productId, double newRating) async {
    final productDoc = _productsRef.doc(productId);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(productDoc);

        if (!snapshot.exists) {
          throw Exception("Product not found");
        }

        final data = snapshot.data() as Map<String, dynamic>;
        final currentCount = (data['reviewCount'] ?? 0) as int;
        final currentAverage = (data['averageRating'] ?? 0.0).toDouble();

        final newCount = currentCount + 1;
        final updatedAverage =
            ((currentAverage * currentCount) + newRating) / newCount;

        transaction.update(productDoc, {
          'reviewCount': newCount,
          'averageRating': updatedAverage,
          'updatedAt': DateTime.now(),
        });
      });
    } catch (e) {
      throw Exception("Error updating product rating: $e");
    }
  }

  /// 6️⃣ Get products by multiple IDs (handles batching if >10)
  Future<List<ProductModel>> getProductsByIds(List<String> productIds) async {
    try {
      if (productIds.isEmpty) return [];

      final List<ProductModel> results = [];
      final chunks = <List<String>>[];

      // Firestore limitation: max 10 ids per query
      for (var i = 0; i < productIds.length; i += 10) {
        chunks.add(
          productIds.sublist(
            i,
            i + 10 > productIds.length ? productIds.length : i + 10,
          ),
        );
      }

      for (final chunk in chunks) {
        final query = await _productsRef
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        results.addAll(
          query.docs.map(
            (doc) => ProductModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ),
          ),
        );
      }

      return results;
    } catch (e) {
      throw Exception("Error fetching products by IDs: $e");
    }
  }

  /// 7️⃣ Add new product
  Future<ProductModel> addProduct(ProductModel product) async {
    try {
      final docId = product.productId.trim().isEmpty
          ? _productsRef.doc().id
          : product.productId;
      final documentPath =
          'businesses/$_businessId/branches/$_branchId/products/$docId';
      await OfflineFirestoreWriteQueueService.instance.setOrQueue(
        documentPath: documentPath,
        data: product.toMap(),
        merge: false,
      );
      return ProductModel(
        productId: docId,
        name: product.name,
        description: product.description,
        imageUrl: product.imageUrl,
        price: product.price,
        categoryId: product.categoryId,
        isAvailable: product.isAvailable,
        createdAt: product.createdAt,
        updatedAt: product.updatedAt,
        averageRating: product.averageRating,
        reviewCount: product.reviewCount,
      );
    } catch (e) {
      throw Exception("Error adding product: $e");
    }
  }

  /// 8️⃣ Delete product by ID
  Future<void> deleteProduct(String productId) async {
    try {
      await OfflineFirestoreWriteQueueService.instance.deleteOrQueue(
        documentPath:
            'businesses/$_businessId/branches/$_branchId/products/$productId',
      );
    } catch (e) {
      throw Exception("Error deleting product: $e");
    }
  }
}
