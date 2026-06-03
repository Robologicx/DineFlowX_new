import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/current_tenant_business_provider.dart';

class AdminDrawerMenuScreen extends ConsumerStatefulWidget {
  const AdminDrawerMenuScreen({super.key});

  @override
  ConsumerState<AdminDrawerMenuScreen> createState() =>
      _AdminDrawerMenuScreenState();
}

class _AdminDrawerMenuScreenState extends ConsumerState<AdminDrawerMenuScreen> {
  bool _businessExpanded = false;
  bool _staffExpanded = false;
  bool _ordersExpanded = false;
  bool _menuExpanded = false;
  bool _profileExpanded = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);
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
    final normalizedLogoUrl = logoUrl?.trim();

    if (user.isLoading) {
      return Center(child: CircularProgressIndicator());
    } else if (user.error != null) {
      return Center(child: Text('Error loading user data'));
    } else if (user.selectedUser == null) {
      return Center(child: Text('No user data available'));
    } else {
      return Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // --- Branding / Logo Area ---
              SizedBox(
                height: 120,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  spacing: 10,
                  children: [
                    CircleAvatar(
                      radius: 24,
                      foregroundImage:
                          (normalizedLogoUrl != null &&
                              normalizedLogoUrl.isNotEmpty)
                          ? NetworkImage(normalizedLogoUrl)
                          : null,
                      onForegroundImageError:
                          (normalizedLogoUrl != null &&
                              normalizedLogoUrl.isNotEmpty)
                          ? (_, __) {}
                          : null,
                      child:
                          (normalizedLogoUrl == null ||
                              normalizedLogoUrl.isEmpty)
                          ? const Icon(Icons.business_center)
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        businessName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // --- Main Drawer List ---
              Expanded(
                child: ListView(
                  children: [
                    _buildGeneralItem(
                      title: "Dashboard",
                      icon: Icons.dashboard,
                      ontap: () {
                        Navigator.pushNamed(context, AdminAppRoutes.dashboard);
                      },
                    ),

                    // --- Collapsible Sections ---
                    userNotifier.hasPermissionOfCurrentUser(
                          Permissions.viewBusiness,
                        )
                        ? _buildExpandableSection(
                            title: "Business Management",
                            icon: Icons.business,
                            expanded: _businessExpanded,
                            onExpand: () => setState(
                              () => _businessExpanded = !_businessExpanded,
                            ),
                            children: [
                              _buildSubItem(Icons.apartment, "Branches", () {
                                Navigator.pushNamed(
                                  context,
                                  AdminAppRoutes.businessManagement,
                                );
                              }),
                              _buildSubItem(Icons.room, "Rooms", () {
                                Navigator.pushNamed(
                                  context,
                                  AdminAppRoutes.roomsManagement,
                                );
                              }),
                              _buildSubItem(Icons.table_view, "Tables", () {
                                Navigator.pushNamed(
                                  context,
                                  AdminAppRoutes.tablesManagement,
                                );
                              }),
                              _buildSubItem(
                                Icons.qr_code,
                                "QR Code Management",
                                () {
                                  Navigator.pushNamed(
                                    context,
                                    AdminAppRoutes.qrCodeManagement,
                                  );
                                },
                              ),
                              _buildSubItem(Icons.report, "Reports", () {
                                Navigator.pushNamed(
                                  context,
                                  AdminAppRoutes.reportsManagement,
                                );
                              }),
                              _buildSubItem(Icons.money, "Expenses", () {
                                Navigator.pushNamed(
                                  context,
                                  AdminAppRoutes.expenseManagement,
                                );
                              }),
                              _buildSubItem(Icons.print, "Printers", () {
                                Navigator.pushNamed(
                                  context,
                                  AdminAppRoutes.printer,
                                );
                              }),
                              // _buildSubItem(Icons.account_balance, "Finance", () {}),
                              // _buildSubItem(Icons.analytics, "Analytics", () {}),
                            ],
                          )
                        : SizedBox.shrink(),

                    // if (userNotifier.hasPermissionoFCurrentUser(
                    //   Permissions.viewStaff,
                    // ))
                    if (true)
                      _buildExpandableSection(
                        title: "Staff Management",
                        icon: Icons.people,
                        expanded: _staffExpanded,
                        onExpand: () =>
                            setState(() => _staffExpanded = !_staffExpanded),
                        children: [
                          _buildSubItem(Icons.person, "Employees", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.staffManagement,
                            );
                          }),
                          _buildSubItem(Icons.security, "Permissions", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.permissionsManagement,
                            );
                          }),
                          _buildSubItem(Icons.security, "Roles", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.rolesManagement,
                            );
                          }),
                          // _buildSubItem(Icons.access_time, "Attendance", () {}),
                        ],
                      ),

                    if (userNotifier.hasPermissionOfCurrentUser(
                          Permissions.viewOrderHistory,
                        ) ||
                        userNotifier.hasPermissionOfCurrentUser(
                          Permissions.viewActiveOrders,
                        ))
                      _buildExpandableSection(
                        title: "Orders Management",
                        icon: Icons.delivery_dining,
                        expanded: _ordersExpanded,
                        onExpand: () =>
                            setState(() => _ordersExpanded = !_ordersExpanded),
                        children: [
                          _buildSubItem(Icons.list, "Create New Orders", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.ordersManagement,
                            );
                          }),
                          _buildSubItem(Icons.done, "Completed Orders", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.ordersManagement,
                            );
                          }),
                          _buildSubItem(
                            Icons.notifications_active,
                            "Active Orders",
                            () {
                              Navigator.pushNamed(
                                context,
                                AdminAppRoutes.ordersManagement,
                              );
                            },
                          ),
                          _buildSubItem(Icons.cancel, "Refunds", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.ordersManagement,
                            );
                          }),
                        ],
                      ),
                    if (userNotifier.hasPermissionOfCurrentUser(
                      Permissions.viewMenu,
                    ))
                      _buildExpandableSection(
                        title: "Menu Management",
                        icon: Icons.menu_book,
                        expanded: _menuExpanded,
                        onExpand: () =>
                            setState(() => _menuExpanded = !_menuExpanded),
                        children: [
                          _buildSubItem(Icons.menu, "Menus", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.menuManagement,
                            );
                          }),
                          _buildSubItem(Icons.category, "Categories", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.categoryManagement,
                            );
                          }),
                          _buildSubItem(Icons.fastfood, "Products", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.productManagement,
                            );
                          }),
                          // _buildSubItem(Icons.price_change, "Pricing", () {
                          //   // Navigator.pushNamed(
                          //   //   context,
                          //   //   AdminAppRoutes.menuManagement,
                          //   // );
                          // }),
                        ],
                      ),

                    // if (userNotifier.hasPermissionOfCurrentUser(
                    //   Permissions.viewOwnProfile,
                    // )
                    if (true)
                      _buildExpandableSection(
                        title: "Profile Management",
                        icon: Icons.person,
                        expanded: _profileExpanded,
                        onExpand: () => setState(
                          () => _profileExpanded = !_profileExpanded,
                        ),
                        children: [
                          _buildSubItem(Icons.menu, "Current Profile", () {
                            Navigator.pushNamed(
                              context,
                              AdminAppRoutes.userProfile,
                            );
                          }),
                          _buildSubItem(Icons.category, "Any other", () {
                            // Navigator.pushNamed(
                            //   context,
                            //   AdminAppRoutes.categoryManagement,
                            // );
                          }),
                        ],
                      ),
                    Divider(),
                  ],
                ),
              ),

              // --- Sign Out Button ---
              ListTile(
                leading: Icon(Icons.logout, color: Colors.red),
                title: Text("Sign Out", style: TextStyle(color: Colors.red)),
                onTap: () {
                  ref.read(authNotifierProvider.notifier).signOut();
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AdminAppRoutes.login,
                    (route) => false,
                  );
                },
              ),

              Text(
                'Powered by RoboLogicX',
                style: Theme.of(context).textTheme.bodySmall,
              ),

              // onTap: () {
              //   Navigator.pushNamedAndRemoveUntil(
              //     context,
              //     AdminAppRoutes.login,
              //     (route) => false,
              //   );
              // },
            ],
          ),
        ),
      );
    }
  }

  Widget _buildGeneralItem({
    required String title,
    required IconData icon,
    required VoidCallback ontap,
  }) {
    return ListTile(
      leading: Icon(icon, size: 26),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      onTap: ontap,
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool expanded,
    required VoidCallback onExpand,
    required List<Widget> children,
  }) {
    return ExpansionTile(
      leading: Icon(icon, size: 26),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: Icon(expanded ? Icons.arrow_drop_up : Icons.arrow_drop_down),
      onExpansionChanged: (value) => onExpand(),
      initiallyExpanded: expanded,
      children: children,
    );
  }

  Widget _buildSubItem(IconData icon, String title, VoidCallback ontap) {
    return ListTile(
      leading: Icon(icon, size: 20),
      contentPadding: EdgeInsets.only(left: 25),
      title: Text(title),
      onTap: ontap,
    );
  }
}
