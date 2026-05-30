import 'package:hotel_management_system/data/models/buisness_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';

class BusinessService {
  final BusinessRepository _repository;

  BusinessService(this._repository);

  /// Create new business
  Future<void> createBusiness(BusinessModel business) async {
    if (business.id.isEmpty) {
      throw Exception("Business ID is required");
    }
    await _repository.createBusiness(business);
  }

  /// Get single business by ID
  Future<BusinessModel?> getBusinessById(String id) async {
    return await _repository.getBusinessById(id);
  }

  /// Get all businesses (with optional filter by owner)
  Future<List<BusinessModel>> getBusinesses({String? ownerId}) async {
    return await _repository.getBusinessesByOwner(ownerId.toString());
  }

  /// Update business details
  Future<void> updateBusiness(BusinessModel business) async {
    await _repository.updateBusiness(business);
  }

  /// Soft delete (mark as deleted, not remove from DB)
  Future<void> softDeleteBusiness(String id) async {
    await _repository.softDeleteBusiness(id);
  }
}
