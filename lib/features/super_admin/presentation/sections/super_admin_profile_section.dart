import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/services/auth_service.dart';
import 'package:hotel_management_system/features/super_admin/application/super_admin_providers.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';

class SuperAdminProfileSection extends ConsumerStatefulWidget {
  const SuperAdminProfileSection({super.key});

  @override
  ConsumerState<SuperAdminProfileSection> createState() =>
      _SuperAdminProfileSectionState();
}

class _SuperAdminProfileSectionState
    extends ConsumerState<SuperAdminProfileSection> {
  final TextEditingController _displayNameController = TextEditingController();
  bool _isSavingProfile = false;

  @override
  void dispose() {
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _refreshUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await user.reload();
    ref.invalidate(superAdminAuthUserProvider);
  }

  Future<void> _saveProfile(User user) async {
    final newName = _displayNameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Display name is required.')),
      );
      return;
    }

    setState(() => _isSavingProfile = true);
    try {
      await user.updateDisplayName(newName);
      await user.reload();
      ref.invalidate(superAdminAuthUserProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to update profile.'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        var isSubmitting = false;
        var showCurrentPassword = false;
        var showNewPassword = false;
        var showConfirmPassword = false;

        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> submit() async {
              if (isSubmitting) return;
              if (!formKey.currentState!.validate()) return;

              setDialogState(() => isSubmitting = true);
              try {
                await AuthService().changePassword(
                  currentPassword: currentPasswordController.text.trim(),
                  newPassword: newPasswordController.text.trim(),
                );

                if (!mounted) return;
                Navigator.of(dialogContext).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Password updated successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } on FirebaseAuthException catch (e) {
                if (!mounted) return;
                setDialogState(() => isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(e.message ?? 'Failed to change password.'),
                    backgroundColor: Colors.red,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setDialogState(() => isSubmitting = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to change password: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Change Password'),
              content: Form(
                key: formKey,
                child: SizedBox(
                  width: 420,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: currentPasswordController,
                        obscureText: !showCurrentPassword,
                        decoration: InputDecoration(
                          labelText: 'Current Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showCurrentPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                showCurrentPassword = !showCurrentPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Current password is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPasswordController,
                        obscureText: !showNewPassword,
                        decoration: InputDecoration(
                          labelText: 'New Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showNewPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                showNewPassword = !showNewPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          final password = value?.trim() ?? '';
                          if (password.isEmpty) {
                            return 'New password is required';
                          }
                          if (password.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          if (password ==
                              currentPasswordController.text.trim()) {
                            return 'New password must be different';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPasswordController,
                        obscureText: !showConfirmPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirm New Password',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: Icon(
                              showConfirmPassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setDialogState(() {
                                showConfirmPassword = !showConfirmPassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if ((value?.trim() ?? '') !=
                              newPasswordController.text.trim()) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSubmitting ? null : submit,
                  child: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Update Password'),
                ),
              ],
            );
          },
        );
      },
    );

    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
  }

  Future<void> _sendPasswordResetEmail(User user) async {
    final email = user.email?.trim();
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No email found for this account.')),
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password reset email sent to $email'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? 'Failed to send reset email.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _signOut() async {
    await AuthService().signOut();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AdminAppRoutes.login,
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUserAsync = ref.watch(superAdminAuthUserProvider);

    return authUserAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Failed to load profile: $error')),
      data: (user) {
        if (user == null) {
          return Center(
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AdminAppRoutes.login,
                  (_) => false,
                );
              },
              icon: const Icon(Icons.login),
              label: const Text('Go to Login'),
            ),
          );
        }

        final displayName = (user.displayName ?? '').trim();
        if (_displayNameController.text.trim() != displayName) {
          _displayNameController.text = displayName;
        }

        final metadata = user.metadata;
        final providers =
            user.providerData.map((p) => p.providerId).toSet().toList()..sort();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Profile', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(
              'Manage your super admin account profile and security settings.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Card(
              child: ExpansionTile(
                initiallyExpanded: true,
                leading: const Icon(Icons.verified_user_outlined),
                title: const Text('Profile Details'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Display Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user.email ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user.uid,
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'UID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      onPressed: _isSavingProfile
                          ? null
                          : () => _saveProfile(user),
                      icon: _isSavingProfile
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.save_outlined),
                      label: const Text('Save Profile'),
                    ),
                  ),
                ],
              ),
            ),
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Password / MFA'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  const ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Multi-factor authentication'),
                    subtitle: Text(
                      'MFA enrollment controls can be added from Firebase console-integrated flow.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      FilledButton.icon(
                        onPressed: _showChangePasswordDialog,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Change Password'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _sendPasswordResetEmail(user),
                        icon: const Icon(Icons.mark_email_read_outlined),
                        label: const Text('Send Reset Email'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.history_toggle_off),
                title: const Text('Session History'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: [
                  _infoRow(
                    context,
                    'Last Sign In',
                    _formatDateTime(metadata.lastSignInTime),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    'Account Created',
                    _formatDateTime(metadata.creationTime),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    'Email Verified',
                    user.emailVerified ? 'Yes' : 'No',
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    context,
                    'Sign-in Providers',
                    providers.isEmpty ? '-' : providers.join(', '),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _refreshUser,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh Session Info'),
                      ),
                      TextButton.icon(
                        onPressed: _signOut,
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 160,
          child: Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(value)),
      ],
    );
  }

  String _formatDateTime(DateTime? dt) {
    if (dt == null) return '-';
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
