import 'package:flutter/material.dart';
import 'package:hotel_management_system/core/widgets/icon_shadow_widget.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_shell.dart';
import 'package:hotel_management_system/presentation/client_screens/menu_screens/favourite_items_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/menu_screens/my_profile_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/menu_screens/order_history_screen.dart';

class HomeWidget extends StatefulWidget {
  const HomeWidget({super.key});

  @override
  State<HomeWidget> createState() => _HomeWidgetState();
}

class _HomeWidgetState extends State<HomeWidget> {
  int index = 0;
  final List<Widget> _screens = [
    ClientHomeShell(),
    FavouriteItemsScreen(),
    MyProfileScreen(),
    OrderHistoryScreen(),
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        currentIndex: index,
        onTap: (value) {
          setState(() {
            index = value;
          });
        },
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 5,
        items: [
          BottomNavigationBarItem(
            icon: _buildIcon(
              currentindex: 0,
              icon: index == 0 ? Icons.home : Icons.home_outlined,
            ),
            label: 'home',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(
              currentindex: 1,
              icon: index == 1 ? Icons.favorite : Icons.favorite_outline,
            ),
            label: 'Favourites',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(
              currentindex: 2,
              icon: index == 2 ? Icons.person : Icons.person_outline,
            ),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: _buildIcon(
              currentindex: 3,
              icon: index == 3 ? Icons.history : Icons.history_outlined,
            ),
            label: 'Delivery',
          ),
        ],
      ),
    );
  }

  Widget _buildIcon({required int currentindex, required IconData icon}) {
    final isSelected = currentindex == index;

    if (isSelected) {
      return IconShadowWidget(icon: icon);
    } else {
      return Icon(icon);
    }
  }
}
