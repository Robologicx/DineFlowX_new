import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/buisness_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/tenant_context_provider.dart';

final currentTenantBusinessProvider = StreamProvider<BusinessModel?>((ref) {
  final tenantBusinessId = ref.watch(
    tenantContextProvider.select((tenant) => tenant.businessId.trim()),
  );
  final userBusinessId = ref.watch(
    userProvider.select(
      (state) => state.selectedUser?.primarybusinessId.trim() ?? '',
    ),
  );

  final fallbackBusinessId = BusinessRepository.temporaryBusinesshId.trim();
  final businessId = tenantBusinessId.isNotEmpty
      ? tenantBusinessId
      : (userBusinessId.isNotEmpty ? userBusinessId : fallbackBusinessId);

  if (businessId.isEmpty) {
    return Stream.value(null);
  }

  final repository = BusinessRepository();
  return repository.listenToBusiness(businessId);
});
