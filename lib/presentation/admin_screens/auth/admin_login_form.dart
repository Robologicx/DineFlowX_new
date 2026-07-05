import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_text_field.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';
import 'package:hotel_management_system/state_management/app_manager.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class AdminLoginForm extends ConsumerStatefulWidget {
  const AdminLoginForm({super.key});

  @override
  ConsumerState<AdminLoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<AdminLoginForm> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void login(BuildContext context) async {
    final authProvider = ref.read(authNotifierProvider.notifier);
    try {
      await authProvider.signIn(
        context,
        emailController.text.trim(),
        passwordController.text.trim(),
      );
      Navigator.of(context).pop(); // close loading only after completion

      final state = ref.read(authNotifierProvider);
      if (state.isLoggedIn) {
        ref.invalidate(appInitializationProvider);
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
    } catch (e) {
      Navigator.of(context).pop(); // Close dialog if it crashes
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
              keyBoardType: TextInputType.emailAddress,
              hint: 'Email Address',
              controller: emailController,
            ),
            SizedBox(height: 50),
            CustomTextField(
              keyBoardType: TextInputType.visiblePassword,
              hint: 'Password',
              isObsecure: true,
              controller: passwordController,
            ),
            SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Forget password ?',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            SizedBox(height: 50),
            CustomButton(
              text: 'Login',
              onTap: () {
                try {
                  showDialog(
                    context: context,
                    builder: (_) =>
                        const Center(child: CircularProgressIndicator()),
                  );
                  login(context);
                } on FirebaseAuthException catch (e) {
                  log(e.message!);
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(e.message!)));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
