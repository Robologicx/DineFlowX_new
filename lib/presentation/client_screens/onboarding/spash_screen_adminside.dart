import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';
import 'package:hotel_management_system/state_management/app_manager.dart';

// class SplashScreen extends ConsumerStatefulWidget {
//   SplashScreen({super.key});

//   @override
//   ConsumerState<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends ConsumerState<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();

//     // ref.listen<AuthState>(authNotifierProvider, (prev, next) async {
//     //   if (_navigated || next.isLoading) return;

//     //   final user = next.firebaseUser;

//     //   if (user == null) {
//     //     _navigateTo(AdminAppRoutes.login);
//     //   } else {
//     //     final exists = await _userExists(user.uid);
//     //     if (!mounted) return;

//     //     if (exists) {
//     //       _navigateTo(AdminAppRoutes.home);
//     //     } else {
//     //       _navigateTo(AdminAppRoutes.splash);
//     //     }
//     //   }
//     // });
//   }

//   void _navigateTo(String route) {
//     Navigator.pushReplacementNamed(context, route);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final initializationState = ref.watch(appInitializationStateProvider);
//     final initializationAsync = ref.watch(appInitializationProvider);
//     // final args = ModalRoute.of(context)!.settings.arguments;
//     // String uid = args as String;
//     // final authState = ref.watch(authNotifierProvider);
//     // final initializer = ref.read(appInitializerProvider);
//     // initializer.initializeApp();
//     // final manager = ref.read(initializationManagerProvider);
//     // manager.initializeUser(widget.uid);

//     return Scaffold(
//       body: initializationAsync.when(
//         loading: () => _buildLoadingState(initializationState),
//         error: (error, stack) => _buildErrorState(error: error.toString()),
//         data: (_) => _buildAppContent(ref),
//       ),
//     );
//   }

//   Widget _buildErrorState({required String error, VoidCallback? onRetry}) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Error: $error'),
//             if (onRetry != null)
//               ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildLoadingState(AppInitializationState state) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const CircularProgressIndicator(),
//         const SizedBox(height: 20),
//         Text(_getLoadingMessage(state), textAlign: TextAlign.center),
//       ],
//     );
//   }

//   String _getLoadingMessage(AppInitializationState state) {
//     switch (state) {
//       case AppInitializationState.checkingAuth:
//         return 'Checking authentication...';
//       case AppInitializationState.loadingUser:
//         return 'Loading user data...';
//       case AppInitializationState.loadingRepositories:
//         return 'Initializing app...';
//       default:
//         return 'Loading...';
//     }
//   }

//   Widget _buildAppContent(WidgetRef ref) {
//     final initializationState = ref.watch(appInitializationStateProvider);

//     return switch (initializationState) {
//       AppInitializationState.loggedOut => const AdminLoginScreen(),
//       AppInitializationState.initialized => AdminShellWrapper(),
//       AppInitializationState.error => _buildErrorState(
//         error: 'Initialization failed',
//         onRetry: () => ref.invalidate(appInitializationProvider),
//       ),
//       _ => _buildLoadingState(initializationState),
//     };
//   }
// }

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Start initialization when screen loads
    ref.read(appInitializationProvider.future);
  }

  void _navigateTo(String route) {
    if (_navigated) return;
    _navigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacementNamed(context, route);
    });
  }

  void _handleInitializationResult() {
    final initializationState = ref.read(appInitializationStateProvider);

    switch (initializationState) {
      case AppInitializationState.loggedOut:
        _navigateTo(AdminAppRoutes.login);
        break;
      case AppInitializationState.initialized:
        _navigateTo(AdminAppRoutes.home);
        break;
      case AppInitializationState.error:
        _navigateTo(AdminAppRoutes.login);
        // Show error in the same screen, don't navigate
        break;
      default:
        // For loading states, do nothing - wait for completion
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final initializationAsync = ref.watch(appInitializationProvider);
    final initializationState = ref.watch(appInitializationStateProvider);

    // Listen for initialization completion and navigate
    ref.listen<AsyncValue<void>>(appInitializationProvider, (previous, next) {
      next.when(
        data: (_) => _handleInitializationResult(),
        error: (error, stack) {},
        loading: () {}, // Do nothing while loading
      );
    });

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo/Icon (optional)
            SizedBox(
              height: 200,
              width: 200,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                width: 200,
                height: 200,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'dineflowx',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // Show different content based on state
            if (initializationState == AppInitializationState.error ||
                initializationAsync.hasError)
              _buildErrorState()
            else
              _buildLoadingState(initializationState),
            // Show error message if initialization failed
            // if (initializationAsync.hasError) ...[
            //   const SizedBox(height: 20),
            //   Padding(
            //     padding: const EdgeInsets.symmetric(horizontal: 40),
            //     child: Text(
            //       'Error: ${initializationAsync.error}',
            //       textAlign: TextAlign.center,
            //       style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            //         color: Theme.of(context).colorScheme.error,
            //       ),
            //     ),
            //   ),
            //   const SizedBox(height: 20),
            //   ElevatedButton(
            //     onPressed: () => ref.invalidate(appInitializationProvider),
            //     child: const Text('Retry'),
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final initializationAsync = ref.watch(appInitializationProvider);

    return Column(
      children: [
        // Error Icon
        // Icon(
        //   Icons.error_outline,
        //   size: 60,
        //   color: Theme.of(context).colorScheme.error,
        // ),
        // const SizedBox(height: 20),

        // Error Title
        Text(
          'Initialization Failed',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 16),

        // Error Message
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            initializationAsync.error?.toString() ??
                'Check your internet connection',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(height: 30),

        // Retry Button
        ElevatedButton.icon(
          onPressed: () => ref.invalidate(appInitializationProvider),
          icon: const Icon(Icons.refresh),
          label: const Text('Retry'),
        ),
      ],
    );
  }

  Widget _buildLoadingState(AppInitializationState state) {
    return Column(
      children: [
        // Circular Progress Indicator
        const CircularProgressIndicator(),
        const SizedBox(height: 20),

        // Status Text
        Text(
          _getLoadingMessage(state),
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }

  String _getLoadingMessage(AppInitializationState state) {
    switch (state) {
      case AppInitializationState.checkingAuth:
        return 'Checking authentication...';
      case AppInitializationState.loadingUser:
        return 'Loading user data...';
      case AppInitializationState.loadingRepositories:
        return 'Initializing repositories...';
      // case AppInitializationState.loadingRoles:
      //   return 'Loading roles and permissions...';
      // case AppInitializationState.loadingBusiness:
      //   return 'Loading business data...';
      case AppInitializationState.initialized:
        return 'Ready!';
      case AppInitializationState.loggedOut:
        return 'Redirecting to login...';
      case AppInitializationState.error:
        return 'Initialization failed';
      default:
        return 'Loading...';
    }
  }
}

// ------------------------CHAT GPT WRITTEN CODE------------------------

// class SplashScreen extends ConsumerStatefulWidget {
//   const SplashScreen({super.key});

//   @override
//   ConsumerState<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends ConsumerState<SplashScreen> {
//   bool _navigated = false;

//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() async {
//       if (_navigated) return;
//       _navigated = true;

//       await ref.read(appInitializationProvider); // Wait until init is done
//       if (!mounted) return;

//       final state = ref.read(
//         appInitializationStateProvider,
//       ); // Now read latest state

//       switch (state) {
//         case AppInitializationState.loggedOut:
//           _navigateTo(AdminAppRoutes.login);
//           break;
//         case AppInitializationState.initialized:
//           _navigateTo(AdminAppRoutes.home);
//           break;
//         case AppInitializationState.error:
//           setState(() {}); // show error UI
//           break;
//         default:
//           break;
//       }
//     });
//   }

//   void _navigateTo(String route) {
//     Navigator.pushReplacementNamed(context, route);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final state = ref.watch(appInitializationStateProvider);

//     return Scaffold(
//       body: switch (state) {
//         AppInitializationState.error => _buildErrorState(
//           error: 'Initialization failed',
//           onRetry: () => ref.invalidate(appInitializationProvider),
//         ),
//         _ => _buildLoadingState(state),
//       },
//     );
//   }

//   Widget _buildLoadingState(AppInitializationState state) {
//     return Column(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         const CircularProgressIndicator(),
//         const SizedBox(height: 20),
//         Text(_getLoadingMessage(state), textAlign: TextAlign.center),
//       ],
//     );
//   }

//   String _getLoadingMessage(AppInitializationState state) {
//     switch (state) {
//       case AppInitializationState.checkingAuth:
//         return 'Checking authentication...';
//       case AppInitializationState.loadingUser:
//         return 'Loading user data...';
//       case AppInitializationState.loadingRepositories:
//         return 'Initializing app...';
//       default:
//         return 'Loading...';
//     }
//   }

//   Widget _buildErrorState({required String error, VoidCallback? onRetry}) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Text('Error: $error'),
//           if (onRetry != null)
//             ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
//         ],
//       ),
//     );
//   }
// }
