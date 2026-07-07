import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/core/utils/currency_formatter.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/presentation/client_screens/helper/image_helper.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/currency_provider.dart';
import 'package:hotel_management_system/state_management/favourite_provider.dart';

class FavouriteItemsScreen extends ConsumerStatefulWidget {
  const FavouriteItemsScreen({super.key});

  @override
  ConsumerState<FavouriteItemsScreen> createState() =>
      _FavouriteItemsScreenState();
}

class _FavouriteItemsScreenState extends ConsumerState<FavouriteItemsScreen> {
  @override
  Widget build(BuildContext context) {
    final currencyCode = ref.watch(tenantCurrencyCodeProvider);
    final product = ref.watch(favouriteProvider);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Favourites',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      body: Center(
        child: product.isNotEmpty
            ? ListView.builder(
                itemCount: product.length,
                itemBuilder: (BuildContext context, int index) {
                  final item = product[index];
                  return _buildFavouriteItemCard(
                    context,
                    product: item,
                    currencyCode: currencyCode,
                  );
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_outline, size: 100),
                  SizedBox(height: 15),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      'No favourites yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 15),
                    child: Text(
                      'Hit the orange bytton down\n   below to Create an Order',
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 200),
                  CustomButton(
                    text: 'Start Adding',
                    onTap: () {
                      context.goNamed(ClientAppRoutes.homeWidget);
                    },
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFavouriteItemCard(
    BuildContext context, {
    required ProductModel product,
    required String currencyCode,
  }) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.15,
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        clipBehavior: Clip.none,
        elevation: 5,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {},
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15),
                ),
                child: Image.network(
                  getDirectImageUrl(product.imageUrl ?? ''),
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height * 0.15,
                  width: MediaQuery.of(context).size.width * 0.3,
                ),
              ),
              SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Text('⭐️ ${product.reviewCount}'),
                    Text(
                      product.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Spacer(),
                    Row(
                      spacing: 70,
                      children: [
                        Text(
                          CurrencyFormatter.formatAmount(
                            product.price,
                            currencyCode: currencyCode,
                          ),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
