import 'package:cloud_firestore/cloud_firestore.dart';

// class BusinessModel {
//   final String id; /
//   final String ownerId; // User ID of the owner/admin
//   final String title; // Business name (Hotel XYZ, Cafe ABC, etc.)
//   final String? description;
//   final String? logoUrl;
//   final String? coverImageUrl;

//   // Contact & Location
//   final String? phone;
//   final String? email;
//   final String? website;
//   final String? address;
//   final String? city;
//   final String? state;
//   final String? country;
//   final String? postalCode;

//   // Business settings
//   final String currencyCode; // e.g. USD, PKR
//   final double taxPercentage; // Default tax %
//   final double?
//   serviceChargePercentage; // e.g. service charges in hotels/restaurants
//   final String timezone; // For correct POS billing & reports
//   final String industryType; // hotel, restaurant, retail, salon, gym etc.

//   // SaaS/Subscription
//   final String? subscriptionPlan; // free, pro, enterprise
//   final DateTime? subscriptionExpiry;

//   // Meta
//   final DateTime createdAt;
//   final DateTime updatedAt;

class BusinessModel {
  static const Object _noChange = Object();

  final String id; // Unique business ID (hotelId, shopId, etc.)
  final String ownerId; // User ID of the owner/admin
  final String title; // Business name (Hotel XYZ, Cafe ABC, etc.)
  final String? description;
  final String? logoUrl;
  final String? coverImageUrl;

  // Contact & location
  final String? phone;
  final String? email;
  final String? website;
  final String? address;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;

  // Settings
  final String currencyCode; // e.g. USD, PKR
  final double taxPercentage; // Default tax %
  final double?
  serviceChargePercentage; // e.g. service charges in hotels/restaurants
  final String timezone; // For correct POS billing & reports
  final String industryType; // hotel, restaurant, retail, salon, gym etc.

  // SaaS
  final String? subscriptionPlan;
  final DateTime? subscriptionExpiry;

  // Flags
  final bool isActive;
  final bool isDeleted;
  final DateTime? deletedAt;

  // Audit
  final DateTime createdAt;
  final DateTime updatedAt;

  // Branch contains branchId and Map<String, String> userId to userName in firestore for now, after that create model for branch;

  BusinessModel({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.phone,
    this.email,
    this.website,
    this.address,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.currencyCode = 'USD',
    this.taxPercentage = 0.0,
    this.serviceChargePercentage,
    this.timezone = 'UTC',
    this.industryType = 'general',
    this.subscriptionPlan,
    this.subscriptionExpiry,
    this.isActive = true,
    this.isDeleted = false,
    this.deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Robust date parser that accepts:
  /// - Firestore Timestamp
  /// - DateTime
  /// - int (millisecondsSinceEpoch)
  /// - ISO8601 string
  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    if (v is Timestamp) return v.toDate();
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
      // try parse as int string
      final ms = int.tryParse(v);
      if (ms != null) return DateTime.fromMillisecondsSinceEpoch(ms);
    }
    return null;
  }

  /// Map -> Model
  /// docId is optional (if you have doc.id from Firestore pass it)
  factory BusinessModel.fromMap(Map<String, dynamic> map, [String? docId]) {
    final created = _parseDate(map['createdAt']) ?? DateTime.now();
    final updated = _parseDate(map['updatedAt']) ?? created;
    final deleted = _parseDate(map['deletedAt']);
    final subscriptionExpiry = _parseDate(map['subscriptionExpiry']);

    return BusinessModel(
      id: (docId ?? map['id'] ?? '').toString(),
      ownerId: (map['ownerId'] ?? '').toString(),
      title: (map['title'] ?? '').toString(),
      description: map['description']?.toString(),
      logoUrl: map['logoUrl']?.toString(),
      coverImageUrl: map['coverImageUrl']?.toString(),
      phone: map['phone']?.toString(),
      email: map['email']?.toString(),
      website: map['website']?.toString(),
      address: map['address']?.toString(),
      city: map['city']?.toString(),
      state: map['state']?.toString(),
      country: map['country']?.toString(),
      postalCode: map['postalCode']?.toString(),
      currencyCode: (map['currencyCode'] ?? 'USD').toString(),
      taxPercentage: (map['taxPercentage'] ?? 0).toDouble(),
      serviceChargePercentage: map['serviceChargePercentage'] != null
          ? (map['serviceChargePercentage'] as num).toDouble()
          : null,
      timezone: (map['timezone'] ?? 'UTC').toString(),
      industryType: (map['industryType'] ?? 'general').toString(),
      subscriptionPlan: map['subscriptionPlan']?.toString(),
      subscriptionExpiry: subscriptionExpiry,
      isActive: (map['isActive'] ?? true) as bool,
      isDeleted: (map['isDeleted'] ?? false) as bool,
      deletedAt: deleted,
      createdAt: created,
      updatedAt: updated,
    );
  }

  /// Model -> Map
  /// We store date fields as millisecondsSinceEpoch (int) for consistency.
  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'title': title,
      'description': description,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'phone': phone,
      'email': email,
      'website': website,
      'address': address,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
      'currencyCode': currencyCode,
      'taxPercentage': taxPercentage,
      'serviceChargePercentage': serviceChargePercentage,
      'timezone': timezone,
      'industryType': industryType,
      'subscriptionPlan': subscriptionPlan,
      'subscriptionExpiry':
          subscriptionExpiry?.millisecondsSinceEpoch, // nullable
      'isActive': isActive,
      'isDeleted': isDeleted,
      'deletedAt': deletedAt?.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  BusinessModel copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    Object? logoUrl = _noChange,
    Object? coverImageUrl = _noChange,
    String? phone,
    String? email,
    String? website,
    String? address,
    String? city,
    String? state,
    String? country,
    String? postalCode,
    String? currencyCode,
    double? taxPercentage,
    double? serviceChargePercentage,
    String? timezone,
    String? industryType,
    String? subscriptionPlan,
    DateTime? subscriptionExpiry,
    bool? isActive,
    bool? isDeleted,
    DateTime? deletedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BusinessModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      logoUrl: identical(logoUrl, _noChange)
          ? this.logoUrl
          : logoUrl as String?,
      coverImageUrl: identical(coverImageUrl, _noChange)
          ? this.coverImageUrl
          : coverImageUrl as String?,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      postalCode: postalCode ?? this.postalCode,
      currencyCode: currencyCode ?? this.currencyCode,
      taxPercentage: taxPercentage ?? this.taxPercentage,
      serviceChargePercentage:
          serviceChargePercentage ?? this.serviceChargePercentage,
      timezone: timezone ?? this.timezone,
      industryType: industryType ?? this.industryType,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
