import 'package:flutter/material.dart';

class ModulePlaceholderSection extends StatelessWidget {
  const ModulePlaceholderSection({
    super.key,
    required this.title,
    required this.description,
    required this.items,
  });

  final String title;
  final String description;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text(description, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 14),
        ...items.map(
          (item) => Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle_outline_rounded),
              title: Text(item),
            ),
          ),
        ),
      ],
    );
  }
}
