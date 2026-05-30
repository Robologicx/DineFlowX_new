import 'package:flutter/material.dart';

class IconShadowWidget extends StatelessWidget {
  final IconData icon;
  const IconShadowWidget({super.key, required this.icon});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(icon, size: 25),
    );
  }
}
