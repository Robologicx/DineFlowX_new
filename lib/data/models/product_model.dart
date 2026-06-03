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

  static DateTime _parseDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    if (value is String) {
      final parsed = DateTime.tryParse(value);
      if (parsed != null) return parsed;
      final ms = int.tryParse(value);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return DateTime.now();
  }

  static double _parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  static int _parseInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  // Firestore doc → Model
  factory ProductModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ProductModel(
      productId: documentId,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      imageUrl: data['imageUrl'] == null ? null : data['imageUrl'].toString(),
      price: _parseDouble(data['price']),
      categoryId: (data['categoryId'] ?? '').toString(),
      isAvailable: data['isAvailable'] is bool
          ? data['isAvailable'] as bool
          : true,
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(data['updatedAt']),
      averageRating: _parseDouble(data['averageRating']),
      reviewCount: _parseInt(data['reviewCount']),
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
