// Add this to your state management
import 'package:flutter_riverpod/flutter_riverpod.dart';

final directDiningProvider = StateProvider<DirectDiningState>((ref) {
  return DirectDiningState();
});

class DirectDiningState {
  final String? tableId;
  final String? businessId;
  final String? branchId;

  const DirectDiningState({this.tableId, this.businessId, this.branchId});

  DirectDiningState copyWith({
    String? tableId,
    String? businessId,
    String? branchId,
  }) {
    return DirectDiningState(
      tableId: tableId ?? this.tableId,
      businessId: businessId ?? this.businessId,
      branchId: branchId ?? this.branchId,
    );
  }
}
