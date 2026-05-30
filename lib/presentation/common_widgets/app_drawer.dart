import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';

class AppDrawer extends StatelessWidget {
  final ZoomDrawerController controller;
  final Widget menuScreen;
  final Widget mainScreen;

  const AppDrawer({
    super.key,
    required this.controller,
    required this.mainScreen,
    required this.menuScreen,
  });

  @override
  Widget build(BuildContext context) {
    // Get screen size and orientation
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 800; // Desktop detection
    final isTablet =
        screenSize.width >= 600 && screenSize.width < 800; // Tablet detection
    final isMobile = screenSize.width < 600; // Mobile detection
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    // Drawer width based on device type and orientation
    double slideWidth = 0.0;
    if (isMobile) {
      slideWidth = isLandscape
          ? screenSize.width * 0.50
          : screenSize.width * 0.75; // 75% for mobile
    } else if (isTablet) {
      slideWidth = screenSize.width * 0.30; // 30% for tablet
    } else if (isDesktop) {
      slideWidth = screenSize.width * 0.25; // 25% for desktop
    }

    // Adjust main screen scale and duration for different screen types
    double mainScreenScale = isMobile
        ? 0.15
        : 0.10; // More zoom effect for mobile
    Duration duration = const Duration(
      milliseconds: 200,
    ); // Smooth animation for all devices

    return ZoomDrawer(
      controller: controller,
      style: DrawerStyle.defaultStyle,
      menuScreen: menuScreen,
      mainScreen: mainScreen,
      borderRadius: 30.0, // Rounded corners
      showShadow: true,
      menuBackgroundColor: Theme.of(context).colorScheme.primaryContainer,
      angle: isDesktop || isTablet
          ? 0.0
          : 0.1, // Slight tilt for mobile and tablet
      slideWidth: slideWidth, // Responsive drawer width
      mainScreenScale: mainScreenScale, // Responsive zoom effect
      duration: duration, // Smooth animation
    );
  }
}
