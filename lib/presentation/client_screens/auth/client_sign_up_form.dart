import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_text_field.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class ClientSignUpForm extends ConsumerStatefulWidget {
  const ClientSignUpForm({super.key});

  @override
  ConsumerState<ClientSignUpForm> createState() => _ClientSignUpFormState();
}

class _ClientSignUpFormState extends ConsumerState<ClientSignUpForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    nameController.dispose();
    addressController.dispose();
    phoneController.dispose();
    super.dispose();
  }

  // Validator methods
  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value.trim())) {
      return 'Name can only contain letters and spaces';
    }
    return null;
  }

  String? _validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your delivery address';
    }
    if (value.trim().length < 10) {
      return 'Address must be at least 10 characters long';
    }
    // Basic address validation - should contain numbers and letters
    if (!RegExp(r'^(?=.*[0-9])(?=.*[a-zA-Z]).{10,}$').hasMatch(value.trim())) {
      return 'Please enter a valid address with street number and name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain at least one uppercase letter, one lowercase letter and one number';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your phone number';
    }

    // Remove any spaces, dashes, parentheses, etc.
    final cleanedPhone = value.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');

    // Check if it contains only digits and optional + at start
    if (!RegExp(r'^\+?[0-9]{8,15}$').hasMatch(cleanedPhone)) {
      return 'Please enter a valid phone number (8-15 digits)';
    }

    // Check minimum length after cleaning
    if (cleanedPhone.length < 8) {
      return 'Phone number must be at least 8 digits long';
    }

    // Check maximum length after cleaning
    if (cleanedPhone.length > 15) {
      return 'Phone number must not exceed 15 digits';
    }

    // Check if it starts with country code (optional + followed by digits)
    if (!RegExp(r'^\+?[0-9]+$').hasMatch(cleanedPhone)) {
      return 'Phone number can only contain digits and optional + prefix';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);

    Future<void> handleSignUp() async {
      if (formKey.currentState!.validate()) {
        final notifier = ref.read(authNotifierProvider.notifier);
        await notifier.signUp(
          emailController.text.trim(),
          passwordController.text.trim(),
        );

        final newState = ref.read(authNotifierProvider);

        if (newState.firebaseUser != null) {
          await ref
              .read(userProvider.notifier)
              .createUser(
                UserModel(
                  uid: newState.firebaseUser!.uid,
                  name: nameController.text,
                  email: emailController.text,
                  phoneNumber: phoneController.text,
                  userLocationText: addressController.text,
                  role: RoleModel(
                    id: newState.firebaseUser!.uid,
                    businessId: BusinessRepository.temporaryBusinesshId,
                    name: nameController.text,
                    permissions: [],
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                  extraPermissions: {},
                  primarybusinessId: BusinessRepository.temporaryBusinesshId,
                  primaryBranchId: BusinessRepository.temporaryBranchId,
                ),
              );
          // ✅ Signup success
          context.goNamed(ClientAppRoutes.shell);
        } else if (newState.error != null) {
          // ❌ Signup failed
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(newState.error!)));
        }
      }
    }

    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(27.0),
        child: Column(
          spacing: MediaQuery.sizeOf(context).height * 0.02,
          children: [
            CustomTextField(
              keyBoardType: TextInputType.name,
              hint: 'Name',
              validator: _validateName,
              controller: nameController,
            ),
            CustomTextField(
              keyBoardType: TextInputType.streetAddress,
              hint: 'Delivery Address',
              controller: addressController,
              validator: _validateAddress,
            ),
            CustomTextField(
              keyBoardType: TextInputType.phone,
              hint: 'Phone Number with Country code',
              controller: phoneController,
              validator: _validatePhone,
            ),
            CustomTextField(
              keyBoardType: TextInputType.emailAddress,
              hint: 'Email Address',
              controller: emailController,
              validator: _validateEmail,
            ),
            CustomTextField(
              keyBoardType: TextInputType.visiblePassword,
              hint: 'Password',
              validator: _validatePassword,
              isObsecure: true,
              controller: passwordController,
            ),
            CustomButton(
              text: authState.isLoading ? 'Signing Up...' : 'Sign Up',
              onTap: authState.isLoading ? () {} : handleSignUp,
            ),
          ],
        ),
      ),
    );
  }
}
