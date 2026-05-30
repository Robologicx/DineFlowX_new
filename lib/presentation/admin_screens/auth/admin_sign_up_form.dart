import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_text_field.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class AdminSignUpForm extends ConsumerStatefulWidget {
  const AdminSignUpForm({super.key});

  @override
  ConsumerState<AdminSignUpForm> createState() => _AdminSignUpFormState();
}

class _AdminSignUpFormState extends ConsumerState<AdminSignUpForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void signUp(BuildContext context) async {
    //take instance of user repo to check if user exists
    final existingUser = await SignUpHelper.checkUserExistsByEmail(
      emailController.text,
    );
    if (existingUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User with this email already exists')),
      );
      if (existingUser.isStaffMember == true) {
        // Means admin/owner already created this user as staff member
        // Now just need to complete signup by setting password
        // and loading complete user data
        final FirebaseAuth auth = FirebaseAuth.instance;
        final userCred = await auth.createUserWithEmailAndPassword(
          email: emailController.text,
          password: passwordController.text,
        );
        // User properly signed up? If not, throw exception
        if (userCred.user == null) {
          throw Exception('Signup failed');
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('User created')));
        }
        // Lets complete signup by loading complete user data
        // await SignUpHelper.completeUserSignup(
        //   uid: existingUser.uid,
        //   email: emailController.text,
        //   name: nameController.text,
        //   ref: ref, businessId: '', branchId: '', phone: '',
        // );
        // Navigator.of(context).pop();
        // return;
      }
    }
    // Proceed with additional setup for the new user

    Navigator.of(context).pop();
    final state = ref.read(authNotifierProvider);
    if (state.isLoggedIn) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AdminAppRoutes.splash,
        (route) => false,
      );
    } else if (state.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(state.error!)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(27.0),
        child: Column(
          children: [
            CustomTextField(
              keyBoardType: TextInputType.name,
              hint: 'Name',
              controller: nameController,
            ),
            SizedBox(height: 20),
            CustomTextField(
              keyBoardType: TextInputType.emailAddress,
              hint: 'Email Address',
              controller: emailController,
            ),
            SizedBox(height: 20),
            CustomTextField(
              keyBoardType: TextInputType.visiblePassword,
              hint: 'Password',
              controller: passwordController,
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Already have an account ?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: 20),
            CustomButton(
              text: 'SignUp',
              onTap: () {
                signUp(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Helper Functions for SignUp Screen - Riverpod Version
/// These functions handle the staff member signup flow using Riverpod

class SignUpHelper {
  /// Check if user exists by email in root users collection
  /// Returns UserModel if found, null otherwise
  static Future<UserModel?> checkUserExistsByEmail(String email) async {
    try {
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return UserModel.fromMap(doc.id, doc.data());
      }
      return null;
    } catch (e) {
      print('Error checking user by email: $e');
      rethrow;
    }
  }

  /// Load complete user data with role and permissions using Riverpod
  /// This uses your existing getUser() which merges everything
  static Future<UserModel?> loadCompleteUserData(
    String uid,
    WidgetRef ref,
  ) async {
    try {
      final userService = ref.read(userProvider.notifier);
      final user = await userService.loadUser(uid);
      final userState = ref.read(userProvider);
      if (userState.error != null) {
        if (userState.selectedUser != null) {
          return userState.selectedUser;
        } else {
          return null;
        }
      }
    } catch (e) {
      print('Error loading complete user data: $e');
      rethrow;
    }
    return null;
  }

  /// Complete user signup - update name and phone using Riverpod
  /// Call this when staff member fills the signup form
  /// Returns true on success, false on failure
  static Future<bool> completeUserSignup({
    required String uid,
    required String businessId,
    required String branchId,
    required String? name,
    required String? phone,
    required WidgetRef ref,
  }) async {
    try {
      final userNotifier = ref.read(userProvider.notifier);
      // Update staff member with name and phone
      final success = await userNotifier.updateStaffMember(
        uid: uid,
        roleId: '', // Will be fetched from current user
        extraPermissions: {}, // Will be fetched from current user
        businessId: businessId,
        branchId: branchId,
        name: name,
        phoneNumber: phone,
      );

      return success;
    } catch (e) {
      print('Error completing signup: $e');
      return false;
    }
  }

  /// Get user's business and branch info using Riverpod
  /// Used to know which business/branch the user belongs to
  static Future<({String businessId, String branchId})?>
  getUserBusinessBranchInfo(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data();
        final businessId = data?['primarybusinessId'] as String?;
        final branchId = data?['primaryBranchId'] as String?;

        if (businessId != null && branchId != null) {
          return (businessId: businessId, branchId: branchId);
        }
      }
      return null;
    } catch (e) {
      print('Error getting user business/branch info: $e');
      return null;
    }
  }

  /// Get current staff user role and permissions using Riverpod
  /// Used to preserve role/permissions when updating profile
  static Future<({String roleId, Map<String, String> extraPermissions})?>
  getUserRoleAndPermissions(String uid, WidgetRef ref) async {
    try {
      final userService = ref.read(userProvider.notifier);

      // Get business/branch info first
      final businessBranch = await getUserBusinessBranchInfo(uid);

      if (businessBranch == null) {
        return null;
      }

      // Fetch branch-specific user info (role + permissions)
      final branchUserInfo = await userService.loadUser(uid);

      // if (branchUserInfo == null) {
      //   return null;
      // }

      // return (
      //   roleId: branchUserInfo.role.id,
      //   extraPermissions: branchUserInfo.extraPermissions,
      // );
    } catch (e) {
      print('Error getting user role and permissions: $e');
      return null;
    }
    return null;
  }

  /// Validate email format
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }
}
