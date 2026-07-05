import 'package:flutter/material.dart';
import 'package:hotel_management_system/presentation/admin_screens/Table_management_screen/qr_code_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/Table_management_screen/table_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/admin_shell_wrapper.dart';
import 'package:hotel_management_system/presentation/admin_screens/auth/admin_login_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/buisness_management_screen/business_management_screen_claude.dart';
import 'package:hotel_management_system/presentation/admin_screens/expense_management_screen/expense_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/home/widgets/user_profile_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/menu_management_screen/category_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/menu_management_screen/menu_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/menu_management_screen/product_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/orders_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/printer/add_new_printer_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/rooms_management_screen/rooms_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/sales_dashboard/sales_dashboard_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/staff_management_screen/role_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/staff_management_screen/permissions_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/staff_management_screen/staff_management_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/cart/add_to_cart.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_shell.dart';
import 'package:hotel_management_system/presentation/client_screens/onboarding/spash_screen_adminside.dart';
import 'package:hotel_management_system/features/super_admin/presentation/super_admin_dashboard_screen.dart';
import 'package:hotel_management_system/presentation/auth/portal_selector_screen.dart';

class AdminAppRoutes {
  static const String splash = '/splash-screen';
  static const String portalSelector = '/portal-selector';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String userProfile = '/user-profile';
  static const String printer = '/printer';
  static const String superAdmin = '/super-admin';

  // Dashboard Screen
  static const String dashboard = '/dashboard';

  /// Management Screens
  static const String businessManagement = '/business-management';
  static const String reportsManagement = '/reports-management';
  static const String expenseManagement = '/expense-management';
  static const String roomsManagement = '/rooms-management';
  static const String tablesManagement = '/tables-management';
  static const String qrCodeManagement = '/qr-code-management';
  static const String clientShell = '/clientShell';
  static const String clientCart = '/addToCartScreen';

  // Staff Management Screens
  static const String staffManagement = '/staff-management';
  static const String permissionsManagement = '/permissions-management';
  static const String rolesManagement = '/roles-management';

  // Orders Management Screens
  static const String ordersManagement = '/orders-management';

  // Menu Management Screens
  static const String menuManagement = '/menu-management';
  static const String categoryManagement = '/category-management';
  static const String productManagement = '/product-management';

  static Map<String, WidgetBuilder> routes = {
    splash: (context) => const SplashScreen(),
    portalSelector: (context) => const PortalSelectorScreen(),
    home: (context) => AdminShellWrapper(),
    login: (context) => const AdminLoginScreen(),
    userProfile: (context) => const UserProfileScreen(),
    // Keep /dashboard as alias of /home so there is only one dashboard shell.
    dashboard: (context) => AdminShellWrapper(),
    staffManagement: (context) => const StaffManagementScreen(),
    businessManagement: (context) => const BusinessManagementScreen(),
    reportsManagement: (context) => const SalesDashboardScreen(),
    expenseManagement: (context) => const ExpenseManagementScreen(),
    roomsManagement: (context) => const RoomsManagementScreen(),
    tablesManagement: (context) => const TablesManagementScreen(),
    qrCodeManagement: (context) => QRCodeGenerationScreen(),
    clientShell: (context) {
      final query = Uri.base.queryParameters;
      return ClientHomeShell(
        tableId: query['tableId'],
        businessId: query['businessId'],
        branchId: query['branchId'],
      );
    },
    clientCart: (context) {
      final query = Uri.base.queryParameters;
      return AddToCartScreen(
        businessId: query['businessId'] ?? '',
        branchId: query['branchId'] ?? '',
        tableId: query['tableId'],
      );
    },
    printer: (context) => PrinterScreen(),
    menuManagement: (context) => const MenuManagementScreen(),
    categoryManagement: (context) => const CategoryManagementScreen(),
    productManagement: (context) => ProductManagementScreen(),
    ordersManagement: (context) => const OrderManagementScreen(),
    superAdmin: (context) => const SuperAdminDashboardScreen(),

    // I want to use provider to manage hotel id and service
    permissionsManagement: (context) => const PermissionsScreen(),
    rolesManagement: (context) => const RolesScreen(),
  };
}
