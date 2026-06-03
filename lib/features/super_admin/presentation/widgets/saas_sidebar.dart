import 'package:flutter/material.dart';
import 'package:hotel_management_system/features/super_admin/presentation/models/super_admin_nav_item.dart';

class SaasSidebar extends StatelessWidget {
  const SaasSidebar({
    super.key,
    required this.currentSection,
    required this.onSelect,
    required this.onLogout,
    this.collapsed = false,
  });

  final SuperAdminSection currentSection;
  final ValueChanged<SuperAdminSection> onSelect;
  final VoidCallback onLogout;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: collapsed ? 88 : 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0A2238), Color(0xFF0F3957)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          right: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFFE7F3FF),
                child: Text(
                  'RLX',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0A2238),
                  ),
                ),
              ),
              title: collapsed
                  ? null
                  : const Text(
                      'RoboLogicx',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
              subtitle: collapsed
                  ? null
                  : const Text(
                      'Enterprise SaaS',
                      style: TextStyle(color: Color(0xFFBDD9F3)),
                    ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: superAdminNavItems.length,
                itemBuilder: (context, index) {
                  final item = superAdminNavItems[index];
                  final selected = item.section == currentSection;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    child: Material(
                      color: selected
                          ? const Color(0xFF1A5D8F)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onSelect(item.section),
                        child: SizedBox(
                          height: 46,
                          child: Row(
                            children: [
                              const SizedBox(width: 14),
                              Icon(item.icon, color: Colors.white, size: 20),
                              if (!collapsed) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Color(0x4DFFFFFF), height: 1),
            Padding(
              padding: const EdgeInsets.all(10),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(42),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.35)),
                  foregroundColor: Colors.white,
                ),
                onPressed: onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: Text(collapsed ? '' : 'Logout'),
              ),
            ),
            Text(
              'v1.0.0',
              style: theme.textTheme.bodySmall?.copyWith(
                color: const Color(0xFFBDD9F3),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
