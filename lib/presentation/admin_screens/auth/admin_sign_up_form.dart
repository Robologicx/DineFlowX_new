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
  bool _isSubmitting = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    super.dispose();
  }

  void signUp(BuildContext context) async {
    if (_isSubmitting) return;
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final FirebaseAuth auth = FirebaseAuth.instance;
      final userCred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final authUser = userCred.user;
      if (authUser == null) {
        throw Exception('Signup failed');
      }

      final pendingStaff = await SignUpHelper.findPendingStaffByEmail(
        email,
      ).timeout(const Duration(seconds: 6), onTimeout: () => null);

      if (pendingStaff != null) {
        try {
          await SignUpHelper.claimPendingStaffForAuthUser(
            authUid: authUser.uid,
            email: email,
            displayName: name,
            pendingStaff: pendingStaff,
          );
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') {
            rethrow;
          }
        }
      } else {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(authUser.uid)
            .set({
              'uid': authUser.uid,
              'email': email,
              'name': name,
              'isStaffMember': false,
              'primarybusinessId': '',
              'primaryBranchId': '',
              'createdAt': DateTime.now().toIso8601String(),
              'updatedAt': DateTime.now().toIso8601String(),
            }, SetOptions(merge: true));
      }

      await ref.read(userProvider.notifier).loadUser(authUser.uid);

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AdminAppRoutes.splash,
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'Signup failed')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
              text: _isSubmitting ? 'Signing up...' : 'SignUp',
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
  /// Find pending invited staff record in branch users collection by email.
  static Future<
    ({
      String businessId,
      String branchId,
      String docId,
      Map<String, dynamic> data,
    })?
  >
  findPendingStaffByEmail(String email) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) return null;

    QuerySnapshot<Map<String, dynamic>> querySnapshot;
    try {
      querySnapshot = await FirebaseFirestore.instance
          .collectionGroup('users')
          .where('email', isEqualTo: normalizedEmail)
          .where('isStaffMember', isEqualTo: true)
          .limit(1)
          .get();
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') {
        return null;
      }
      rethrow;
    }

    if (querySnapshot.docs.isEmpty) return null;

    final doc = querySnapshot.docs.first;
    final segments = doc.reference.path.split('/');
    // businesses/{businessId}/branches/{branchId}/users/{uid}
    if (segments.length < 6 ||
        segments[0] != 'businesses' ||
        segments[2] != 'branches' ||
        segments[4] != 'users') {
      return null;
    }

    return (
      businessId: segments[1],
      branchId: segments[3],
      docId: doc.id,
      data: doc.data(),
    );
  }

  /// Bind pending branch-staff record to real Firebase Auth UID.
  static Future<void> claimPendingStaffForAuthUser({
    required String authUid,
    required String email,
    String? displayName,
    required ({
      String businessId,
      String branchId,
      String docId,
      Map<String, dynamic> data,
    })
    pendingStaff,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final businessId = pendingStaff.businessId;
    final branchId = pendingStaff.branchId;
    final sourceData = pendingStaff.data;

    final rootPayload = {
      'uid': authUid,
      'email': email,
      'name': (displayName != null && displayName.trim().isNotEmpty)
          ? displayName.trim()
          : (sourceData['name'] ?? ''),
      'phoneNumber': sourceData['phoneNumber'],
      'profileImageUrl': null,
      'primarybusinessId': businessId,
      'primaryBranchId': branchId,
      'isStaffMember': true,
      'favoriteProductIds': sourceData['favoriteProductIds'] ?? [],
      'userLocationText': sourceData['userLocationText'],
      'userLatlng': sourceData['userLatlng'],
      'deliveryAddresses': sourceData['deliveryAddresses'] ?? [],
      'updatedAt': nowIso,
      'createdAt': sourceData['createdAt'] ?? nowIso,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(authUid)
        .set(rootPayload, SetOptions(merge: true));

    final branchPayload = {
      ...sourceData,
      'uid': authUid,
      'email': email,
      'name': rootPayload['name'],
      'isStaffMember': true,
      'primarybusinessId': businessId,
      'primaryBranchId': branchId,
      'updatedAt': nowIso,
      'createdAt': sourceData['createdAt'] ?? nowIso,
    };

    final branchUsersRef = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('users');

    await branchUsersRef
        .doc(authUid)
        .set(branchPayload, SetOptions(merge: true));

    if (pendingStaff.docId != authUid) {
      await branchUsersRef.doc(pendingStaff.docId).delete();
    }
  }

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
