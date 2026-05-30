import "package:flutter/material.dart";

class OrdersListScreen extends StatelessWidget {
  const OrdersListScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Orders")),
    body: Center(child: Text("Orders List")),
  );
}
