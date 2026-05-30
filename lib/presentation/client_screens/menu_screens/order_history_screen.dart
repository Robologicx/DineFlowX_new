import 'dart:developer';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/order_state_and_notifier.dart';
import 'package:intl/intl.dart' show DateFormat;

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen>
    with TickerProviderStateMixin {
  late AnimationController controller;
  int ordersLength = 0;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    getAllOrders();
  }

  void getAllOrders() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final orders = await ref
        .read(orderNotifierProvider)
        .getOrdersByUser(currentUser.uid);

    setState(() {
      ordersLength = orders.length;
    });
    log("Orders count: ${orders.length}");
  }

  @override
  Widget build(BuildContext context) {
    final ordersProvider = ref.watch(orderNotifierProvider);
    final screenWidth = MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final crossAxisCount = isDesktop
        ? 3
        : isTablet
        ? 2
        : 1;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.goNamed(ClientAppRoutes.shell);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        centerTitle: true,
        title: Text(
          'Order History',
          style: Theme.of(context).textTheme.titleLarge,
        ),
      ),
      // body: Padding(
      //   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      //   child: FutureBuilder<List<OrderModel>>(
      //     future: ordersProvider.getOrdersByUser(
      //       FirebaseAuth.instance.currentUser?.uid ?? '',
      //     ),
      //     builder: (context, snapshot) {
      //       if (snapshot.connectionState == ConnectionState.waiting) {
      //         return const Center(child: CircularProgressIndicator());
      //       }

      //       if (snapshot.hasError) {
      //         return const Center(
      //           child: Text('Some unexpected error occurred'),
      //         );
      //       }

      //       final data = snapshot.data;
      //       if (data == null || data.isEmpty) {
      //         return const Center(
      //           child: Text('You have not placed any orders yet'),
      //         );
      //       }

      //       return GridView.builder(
      //         gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      //           crossAxisCount: crossAxisCount,
      //           mainAxisSpacing: 12,
      //           crossAxisSpacing: 12,
      //           childAspectRatio: 2.5,
      //         ),
      //         itemCount: data.length,
      //         itemBuilder: (context, index) {
      //           final item = data[index];
      //           return _buildOrderCard(context, item, screenWidth);
      //         },
      //       );
      //     },
      //   ),
      // ),
      // floatingActionButton: ordersLength == 0
      //     ? FloatingActionButton(
      //         tooltip: 'Place Order',
      //         onPressed: () => context.goNamed(ClientAppRoutes.home),
      //         child: const Icon(Icons.add),
      //       )
      //     : null,
      body: Center(child: Text('Work in progress.......')),
    );
  }

  double _getChildAspectRatio(double screenWidth) {
    if (screenWidth >= 1024) {
      return 1.8; // Desktop
    } else if (screenWidth >= 600) {
      return 1.6; // Tablet
    } else {
      return 1.4; // Mobile
    }
  }

  Widget _buildOrderCard(
    BuildContext context,
    OrderModel product,
    double screenWidth,
  ) {
    final theme = Theme.of(context);
    final bool isMobile = screenWidth < 600;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product name
              Text(
                product.items.isNotEmpty
                    ? product.items.first.productName
                    : 'Unknown Product',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
              const SizedBox(height: 8),
              // Order details - using Expanded to handle text overflow
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOrderDetail(
                    "Order Type: ${product.orderType.name}",
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildOrderDetail(
                    "Date: ${formatDateTime(product.createdAt)}",
                    theme,
                  ),
                  const SizedBox(height: 8),
                  _buildOrderDetail(
                    "Address: ${_truncateText(product.deliveryAddress!, isMobile ? 40 : 60)}",
                    theme,
                    maxLines: 2,
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Price and status row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rs ${product.totalAmount}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: getStatusColor(
                        product.orderStatus,
                      ).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      product.orderStatus.name.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: getStatusColor(product.orderStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderDetail(String text, ThemeData theme, {int maxLines = 1}) {
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      overflow: TextOverflow.ellipsis,
      maxLines: maxLines,
    );
  }

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  String formatDateTime(DateTime dateTime) {
    final formatter = DateFormat('d MMM yyyy hh:mm a');
    return formatter.format(dateTime);
  }

  Color getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.inProgress:
        return Colors.blueAccent;
      case OrderStatus.pending:
        return Colors.orangeAccent;
      case OrderStatus.ready:
        return Colors.amber;
      case OrderStatus.cancelled:
        return Colors.redAccent;
      case OrderStatus.refunded:
        return Colors.purpleAccent;
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
