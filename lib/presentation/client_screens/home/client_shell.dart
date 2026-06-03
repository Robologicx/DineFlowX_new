import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_home_screen.dart';
import 'package:hotel_management_system/presentation/client_screens/home/client_drawer_menu_screen.dart';
import 'package:hotel_management_system/presentation/common_widgets/app_drawer.dart';
import 'package:hotel_management_system/state_management/direct_dining_state.dart';
import 'package:hotel_management_system/state_management/tenant_context_provider.dart';

class ClientHomeShell extends ConsumerStatefulWidget {
  final String? tableId;
  final String? businessId;
  final String? branchId;

  const ClientHomeShell({
    super.key,
    this.tableId,
    this.businessId,
    this.branchId,
  });

  @override
  ConsumerState<ClientHomeShell> createState() => _ClientHomeShellState();
}

class _ClientHomeShellState extends ConsumerState<ClientHomeShell> {
  final ZoomDrawerController _drawerController = ZoomDrawerController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final businessId = widget.businessId?.trim() ?? '';
      final branchId = widget.branchId?.trim() ?? '';
      final tableId = widget.tableId?.trim() ?? '';

      if (businessId.isNotEmpty && branchId.isNotEmpty) {
        ref
            .read(tenantContextProvider.notifier)
            .setContext(tenantId: businessId, branchId: branchId);
      }

      if (tableId.isNotEmpty && businessId.isNotEmpty && branchId.isNotEmpty) {
        ref.read(directDiningProvider.notifier).state = DirectDiningState(
          tableId: tableId,
          businessId: businessId,
          branchId: branchId,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isQrGuestSession =
        (widget.tableId?.trim().isNotEmpty ?? false) &&
        (widget.businessId?.trim().isNotEmpty ?? false) &&
        (widget.branchId?.trim().isNotEmpty ?? false);

    if (isQrGuestSession) {
      return ClientHomeScreen(
        drawerController: _drawerController,
        forceBusinessId: widget.businessId,
        forceBranchId: widget.branchId,
        forceTableId: widget.tableId,
      );
    }

    return AppDrawer(
      controller: _drawerController,
      mainScreen: ClientHomeScreen(drawerController: _drawerController),
      menuScreen: ClientDrawerMeuScreen(),
    );
    // return ZoomDrawer(
    //   controller: _drawerController,
    //   style: DrawerStyle.defaultStyle,
    //   menuScreen: DrawerMenuScreen(),
    //   mainScreen: ClientHomeScreen(drawerController: _drawerController),
    // );
  }
}
