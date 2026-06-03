import 'package:flutter/material.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';

class PortalSelectorScreen extends StatelessWidget {
  const PortalSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF0F6FF), Color(0xFFE6EEF9), Color(0xFFF9FCFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Choose Portal',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'RoboLogicx Enterprise Restaurant and Hotel Management Platform',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final stacked = constraints.maxWidth < 760;
                      final businessCard = _portalCard(
                        context: context,
                        title: 'Business Portal',
                        subtitle:
                            'For business owners, branch managers, and staff to manage daily operations.',
                        icon: Icons.storefront_rounded,
                        accent: const Color(0xFF0F6CBD),
                        buttonLabel: 'Continue to Business Login',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AdminAppRoutes.login,
                            arguments: {'initialTab': 0},
                          );
                        },
                      );

                      final superAdminCard = _portalCard(
                        context: context,
                        title: 'Super Admin Portal',
                        subtitle:
                            'For RoboLogicx platform administrators to control tenants, billing, and analytics.',
                        icon: Icons.admin_panel_settings_rounded,
                        accent: const Color(0xFF7A2E8A),
                        buttonLabel: 'Continue to Super Admin Login',
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AdminAppRoutes.login,
                            arguments: {'initialTab': 2},
                          );
                        },
                      );

                      if (stacked) {
                        return Column(
                          children: [
                            businessCard,
                            const SizedBox(height: 16),
                            superAdminCard,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(child: businessCard),
                          const SizedBox(width: 16),
                          Expanded(child: superAdminCard),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _portalCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.arrow_forward_rounded),
              style: ElevatedButton.styleFrom(
                backgroundColor: accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              label: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
