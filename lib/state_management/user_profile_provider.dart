import 'package:hotel_management_system/data/models/permission_model.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:riverpod/riverpod.dart';

class UserProfileNotifier extends StateNotifier<UserModel> {
  UserProfileNotifier()
    : super(
        UserModel(
          name: "Marvis Ighedosa",
          email: "test@gmail.com",
          phoneNumber: '+92308156789234',
          uid: '',
          userLocationText: 'abcdefghijklmno',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          role: RoleModel(
            id: '',
            name: 'Manager',
            permissions: <PermissionModel>[],
            businessId: '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          extraPermissions: <String, String>{},
          primaryBranchId: BusinessRepository.temporaryBranchId,
          primarybusinessId: BusinessRepository.temporaryBranchId,
        ),
      );

  void updateName({required String name}) {
    state = state.copyWith(name: name);
  }

  void updateEmail({required String email}) {
    state = state.copyWith(email: email);
  }

  void updatePhone({required String phone}) {
    state = state.copyWith(phoneNumber: phone);
  }

  void updateAddress({required String address}) {
    state = state.copyWith(userLocationText: address);
  }
}

// Provider
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserModel>((ref) {
      return UserProfileNotifier();
    });
