import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/routes/client_app_router.dart';
import 'firebase_options.dart';
import 'package:hotel_management_system/state_management/theme_provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure bindings are initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  runApp(ProviderScope(child: ClientApp()));
}

class ClientApp extends ConsumerWidget {
  const ClientApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeref = ref.watch(themeProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'DineFlowX',
      theme: themeref.lightTheme,
      darkTheme: themeref.darkTheme,
      themeMode: themeref.themeMode,
      routerConfig: ClientAppRouter.router,
    );
  }
}
