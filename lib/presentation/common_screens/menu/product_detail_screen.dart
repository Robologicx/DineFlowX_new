import "package:flutter/material.dart";

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Product Detail")),
    body: Center(child: Text("Product Detail Screen")),
  );
}
