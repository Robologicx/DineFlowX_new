import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/core/sync/realtime_sync_service.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/product_model.dart';
import 'package:hotel_management_system/data/models/category_model.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/data/models/room_model.dart';
import 'package:hotel_management_system/data/models/menu_model.dart';

// ==================== ORDERS ====================
final realtimeOrdersProvider =
    StreamProvider.family<
      List<OrderModel>,
      (String businessId, String branchId)
    >((ref, params) async* {
      final (businessId, branchId) = params;
      final collectionPath = 'businesses/$businessId/branches/$branchId/orders';

      final syncService = RealtimeSyncService<OrderModel>(
        collectionPath: collectionPath,
        fromMap: (data, id) => OrderModel.fromMap(data, id),
      );

      await syncService.initialize();
      ref.onDispose(() => syncService.dispose());

      yield syncService.currentItems;
      await for (final items in syncService.itemsStream) {
        yield items;
      }
    });

// ==================== PRODUCTS ====================
final realtimeProductsProvider =
    StreamProvider.family<
      List<ProductModel>,
      (String businessId, String branchId)
    >((ref, params) async* {
      final (businessId, branchId) = params;
      final collectionPath =
          'businesses/$businessId/branches/$branchId/products';

      final syncService = RealtimeSyncService<ProductModel>(
        collectionPath: collectionPath,
        fromMap: (data, id) => ProductModel.fromMap(data, id),
      );

      await syncService.initialize();
      ref.onDispose(() => syncService.dispose());

      yield syncService.currentItems;
      await for (final items in syncService.itemsStream) {
        yield items;
      }
    });

// ==================== CATEGORIES ====================
final realtimeCategoriesProvider =
    StreamProvider.family<
      List<CategoryModel>,
      (String businessId, String branchId)
    >((ref, params) async* {
      final (businessId, branchId) = params;
      final collectionPath =
          'businesses/$businessId/branches/$branchId/categories';

      final syncService = RealtimeSyncService<CategoryModel>(
        collectionPath: collectionPath,
        fromMap: (data, id) => CategoryModel.fromMap(id, data),
      );

      await syncService.initialize();
      ref.onDispose(() => syncService.dispose());

      yield syncService.currentItems;
      await for (final items in syncService.itemsStream) {
        yield items;
      }
    });

// ==================== TABLES ====================
final realtimeTablesProvider =
    StreamProvider.family<
      List<TableModel>,
      (String businessId, String branchId)
    >((ref, params) async* {
      final (businessId, branchId) = params;
      final collectionPath =
          'businesses/$businessId/branches/$branchId/diningTables';

      final syncService = RealtimeSyncService<TableModel>(
        collectionPath: collectionPath,
        fromMap: (data, id) => TableModel.fromMap(data),
      );

      await syncService.initialize();
      ref.onDispose(() => syncService.dispose());

      yield syncService.currentItems;
      await for (final items in syncService.itemsStream) {
        yield items;
      }
    });

// ==================== ROOMS ====================
final realtimeRoomsProvider =
    StreamProvider.family<
      List<RoomModel>,
      (String businessId, String branchId)
    >((ref, params) async* {
      final (businessId, branchId) = params;
      final collectionPath = 'businesses/$businessId/branches/$branchId/rooms';

      final syncService = RealtimeSyncService<RoomModel>(
        collectionPath: collectionPath,
        fromMap: (data, id) => RoomModel.fromMap(data),
      );

      await syncService.initialize();
      ref.onDispose(() => syncService.dispose());

      yield syncService.currentItems;
      await for (final items in syncService.itemsStream) {
        yield items;
      }
    });

// ==================== MENUS ====================
final realtimeMenusProvider =
    StreamProvider.family<
      List<MenuModel>,
      (String businessId, String branchId)
    >((ref, params) async* {
      final (businessId, branchId) = params;
      final collectionPath = 'businesses/$businessId/branches/$branchId/menus';

      final syncService = RealtimeSyncService<MenuModel>(
        collectionPath: collectionPath,
        fromMap: (data, id) => MenuModel.fromMap(id, data),
      );

      await syncService.initialize();
      ref.onDispose(() => syncService.dispose());

      yield syncService.currentItems;
      await for (final items in syncService.itemsStream) {
        yield items;
      }
    });

// ==================== HELPER NOTES ====================
// To use in UI:
// final orders = ref.watch(realtimeOrdersProvider((businessId, branchId)));
// orders.when(
//   data: (list) => Text('${list.length} items'),
//   loading: () => CircularProgressIndicator(),
//   error: (err, st) => Text('Error: $err'),
// )
