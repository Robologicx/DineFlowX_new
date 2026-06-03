import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hotel_management_system/data/models/role_model.dart';

/// ------------------ ENUMS ------------------
// enum UserRole { owner, admin, waiter, customer }

/// ------------------ MAIN USER MODEL ------------------
class UserModel {
  /// Auth/Firestore UID
  final String uid;

  /// Basic profile
  final String name;
  final String email;
  final String? phoneNumber;
  final String? profileImageUrl;

  /// ModelRole -- for multirole system
  bool isStaffMember;
  final RoleModel role;
  final String primarybusinessId;
  final String primaryBranchId;

  /// Product IDs the user has favorited
  final List<String> favoriteProductIds;

  /// Primary user location (optional)
  /// If user types an address:
  final String? userLocationText;

  /// If user picks from Google Maps:
  final LatLng? userLatlng;

  /// Multiple saved delivery addresses (each with optional lat/lng)
  final List<DeliveryAddress> deliveryAddresses;

  /// Audit
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Extra permissions
  /// These are additional permission IDs assigned to the user,
  /// beyond their role's default permissions.
  /// For example, an 'admin' role user might get extra permissions to access certain modules.
  /// But issue arises when user has more than one business/branch. So each branch has its own role and permissions.
  /// For selected hotel/branch, we will fetch permissions from that branch dynamically and add to this.
  /// Key: permissionId, Value: permissionName (for easy display in UI if needed)
  final Map<String, String> extraPermissions;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.isStaffMember = false,
    required this.role,
    this.favoriteProductIds = const [],
    this.userLocationText,
    this.userLatlng,
    this.deliveryAddresses = const [],
    required this.createdAt,
    required this.updatedAt,
    required this.extraPermissions,
    required this.primarybusinessId,
    required this.primaryBranchId,
  });

  /// Robust DateTime parser that accepts:
  /// - DateTime
  /// - ISO8601 String
  /// - int (millisecondsSinceEpoch)
  static DateTime _parseDate(dynamic v, {DateTime? fallback}) {
    if (v is DateTime) return v;
    if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
    if (v is String) {
      final parsed = DateTime.tryParse(v);
      if (parsed != null) return parsed;
    }
    return fallback ?? DateTime.now();
    // Note: If you're saving Firestore Timestamps, convert them
    // to ISO strings or millis when writing, so this stays Timestamp-free.
  }

  /// Map<String, dynamic> (from Firestore) -> UserModel
  factory UserModel.fromMap(String documentId, Map<String, dynamic> data) {
    final primarybusinessId = (data['primarybusinessId'] ?? '').toString();
    final primaryBranchId = (data['primaryBranchId'] ?? '').toString();
    final isStaffMember = (data['isStaffMember'] ?? false) == true;
    final fallbackRoleName = (data['roleName'] ?? data['role_name'] ?? '')
        .toString()
        .trim();
    final fallbackRoleId =
        (data['roleId'] ?? data['role_id'] ?? fallbackRoleName.toLowerCase())
            .toString()
            .trim();
    final rawRole = data['role'];

    if (isStaffMember) {
      if (primaryBranchId.isEmpty || primarybusinessId.isEmpty) {
        throw Exception(
          "Invalid data: primarybusinessId and primaryBranchId are required for staff members.",
        );
      }
    }
    return UserModel(
      uid: documentId,
      name: (data['name'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phoneNumber: data['phoneNumber']?.toString(),
      profileImageUrl: data['profileImageUrl']?.toString(),
      isStaffMember: isStaffMember,
      role: (() {
        final fallbackRole = RoleModel(
          id: fallbackRoleId,
          name: fallbackRoleName,
          permissions: const [],
          businessId: primarybusinessId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        if (rawRole is Map) {
          final parsed = RoleModel.fromMap(Map<String, dynamic>.from(rawRole));
          final hasParsedIdentity =
              parsed.id.trim().isNotEmpty || parsed.name.trim().isNotEmpty;
          if (hasParsedIdentity) {
            return parsed;
          }
        }

        return fallbackRole;
      })(),
      favoriteProductIds: List<String>.from(
        (data['favoriteProductIds'] ?? const <dynamic>[]).map(
          (e) => e.toString(),
        ),
      ),
      userLocationText: data['userLocationText']?.toString(),
      userLatlng:
          (data['userLatlng'] is Map &&
              data['userLatlng']['lat'] != null &&
              data['userLatlng']['lng'] != null)
          ? LatLng(
              (data['userLatlng']['lat'] as num).toDouble(),
              (data['userLatlng']['lng'] as num).toDouble(),
            )
          : null,
      deliveryAddresses: (data['deliveryAddresses'] as List<dynamic>? ?? [])
          .map(
            (e) => DeliveryAddress.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      createdAt: _parseDate(data['createdAt']),
      updatedAt: _parseDate(
        data['updatedAt'],
        fallback: _parseDate(data['createdAt']),
      ),
      extraPermissions:
          (data['extraPermissions'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, v.toString()),
          ) ??
          {},
      primarybusinessId: primarybusinessId,
      primaryBranchId: primaryBranchId,
    );
  }

  /// UserModel -> Map<String, dynamic> (for Firestore)
  Map<String, dynamic> toMap() {
    if (isStaffMember) {
      if (primaryBranchId.isEmpty || primarybusinessId.isEmpty) {
        throw Exception(
          "Invalid data: primarybusinessId and primaryBranchId must not be empty for staff members.",
        );
      }
    }
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'isStaffMember': isStaffMember,
      'role': role
          .toMap(), // stores as 'owner' | 'admin' | 'waiter' | 'customer'
      'favoriteProductIds': favoriteProductIds,
      'userLocationText': userLocationText,
      'userLatlng': userLatlng == null
          ? null
          : {'lat': userLatlng!.latitude, 'lng': userLatlng!.longitude},
      'deliveryAddresses': deliveryAddresses.map((e) => e.toMap()).toList(),
      // Store DateTime as ISO strings (consistent & Timestamp-free)
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'extraPermissions': extraPermissions,
      'primarybusinessId': primarybusinessId,
      'primaryBranchId': primaryBranchId,
    };
  }

  /// Handy helper for updates
  UserModel copyWith({
    String? uid,
    String? name,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    bool? isStaffMember,
    String? primarybusinessId,
    String? primaryBranchId,
    RoleModel? role,
    List<String>? favoriteProductIds,
    String? userLocationText,
    LatLng? userLatlng,
    List<DeliveryAddress>? deliveryAddresses,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, String>? extraPermissions,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isStaffMember: isStaffMember ?? this.isStaffMember,
      role: role ?? this.role,
      favoriteProductIds: favoriteProductIds ?? this.favoriteProductIds,
      userLocationText: userLocationText ?? this.userLocationText,
      userLatlng: userLatlng ?? this.userLatlng,
      deliveryAddresses: deliveryAddresses ?? this.deliveryAddresses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      extraPermissions: extraPermissions ?? this.extraPermissions,
      primarybusinessId: primarybusinessId ?? this.primarybusinessId,
      primaryBranchId: primaryBranchId ?? this.primaryBranchId,
    );
  }
}

/// ------------------ SUPPORT MODEL ------------------
/// A single saved delivery address.
/// If picked from map, store lat/lng alongside the text.
class DeliveryAddress {
  final String addressText; // Required: human-readable address
  final LatLng? latLng; // Optional: precise map location

  DeliveryAddress({required this.addressText, this.latLng});

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      addressText: (map['addressText'] ?? '').toString(),
      latLng:
          (map['latLng'] is Map &&
              map['latLng']['lat'] != null &&
              map['latLng']['lng'] != null)
          ? LatLng(
              (map['latLng']['lat'] as num).toDouble(),
              (map['latLng']['lng'] as num).toDouble(),
            )
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addressText': addressText,
      // Store LatLng as a map so Firestore can persist it safely
      'latLng': latLng == null
          ? null
          : {'lat': latLng!.latitude, 'lng': latLng!.longitude},
    };
  }
}

// This keeps the user profile light and links:
// Orders → via userId in the orders collection
// Reviews → via userId in the reviews collection
// Dining assistance → via userId in a dining_assistance_requests collection
