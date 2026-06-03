import 'package:hotel_management_system/features/super_admin/domain/entities/super_admin_entities.dart';

abstract class SuperAdminRepository {
  Stream<PlatformKpi> watchPlatformKpi();
  Stream<List<TrendPoint>> watchMonthlyOrdersTrend();
  Stream<List<TrendPoint>> watchMonthlyRevenueTrend();
  Stream<List<BusinessTenantSummary>> watchBusinesses();

  Future<void> suspendBusiness(String businessId);
  Future<void> activateBusiness(String businessId);
  Future<void> deleteBusiness(String businessId);
  Future<void> updateBusiness(
    String businessId, {
    String? businessName,
    String? ownerName,
    String? ownerEmail,
    String? ownerPhone,
    String? industryType,
    String? country,
    String? city,
    String? subscriptionPlan,
    DateTime? subscriptionExpiry,
  });

  Future<String> createBusinessTenant(CreateBusinessRequest request);
}
