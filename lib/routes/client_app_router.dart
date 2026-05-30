import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/presentation/client_screens/auth/client_login_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/cart/add_to_cart.dart';
import 'package:hotel_management_system/presentation/client_screens/cart/check_out_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/categories/all_food_items_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_shell.dart';
import 'package:hotel_management_system/presentation/client_screens/menu_screens/my_profile_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/menu_screens/order_history_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/onboarding/on_boarding_screen.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';

/// Centralized GoRouter configuration for the Client App
class ClientAppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/${ClientAppRoutes.onBoarding}',
    routes: [
      /// ✅ Onboarding
      GoRoute(
        path: '/${ClientAppRoutes.onBoarding}',
        name: ClientAppRoutes.onBoarding,
        builder: (context, state) => OnBoardingScreen(),
      ),
      GoRoute(
        path: '/${ClientAppRoutes.checkOut}',
        name: ClientAppRoutes.checkOut,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          final items = (extra['items'] as List<OrderItem>?) ?? [];
          final totalAmount = extra['totalAmount'] as double? ?? 0.0;

          return CheckOutScreen(items: items, totalAmount: totalAmount);
        },
      ),
      GoRoute(
        path: '/${ClientAppRoutes.orderHistory}',
        name: ClientAppRoutes.orderHistory,
        builder: (context, state) => OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/${ClientAppRoutes.shell}',
        name: ClientAppRoutes.shell,
        builder: (context, state) => ClientHomeShell(),
      ),

      /// ✅ Login
      GoRoute(
        path: '/${ClientAppRoutes.login}',
        name: ClientAppRoutes.login,
        builder: (context, state) => const ClientLoginScreen(),
      ),

      /// ✅ Other independent screens
      GoRoute(
        path: '/${ClientAppRoutes.allFoodItems}',
        name: ClientAppRoutes.allFoodItems,
        builder: (context, state) {
          // Extract tableId from query parameters
          final tableId = state.uri.queryParameters['tableId'] ?? '';
          return AllFoodItemsScreen(
            tableId: tableId, // Provide default or handle null
          );
        },
      ),
      GoRoute(
        path: '/${ClientAppRoutes.cartScreen}',
        name: ClientAppRoutes.cartScreen,
        builder: (context, state) {
          final tableId = state.uri.queryParameters['tableId'];
          return AddToCartScreen(
            businessId: BusinessRepository.temporaryBusinesshId,
            branchId: BusinessRepository.temporaryBranchId,
            tableId: tableId,
          );
        },
      ),
      GoRoute(
        path: '/${ClientAppRoutes.myProfile}',
        name: ClientAppRoutes.myProfile,
        builder: (context, state) => MyProfileScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        const Scaffold(body: Center(child: Text('404 - Page not found'))),
  );
}
