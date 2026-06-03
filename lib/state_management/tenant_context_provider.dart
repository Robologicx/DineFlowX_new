import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/user_state_and_notifier.dart';

class TenantContext {
  final String tenantId;
  final String businessId;
  final String branchId;
  final bool fromAuthenticatedUser;

  const TenantContext({
    required this.tenantId,
    required this.businessId,
    required this.branchId,
    required this.fromAuthenticatedUser,
  });

  TenantContext copyWith({
    String? tenantId,
    String? businessId,
    String? branchId,
    bool? fromAuthenticatedUser,
  }) {
    return TenantContext(
      tenantId: tenantId ?? this.tenantId,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
      fromAuthenticatedUser:
          fromAuthenticatedUser ?? this.fromAuthenticatedUser,
    );
  }
}

class TenantContextNotifier extends StateNotifier<TenantContext> {
  TenantContextNotifier()
    : super(
        TenantContext(
          tenantId: BusinessRepository.temporaryBusinesshId,
          businessId: BusinessRepository.temporaryBusinesshId,
          branchId: BusinessRepository.temporaryBranchId,
          fromAuthenticatedUser: false,
        ),
      );

  void hydrateFromUser(UserState userState) {
    final user = userState.selectedUser;
    if (user == null) return;
    if (user.primarybusinessId.isEmpty || user.primaryBranchId.isEmpty) return;

    state = TenantContext(
      tenantId: user.primarybusinessId,
      businessId: user.primarybusinessId,
      branchId: user.primaryBranchId,
      fromAuthenticatedUser: true,
    );
  }

  void setContext({required String tenantId, required String branchId}) {
    state = state.copyWith(
      tenantId: tenantId,
      businessId: tenantId,
      branchId: branchId,
      fromAuthenticatedUser: false,
    );
  }
}

final tenantContextProvider =
    StateNotifierProvider<TenantContextNotifier, TenantContext>((ref) {
      final notifier = TenantContextNotifier();

      notifier.hydrateFromUser(ref.read(userProvider));
      ref.listen<UserState>(userProvider, (previous, next) {
        notifier.hydrateFromUser(next);
      });

      return notifier;
    });
