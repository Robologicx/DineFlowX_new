import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_text_field.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/client_cart_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/direct_dining_state.dart';
import 'package:hotel_management_system/state_management/favourite_provider.dart';
import 'package:hotel_management_system/state_management/order_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/tenant_context_provider.dart';

class FoodItemDetailsScreen extends ConsumerStatefulWidget {
  final String? tableId;
  final ProductModel product;

  const FoodItemDetailsScreen({
    super.key,
    required this.product,
    this.tableId = '',
  });

  @override
  ConsumerState<FoodItemDetailsScreen> createState() =>
      _FoodItemDetailsScreenState();
}

class _FoodItemDetailsScreenState extends ConsumerState<FoodItemDetailsScreen> {
  final TextEditingController noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favourite = ref.watch(favouriteProvider);
    final orderRef = ref.read(orderNotifierProvider);
    final tenantContext = ref.watch(tenantContextProvider);
    final directDining = ref.watch(directDiningProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Device breakpoints
    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    // Max content width for tablet/desktop
    final double maxContentWidth = isDesktop
        ? 800
        : isTablet
        ? 600
        : double.infinity;

    // Dynamic paddings
    final double horizontalPadding = isMobile ? 16 : 24;
    final double verticalPadding = isMobile ? 16 : 24;

    return Scaffold(
      appBar: AppBar(
        actions: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: Center(
              child: IconButton(
                onPressed: () {
                  ref
                      .read(favouriteProvider.notifier)
                      .toggleFavourite(widget.product);
                },
                icon: Icon(
                  favourite.contains(widget.product)
                      ? Icons.favorite
                      : Icons.favorite_outline,
                  size: 30,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                InkWell(
                  onTap: () {
                    openFullScreenImage();
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      widget.product.imageUrl ?? '',
                      fit: BoxFit.cover,
                      height: isMobile
                          ? screenHeight * 0.35
                          : isTablet
                          ? screenHeight * 0.4
                          : screenHeight * 0.5,
                      width: double.infinity,
                    ),
                  ),
                ),

                _buildItemInfoTile(
                  context,
                  title: widget.product.name,
                  description: widget.product.description,
                  price: widget.product.price.toString(),
                ),

                CustomTextField(
                  maxLines: 3,
                  controller: noteController,
                  hint: 'Any specific note',
                ),
                SizedBox(height: isMobile ? 16 : 24),
                CustomButton(
                  text: 'Add to cart',
                  onTap: () {
                    ref
                        .read(cartProvider.notifier)
                        .addToCart(
                          OrderItem(
                            productId: widget.product.productId,
                            productName: widget.product.name,
                            quantity: 1,
                            price: widget.product.price,
                          ),
                        );
                    final businessId =
                        (directDining.businessId ?? '').trim().isNotEmpty
                        ? directDining.businessId!.trim()
                        : tenantContext.businessId.trim();
                    final branchId =
                        (directDining.branchId ?? '').trim().isNotEmpty
                        ? directDining.branchId!.trim()
                        : tenantContext.branchId.trim();
                    final tableId = (widget.tableId ?? '').trim();
                    final qp = <String, String>{
                      'businessId': businessId,
                      'branchId': branchId,
                    };
                    if (tableId.isNotEmpty) {
                      qp['tableId'] = tableId;
                    }
                    context.goNamed(
                      ClientAppRoutes.cartScreen,
                      queryParameters: qp,
                    );
                  },
                ),
                SizedBox(height: screenHeight * 0.03),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemInfoTile(
    BuildContext context, {
    required String title,
    required String description,
    required String price,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
          Text(
            description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.normal),
          ),
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.01),
          Text(
            "RS $price",
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void openFullScreenImage() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.network(
              'https://cdn.pixabay.com/photo/2022/06/02/12/19/choco-shake-7237884_1280.jpg',
              fit: BoxFit.cover,
            ),
          ),
        );
      },
    );
  }
}
