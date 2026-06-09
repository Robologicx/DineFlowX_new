import 'package:flutter/material.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/food_grid.dart';

class CategoryProducts extends StatelessWidget {
  final List<ProductModel> productModel;
  final String categoryName;
  final String? tableID;

  const CategoryProducts({
    super.key,
    this.tableID,
    required this.productModel,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxW = constraints.maxWidth;
        final bool isMobile = maxW < 600;
        final bool isTablet = maxW >= 600 && maxW < 1024;
        final bool isDesktop = maxW >= 1024;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              categoryName,
              style: Theme.of(
                context,
              ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            ///Mobile → List
            if (isMobile)
              Expanded(
                child: ListView.builder(
                  itemCount: productModel.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: FoodGrid(
                        product: productModel[index],
                        tableID: tableID,
                      ),
                    );
                  },
                ),
              ),

            ///Tablet → Grid (2-column)
            if (isTablet)
              Expanded(
                child: GridView.builder(
                  itemCount: productModel.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.5, // card ratio stays consistent
                  ),
                  itemBuilder: (context, index) {
                    return FoodGrid(
                      product: productModel[index],
                      tableID: tableID,
                    );
                  },
                ),
              ),

            ///Desktop → Grid (3-column)
            if (isDesktop)
              Expanded(
                child: GridView.builder(
                  itemCount: productModel.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 3.5,
                  ),
                  itemBuilder: (context, index) {
                    return FoodGrid(
                      product: productModel[index],
                      tableID: tableID,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}
