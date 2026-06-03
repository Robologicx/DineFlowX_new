class PlatformKpi {
  final int totalBusinesses;
  final int activeBusinesses;
  final int suspendedBusinesses;
  final int expiredSubscriptions;
  final int totalBranches;
  final int totalStaffUsers;
  final int totalOrdersToday;
  final int totalOrdersThisMonth;
  final double totalRevenueThisMonth;
  final double totalRevenueThisYear;
  final double platformGrowthPercent;
  final double averageOrdersPerBusiness;
  final double averageRevenuePerBusiness;

  const PlatformKpi({
    required this.totalBusinesses,
    required this.activeBusinesses,
    required this.suspendedBusinesses,
    required this.expiredSubscriptions,
    required this.totalBranches,
    required this.totalStaffUsers,
    required this.totalOrdersToday,
    required this.totalOrdersThisMonth,
    required this.totalRevenueThisMonth,
    required this.totalRevenueThisYear,
    required this.platformGrowthPercent,
    required this.averageOrdersPerBusiness,
    required this.averageRevenuePerBusiness,
  });

  factory PlatformKpi.empty() {
    return const PlatformKpi(
      totalBusinesses: 0,
      activeBusinesses: 0,
      suspendedBusinesses: 0,
      expiredSubscriptions: 0,
      totalBranches: 0,
      totalStaffUsers: 0,
      totalOrdersToday: 0,
      totalOrdersThisMonth: 0,
      totalRevenueThisMonth: 0,
      totalRevenueThisYear: 0,
      platformGrowthPercent: 0,
      averageOrdersPerBusiness: 0,
      averageRevenuePerBusiness: 0,
    );
  }
}

class TrendPoint {
  final String label;
  final double value;

  const TrendPoint({required this.label, required this.value});
}

class BusinessTenantSummary {
  final String businessId;
  final String businessName;
  final DateTime? createdAt;
  final String ownerName;
  final String email;
  final String phone;
  final String industryType;
  final String country;
  final String city;
  final int branches;
  final int users;
  final String subscriptionPlan;
  final DateTime? expiryDate;
  final double monthlyRevenue;
  final int totalOrders;
  final String status;

  const BusinessTenantSummary({
    required this.businessId,
    required this.businessName,
    required this.createdAt,
    required this.ownerName,
    required this.email,
    required this.phone,
    required this.industryType,
    required this.country,
    required this.city,
    required this.branches,
    required this.users,
    required this.subscriptionPlan,
    required this.expiryDate,
    required this.monthlyRevenue,
    required this.totalOrders,
    required this.status,
  });
}

class CreateBusinessRequest {
  final String businessName;
  final String industryType;
  final String country;
  final String city;
  final String ownerName;
  final String ownerEmail;
  final String ownerPhone;
  final String ownerPassword;
  final String selectedPlan;
  final int maxBranches;
  final int maxUsers;
  final int maxOrdersPerMonth;
  final int storageLimitMb;
  final bool qrOrderingEnabled;
  final bool onlineOrderingEnabled;
  final bool customerAppEnabled;
  final bool hotelModuleEnabled;
  final bool inventoryModuleEnabled;

  const CreateBusinessRequest({
    required this.businessName,
    required this.industryType,
    required this.country,
    required this.city,
    required this.ownerName,
    required this.ownerEmail,
    required this.ownerPhone,
    required this.ownerPassword,
    required this.selectedPlan,
    required this.maxBranches,
    required this.maxUsers,
    required this.maxOrdersPerMonth,
    required this.storageLimitMb,
    required this.qrOrderingEnabled,
    required this.onlineOrderingEnabled,
    required this.customerAppEnabled,
    required this.hotelModuleEnabled,
    required this.inventoryModuleEnabled,
  });
}
