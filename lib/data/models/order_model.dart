import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/models/table_model.dart';

enum OrderType { dining, takeaway, delivery }

enum OrderStatus {
  pending,
  inProgress,
  ready, // for takeaway orders
  completed,
  cancelled,
  refunded,
}

class OrderModel {
  final String orderId;
  final String?
  userId; // Reference to UserModel - null if order is took by waiter.
  final String userName;
  final String? userPhoneNo; // Mandatory for delivery orders
  final OrderType orderType;
  final List<OrderItem> items;
  final double totalAmount;
  final OrderStatus orderStatus;
  final DateTime createdAt;
  final DateTime updatedAt;
  // Optional but required in specific cases
  // For delivery orders
  final String? deliveryAddress; // Required if orderType == delivery
  final LatLng?
  deliveryLocation; // Required if orderType == delivery - Maps location
  // For dining orders
  final TableModel? diningTable; // Required if orderType == dining
  final String? waiterId; // Assigned waiter (only for dining orders)
  final String? waiterName; // Assigned waiter (only for dining orders)
  final String? additionalNotes;
  final String? businessDayId;
  final DateTime? businessDayStartAt;

  OrderModel({
    required this.orderId,
    required this.userId,
    required this.userName,
    this.userPhoneNo,
    required this.orderType,
    required this.items,
    required this.totalAmount,
    required this.orderStatus,
    required this.createdAt,
    required this.updatedAt,
    this.deliveryAddress,
    this.deliveryLocation,
    this.diningTable,
    // this.diningTableNo,
    // this.diningRoomNoOrName,
    this.waiterId,
    this.waiterName,
    this.additionalNotes,
    this.businessDayId,
    this.businessDayStartAt,
  }) {
    // Validation rules
    if (orderType == OrderType.delivery &&
        deliveryAddress == null &&
        deliveryLocation == null) {
      throw ArgumentError(
        'Delivery orders must have a deliveryAddress or deliveryLocation.',
      );
    }
    if (orderType == OrderType.dining && diningTable == null) {
      throw ArgumentError('Dining orders must have a diningTableNo.');
    }
    // if order is takeaway, create a new field as pickedup 0r Ready.
    //-----------Later on ---------------//
  }

  // Firestore doc → Model
  // factory OrderModel.fromMap(Map<String, dynamic> data, String documentId) {
  //   return OrderModel(
  //     orderId: documentId,
  //     userId: data['userId'] ?? '',
  //     userName: data['userName'] ?? '',
  //     userPhoneNo: data['userPhoneNo'] ?? '',
  //     orderType: OrderType.values.firstWhere(
  //       (e) => e.toString() == 'OrderType.${data['orderType']}',
  //       orElse: () => OrderType.takeaway,
  //     ),
  //     items:
  //         (data['items'] as List<dynamic>?)
  //             ?.map((item) => OrderItem.fromMap(item))
  //             .toList() ??
  //         [],
  //     totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
  //     orderStatus: OrderStatus.values.firstWhere(
  //       (e) => e.toString() == 'OrderStatus.${data['orderStatus']}',
  //       orElse: () => OrderStatus.pending,
  //     ),
  //     createdAt: (data['createdAt'] as Timestamp).toDate(),
  //     updatedAt: (data['updatedAt'] as Timestamp).toDate(),
  //     deliveryAddress: data['deliveryAddress'],
  //     deliveryLocation: data['deliveryLocation'] != null
  //         ? LatLng(
  //             data['deliveryLocation']['lat'],
  //             data['deliveryLocation']['lng'],
  //           )
  //         : null,
  //     diningTable: data['diningTable'] != null
  //         ? TableModel.fromMap(data['diningTable'])
  //         : null,
  //     waiterId: data['waiterId'],
  //     waiterName: data['waiterName'],
  //   );
  // }
  factory OrderModel.fromMap(Map<String, dynamic> data, String documentId) {
    final orderType = OrderType.values.firstWhere(
      (e) => e.toString() == 'OrderType.${data['orderType']}',
      orElse: () => OrderType.takeaway, // Default to 'takeaway' if not found
    );

    final userId = data['userId'] as String? ?? '';
    final userPhoneNo = data['userPhoneNo'] as String?;
    final userName = data['userName'] as String? ?? '';

    if (orderType == OrderType.delivery && userPhoneNo == null) {
      throw ArgumentError('User phone number is mandatory for delivery orders');
    }

    final deliveryLocation = data['deliveryLocation'] != null
        ? LatLng(
            data['deliveryLocation']['lat'] as double,
            data['deliveryLocation']['lng'] as double,
          )
        : null;

    if (orderType == OrderType.delivery) {
      if (deliveryLocation == null && data['deliveryAddress'] == null) {
        throw ArgumentError(
          'Delivery location is required for delivery orders',
        );
      }
    }

    final waiterId = data['waiterId'] as String?;
    final waiterName = data['waiterName'] as String?;

    if (orderType == OrderType.dining) {
      if (waiterId == null || waiterName == null) {
        throw ArgumentError('Waiter information is required for dining orders');
      }
    } else {
      assert(
        waiterId == null && waiterName == null,
      ); // Ensure they are null for non-dining orders
    }

    final additionalNotes = data['additionalNotes'] as String?;

    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is String) {
        final parsed = DateTime.tryParse(value);
        if (parsed != null) return parsed;
      }
      if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    return OrderModel(
      orderId: documentId,
      userId: userId,
      userName: userName,
      userPhoneNo: userPhoneNo,
      orderType: orderType,
      items:
          (data['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
              .toList() ??
          [],
      totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,

      //all otder status default value is pending
      orderStatus: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${data['orderStatus']}',
        orElse: () => OrderStatus.pending,
      ),

      //take away order stautus default value is complate
      /*orderStatus: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${data['orderStatus']}',
        orElse: () => orderType == OrderType.takeaway
            ? OrderStatus.completed
            : OrderStatus.pending,
      ),*/
      createdAt: parseDateTime(data['createdAt']),
      updatedAt: parseDateTime(data['updatedAt']),
      deliveryAddress: data['deliveryAddress'] as String?,
      deliveryLocation: deliveryLocation,
      diningTable: data['diningTable'] != null
          ? TableModel.fromMap(data['diningTable'] as Map<String, dynamic>)
          : null,
      waiterId: waiterId,
      waiterName: waiterName,
      additionalNotes: additionalNotes,
      businessDayId: data['businessDayId'] as String?,
      businessDayStartAt: data['businessDayStartAt'] != null
          ? parseDateTime(data['businessDayStartAt'])
          : null,
    );
  }

  // Model → Firestore doc
  Map<String, dynamic> toMap() {
    // Business logic validations
    if (orderType == OrderType.delivery) {
      if (userPhoneNo == null || userPhoneNo!.isEmpty) {
        throw ArgumentError(
          'User phone number is required for delivery orders.',
        );
      }
      if (deliveryAddress == null && deliveryLocation == null) {
        throw ArgumentError(
          'Either deliveryAddress or deliveryLocation must be provided for delivery orders.',
        );
      }
    }

    if (orderType == OrderType.dining) {
      if (diningTable == null) {
        throw ArgumentError('Dining table is required for dining orders.');
      }
      if (waiterId == null || waiterName == null) {
        throw ArgumentError(
          'Waiter information is required for dining orders.',
        );
      }
    }

    return {
      'userId': userId,
      'userName': userName,
      'userPhoneNo': userPhoneNo,
      'orderType': orderType.toString().split('.').last,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderStatus': orderStatus.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'deliveryAddress': deliveryAddress,
      'deliveryLocation': deliveryLocation != null
          ? {
              'lat': deliveryLocation!.latitude,
              'lng': deliveryLocation!.longitude,
            }
          : null,
      'diningTable': diningTable?.toMap(),
      'waiterId': waiterId,
      'waiterName': waiterName,
      'additionalNotes': additionalNotes,
      'businessDayId': businessDayId,
      'businessDayStartAt': businessDayStartAt != null
          ? Timestamp.fromDate(businessDayStartAt!)
          : null,
    };
  }
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
  });

  OrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? price,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'],
      productName: data['productName'] ?? 'Unknown Product',
      quantity: data['quantity'],
      price: (data['price'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
    };
  }
}
