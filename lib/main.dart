import 'package:firebase_core/firebase_core.dart' show Firebase;
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/state_management/theme_provider.dart';
import 'routes/admin_app_routes.dart';
import 'firebase_options.dart'; // Import the generated Firebase options

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensure bindings are initialized
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeRef = ref.watch(themeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'dineflowx',
      theme: themeRef.lightTheme,
      darkTheme: themeRef.darkTheme,
      themeMode: themeRef.themeMode,
      routes: AdminAppRoutes.routes,
      initialRoute: AdminAppRoutes.splash,
      // home: SplashScreen(),
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
