import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/core/utils/currency_formatter.dart';
import 'package:hotel_management_system/state_management/current_tenant_business_provider.dart';

final tenantCurrencyCodeProvider = Provider<String>((ref) {
  final businessAsync = ref.watch(currentTenantBusinessProvider);
  final currencyCode = businessAsync.maybeWhen(
    data: (business) => business?.currencyCode,
    orElse: () => CurrencyFormatter.usd,
  );
  return CurrencyFormatter.normalizeCode(currencyCode);
});
