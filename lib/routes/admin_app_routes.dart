import 'package:flutter/material.dart';
import 'package:hotel_management_system/presentation/admin_screens/Table_management_screen/qr_code_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/Table_management_screen/table_management_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/admin_shell_wrapper.dart';
import 'package:hotel_management_system/presentation/admin_screens/auth/admin_login_screen.dart';
import 'package:hotel_management_system/presentation/admin_screens/buisness_management_screen/business_management_screen_claude.dart';
import 'package:hotel_management_system/presentation/admin_screens/dashboard_screen.dart';
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
import 'package:hotel_management_system/presentation/client_screens/onboarding/spash_screen_adminside.dart';

class AdminAppRoutes {
  static const String splash = '/splash-screen';
  static const String home = '/home';
  static const String login = '/login';
  static const String register = '/register';
  static const String userProfile = '/user-profile';
  static const String printer = '/printer';

  // Dashboard Screen
  static const String dashboard = '/dashboard';

  /// Management Screens
  static const String businessManagement = '/business-management';
  static const String reportsManagement = '/reports-management';
  static const String expenseManagement = '/expense-management';
  static const String roomsManagement = '/rooms-management';
  static const String tablesManagement = '/tables-management';
  static const String qrCodeManagement = '/qr-code-management';

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
    splash: (context) => SplashScreen(),
    home: (context) => AdminShellWrapper(),
    login: (context) => const AdminLoginScreen(),
    userProfile: (context) => const UserProfileScreen(),
    dashboard: (context) => const DashboardScreen(),
    staffManagement: (context) => const StaffManagementScreen(),
    businessManagement: (context) => const BusinessManagementScreen(),
    reportsManagement: (context) => const SalesDashboardScreen(),
    expenseManagement: (context) => const ExpenseManagementScreen(),
    roomsManagement: (context) => const RoomsManagementScreen(),
    tablesManagement: (context) => const TablesManagementScreen(),
    qrCodeManagement: (context) => QRCodeGenerationScreen(),
    printer: (context) => PrinterScreen(),
    menuManagement: (context) => const MenuManagementScreen(),
    categoryManagement: (context) => const CategoryManagementScreen(),
    productManagement: (context) => ProductManagementScreen(),
    ordersManagement: (context) => const OrderManagementScreen(),

    // I want to use provider to manage hotel id and service
    permissionsManagement: (context) => const PermissionsScreen(),
    rolesManagement: (context) => const RolesScreen(),
  };
}
