import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/presentation/client_screens/onboarding/spash_screen_adminside.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';
import 'package:hotel_management_system/state_management/app_manager.dart';

void main() {
  Widget _buildTestApp({required AppInitializationState state}) {
    return ProviderScope(
      overrides: [
        appInitializationProvider.overrideWith((ref) async {}),
        appInitializationStateProvider.overrideWith((ref) => state),
      ],
      child: MaterialApp(
        initialRoute: AdminAppRoutes.splash,
        routes: {
          AdminAppRoutes.splash: (context) => const SplashScreen(),
          AdminAppRoutes.login: (context) =>
              const Scaffold(body: Center(child: Text('LOGIN_SCREEN'))),
          AdminAppRoutes.home: (context) =>
              const Scaffold(body: Center(child: Text('HOME_SCREEN'))),
        },
      ),
    );
  }

  testWidgets('navigates to login when state is already loggedOut', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(state: AppInitializationState.loggedOut),
    );

    await tester.pumpAndSettle();

    expect(find.text('LOGIN_SCREEN'), findsOneWidget);
  });

  testWidgets('navigates to home when state is already initialized', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(state: AppInitializationState.initialized),
    );

    await tester.pumpAndSettle();

    expect(find.text('HOME_SCREEN'), findsOneWidget);
  });
}
