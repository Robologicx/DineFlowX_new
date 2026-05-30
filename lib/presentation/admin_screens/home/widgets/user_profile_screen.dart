// user_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/app_error_widget.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/loading_indicator.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool _isEditing = false;
  bool _isSaving = false;
  File? _selectedImage;
  // final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userState = ref.read(userProvider);
      if (userState.selectedUser != null) {
        _populateFields(userState.selectedUser!);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  void _populateFields(UserModel user) {
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _imageUrlController.text = user.profileImageUrl ?? '';
  }

  Future<void> _pickImage() async {
    try {
      // final XFile? image = await _picker.pickImage(
      //   source: ImageSource.gallery,
      //   maxWidth: 800,
      //   maxHeight: 800,
      //   imageQuality: 85,
      // );

      // if (image != null) {
      //   setState(() {
      //     _selectedImage = File(image.path);
      //   });
      // }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final userState = ref.read(userProvider);
      if (userState.selectedUser == null) return;

      final updatedUser = userState.selectedUser!.copyWith(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        profileImageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        updatedAt: DateTime.now(),
      );

      // Here you would call your update method
      await ref.read(userProvider.notifier).updateUser(updatedUser);

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _selectedImage = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<String> _getAllPermissions(UserModel user) {
    final allPermissions = <String>[];

    // Add role permissions
    for (final permission in user.role.permissions) {
      allPermissions.add(permission.name);
    }

    // Add extra permissions
    allPermissions.addAll(user.extraPermissions.values);

    // Remove duplicates and sort
    return allPermissions.toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final userNotifier = ref.read(userProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          if (!_isEditing && userState.selectedUser != null)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit Profile',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  _selectedImage = null;
                  if (userState.selectedUser != null) {
                    _populateFields(userState.selectedUser!);
                  }
                });
              },
              tooltip: 'Cancel',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: userState.selectedUser != null
                ? () => userNotifier.loadUser(userState.selectedUser!.uid)
                : null,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Error Display
          if (userState.error != null)
            AppErrorWidget(
              error: userState.error!,
              onDismiss: () {
                // userNotifier.clearError(); // Add this method to your notifier
              },
            ),

          // Loading Indicator
          if (userState.isLoading) const LoadingIndicator(),

          // Content
          Expanded(
            child: userState.selectedUser == null && !userState.isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No user data available',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : _buildProfileContent(userState.selectedUser!),
          ),
        ],
      ),
      floatingActionButton: _isEditing
          ? FloatingActionButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
            )
          : null,
    );
  }

  Widget _buildProfileContent(UserModel user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image Section
            _buildProfileImageSection(user),
            const SizedBox(height: 24),

            // Basic Information
            _buildBasicInfoSection(user),
            const SizedBox(height: 24),

            // Role Information
            _buildRoleSection(user),
            const SizedBox(height: 24),

            // Permissions Section
            _buildPermissionsSection(user),
            const SizedBox(height: 24),

            // Account Information
            _buildAccountInfoSection(user),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileImageSection(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Current/Selected Image
            CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey[200],
              backgroundImage: _selectedImage != null
                  ? FileImage(_selectedImage!)
                  : (user.profileImageUrl?.isNotEmpty == true
                            ? NetworkImage(user.profileImageUrl!)
                            : null)
                        as ImageProvider?,
              child:
                  _selectedImage == null &&
                      (user.profileImageUrl?.isEmpty != false)
                  ? Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 16),

            if (_isEditing) ...[
              // Image picker button (Option 1)
              // ElevatedButton.icon(
              //   onPressed: _pickImage,
              //   icon: const Icon(Icons.camera_alt),
              //   label: const Text('Pick Image from Gallery'),
              // ),
              const SizedBox(height: 8),

              // Image URL input (Option 2) - Comment out one of these options
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: 'Profile Image URL',
                  hintText: 'https://example.com/image.jpg',
                  prefixIcon: const Icon(Icons.link),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final uri = Uri.tryParse(value);
                    if (uri == null || !uri.hasScheme) {
                      return 'Please enter a valid URL';
                    }
                  }
                  return null;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Basic Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Full Name *',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                if (value.trim().length < 2) {
                  return 'Name must be at least 2 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Email *',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Email is required';
                }
                if (!RegExp(
                  r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                ).hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Phone
            TextFormField(
              controller: _phoneController,
              enabled: _isEditing,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value != null && value.isNotEmpty && value.length < 10) {
                  return 'Phone number must be at least 10 digits';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleSection(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Role Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.work, color: Colors.blue),
              title: Text(user.role.name),
              // subtitle: user.role..isNotEmpty
              //     ? Text(user.role.description)
              //     : null,
              contentPadding: EdgeInsets.zero,
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Chip(
                  label: Text(
                    '${user.role.permissions.length} role permissions',
                  ),
                  backgroundColor: Colors.blue.withOpacity(0.1),
                ),
                const SizedBox(width: 8),
                if (user.extraPermissions.isNotEmpty)
                  Chip(
                    label: Text(
                      '${user.extraPermissions.length} extra permissions',
                    ),
                    backgroundColor: Colors.green.withOpacity(0.1),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection(UserModel user) {
    final allPermissions = _getAllPermissions(user);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'All Permissions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Chip(
                  label: Text('${allPermissions.length} total'),
                  backgroundColor: Colors.grey.withOpacity(0.1),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (allPermissions.isEmpty)
              const Text(
                'No permissions assigned',
                style: TextStyle(color: Colors.grey),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: allPermissions.map((permission) {
                  final isExtraPermission = user.extraPermissions.values
                      .contains(permission);

                  return Chip(
                    label: Text(permission),
                    backgroundColor: isExtraPermission
                        ? Colors.green.withOpacity(0.1)
                        : Colors.blue.withOpacity(0.1),
                    side: BorderSide(
                      color: isExtraPermission ? Colors.green : Colors.blue,
                      width: 1,
                    ),
                  );
                }).toList(),
              ),

            if (allPermissions.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      border: Border.all(color: Colors.blue),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Role Permissions',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Extra Permissions',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoSection(UserModel user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            _buildInfoRow('User ID', user.uid, Icons.fingerprint),
            const SizedBox(height: 12),

            _buildInfoRow(
              'Primary Business ID',
              user.primarybusinessId,
              Icons.business,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              'Primary Branch ID',
              user.primaryBranchId,
              Icons.location_on,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              'Account Created',
              _formatDate(user.createdAt),
              Icons.calendar_today,
            ),
            const SizedBox(height: 12),

            _buildInfoRow(
              'Last Updated',
              _formatDate(user.updatedAt),
              Icons.update,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w400),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
