import "package:flutter/material.dart";

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Order Details")),
    body: Center(child: Text("Order Detail")),
  );
}
