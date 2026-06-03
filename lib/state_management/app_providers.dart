import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/room_model.dart';
import 'package:hotel_management_system/data/models/sales_model_and_management.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/repositories/category_repository.dart';
import 'package:hotel_management_system/data/repositories/expense_repository.dart';
import 'package:hotel_management_system/data/repositories/images_storage_repository.dart';
import 'package:hotel_management_system/data/repositories/menu_repository.dart';
import 'package:hotel_management_system/data/repositories/order_repository.dart';
import 'package:hotel_management_system/data/repositories/permission_repository.dart';
import 'package:hotel_management_system/data/repositories/product_repository.dart';
import 'package:hotel_management_system/data/repositories/role_repository.dart';
import 'package:hotel_management_system/data/repositories/room_repository.dart';
import 'package:hotel_management_system/data/repositories/sales_repository.dart';
import 'package:hotel_management_system/data/repositories/table_repository.dart';
import 'package:hotel_management_system/data/repositories/user_repository.dart';
import 'package:hotel_management_system/data/services/auth_service.dart';
import 'package:hotel_management_system/data/services/buisness_service.dart';
import 'package:hotel_management_system/data/services/category_service.dart';
import 'package:hotel_management_system/data/services/expense_service.dart';
import 'package:hotel_management_system/data/services/image_storage_service.dart';
import 'package:hotel_management_system/data/services/menu_service.dart';
import 'package:hotel_management_system/data/services/order_service.dart';
import 'package:hotel_management_system/data/services/permission_service.dart';
import 'package:hotel_management_system/data/services/product_service.dart';
import 'package:hotel_management_system/data/services/role_service.dart';
import 'package:hotel_management_system/data/services/room_service.dart';
import 'package:hotel_management_system/data/services/sales_service.dart';
import 'package:hotel_management_system/data/services/table_service.dart';
import 'package:hotel_management_system/data/services/user_service.dart';
// import 'package:hotel_management_system/main.dart';
import 'package:hotel_management_system/state_management/auth_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/buisness_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/category_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/expense_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/menu_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/order_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/permission_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/product_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/role_state_and_provider.dart';
import 'package:hotel_management_system/state_management/room_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/table_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/user_state_and_notifier.dart';

class TenantBusinessAccessState {
  const TenantBusinessAccessState({
    required this.isBlocked,
    required this.reason,
    required this.businessId,
  });

  final bool isBlocked;
  final String reason;
  final String businessId;
}

final tenantBusinessAccessProvider = StreamProvider<TenantBusinessAccessState>((
  ref,
) {
  final businessId = ref.watch(
    userProvider.select(
      (state) => state.selectedUser?.primarybusinessId.trim() ?? '',
    ),
  );

  if (businessId.isEmpty) {
    return Stream.value(
      const TenantBusinessAccessState(
        isBlocked: false,
        reason: '',
        businessId: '',
      ),
    );
  }

  return FirebaseFirestore.instance
      .collection('businesses')
      .doc(businessId)
      .snapshots()
      .map((doc) {
        final data = doc.data() ?? const <String, dynamic>{};
        final status = (data['status'] ?? 'active').toString().toLowerCase();
        final isActiveField = data['isActive'];
        final isDeleted = data['isDeleted'] == true || status == 'deleted';
        final isSuspended =
            status == 'suspended' ||
            status == 'disabled' ||
            isActiveField == false;

        final isBlocked = isDeleted || isSuspended;
        final reason = isBlocked
            ? 'Your business account is disabled. Please contact DineFlowX team.'
            : '';

        return TenantBusinessAccessState(
          isBlocked: isBlocked,
          reason: reason,
          businessId: businessId,
        );
      })
      .distinct((previous, next) {
        return previous.isBlocked == next.isBlocked &&
            previous.reason == next.reason &&
            previous.businessId == next.businessId;
      });
});

/// --------------------
/// Core Providers
/// --------------------
///

/// Global provider for User
// RIVER POD PROVIDERS
// final appInitializerProvider = Provider((ref) {
//   return AppInitializer(ref);
// });
// Define the provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(); // Creates an instance of AuthService
});

// auth_providers.dart
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((
  ref,
) {
  //-----------------------Dont use AuthService() directly here-----------------------//
  final service = ref.read(authServiceProvider);
  return AuthNotifier(ref, service);
});

// -------------------------------------------------STORAGE RIVERPOD CLASSES--------------------------------------------------//
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  return StorageRepository();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  final repository = ref.read(storageRepositoryProvider);
  return StorageService(repository);
});
//--------------------------------------------------USER RIVERPOD CLASSES--------------------------------------------------//
final _userRepositoryProvider = FutureProvider<UserRepository>((ref) {
  return UserRepository();
});

// User Service Provider
final _userServiceProvider = FutureProvider<UserService>((ref) async {
  final userRepo = await ref.watch(_userRepositoryProvider.future);
  return UserService(
    userRepo,
    // Role repo factory - pass parameters as record
    // Proper factory functions without ref.read() calls
    (branchId, businessId) =>
        RoleRepository(businessId: businessId, branchId: branchId),
    (branchId, businessId) =>
        PermissionRepository(businessId: businessId, branchId: branchId),
  );
});

/// StateNotifierProvider for UserNotifier, which manages the user state
// Public notifier provider using same family parameters
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final service = ref.read(_userServiceProvider);
  final notifier = service.when(
    loading: () => UserNotifier(_createStubService()), // Handle loading state
    error: (error, stack) =>
        UserNotifier(_createErrorService(error)), // Handle error
    data: (userService) =>
        UserNotifier(userService), // Use actual service when ready
  );

  ref.listen<AuthState>(authNotifierProvider, (previous, next) {
    final previousUid = previous?.firebaseUser?.uid;
    final nextUid = next.firebaseUser?.uid;

    if (nextUid == null || nextUid.isEmpty) {
      notifier.clearCurrentUser();
      return;
    }

    if (previousUid != nextUid || previous == null) {
      notifier.loadUser(nextUid);
      notifier.listenToUser(nextUid);
    }
  }, fireImmediately: true);

  return notifier;
});

// Helper methods for loading/error states
UserService _createStubService() {
  // Return a stub service that shows loading state
  return UserService(
    UserRepository(),
    (b, bus) => RoleRepository(businessId: bus, branchId: b),
    (b, bus) => PermissionRepository(businessId: bus, branchId: b),
  );
}

UserService _createErrorService(Object error) {
  // Return a service that handles errors appropriately
  return UserService(
    UserRepository(),
    (b, bus) => RoleRepository(businessId: bus, branchId: b),
    (b, bus) => PermissionRepository(businessId: bus, branchId: b),
  );
}

//--------------------------------------------------ROLE RIVERPOD CLASSES--------------------------------------------------//
// Private repository provider (family)
final _roleRepositoryProvider =
    Provider.family<RoleRepository, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return RoleRepository(
        businessId: params.businessId,
        branchId: params.branchId,
      );
    });

// Private service provider (family)
final _roleServiceProvider =
    Provider.family<RoleService, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      final repository = ref.read(_roleRepositoryProvider(params));
      return RoleService(repository);
    });

// Public notifier provider (family)
final roleProvider =
    StateNotifierProvider.family<
      RoleNotifier,
      RoleState,
      ({String businessId, String branchId})
    >((ref, params) {
      final service = ref.read(_roleServiceProvider(params));
      return RoleNotifier(service);
    });

//--------------------------------------------------PERMISSION RIVERPOD CLASSES--------------------------------------------------//

// Private repository provider (family)
final _permissionRepositoryProvider =
    Provider.family<
      PermissionRepository,
      ({String businessId, String branchId})
    >((ref, params) {
      return PermissionRepository(
        branchId: params.branchId,
        businessId: params.businessId,
      );
    });

// Private service provider (family)
final _permissionServiceProvider =
    Provider.family<PermissionService, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      final repository = ref.read(_permissionRepositoryProvider(params));
      return PermissionService(repository);
    });

// Public notifier provider (family)
final permissionProvider =
    StateNotifierProvider.family<
      PermissionNotifier,
      PermissionState,
      ({String businessId, String branchId})
    >((ref, params) {
      final service = ref.read(_permissionServiceProvider(params));
      return PermissionNotifier(service);
    });

//--------------------------------------------------BUSINESS RIVERPOD CLASSES--------------------------------------------------//
/// Private repository provider
final _businessRepositoryProvider = Provider<BusinessRepository>((ref) {
  return BusinessRepository();
});

/// Private service provider
final _businessServiceProvider = Provider<BusinessService>((ref) {
  final repo = ref.read(_businessRepositoryProvider);
  return BusinessService(repo);
});

/// Public notifier provider
final businessProvider = StateNotifierProvider<BusinessNotifier, BusinessState>(
  (ref) {
    final service = ref.read(_businessServiceProvider);
    return BusinessNotifier(service);
  },
);

//--------------------------------------------------ROOM RIVERPOD CLASSES--------------------------------------------------//
// Private repository provider (family)
final _roomRepositoryProvider =
    Provider.family<RoomRepository, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return RoomRepository(
        businessId: params.businessId,
        branchId: params.branchId,
      );
    });

// Private service provider (family)
final _roomServiceProvider =
    Provider.family<RoomService, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      final repository = ref.read(_roomRepositoryProvider(params));
      return RoomService(repository);
    });

// Public notifier provider (family)
final roomProvider =
    StateNotifierProvider.family<
      RoomNotifier,
      RoomState,
      ({String businessId, String branchId})
    >((ref, params) {
      final service = ref.read(_roomServiceProvider(params));
      return RoomNotifier(service);
    });

// Selectors for easier access (optional)
final roomsListProvider =
    Provider.family<List<RoomModel>, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ref.watch(roomProvider(params).select((state) => state.rooms));
    });

final currentRoomProvider =
    Provider.family<RoomModel?, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ref.watch(
        roomProvider(params).select((state) => state.currentRoom),
      );
    });

final roomLoadingProvider =
    Provider.family<bool, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ref.watch(roomProvider(params).select((state) => state.isLoading));
    });

final roomErrorProvider =
    Provider.family<String?, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ref.watch(roomProvider(params).select((state) => state.error));
    });

//----------------------------------------------TABLE RIVERPOD CLASSES--------------------------------------------------//

// Private repository provider (family)
final _tableRepositoryProvider =
    Provider.family<TableRepository, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return TableRepository(
        businessId: params.businessId,
        branchId: params.branchId,
      );
    });

// Private service provider (family)
final _tableServiceProvider =
    Provider.family<TableService, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      final repository = ref.read(_tableRepositoryProvider(params));
      return TableService(repository);
    });

// Public notifier provider (family)
final tableProvider =
    StateNotifierProvider.family<
      TableNotifier,
      TableState,
      ({String businessId, String branchId})
    >((ref, params) {
      final service = ref.read(_tableServiceProvider(params));
      return TableNotifier(service);
    });

// Selectors for easier access (optional)
final tablesListProvider =
    Provider.family<List<TableModel>, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ref.watch(tableProvider(params).select((state) => state.tables));
    });

final currentTableProvider =
    Provider.family<TableModel?, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ref.watch(
        tableProvider(params).select((state) => state.currentTable),
      );
    });

final tableLoadingProvider =
    Provider.family<bool, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ref.watch(
        tableProvider(params).select((state) => state.isLoading),
      );
    });

final tableErrorProvider =
    Provider.family<String?, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ref.watch(tableProvider(params).select((state) => state.error));
    });

//----------------------------------------------EXPENSE RIVERPOD CLASSES--------------------------------------------------//
final _expenseRepositoryProvider =
    Provider.family<ExpenseRepository, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ExpenseRepository(
        businessId: params.businessId,
        branchId: params.branchId,
      );
    });

final _expenseServiceProvider =
    Provider.family<ExpenseService, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      final repo = ref.read(_expenseRepositoryProvider(params));
      return ExpenseService(repo);
    });

final expenseProvider =
    StateNotifierProvider.family<
      ExpenseNotifier,
      ExpenseState,
      ({String businessId, String branchId})
    >((ref, params) {
      final service = ref.read(_expenseServiceProvider(params));
      return ExpenseNotifier(service);
    });

//----------------------------------------------SALES RIVERPOD CLASSES--------------------------------------------------//
// Private repository provider
final _salesRepositoryProvider =
    Provider.family<SalesRepository, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return SalesRepository(
        businessId: params.businessId,
        branchId: params.branchId,
      );
    });

// Private service provider
final _salesServiceProvider =
    Provider.family<SalesService, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      final repository = ref.read(_salesRepositoryProvider(params));
      final expenseRepository = ref.read(_expenseRepositoryProvider(params));
      return SalesService(
        salesRepository: repository,
        expenseRepository: expenseRepository,
      );
    });

// Public notifier provider
final salesProvider =
    StateNotifierProvider.family<
      SalesNotifier,
      SalesState,
      ({String businessId, String branchId})
    >((ref, params) {
      final service = ref.read(_salesServiceProvider(params));
      return SalesNotifier(service);
    });
//--------------------------------------------------MENU RIVERPOD CLASSES--------------------------------------------------//

// Private repository provider (family)
// Only repository needs family provider that's why service and notifier also have to use family
// --------------------------------------------------
// 1. REPOSITORY (Family) - Needs businessId, branchId
// --------------------------------------------------
final _menuRepositoryProvider =
    Provider.family<MenuRepository, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return MenuRepository(
        branchId: params.branchId,
        businessId: params.businessId,
      );
    });

// --------------------------------------------------
// 2. SERVICE (Family) - Needs Repository from same context
// --------------------------------------------------
final _menuServiceProvider =
    Provider.family<MenuService, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      // Get repo with SAME businessId/branchId
      final repo = ref.read(_menuRepositoryProvider(params));
      return MenuService(repo); // Service only needs repo, not the IDs
    });

// --------------------------------------------------
// 3. NOTIFIER (Family) - Needs Service from same context
// --------------------------------------------------
final menuProvider =
    StateNotifierProvider.family<
      MenuNotifier,
      MenuState,
      ({String businessId, String branchId})
    >((ref, params) {
      // Get service with SAME businessId/branchId
      final service = ref.read(_menuServiceProvider(params));
      return MenuNotifier(service); // Notifier only needs service, not the IDs
    });

//--------------------------------------------------CATEGORY RIVERPOD CLASSES--------------------------------------------------//

// Private repository provider (family)
final _categoryRepositoryProvider =
    Provider.family<CategoryRepository, ({String businessId, String branchId})>(
      (ref, params) {
        return CategoryRepository(
          branchId: params.branchId,
          businessId: params.businessId,
        );
      },
    );

// Private service provider (family)
final _categoryServiceProvider =
    Provider.family<CategoryService, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return CategoryService(
        //---------------------PRODUCT SERVICE DEPENDS ON STORAGE SERVICE--------------------//
        ref.read(storageServiceProvider),
        ref.read(_categoryRepositoryProvider(params)),
      );
    });

// Public notifier provider (family)
final categoryProvider =
    StateNotifierProvider.family<
      CategoryNotifier,
      CategoryState,
      ({String businessId, String branchId})
    >((ref, params) {
      final service = ref.read(_categoryServiceProvider(params));
      return CategoryNotifier(service);
    });

//--------------------------------------------------PRODUCT RIVERPOD CLASSES--------------------------------------------------//

// Private repository provider (family)
final _productRepositoryProvider =
    Provider.family<ProductRepository, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      return ProductRepository(
        branchId: params.branchId,
        businessId: params.businessId,
      );
    });

// Private service provider (family)
final _productServiceProvider =
    Provider.family<ProductService, ({String businessId, String branchId})>((
      ref,
      params,
    ) {
      final repo = ref.read(_productRepositoryProvider(params));
      return ProductService(
        repository: repo,
        //---------------------PRODUCT SERVICE DEPENDS ON STORAGE SERVICE--------------------//
        storageService: ref.read(storageServiceProvider),
      );
    });

// Public notifier provider (family)
final productProvider =
    StateNotifierProvider.family<
      ProductNotifier,
      ProductState,
      ({String businessId, String branchId})
    >((ref, params) {
      final service = ref.read(_productServiceProvider(params));
      return ProductNotifier(service);
    });

//--------------------------------------------------ORDER RIVERPOD CLASSES--------------------------------------------------//
// Private repository provider (family)
final _orderRepositoryProvider =
    Provider.family<
      OrderRepository,
      ({String businessId, String branchId, TableNotifier tableNotifier})
    >((ref, params) {
      return OrderRepository(
        branchId: params.branchId,
        businessId: params.businessId,
        tableNotifier: params.tableNotifier,
      );
    });

// Private service provider (family)
final _orderServiceProvider =
    Provider.family<
      OrderService,
      ({String businessId, String branchId, TableNotifier tableNotifier})
    >((ref, params) {
      final repo = ref.read(_orderRepositoryProvider(params));
      return OrderService(repo);
    });

// Public notifier provider (family)
final orderProvider =
    StateNotifierProvider.family<
      OrderNotifier,
      OrderState,
      ({String businessId, String branchId, TableNotifier tableNotifier})
    >((ref, params) {
      final service = ref.read(_orderServiceProvider(params));
      return OrderNotifier(service);
    });

final allOrdersStreamProvider =
    StreamProvider.family<
      List<OrderModel>,
      ({String businessId, String branchId, TableNotifier tableNotifier})
    >((ref, params) {
      final service = ref.read(_orderServiceProvider(params));
      return service.getAllOrdersStream();
    });

final todayOrdersStreamProvider =
    StreamProvider.family<
      List<OrderModel>,
      ({String businessId, String branchId, TableNotifier tableNotifier})
    >((ref, params) {
      final service = ref.read(_orderServiceProvider(params));
      return service.getTodayOrdersStream();
    });
