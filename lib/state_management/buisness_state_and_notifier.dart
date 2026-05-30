import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/buisness_model.dart';
import 'package:hotel_management_system/data/services/buisness_service.dart';

class BusinessState {
  final List<BusinessModel> businesses;
  final BusinessModel? selectedBusiness;
  final bool isLoading;
  final String? error;

  BusinessState({
    this.businesses = const [],
    this.selectedBusiness,
    this.isLoading = false,
    this.error,
  });

  BusinessState copyWith({
    List<BusinessModel>? businesses,
    BusinessModel? selectedBusiness,
    bool? isLoading,
    String? error,
  }) {
    return BusinessState(
      businesses: businesses ?? this.businesses,
      selectedBusiness: selectedBusiness ?? this.selectedBusiness,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

//-------------------Create method for selected business-------------------//
//
// i,e selectedHotelId, selectedResturant, selectedCafe etc
//
//
//-------------------Create method for selected business-------------------//

class BusinessNotifier extends StateNotifier<BusinessState> {
  final BusinessService _service;

  BusinessNotifier(this._service) : super(BusinessState());

  Future<void> loadBusinesses({String? ownerId}) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final list = await _service.getBusinesses(ownerId: ownerId);
      state = state.copyWith(businesses: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectBusiness(String id) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final business = await _service.getBusinessById(id);
      state = state.copyWith(selectedBusiness: business, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  BusinessModel? getSelectedBusiness() {
    return state.selectedBusiness;
  }

  Future<void> addBusiness(BusinessModel business) async {
    try {
      await _service.createBusiness(business);
      await loadBusinesses(); // refresh list
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateBusiness(BusinessModel business) async {
    try {
      await _service.updateBusiness(business);
      await loadBusinesses();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> softDeleteBusiness(String id) async {
    try {
      await _service.softDeleteBusiness(id);
      await loadBusinesses();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
