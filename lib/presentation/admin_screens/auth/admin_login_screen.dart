import 'package:flutter/material.dart';
import 'package:hotel_management_system/presentation/admin_screens/auth/admin_login_form.dart';
import 'package:hotel_management_system/presentation/admin_screens/auth/admin_sign_up_form.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  height: 382,
                  width: 400,
                  child: Center(
                    child: Image.asset(
                      'assets/images/app_icon.PNG',
                      fit: BoxFit.cover,
                      height: 200,
                      width: 200,
                    ),
                  ),
                ),
                TabBar(
                  tabs: [
                    Tab(text: 'Login'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SingleChildScrollView(child: AdminLoginForm()),
                  SingleChildScrollView(child: AdminSignUpForm()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
