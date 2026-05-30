// import 'package:flutter/material.dart';
// import 'package:hotel_management_system/data/models/product_model.dart';

// // class ProductListPage extends ConsumerWidget {
// //   const ProductListPage({super.key});

// //   @override
// //   Widget build(BuildContext context, WidgetRef ref) {
// //     final productsAsync = ref.watch(productListProvider);

// //     return Scaffold(
// //       appBar: AppBar(title: const Text("Products")),
// //       body: productsAsync.when(
// //         data: (products) => ListView.builder(
// //           itemCount: products.length,
// //           itemBuilder: (context, index) {
// //             final product = products[index];
// //             return ProductTile(product: product);
// //           },
// //         ),
// //         loading: () => const Center(child: CircularProgressIndicator()),
// //         error: (err, stack) => Center(child: Text("Error: $err")),
// //       ),
// //     );
// //   }
// // }

// class ProductListPage extends ConsumerStatefulWidget {
//   const ProductListPage({super.key});

//   @override
//   ConsumerState<ProductListPage> createState() => _ProductListPageState();
// }

// class _ProductListPageState extends ConsumerState<ProductListPage> {
//   String searchQuery = "";
//   String? selectedCategory;

//   @override
//   Widget build(BuildContext context) {
//     // Base product list (from provider)
//     final productsAsync = searchQuery.isEmpty && selectedCategory == null
//         ? ref.watch(productListProvider)
//         : selectedCategory != null
//             ? ref.watch(productsByCategoryProvider(selectedCategory!))
//             : ref.watch(filteredProductsProvider(searchQuery));

//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Products"),
//       ),
//       body: Column(
//         children: [
//           // 🔍 Search Bar
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               decoration: const InputDecoration(
//                 prefixIcon: Icon(Icons.search),
//                 hintText: "Search products...",
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 setState(() {
//                   searchQuery = value;
//                   selectedCategory = null; // reset category filter on search
//                 });
//               },
//             ),
//           ),

//           // ⏬ Category Dropdown
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: DropdownButtonFormField<String>(
//               decoration: const InputDecoration(
//                 labelText: "Filter by Category",
//                 border: OutlineInputBorder(),
//               ),
//               value: selectedCategory,
//               items: const [
//                 DropdownMenuItem(value: "cat1", child: Text("Category 1")),
//                 DropdownMenuItem(value: "cat2", child: Text("Category 2")),
//                 DropdownMenuItem(value: "cat3", child: Text("Category 3")),
//               ],
//               onChanged: (value) {
//                 setState(() {
//                   selectedCategory = value;
//                   searchQuery = ""; // reset search when category is picked
//                 });
//               },
//             ),
//           ),

//           // 📦 Product List
//           Expanded(
//             child: productsAsync.when(
//               data: (products) {
//                 if (products.isEmpty) {
//                   return const Center(child: Text("No products found"));
//                 }
//                 return ListView.builder(
//                   itemCount: products.length,
//                   itemBuilder: (context, index) {
//                     final product = products[index];
//                     return ProductTile(product: product);
//                   },
//                 );
//               },
//               loading: () => const Center(child: CircularProgressIndicator()),
//               error: (err, stack) => Center(child: Text("Error: $err")),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class ProductTile extends StatelessWidget {
//   final ProductModel product;

//   const ProductTile({super.key, required this.product});

//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       child: ListTile(
//         leading: const Icon(Icons.fastfood),
//         title: Text(product.name),
//         subtitle: Text("Price: \$${product.price}"),
//         trailing: Icon(
//           product.isAvailable ? Icons.check_circle : Icons.cancel,
//           color: product.isAvailable ? Colors.green : Colors.red,
//         ),
//         onTap: () {
//           // navigate to detail page later
//         },
//       ),
//     );
//   }
// }
