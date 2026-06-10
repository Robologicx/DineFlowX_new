// AppManager to handle the entire initialization sequence
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/buisness_model.dart';
import 'package:hotel_management_system/data/models/category_model.dart';
import 'package:hotel_management_system/data/models/menu_model.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/permission_model.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/data/models/room_model.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/repositories/menu_repository.dart';
import 'package:hotel_management_system/data/repositories/product_repository.dart';
import 'package:hotel_management_system/data/repositories/user_repository.dart';
import 'package:hotel_management_system/permissions.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class AppManager {
  final Ref ref;

  static const bool _allowDashboardWithoutAuth = false;
  static const bool _enableDemoSeed = false;
  static const bool _forceReseed = false;
  static const String _demoUserId = 'demo-admin';

  AppManager(this.ref);

  Future<void> initializeApp() async {
    try {
      ref.read(appInitializationErrorProvider.notifier).state = null;
      ref.read(appInitializationStateProvider.notifier).state =
          AppInitializationState.checkingAuth;
      // Step 1: Check auth status
      final authService = ref.read(authServiceProvider);
      final isLoggedIn = await authService.isLoggedIn();
      final appProviderNotifier = ref.read(
        appInitializationStateProvider.notifier,
      );

      if (!isLoggedIn) {
        if (_allowDashboardWithoutAuth) {
          await _seedDemoDataIfNeeded();
          await _initializeDemoUserData();
          appProviderNotifier.state =
              AppInitializationState.loadingRepositories;
          await _initializeDependentRepositories();
          appProviderNotifier.state = AppInitializationState.initialized;
          return;
        }

        if (_enableDemoSeed) {
          await _seedDemoDataIfNeeded();
          await _initializeDemoUserData();
          appProviderNotifier.state =
              AppInitializationState.loadingRepositories;
          await _initializeDependentRepositories();
          appProviderNotifier.state = AppInitializationState.initialized;
          return;
        }

        // Handle logout case
        await _handleLoggedOut();
        return;
      }

      appProviderNotifier.state = AppInitializationState.loadingUser;
      // Step 2: Initialize user data
      await _initializeUserData();

      appProviderNotifier.state = AppInitializationState.loadingRepositories;
      // Step 3: Initialize other repositories that depend on user data
      await _initializeDependentRepositories();

      // Step 4: Mark app as ready
      ref.read(appInitializationStateProvider.notifier).state =
          AppInitializationState.initialized;
    } catch (e) {
      ref.read(appInitializationErrorProvider.notifier).state = e.toString();
      ref.read(appInitializationStateProvider.notifier).state =
          AppInitializationState.error;
      // u can also pass e.toString() to error later.
    }
  }

  Future<void> _initializeDemoUserData() async {
    final userNotifier = ref.read(userProvider.notifier);
    await userNotifier.loadUser(_demoUserId);

    final userState = ref.read(userProvider);
    if (userState.selectedUser == null) {
      final businessId = BusinessRepository.temporaryBusinesshId;
      final branchId = BusinessRepository.temporaryBranchId;
      final now = DateTime.now();
      final demoRole = RoleModel(
        id: 'admin',
        businessId: businessId,
        name: 'Admin',
        permissions: const [],
        createdAt: now,
        updatedAt: now,
      );
      final demoUser = UserModel(
        uid: _demoUserId,
        name: 'Demo Admin',
        email: 'demo@dineflowx.app',
        role: demoRole,
        createdAt: now,
        updatedAt: now,
        extraPermissions: const {},
        primarybusinessId: businessId,
        primaryBranchId: branchId,
      );
      userNotifier.setUser(demoUser);
    }
    await _waitForUserData();
  }

  Future<void> _seedDemoDataIfNeeded() async {
    final businessId = BusinessRepository.temporaryBusinesshId;
    final branchId = BusinessRepository.temporaryBranchId;
    final now = DateTime.now();
    final firestore = FirebaseFirestore.instance;

    final businessDoc = firestore.collection('businesses').doc(businessId);
    final businessSnap = await businessDoc.get();
    if (!_forceReseed) {
      if (businessSnap.exists &&
          (businessSnap.data()?['isDemoSeeded'] == true)) {
        return;
      }
    }

    // 1) Business
    final business = BusinessModel(
      id: businessId,
      ownerId: _demoUserId,
      title: 'DineFlowX Demo',
      description: 'Demo business for DineFlowX',
      currencyCode: 'USD',
      taxPercentage: 0,
      timezone: 'UTC',
      industryType: 'restaurant',
      isActive: true,
      isDeleted: false,
      createdAt: now,
      updatedAt: now,
    );
    await businessDoc.set({
      ...business.toMap(),
      'id': businessId,
      'title_lower': business.title.toLowerCase(),
      'isDemoSeeded': true,
    }, SetOptions(merge: true));

    // 2) Branch (basic doc)
    await businessDoc.collection('branches').doc(branchId).set({
      'id': branchId,
      'name': 'Main Branch',
      'name_lower': 'main branch',
      'isActive': true,
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
    }, SetOptions(merge: true));

    final permissionsRef = businessDoc
        .collection('branches')
        .doc(branchId)
        .collection('permissions');

    final adminPermissions = permissionsRegistry
        .map((perm) => PermissionModel.fromMap(Map<String, dynamic>.from(perm)))
        .toList();

    for (final permission in adminPermissions) {
      await permissionsRef.doc(permission.id).set({
        ...permission.toMap(),
        'name_lower': permission.name.toLowerCase(),
      }, SetOptions(merge: true));
    }

    // 3) Role (admin)
    final adminRole = RoleModel(
      id: 'admin',
      businessId: businessId,
      name: 'Admin',
      permissions: adminPermissions,
      createdAt: now,
      updatedAt: now,
    );
    await businessDoc
        .collection('branches')
        .doc(branchId)
        .collection('roles')
        .doc('admin')
        .set({
          ...adminRole.toMap(),
          'id': 'admin',
          'name_lower': 'admin',
        }, SetOptions(merge: true));

    // 4) Root user
    final demoUser = UserModel(
      uid: _demoUserId,
      name: 'Demo Admin',
      email: 'demo@dineflowx.app',
      role: adminRole,
      createdAt: now,
      updatedAt: now,
      extraPermissions: const {},
      primarybusinessId: businessId,
      primaryBranchId: branchId,
    );
    await UserRepository().createUser(demoUser);

    // 5) Branch-specific user info
    await businessDoc
        .collection('branches')
        .doc(branchId)
        .collection('users')
        .doc(_demoUserId)
        .set({
          'uid': _demoUserId,
          'roleId': 'admin',
          'name': 'Admin',
          'permissions': [],
          'extraPermissions': {},
          'createdAt': Timestamp.fromDate(now),
          'updatedAt': Timestamp.fromDate(now),
        }, SetOptions(merge: true));

    // 6) Menu
    final menuRepo = MenuRepository(businessId: businessId, branchId: branchId);
    final menu = MenuModel(
      id: 'menu1',
      name: 'Main Menu',
      description: 'Demo menu',
      isActive: true,
      createdBy: _demoUserId,
      createdAt: now,
      updatedAt: now,
    );
    await menuRepo.addMenu(menu);

    // 7) Categories
    final categoriesRef = businessDoc
        .collection('branches')
        .doc(branchId)
        .collection('categories');
    final category1 = CategoryModel(
      id: 'cat1',
      name: 'Starters',
      menuId: menu.id,
      createdAt: now,
      updatedAt: now,
    );
    await categoriesRef.doc('cat1').set(category1.toMap());
    final category2 = CategoryModel(
      id: 'cat2',
      name: 'Main Course',
      menuId: menu.id,
      createdAt: now,
      updatedAt: now,
    );
    await categoriesRef.doc('cat2').set(category2.toMap());

    // 8) Products
    final productRepo = ProductRepository(
      businessId: businessId,
      branchId: branchId,
    );
    await productRepo.addProduct(
      ProductModel(
        productId: 'prod1',
        name: 'Classic Burger',
        description: 'Juicy grilled burger with cheese',
        price: 8.99,
        categoryId: 'cat2',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await productRepo.addProduct(
      ProductModel(
        productId: 'prod2',
        name: 'Caesar Salad',
        description: 'Crisp romaine, parmesan, croutons',
        price: 6.50,
        categoryId: 'cat1',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await productRepo.addProduct(
      ProductModel(
        productId: 'prod3',
        name: 'Pasta Alfredo',
        description: 'Creamy alfredo with herbs',
        price: 9.75,
        categoryId: 'cat2',
        createdAt: now,
        updatedAt: now,
      ),
    );

    // 9) Rooms
    final roomsRef = businessDoc
        .collection('branches')
        .doc(branchId)
        .collection('rooms');
    final room = RoomModel(
      id: 'room1',
      businessId: businessId,
      branchId: branchId,
      name: 'Main Hall',
      type: RoomType.regular,
      capacity: 40,
      currentOccupancy: 0,
      status: RoomStatus.available,
      amenities: const ['WiFi', 'AC'],
      createdAt: now,
      updatedAt: now,
    );
    await roomsRef.doc('room1').set(room.toMap());

    // 10) Tables
    final tablesRef = businessDoc
        .collection('branches')
        .doc(branchId)
        .collection('diningTables');
    final table1 = TableModel(
      id: 'table1',
      businessId: businessId,
      branchId: branchId,
      tableNumber: 'T1',
      roomId: 'room1',
      seats: 4,
      status: TableStatus.available,
      createdAt: now,
      updatedAt: now,
    );
    final table2 = TableModel(
      id: 'table2',
      businessId: businessId,
      branchId: branchId,
      tableNumber: 'T2',
      roomId: 'room1',
      seats: 6,
      status: TableStatus.available,
      createdAt: now,
      updatedAt: now,
    );
    await tablesRef.doc('table1').set(table1.toMap());
    await tablesRef.doc('table2').set(table2.toMap());

    // 11) Orders
    final ordersRef = businessDoc
        .collection('branches')
        .doc(branchId)
        .collection('orders');

    final diningOrder = OrderModel(
      orderId: 'order1',
      userId: _demoUserId,
      userName: 'Demo Admin',
      userPhoneNo: '+1555000001',
      orderType: OrderType.dining,
      items: [
        OrderItem(
          productId: 'prod1',
          productName: 'Classic Burger',
          quantity: 2,
          price: 8.99,
        ),
      ],
      totalAmount: 17.98,
      orderStatus: OrderStatus.inProgress,
      createdAt: now,
      updatedAt: now,
      diningTable: table1,
      waiterId: _demoUserId,
      waiterName: 'Demo Admin',
      additionalNotes: 'Seeded demo dining order',
    );

    final takeawayOrder = OrderModel(
      orderId: 'order2',
      userId: _demoUserId,
      userName: 'Walk-in Customer',
      userPhoneNo: '+1555000002',
      orderType: OrderType.takeaway,
      items: [
        OrderItem(
          productId: 'prod2',
          productName: 'Caesar Salad',
          quantity: 1,
          price: 6.50,
        ),
        OrderItem(
          productId: 'prod3',
          productName: 'Pasta Alfredo',
          quantity: 1,
          price: 9.75,
        ),
      ],
      totalAmount: 16.25,
      orderStatus: OrderStatus.completed,
      createdAt: now,
      updatedAt: now,
      additionalNotes: 'Seeded demo takeaway order',
    );

    await ordersRef
        .doc('order1')
        .set(diningOrder.toMap(), SetOptions(merge: true));
    await ordersRef
        .doc('order2')
        .set(takeawayOrder.toMap(), SetOptions(merge: true));

    // 12) Printers
    final printersRef = businessDoc
        .collection('branches')
        .doc(branchId)
        .collection('printers');
    await printersRef.doc('printer1').set({
      'ip': '192.168.1.50',
      'isPrimary': true,
      'createdAt': Timestamp.fromDate(now),
      'updatedAt': Timestamp.fromDate(now),
    }, SetOptions(merge: true));
  }

  Future<void> _handleLoggedOut() async {
    // Clear any existing data
    ref.invalidate(userProvider);
    ref.read(appInitializationErrorProvider.notifier).state = null;
    // ref.invalidate(userServiceProvider);

    // Navigate to login or show login screen
    ref.read(appInitializationStateProvider.notifier).state =
        AppInitializationState.loggedOut;
  }

  Future<void> _initializeUserData() async {
    final authService = ref.read(authServiceProvider);
    final currentUser = authService.currentUser;
    if (currentUser == null) {
      throw Exception('No user found after auth check');
    }

    final authUid = currentUser.uid;

    // Resolve and self-heal user profile via Admin SDK to avoid client-side rule denials.
    try {
      final callable = FirebaseFunctions.instance.httpsCallable(
        'resolveCurrentUserProfile',
      );
      await callable.call();
    } on FirebaseFunctionsException catch (e) {
      throw Exception(
        'Profile resolution failed: ${e.code} ${e.message ?? ''}'.trim(),
      );
    } catch (e) {
      throw Exception('Profile resolution failed: $e');
    }

    // Initialize user notifier
    final userNotifier = ref.read(userProvider.notifier);
    await userNotifier.loadUser(authUid);

    final userStateAfterLoad = ref.read(userProvider);
    if (userStateAfterLoad.selectedUser == null) {
      if (userStateAfterLoad.error != null) {
        throw Exception(userStateAfterLoad.error);
      }
      throw Exception('No user profile found for authenticated account.');
    }

    // Wait for user data to be fully loaded
    await _waitForUserData();
  }

  Future<void> _waitForUserData() async {
    const maxWaitTime = Duration(seconds: 30);
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime) < maxWaitTime) {
      final userState = ref.read(userProvider);

      // Check for error first
      if (userState.error != null) {
        throw Exception('Failed to load user data: ${userState.error}');
      }

      // Check if user data is available
      if (userState.selectedUser != null) {
        return; // Success! User data is loaded
      }

      // If still loading, wait a bit and check again
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // If we get here, it timed out
    throw Exception('Timeout waiting for user data');
  }

  Future<void> _initializeDependentRepositories() async {
    final userState = ref.read(userProvider);
    final user = userState.selectedUser!;

    // Initialize branches
    // final branchNotifier = ref.read(branchNotifierProvider.notifier);
    // await branchNotifier.loadBranches(user.primarybusinessId);

    try {
      // Just await each initialization - they'll complete in order
      // final branchNotifier = ref.read(
      //   branchNotifierProvider(user.primarybusinessId).notifier,
      // );
      // await branchNotifier.loadBranches(user.primarybusinessId);

      // These will be created on first access
      ref.read(
        roomProvider((
          businessId: user.primarybusinessId,
          branchId: user.primaryBranchId,
        )),
      );
      final tableNotifier = ref.read(
        tableProvider((
          businessId: user.primarybusinessId,
          branchId: user.primaryBranchId,
        )).notifier,
      );
      // tableNotifier.setBusinessContext(
      //   user.primarybusinessId,
      //   user.primaryBranchId,
      // );

      final menuNotifier = ref.read(
        menuProvider((
          businessId: user.primarybusinessId,
          branchId: user.primaryBranchId,
        )).notifier,
      );
      await menuNotifier.loadAllMenus();

      final categoryNotifier = ref.read(
        categoryProvider((
          businessId: user.primarybusinessId,
          branchId: user.primaryBranchId,
        )).notifier,
      );
      await categoryNotifier.loadAllCategories();

      final productNotifier = ref.read(
        productProvider((
          businessId: user.primarybusinessId,
          branchId: user.primaryBranchId,
        )).notifier,
      );

      ref.read(
        orderProvider((
          businessId: user.primarybusinessId,
          branchId: user.primaryBranchId,
          tableNotifier: tableNotifier,
        )),
      );
      await productNotifier.loadAllProducts();
    } catch (e) {
      throw Exception('Failed to initialize repositories: $e');
    }

    // // Initialize menus
    // final menuNotifier = ref.read(
    //   menuProvider((
    //     branchId: user.primaryBranchId,
    //     businessId: user.primarybusinessId,
    //   )).notifier,
    // );

    // // Initialize categories
    // final categoryNotifier = ref.read(
    //   categoryProvider((
    //     branchId: user.primaryBranchId,
    //     businessId: user.primarybusinessId,
    //   )).notifier,
    // );

    // // Initialize products
    // final productNotifier = ref.read(
    //   productProvider((
    //     branchId: user.primaryBranchId,
    //     businessId: user.primarybusinessId,
    //   )).notifier,
    // );

    // // Wait for all to complete
    // await Future.wait([
    //   // _waitForRepository(),
    //   _waitForRepository(menuNotifier),
    //   _waitForRepository(categoryNotifier),
    //   _waitForRepository(productNotifier),
    // ]);
  }

  Future<void> retryInitialization() async {
    ref.read(appInitializationStateProvider.notifier).state =
        AppInitializationState.notInitialized;
    await initializeApp();
  }
}

enum AppInitializationState {
  notInitialized,
  checkingAuth,
  loadingUser,
  loadingRepositories,
  initialized,
  loggedOut,
  error,
}

final appInitializationStateProvider = StateProvider<AppInitializationState>(
  (ref) => AppInitializationState.notInitialized,
);

final appInitializationErrorProvider = StateProvider<String?>((ref) => null);

final appManagerProvider = Provider<AppManager>((ref) {
  return AppManager(ref);
});

final appInitializationProvider = FutureProvider<void>((ref) async {
  // Defer initialization to next event-loop turn so provider graph is fully built
  // before we mutate appInitializationStateProvider.
  await Future<void>.delayed(Duration.zero);
  final appManager = ref.read(appManagerProvider);
  await appManager.initializeApp();
});
