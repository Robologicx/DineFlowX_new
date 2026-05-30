import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:hotel_management_system/presentation/admin_screens/admin_shell.dart';
import 'package:hotel_management_system/presentation/admin_screens/home/widgets/admin_drawer_menu_screen.dart';
import 'package:hotel_management_system/presentation/common_widgets/app_drawer.dart';

class AdminShellWrapper extends StatelessWidget {
  final ZoomDrawerController zoomDrawerController = ZoomDrawerController();
  AdminShellWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDrawer(
      controller: zoomDrawerController,
      mainScreen: AdminShell(),
      menuScreen: AdminDrawerMenuScreen(),
    );
  }
}
