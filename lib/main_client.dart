import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import 'package:hotel_management_system/core/utils/firestore_offline_config.dart';
import 'package:hotel_management_system/core/utils/offline_media_upload_queue_service.dart';
import 'package:hotel_management_system/core/utils/offline_order_queue_service.dart';
import 'package:hotel_management_system/presentation/common_widgets/offline_sync_status_banner.dart';
import 'package:hotel_management_system/routes/client_app_router.dart';
import 'package:hotel_management_system/state_management/current_tenant_business_provider.dart';
import 'firebase_options.dart';
import 'package:hotel_management_system/state_management/theme_provider.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Ensure bindings are initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await configureFirestoreOfflineSupport();
  await OfflineFirestoreWriteQueueService.instance.start();
  await OfflineMediaUploadQueueService.instance.start();
  await OfflineOrderQueueService.instance.start();
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
    final businessTitle = ref
        .watch(currentTenantBusinessProvider)
        .maybeWhen(
          data: (business) {
            final title = business?.title.trim() ?? '';
            return title.isEmpty ? 'DineFlowX' : title;
          },
          orElse: () => 'DineFlowX',
        );
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: businessTitle,
      theme: themeref.lightTheme,
      darkTheme: themeref.darkTheme,
      themeMode: themeref.themeMode,
      routerConfig: ClientAppRouter.router,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            const OfflineSyncStatusBanner(),
          ],
        );
      },
    );
  }
}
