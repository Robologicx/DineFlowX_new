import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/core/utils/currency_formatter.dart';
import 'package:hotel_management_system/core/widgets/icon_shadow_widget.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/presentation/client_screens/categories/food_item_details_screen.dart';
import 'package:hotel_management_system/state_management/client_cart_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/currency_provider.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class FoodGrid extends ConsumerWidget {
  final ProductModel product;
  final String? tableID;
  const FoodGrid({super.key, required this.product, this.tableID});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(tenantCurrencyCodeProvider);
    log('ImageURL:${product.imageUrl}');
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive scale factor
        final double width = constraints.maxWidth;
        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1024;

        final double scale = isMobile
            ? 1.0
            : isTablet
            ? 1.2
            : 1.4; // auto resize factor

        return Shimmer(
          child: Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            elevation: 4,
            child: InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () {
                Navigator.of(context).push(
                  ScalePageRoute(
                    page: FoodItemDetailsScreen(
                      tableId: tableID,
                      product: product,
                    ),
                  ),
                );
              },
              child: Row(
                children: [
                  ///Image section (square, scales correctly)
                  Flexible(
                    flex: 4,
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        bottomLeft: Radius.circular(15),
                      ),
                      child: AspectRatio(
                        aspectRatio: 1, // keeps image square
                        child: product.imageUrl == null
                            ? const Icon(Icons.image)
                            : CachedNetworkImage(
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                fit: BoxFit.cover,
                                imageUrl: product.imageUrl!,
                                placeholder: (context, url) =>
                                    const Icon(Icons.image),
                              ),
                      ),
                    ),
                  ),

                  ///Content section
                  Flexible(
                    flex: 5,
                    child: Padding(
                      padding: EdgeInsets.all(8.0 * scale * 0.6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: Theme.of(context).textTheme.bodyLarge!
                                .copyWith(
                                  fontSize: 14 * scale,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          SizedBox(height: 4 * scale),
                          Text(
                            product.description,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: Theme.of(context).textTheme.bodySmall!
                                .copyWith(fontSize: 12 * scale),
                          ),
                          SizedBox(height: 4 * scale),

                          ///Price + Add-to-cart icon
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                CurrencyFormatter.formatAmount(
                                  product.price,
                                  currencyCode: currencyCode,
                                ),
                                style: Theme.of(context).textTheme.bodyLarge!
                                    .copyWith(
                                      fontSize: 14 * scale,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  // Add to cart first
                                  ref
                                      .read(cartProvider.notifier)
                                      .addToCart(
                                        OrderItem(
                                          productId: product.productId,
                                          productName: product.name,
                                          quantity: 1,
                                          price: product.price,
                                        ),
                                      );
                                  // Then show animation
                                  showCartAnimation(context);
                                },
                                child: const IconShadowWidget(
                                  icon: Icons.shopping_bag,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

void showCartAnimation(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black54,
    barrierDismissible: false,
    builder: (context) => const CartAnimationDialog(),
  );
}

class CartAnimationDialog extends StatefulWidget {
  const CartAnimationDialog({super.key});

  @override
  State<CartAnimationDialog> createState() => _CartAnimationDialogState();
}

class _CartAnimationDialogState extends State<CartAnimationDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeIn),
      ),
    );

    // Start animation
    _controller.forward().then((_) {
      // Close dialog when animation completes
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(context, rootNavigator: true).pop();
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(40),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated check icon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_cart_checkout,
                    size: 40,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Added to Cart!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Item successfully added to your cart',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  ScalePageRoute({required this.page})
    : super(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
            child: child,
          );
        },
      );
}
