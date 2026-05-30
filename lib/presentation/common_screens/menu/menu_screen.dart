import "package:flutter/material.dart";

class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text("Menu")),
    body: Center(child: Text("Menu Screen")),
  );
}
