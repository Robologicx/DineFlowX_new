import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/current_tenant_business_provider.dart';

class ClientDrawerMeuScreen extends ConsumerWidget {
  const ClientDrawerMeuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final businessAsync = ref.watch(currentTenantBusinessProvider);
    final businessName = businessAsync.maybeWhen(
      data: (business) {
        final title = business?.title.trim() ?? '';
        return title.isEmpty ? 'Business' : title;
      },
      orElse: () => 'Business',
    );
    final logoUrl = businessAsync.maybeWhen(
      data: (business) => business?.logoUrl,
      orElse: () => null,
    );

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Column(
              children: [
                const SizedBox(height: 24),
                CircleAvatar(
                  radius: 36,
                  backgroundImage: (logoUrl != null && logoUrl.isNotEmpty)
                      ? NetworkImage(logoUrl)
                      : null,
                  child: (logoUrl == null || logoUrl.isEmpty)
                      ? const Icon(Icons.storefront_rounded, size: 30)
                      : null,
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    businessName,
                    style: Theme.of(context).textTheme.titleLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 26),
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
            Text(
              'Powered by RoboLogicX',
              style: Theme.of(context).textTheme.bodySmall,
            ),

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
