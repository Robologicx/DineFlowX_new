import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';

class ClientDrawerMeuScreen extends StatelessWidget {
  const ClientDrawerMeuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Column(
              children: [
                const SizedBox(height: 200),
                _buildMenuItem(
                  context,
                  title: 'Profile',
                  icon: Icons.person_2_rounded,
                  ontap: () {
                    context.goNamed(ClientAppRoutes.myProfile);
                  },
                ),
                _divider(),
                _buildMenuItem(
                  context,
                  ontap: () {
                    context.goNamed(ClientAppRoutes.allFoodItems);
                  },
                  title: 'All products',
                  icon: Icons.shopping_bag,
                ),
                _divider(),
                _buildMenuItem(
                  context,
                  ontap: () {
                    context.goNamed(ClientAppRoutes.orderHistory);
                  },
                  title: 'Order History',
                  icon: Icons.history,
                ),
              ],
            ),
            Spacer(),
            Text('Powered By'),
            Text('ROBOLOGICX'),

            // _buildMenuItem(
            //   context,
            //   ontap: () {
            //     context.goNamed(ClientAppRoutes.login);
            //   },
            //   title: 'Sign out',
            //   icon: Icons.exit_to_app_outlined,
            // ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.only(left: 30, right: 10),
      child: Divider(),
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required String title,
    required IconData icon,
    required VoidCallback ontap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 30),
      title: Text(title, style: Theme.of(context).textTheme.titleLarge),
      onTap: ontap,
    );
  }
}
