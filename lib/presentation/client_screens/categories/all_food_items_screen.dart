import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/category_products_widget.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/product_state_and_notifier.dart';

class AllFoodItemsScreen extends ConsumerWidget {
  final String? tableId;
  AllFoodItemsScreen({super.key, this.tableId = ''});

  final Random random = Random();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productRef = ref.read(productRepositoryProvider);
    print("table id is $tableId");
    return Scaffold(
      appBar: AppBar(
        title: Text('All Products'),
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            context.goNamed(ClientAppRoutes.shell);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FutureBuilder(
          future: productRef.getAllProducts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Some error occured'));
            }
            if (snapshot.data == null) {
              return Center(child: Text('No data found'));
            }
            return CategoryProducts(
              productModel: snapshot.data!,
              categoryName: '',
            );
          },
        ),
      ),
    );
  }
}
