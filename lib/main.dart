import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/services/auth_service.dart';
import 'package:hotel_management_system/presentation/client_screens/cart/add_to_cart.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_shell.dart';
import 'package:hotel_management_system/presentation/client_screens/onboarding/spash_screen_adminside.dart';
import 'package:hotel_management_system/state_management/theme_provider.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';
import 'package:hotel_management_system/core/utils/firestore_offline_config.dart';
import 'package:hotel_management_system/core/utils/offline_media_upload_queue_service.dart';
import 'package:hotel_management_system/core/utils/offline_order_queue_service.dart';
import 'package:hotel_management_system/core/alerts/order_alert_listener.dart';
import 'package:hotel_management_system/presentation/common_widgets/offline_sync_status_banner.dart';
import 'routes/admin_app_routes.dart';
import 'firebase_options.dart'; // Import the generated Firebase options

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AuthService().initializeSession();
  await configureFirestoreOfflineSupport();
  await OfflineFirestoreWriteQueueService.instance.start();
  await OfflineMediaUploadQueueService.instance.start();
  await OfflineOrderQueueService.instance.start();
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  runApp(ProviderScope(child: AdminApp()));
}

// class AdminApp extends ConsumerWidget {
//   AdminApp({super.key});
//   late final AppInitializer appInitializer;
//   UserState? _userState;
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     final manager = ref.read(initializationManagerProvider);
//     // Step 1: Auth (always first)
//     manager.initializeAuth();
//     final authProvider = ref.read(authNotifierProvider.notifier);
//     final __authstate = ref.read(authNotifierProvider);
//     final themeRef = ref.watch(themeProvider);
//     // final userState = ref.watch(userProvider);
//     // final userNotifier = ref.read(userProvider.notifier);
//     final initializer = ref.read(appInitializerProvider);
//     _userState = ref.watch(userProvider);
//     // initializer.initializeApp();
//     return MaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: 'Hotel Management System Admin',
//       theme: themeRef.lightTheme,
//       darkTheme: themeRef.darkTheme,
//       themeMode: themeRef.themeMode,
//       // initialRoute: AdminAppRoutes.splash,
//       builder: (context, child) {
//         return Scaffold(
//           appBar: AppBar(title: Text('Hotel Management System Admin')),
//           body: FutureBuilder(
//             future: manager.initializeAuth(),
//             builder: (context, snapshot) {
//               if (snapshot.hasData) {
//                 // means we have auth service now
//                 var authService = snapshot.data;
//                 authService!.signIn("abcd@gmail.com", "asdf12345");
//                 return SplashScreen(authService.currentUser!.uid);
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) =>
//                         SplashScreen(authService.currentUser!.uid),
//                   ),
//                 );
//                 // Navigator.pushNamed(
//                 //   context,
//                 //   AdminAppRoutes.splash,
//                 //   arguments: authService.currentUser?.uid,
//                 // );
//                 return child!;
//               }
//               if (snapshot.connectionState == ConnectionState.done) {
//                 return child!;
//               } else {
//                 return const Center(child: CircularProgressIndicator());
//               }
//             },
//           ),
//         );
//       },
//       // userState.user == null
//       //     ? AdminAppRoutes.login
//       //     : userState.user!.role == 'admin'
//       //     ? AdminAppRoutes.home
//       //     : AdminAppRoutes.home,
//       // routes: AdminAppRoutes.routes,
//     );
//   }
// }

class AdminApp extends ConsumerWidget {
  const AdminApp({super.key});

  bool _isClientPath(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'clientapp' ||
        normalized == 'cleintapp' ||
        normalized == 'clientshell';
  }

  Widget? _resolveDeepLinkHome() {
    final uri = Uri.base;
    final path = uri.path.trim();
    final fullUrl = uri.toString().toLowerCase();
    final segments = uri.pathSegments
        .where((segment) => segment.trim().isNotEmpty)
        .toList(growable: false);
    final normalizedPath = path.endsWith('/') && path.length > 1
        ? path.substring(0, path.length - 1)
        : path;

    final hasQrParams =
        (uri.queryParameters['tableId'] ?? '').trim().isNotEmpty &&
        (uri.queryParameters['businessId'] ?? '').trim().isNotEmpty &&
        (uri.queryParameters['branchId'] ?? '').trim().isNotEmpty;

    if (hasQrParams &&
        (fullUrl.contains('/clientshell') ||
            fullUrl.contains('/addtocartscreen'))) {
      if (fullUrl.contains('/addtocartscreen')) {
        return AddToCartScreen(
          tableId: uri.queryParameters['tableId'],
          businessId: uri.queryParameters['businessId'] ?? '',
          branchId: uri.queryParameters['branchId'] ?? '',
        );
      }
      return ClientHomeShell(
        tableId: uri.queryParameters['tableId'],
        businessId: uri.queryParameters['businessId'],
        branchId: uri.queryParameters['branchId'],
      );
    }

    if (normalizedPath.toLowerCase() == '/clientshell') {
      return ClientHomeShell(
        tableId: uri.queryParameters['tableId'],
        businessId: uri.queryParameters['businessId'],
        branchId: uri.queryParameters['branchId'],
      );
    }

    if (normalizedPath.toLowerCase() == '/addtocartscreen') {
      return AddToCartScreen(
        tableId: uri.queryParameters['tableId'],
        businessId: uri.queryParameters['businessId'] ?? '',
        branchId: uri.queryParameters['branchId'] ?? '',
      );
    }

    if (segments.length >= 2 && _isClientPath(segments[1])) {
      return _buildBusinessPathClientEntry(
        businessKey: Uri.decodeComponent(segments[0]),
        branchId: uri.queryParameters['branchId'],
        tableId: uri.queryParameters['tableId'],
      );
    }

    if (segments.length >= 2 && _isClientPath(segments[0])) {
      return _buildBusinessPathClientEntry(
        businessKey: Uri.decodeComponent(segments[1]),
        branchId: uri.queryParameters['branchId'],
        tableId: uri.queryParameters['tableId'],
      );
    }

    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeRef = ref.watch(themeProvider);
    final deepLinkHome = _resolveDeepLinkHome();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DineFlowX',
      theme: themeRef.lightTheme,
      darkTheme: themeRef.darkTheme,
      themeMode: themeRef.themeMode,
      builder: (context, child) {
        return Stack(
          fit: StackFit.expand,
          children: [
            child ?? const SizedBox.shrink(),
            const OrderAlertListener(),
            const OfflineSyncStatusBanner(),
          ],
        );
      },
      routes: AdminAppRoutes.routes,
      home: deepLinkHome ?? const SplashScreen(),
      initialRoute: null,
      // home: SplashScreen(),
    );
  }

  String _slugify(String input) {
    final lower = input.trim().toLowerCase();
    final buffer = StringBuffer();
    var lastDash = false;
    for (final codeUnit in lower.codeUnits) {
      final isAlphaNum =
          (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 97 && codeUnit <= 122);
      if (isAlphaNum) {
        buffer.writeCharCode(codeUnit);
        lastDash = false;
      } else if (!lastDash) {
        buffer.write('-');
        lastDash = true;
      }
    }
    final value = buffer.toString();
    return value.replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<String?> _resolveBusinessId(String businessKey) async {
    final key = businessKey.trim();
    if (key.isEmpty) return null;

    final businesses = FirebaseFirestore.instance.collection('businesses');

    final byId = await businesses.doc(key).get();
    if (byId.exists) return byId.id;

    final normalized = key.toLowerCase();
    final normalizedTitle = normalized
        .replaceAll('-', ' ')
        .replaceAll('_', ' ')
        .trim();

    final byLower = await businesses
        .where('title_lower', isEqualTo: normalizedTitle)
        .limit(1)
        .get();
    if (byLower.docs.isNotEmpty) return byLower.docs.first.id;

    final byPrefix = await businesses
        .where('title_lower', isGreaterThanOrEqualTo: normalizedTitle)
        .where('title_lower', isLessThanOrEqualTo: '$normalizedTitle\uf8ff')
        .limit(1)
        .get();
    if (byPrefix.docs.isNotEmpty) return byPrefix.docs.first.id;

    final all = await businesses.limit(100).get();
    final targetSlug = _slugify(key);
    for (final doc in all.docs) {
      final title = (doc.data()['title'] ?? '').toString();
      if (_slugify(title) == targetSlug) {
        return doc.id;
      }
    }

    return null;
  }

  Future<String> _resolveBranchId(String businessId, String? branchId) async {
    final incoming = (branchId ?? '').trim();
    if (incoming.isNotEmpty) return incoming;

    final firstBranch = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .limit(1)
        .get();

    if (firstBranch.docs.isNotEmpty) {
      return firstBranch.docs.first.id;
    }

    return BusinessRepository.temporaryBranchId;
  }

  Widget _buildBusinessPathClientEntry({
    required String businessKey,
    String? branchId,
    String? tableId,
  }) {
    return FutureBuilder<String?>(
      future: _resolveBusinessId(businessKey),
      builder: (context, businessSnapshot) {
        if (businessSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final businessId = (businessSnapshot.data ?? '').trim();
        if (businessId.isEmpty) {
          return const Scaffold(
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Unable to open client app for this business.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return FutureBuilder<String>(
          future: _resolveBranchId(businessId, branchId),
          builder: (context, branchSnapshot) {
            if (branchSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final resolvedBranchId =
                (branchSnapshot.data ?? BusinessRepository.temporaryBranchId)
                    .trim();
            final trimmedTableId = (tableId ?? '').trim();

            return ClientHomeShell(
              businessId: businessId,
              branchId: resolvedBranchId,
              tableId: trimmedTableId.isEmpty ? null : trimmedTableId,
            );
          },
        );
      },
    );
  }

  //--------------------Error codde mistakes regarding riverpod initialization---------------------
  // class AppInitializer {
  //   final Ref ref;

  //   AppInitializer(this.ref);

  //   Stream initializeApp(UserState? _userState) async* {
  //     final manager = ref.read(initializationManagerProvider);

  //     // Step 1: Auth (always first)
  //     await manager.initializeAuth();
  //     final authProvider = ref.read(authNotifierProvider.notifier);
  //     final __authstate = ref.read(authNotifierProvider);
  //     if (__authstate.isLoggedIn) {
  //       // init user.
  //       await manager.initializeUser(__authstate.firebaseUser!.uid);

  //       // At this point Emit some text from here that i can show to UI to show user is logged in and initializing user data
  //       if (_userState != null) {
  //         // Check if userState is not null there's some selected user (Means current user is selected user and user is logged in and data is initialized).
  //         if (_userState!.isLoading) {
  //           return;
  //         } else {
  //           if (!_userState!.isLoading && _userState!.selectedUser != null) {
  //             // Check if there's some business pre selected for this user so that business gets initialized.
  //             // For 1st time account created users it will be null - so some (Admin will add business to their profile)
  //             if (_userState!.selectedUser!.primarybusinessId != null) {
  //               // Check that current user belongs to some pre selected business
  //               // Lets initialize that business and move towards app with current user's role and permissions.
  //               // At this point Emit some text from here that i can show to UI to show "Preparing business Setup"
  //               final businessState = await manager.initializeBusiness(
  //                 _userState!.selectedUser!.primarybusinessId,
  //               );
  //             } else {
  //               // Business not assigned to this user. So let's show user the business selection screen.
  //               // Contact your admin to assign you a business
  //             }

  //             // Step 4: Branch providers are initialized on-demand when needed
  //             // manager.initializeBranchProviders(
  //             //   _userState!.selectedUser!.primarybusinessId,
  //             //   BusinessRepository.temporaryBranchId,
  //             // );
  //           } else {
  //             // Either User data not exists in Users Repository or not initialized yet.
  //             final _userNotifier = await ref.read(userProvider.notifier);
  //             if (ref.read(userProvider).selectedUser != null)
  //               return;
  //             else {
  //               UserModel user = UserModel(
  //                 uid: __authstate.firebaseUser!.uid,
  //                 name: "Demo Owner",
  //                 email: "abcd@gmail.com",
  //                 role: RoleModel.fromMap({'id': 'admin', 'name': 'Admin'}),
  //                 createdAt: DateTime.now(),
  //                 updatedAt: DateTime.now(),
  //                 extraPermissions: {},
  //                 primarybusinessId: "business1",
  //                 primaryBranchId: "branch1",
  //               );

  //               _userNotifier.createUser(
  //                 UserModel.fromMap(user.uid, user.toMap()),
  //               );
  //             }
  //           }
  //         }
  //       }
  //     } else {
  //       // Navigate to login screen
  //     }

  //     if (__authstate.isLoading) return;
  //     //
  //     if (__authstate.error != null) return;
  //   }
  // }

  /////////---------------------before trying future-----------------////////
  // app_initializer.dart
  // class AppInitializer {
  //   final Ref ref;

  //   AppInitializer(this.ref);

  //   Stream initializeApp(UserState? _userState) async* {
  //     final manager = ref.read(initializationManagerProvider);

  //     // Step 1: Auth (always first)
  //     await manager.initializeAuth();
  //     final authProvider = ref.read(authNotifierProvider.notifier);
  //     final __authstate = ref.read(authNotifierProvider);
  //     if (__authstate.isLoggedIn) {
  //       // init user.
  //       await manager.initializeUser(__authstate.firebaseUser!.uid);

  //       // At this point Emit some text from here that i can show to UI to show user is logged in and initializing user data
  //       if (_userState != null) {
  //         // Check if userState is not null there's some selected user (Means current user is selected user and user is logged in and data is initialized).
  //         if (_userState!.isLoading) {
  //           return;
  //         } else {
  //           if (!_userState!.isLoading && _userState!.selectedUser != null) {
  //             // Check if there's some business pre selected for this user so that business gets initialized.
  //             // For 1st time account created users it will be null - so some (Admin will add business to their profile)
  //             if (_userState!.selectedUser!.primarybusinessId != null) {
  //               // Check that current user belongs to some pre selected business
  //               // Lets initialize that business and move towards app with current user's role and permissions.
  //               // At this point Emit some text from here that i can show to UI to show "Preparing business Setup"
  //               final businessState = await manager.initializeBusiness(
  //                 _userState!.selectedUser!.primarybusinessId,
  //               );
  //             } else {
  //               // Business not assigned to this user. So let's show user the business selection screen.
  //               // Contact your admin to assign you a business
  //             }

  //             // Step 4: Branch providers are initialized on-demand when needed
  //             // manager.initializeBranchProviders(
  //             //   _userState!.selectedUser!.primarybusinessId,
  //             //   BusinessRepository.temporaryBranchId,
  //             // );
  //           } else {
  //             // Either User data not exists in Users Repository or not initialized yet.
  //             final _userNotifier = await ref.read(userProvider.notifier);
  //             if (ref.read(userProvider).selectedUser != null)
  //               return;
  //             else {
  //               UserModel user = UserModel(
  //                 uid: __authstate.firebaseUser!.uid,
  //                 name: "Demo Owner",
  //                 email: "abcd@gmail.com",
  //                 role: RoleModel.fromMap({'id': 'admin', 'name': 'Admin'}),
  //                 createdAt: DateTime.now(),
  //                 updatedAt: DateTime.now(),
  //                 extraPermissions: {},
  //                 primarybusinessId: "business1",
  //                 primaryBranchId: "branch1",
  //               );

  //               _userNotifier.createUser(
  //                 UserModel.fromMap(user.uid, user.toMap()),
  //               );
  //             }
  //           }
  //         }
  //       }
  //     } else {
  //       // Navigate to login screen
  //     }

  //     if (__authstate.isLoading) return;
  //     //
  //     if (__authstate.error != null) return;
  //   }
  // }
}
