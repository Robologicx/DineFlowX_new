import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:hotel_management_system/presentation/admin_screens/dashboard_screen.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
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
    final businessAccessAsync = ref.watch(tenantBusinessAccessProvider);

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

      body: businessAccessAsync.when(
        skipLoadingOnReload: true,
        skipLoadingOnRefresh: true,
        data: (access) {
          if (access.isBlocked) {
            return _buildBusinessDisabledScreen(access.reason);
          }
          return const DashboardScreen(showNavigationBar: false);
        },
        loading: () => const DashboardScreen(showNavigationBar: false),
        error: (_, __) => const DashboardScreen(showNavigationBar: false),
      ),
    );
  }

  Widget _buildBusinessDisabledScreen(String reason) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Card(
          margin: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.block_rounded,
                  color: Theme.of(context).colorScheme.error,
                  size: 56,
                ),
                const SizedBox(height: 12),
                Text(
                  'Business Disabled',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 10),
                Text(
                  reason,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'Please contact DineFlowX team to reactivate your business.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ),
      ),
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
