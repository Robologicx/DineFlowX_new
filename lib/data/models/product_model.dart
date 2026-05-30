import 'package:cloud_firestore/cloud_firestore.dart';

class ProductModel {
  final String productId;
  final String name;
  final String description;
  final String? imageUrl;
  final double price;
  final String categoryId; // Reference to CategoryModel
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double averageRating;
  final int reviewCount;

  ProductModel({
    required this.productId,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.price,
    required this.categoryId,
    this.isAvailable = true,
    required this.createdAt,
    required this.updatedAt,
    this.averageRating = 0.0,
    this.reviewCount = 0,
  });

  // Firestore doc → Model
  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      productId: documentId,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      price: (data['price'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      isAvailable: data['isAvailable'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
    );
  }

  // Model → Firestore doc
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'categoryId': categoryId,
      'isAvailable': isAvailable,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
    };
  }
}

extension ProductCopyWith on ProductModel {
  ProductModel copyWith({
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    String? categoryId,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? averageRating,
    int? reviewCount,
  }) {
    return ProductModel(
      productId: productId,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }
}

// Future Linking
// Favorites → User.favorites already stores a list of productIds

// Orders → Order items will store productId & quantity

// Reviews → Stored in reviews collection, linked by productId

// Categories → categoryId will link to a CategoryModel
