import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_text_field.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class ClientLoginForm extends ConsumerStatefulWidget {
  const ClientLoginForm({super.key});

  @override
  ConsumerState<ClientLoginForm> createState() => _ClientLoginFormState();
}

class _ClientLoginFormState extends ConsumerState<ClientLoginForm> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.all(27.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomTextField(
              keyBoardType: TextInputType.emailAddress,
              hint: 'Email Address',
              controller: emailController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                  return 'Enter a valid email address';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            CustomTextField(
              isObsecure: true,
              keyBoardType: TextInputType.visiblePassword,
              hint: 'Password',
              controller: passwordController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  // TODO: Implement Forgot Password
                },
                child: Text(
                  'Forgot password?',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 25),
            CustomButton(
              text: authState.isLoading ? 'Logging in...' : 'Login',
              onTap: authState.isLoading
                  ? () {}
                  : () async {
                      FocusScope.of(context).unfocus(); // hide keyboard
                      if (formKey.currentState!.validate()) {
                        final notifier = ref.read(
                          authNotifierProvider.notifier,
                        );
                        await notifier.signIn(
                          context,
                          emailController.text.trim(),
                          passwordController.text.trim(),
                        );
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
