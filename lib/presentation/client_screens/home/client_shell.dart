import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_home_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_drawer_menu_screen.dart';
import 'package:hotel_management_system/presentation/common_widgets/app_drawer.dart';

class ClientHomeShell extends StatelessWidget {
  final ZoomDrawerController _drawerController = ZoomDrawerController();

  ClientHomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return AppDrawer(
      controller: _drawerController,
      mainScreen: ClientHomeScreen(drawerController: _drawerController),
      menuScreen: ClientDrawerMeuScreen(),
    );
    // return ZoomDrawer(
    //   controller: _drawerController,
    //   style: DrawerStyle.defaultStyle,
    //   menuScreen: DrawerMenuScreen(),
    //   mainScreen: ClientHomeScreen(drawerController: _drawerController),
    // );
  }
}
