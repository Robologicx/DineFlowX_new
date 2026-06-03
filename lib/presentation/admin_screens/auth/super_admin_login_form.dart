import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_text_field.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';

class SuperAdminLoginForm extends StatefulWidget {
  const SuperAdminLoginForm({super.key});

  @override
  State<SuperAdminLoginForm> createState() => _SuperAdminLoginFormState();
}

class _SuperAdminLoginFormState extends State<SuperAdminLoginForm> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _loading = false;

  static const _superAdminDomain = '@robologicx.com';
  static const _bootstrapSuperAdminEmail = 'info.robologicx@gmail.com';

  @override
  void initState() {
    super.initState();
    _emailController.text = _bootstrapSuperAdminEmail;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loginSuperAdmin() async {
    final email = _bootstrapSuperAdminEmail;
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      _showMessage('Password is required.');
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = FirebaseAuth.instance;
      await auth.signInWithEmailAndPassword(email: email, password: password);

      final user = auth.currentUser;
      if (user == null) {
        _showMessage('Unable to load authenticated user.');
        return;
      }

      final token = await user.getIdTokenResult(true);
      final hasClaim = token.claims?['superAdmin'] == true;
      final isRoboLogicxDomain = (user.email ?? '').toLowerCase().endsWith(
        _superAdminDomain,
      );
      var isAllowlisted = await _hasSuperAdminAllowlistEntry(user.uid);

      if (!hasClaim && !isRoboLogicxDomain && !isAllowlisted) {
        isAllowlisted = await _ensureBootstrapAllowlistEntry(user);
      }

      if (!hasClaim && !isRoboLogicxDomain && !isAllowlisted) {
        await auth.signOut();
        _showMessage('This account is not authorized as Super Admin.');
        return;
      }

      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(
        context,
        AdminAppRoutes.superAdmin,
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      _showMessage(e.message ?? 'Super Admin login failed.');
    } catch (e) {
      _showMessage('Super Admin login failed: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createSuperAdminId() async {
    final email = _bootstrapSuperAdminEmail;
    final password = _passwordController.text.trim();

    if (password.isEmpty) {
      _showMessage('Password is required.');
      return;
    }

    if (password.length < 8) {
      _showMessage('Password must be at least 8 characters.');
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = FirebaseAuth.instance;
      final credential = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      await credential.user?.updateDisplayName('RoboLogicx Super Admin');
      final createdUser = credential.user;
      if (createdUser != null) {
        await FirebaseFirestore.instance
            .collection('super_admins')
            .doc(createdUser.uid)
            .set({
              'uid': createdUser.uid,
              'email': email,
              'isActive': true,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
      }
      _showMessage('Super Admin ID created successfully. You can now login.');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showMessage('This super admin email already exists. Please login.');
      } else {
        _showMessage(e.message ?? 'Failed to create super admin ID.');
      }
    } catch (e) {
      _showMessage('Failed to create super admin ID: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _hasSuperAdminAllowlistEntry(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('super_admins')
        .doc(uid)
        .get();
    if (!doc.exists) return false;
    final data = doc.data() ?? const <String, dynamic>{};
    return data['isActive'] == true;
  }

  Future<bool> _ensureBootstrapAllowlistEntry(User user) async {
    final email = (user.email ?? '').toLowerCase();
    if (email != _bootstrapSuperAdminEmail) {
      return false;
    }

    await FirebaseFirestore.instance
        .collection('super_admins')
        .doc(user.uid)
        .set({
          'uid': user.uid,
          'email': email,
          'isActive': true,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

    return true;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(27),
      child: Column(
        children: [
          TextFormField(
            controller: _emailController,
            readOnly: true,
            decoration: InputDecoration(
              labelText: 'Super Admin Email',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            keyBoardType: TextInputType.visiblePassword,
            hint: 'Password',
            controller: _passwordController,
            isObsecure: true,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Super Admin email is fixed. Enter password from Firebase Authentication.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 30),
          CustomButton(
            text: _loading ? 'Logging in...' : 'Login as Super Admin',
            onTap: _loading ? () {} : _loginSuperAdmin,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _loading ? null : _createSuperAdminId,
            child: Text(_loading ? 'Please wait...' : 'Create Super Admin ID'),
          ),
        ],
      ),
    );
  }
}
