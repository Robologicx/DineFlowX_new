import 'package:flutter/material.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/category_products_widget.dart';

class ProductSearchDelegate extends SearchDelegate<ProductModel?> {
  final List<ProductModel> allProducts;

  ProductSearchDelegate(this.allProducts);

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(icon: Icon(Icons.clear), onPressed: () => query = ''),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    final results = allProducts.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase()) ||
          product.description.toLowerCase().contains(query.toLowerCase());
    }).toList();

    if (results.isEmpty) {
      return Center(child: Text("No products found"));
    }

    return _buildProductGrid(results);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = query.isEmpty
        ? allProducts // show all products initially
        : allProducts.where((product) {
            return product.name.toLowerCase().contains(query.toLowerCase()) ||
                product.description.toLowerCase().contains(query.toLowerCase());
          }).toList();

    return _buildProductGrid(suggestions);
  }

  Widget _buildProductGrid(List<ProductModel> products) {
    return CategoryProducts(productModel: products, categoryName: '');
  }
}
