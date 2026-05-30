// // initialization_manager.dart
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hotel_management_system/data/services/auth_service.dart';
// import 'package:hotel_management_system/state_management/app_providers.dart';
// import 'package:hotel_management_system/state_management/table_state_and_notifier.dart';
// import 'package:hotel_management_system/state_management/user_state_and_notifier.dart';

// class InitializationManager {
//   final Ref ref;

//   InitializationManager(this.ref);

//   // Step 1: Initialize Auth (no dependencies)
//   Future<AuthService> initializeAuth() async {
//     return ref.read(authServiceProvider);
//   }

//   // Step 2: Initialize User (depends on auth)
//   Future<void> initializeUser(String uid) async {
//     final authState = ref.read(authNotifierProvider);
//     if (!authState.isLoggedIn) {
//       throw Exception('Auth must be initialized first');
//     }
//     ref.read(userProvider.notifier).loadUser(uid);
//   }

//   // Step 3: Initialize Business (depends on user)
//   Future<void> initializeBusiness(String selectedBusiness) async {
//     final userState = ref.read(userProvider);
//     if (userState.selectedUser == null) {
//       throw Exception('User must be initialized first');
//     }
//   }

//   // Step 4: Initialize specific branch providers on-demand
//   void initializeBranchProviders(String businessId, String branchId) async {
//     // These will be created on first access
//     ref.read(roomProvider((businessId: businessId, branchId: branchId)));
//     TableNotifier tableNotifier = await ref.read(
//       tableProvider((businessId: businessId, branchId: branchId)).notifier,
//     );
//     ref.read(categoryProvider((businessId: businessId, branchId: branchId)));
//     ref.read(menuProvider((businessId: businessId, branchId: branchId)));
//     ref.read(
//       orderProvider((
//         businessId: businessId,
//         branchId: branchId,
//         tableNotifier: tableNotifier,
//       )),
//     );
//   }

//   // Check if a provider is initialized
//   bool isProviderInitialized<T>(ProviderBase<T> provider) {
//     try {
//       ref.read(provider);
//       return true;
//     } catch (e) {
//       return false;
//     }
//   }
// }

// // Provider for the manager
// final initializationManagerProvider = Provider<InitializationManager>((ref) {
//   return InitializationManager(ref);
// });
