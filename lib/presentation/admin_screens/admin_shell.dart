import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:hotel_management_system/presentation/admin_screens/dashboard_screen.dart';
import 'package:hotel_management_system/state_management/theme_provider.dart';

class AdminShell extends ConsumerStatefulWidget {
  // ✅ add controller
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final themeController = ref.watch(themeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Dashboard"),
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            ZoomDrawer.of(context)?.toggle();
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeController.themeMode == ThemeMode.dark
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
            onPressed: () {
              final newMode = themeController.themeMode == ThemeMode.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(themeProvider.notifier).updateMode(newMode);
            },
          ),
          IconButton(
            onPressed: () {
              pickColorforTheme();
            },
            icon: Icon(Icons.color_lens),
          ),
        ],
      ),

      body: DashboardScreen(),
    );
  }

  void pickColorforTheme() {
    final themeController = ref.watch(themeProvider);
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = themeController.primaryColor;
        return AlertDialog(
          title: const Text("Pick a color"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: themeController.primaryColor,
              onColorChanged: (color) {
                tempColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(themeProvider.notifier).updateColor(tempColor);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
