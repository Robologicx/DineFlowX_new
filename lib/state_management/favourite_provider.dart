import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/product_model.dart';

class FavouriteProvider extends StateNotifier<List<ProductModel>> {
  FavouriteProvider() : super([]);

  void toggleFavourite(ProductModel product) {
    if (state.contains(product)) {
      state = state.where((p) => p != product).toList();
    } else {
      state = [...state, product];
    }
  }
}

final favouriteProvider =
    StateNotifierProvider<FavouriteProvider, List<ProductModel>>(
      (ref) => FavouriteProvider(),
    );
