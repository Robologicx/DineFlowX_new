
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
// import 'package:image_picker/image_picker.dart';
import 'package:hotel_management_system/data/models/buisness_model.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/repositories/images_storage_repository.dart'
    show StorageRepository;
import 'package:hotel_management_system/data/services/image_storage_service.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/app_error_widget.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/loading_indicator.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/current_tenant_business_provider.dart';

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
  final _businessNameController = TextEditingController();
  final _businessLogoUrlController = TextEditingController();
  final StorageService _storageService = StorageService(StorageRepository());
  final Set<String> _ensuredPublicKeyBusinessIds = <String>{};

  bool _isEditing = false;
  bool _isSaving = false;
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
    _businessNameController.dispose();
    _businessLogoUrlController.dispose();
    super.dispose();
  }

  void _populateFields(UserModel user) {
    _nameController.text = user.name;
    _emailController.text = user.email;
    _phoneController.text = user.phoneNumber ?? '';
    _imageUrlController.text = user.profileImageUrl ?? '';
  }

  bool _canManageBusinessBrand(UserModel user) {
    final roleName = user.role.name.trim().toLowerCase();
    return roleName == 'owner' || roleName.contains('admin');
  }

  String _resolveBrandingBranchId() {
    final currentUser = ref.read(userProvider).selectedUser;
    final currentBranchId = currentUser?.primaryBranchId.trim() ?? '';
    if (currentBranchId.isNotEmpty) {
      return currentBranchId;
    }

    final fallbackBranchId = BusinessRepository.temporaryBranchId.trim();
    if (fallbackBranchId.isNotEmpty) {
      return fallbackBranchId;
    }

    return 'branch1';
  }

  String _normalizeLogoExtension(fp.PlatformFile file) {
    final rawExtension = (file.extension ?? '').trim().toLowerCase();
    if (rawExtension.isNotEmpty) {
      return rawExtension;
    }

    final fileName = file.name.trim().toLowerCase();
    if (fileName.contains('.')) {
      return fileName.split('.').last;
    }

    return 'png';
  }

  CircleAvatar _buildBusinessLogoAvatar({
    required String businessName,
    String? logoUrl,
    Uint8List? previewBytes,
    double radius = 28,
  }) {
    final normalizedLogoUrl = logoUrl?.trim();
    final ImageProvider? imageProvider;
    if (previewBytes != null && previewBytes.isNotEmpty) {
      imageProvider = MemoryImage(previewBytes);
    } else if (normalizedLogoUrl != null && normalizedLogoUrl.isNotEmpty) {
      imageProvider = NetworkImage(normalizedLogoUrl);
    } else {
      imageProvider = null;
    }

    final fallbackInitial = businessName.trim().isNotEmpty
        ? businessName.trim()[0].toUpperCase()
        : 'B';

    return CircleAvatar(
      radius: radius,
      foregroundImage: imageProvider,
      onForegroundImageError: imageProvider == null ? null : (_, __) {},
      child: Text(
        fallbackInitial,
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: radius * 0.7),
      ),
    );
  }

  String _toPublicSlug(String value) {
    final lower = value
        .trim()
        .toLowerCase()
        .replaceAll('&', ' and ')
        .replaceAll('+', ' and ');
    final buffer = StringBuffer();

    for (final codeUnit in lower.codeUnits) {
      final isAlphaNum =
          (codeUnit >= 48 && codeUnit <= 57) ||
          (codeUnit >= 97 && codeUnit <= 122);
      if (isAlphaNum) {
        buffer.writeCharCode(codeUnit);
      }
    }

    return buffer.toString();
  }

  String _buildPublicClientOrderingLink(BusinessModel business) {
    final businessKey = Uri.encodeComponent(business.id.trim());
    return 'https://dineflowx-client.web.app/$businessKey';
  }

  Future<void> _ensurePublicBusinessKey(BusinessModel business) async {
    final businessId = business.id.trim();
    if (businessId.isEmpty ||
        _ensuredPublicKeyBusinessIds.contains(businessId)) {
      return;
    }

    final titleSlug = _toPublicSlug(business.title);
    if (titleSlug.isEmpty) {
      _ensuredPublicKeyBusinessIds.add(businessId);
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('public_business_keys')
          .doc(titleSlug)
          .set({
            'businessId': businessId,
            'key': titleSlug,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      _ensuredPublicKeyBusinessIds.add(businessId);
    } catch (_) {
      // Ignore mapping write failures; the link still includes direct business-id fallback path.
    }
  }

  Future<void> _copyOrderingLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Client ordering link copied.'),
        backgroundColor: Colors.green,
      ),
    );
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
    final businessAsync = ref.watch(currentTenantBusinessProvider);

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
    final businessAsync = ref.watch(currentTenantBusinessProvider);
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

            if (_canManageBusinessBrand(user)) ...[
              _buildBusinessBrandSection(businessAsync),
              const SizedBox(height: 24),
            ],

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

  Widget _buildBusinessBrandSection(AsyncValue<BusinessModel?> businessAsync) {
    return businessAsync.when(
      data: (business) {
        if (business == null) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Business Branding',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () {
                          ref.invalidate(currentTenantBusinessProvider);
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reload'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Business details are still loading. Tap Reload, then Manage to upload logo.',
                  ),
                ],
              ),
            ),
          );
        }

        final orderingLink = _buildPublicClientOrderingLink(business);
        _ensurePublicBusinessKey(business);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Business Branding',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _showBusinessBrandDialog(business),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: _buildBusinessLogoAvatar(
                    businessName: business.title,
                    logoUrl: business.logoUrl,
                  ),
                  title: Text(business.title),
                  subtitle: Text(
                    business.logoUrl?.isNotEmpty == true
                        ? business.logoUrl!
                        : 'No business logo set',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Online Ordering Link',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SelectableText(orderingLink),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: () => _copyOrderingLink(orderingLink),
                    icon: const Icon(Icons.copy_outlined),
                    label: const Text('Copy Link'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, _) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Failed to load business branding: $error'),
        ),
      ),
    );
  }

  Future<void> _showBusinessBrandDialog(BusinessModel business) async {
    _businessNameController.text = business.title;
    _businessLogoUrlController.text = business.logoUrl ?? '';

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        var isSavingBrand = false;
        var isUploadingLogo = false;
        Uint8List? selectedLogoBytes;
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> uploadLogoFromDevice() async {
              try {
                final result = await fp.FilePicker.platform.pickFiles(
                  type: fp.FileType.custom,
                  allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
                  withData: true,
                );
                if (result == null || result.files.isEmpty) {
                  return;
                }

                final pickedFile = result.files.single;
                final bytes = pickedFile.bytes;
                if (bytes == null || bytes.isEmpty) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Unable to read the selected logo file.'),
                    ),
                  );
                  return;
                }

                if (bytes.length > 5 * 1024 * 1024) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Logo must be 5 MB or smaller.'),
                    ),
                  );
                  return;
                }

                setDialogState(() {
                  isUploadingLogo = true;
                  selectedLogoBytes = bytes;
                });

                final currentLogoUrl = _businessLogoUrlController.text.trim();
                final uploadedUrl = currentLogoUrl.isNotEmpty
                    ? await _storageService.updateRestaurantLogo(
                        businessId: business.id,
                        branchId: _resolveBrandingBranchId(),
                        imageBytes: bytes,
                        fileExtension: _normalizeLogoExtension(pickedFile),
                        oldImageUrl: currentLogoUrl,
                      )
                    : await _storageService.uploadRestaurantLogo(
                        businessId: business.id,
                        branchId: _resolveBrandingBranchId(),
                        imageBytes: bytes,
                        fileExtension: _normalizeLogoExtension(pickedFile),
                      );

                await BusinessRepository().updateBusiness(
                  business.copyWith(
                    logoUrl: uploadedUrl,
                    updatedAt: DateTime.now(),
                  ),
                );
                _businessLogoUrlController.text = uploadedUrl;
                if (!mounted) return;
                setDialogState(() {
                  isUploadingLogo = false;
                });
                ref.invalidate(currentTenantBusinessProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Business logo uploaded successfully.'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                setDialogState(() {
                  isUploadingLogo = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to upload logo: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            return AlertDialog(
              title: const Text('Manage Business Branding'),
              content: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildBusinessLogoAvatar(
                        businessName:
                            _businessNameController.text.trim().isEmpty
                            ? business.title
                            : _businessNameController.text.trim(),
                        logoUrl: _businessLogoUrlController.text.trim(),
                        previewBytes: selectedLogoBytes,
                        radius: 38,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: [
                          OutlinedButton.icon(
                            onPressed: isUploadingLogo
                                ? null
                                : uploadLogoFromDevice,
                            icon: isUploadingLogo
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.upload_file_outlined),
                            label: Text(
                              isUploadingLogo ? 'Uploading...' : 'Upload Logo',
                            ),
                          ),
                          TextButton.icon(
                            onPressed: isUploadingLogo
                                ? null
                                : () async {
                                    final currentLogoUrl =
                                        _businessLogoUrlController.text.trim();

                                    setDialogState(() {
                                      isUploadingLogo = true;
                                      selectedLogoBytes = null;
                                    });

                                    try {
                                      if (currentLogoUrl.isNotEmpty) {
                                        await _storageService
                                            .deleteRestaurantLogo(
                                              currentLogoUrl,
                                            );
                                      }

                                      await BusinessRepository().updateBusiness(
                                        business.copyWith(
                                          logoUrl: null,
                                          updatedAt: DateTime.now(),
                                        ),
                                      );

                                      if (!mounted) return;
                                      setDialogState(() {
                                        isUploadingLogo = false;
                                        _businessLogoUrlController.clear();
                                      });
                                      ref.invalidate(
                                        currentTenantBusinessProvider,
                                      );
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Business logo removed successfully.',
                                          ),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    } catch (e) {
                                      if (!mounted) return;
                                      setDialogState(() {
                                        isUploadingLogo = false;
                                      });
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Failed to remove logo: $e',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove Logo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upload from your device to store the logo in Cloud Storage.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _businessNameController,
                        onChanged: (_) => setDialogState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Business Name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _businessLogoUrlController,
                        onChanged: (_) => setDialogState(() {
                          selectedLogoBytes = null;
                        }),
                        decoration: const InputDecoration(
                          labelText: 'Business Logo URL',
                          border: OutlineInputBorder(),
                          hintText: 'https://example.com/logo.png',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSavingBrand || isUploadingLogo
                      ? null
                      : () async {
                          final trimmedName = _businessNameController.text
                              .trim();
                          if (trimmedName.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Business name is required.'),
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSavingBrand = true);
                          try {
                            final updatedBusiness = business.copyWith(
                              title: trimmedName,
                              logoUrl:
                                  _businessLogoUrlController.text.trim().isEmpty
                                  ? null
                                  : _businessLogoUrlController.text.trim(),
                              updatedAt: DateTime.now(),
                            );
                            await BusinessRepository().updateBusiness(
                              updatedBusiness,
                            );
                            if (!mounted) return;
                            Navigator.of(dialogContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Business branding updated.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } catch (e) {
                            if (!mounted) return;
                            setDialogState(() => isSavingBrand = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to update branding: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                  child: isSavingBrand
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
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
              backgroundImage: user.profileImageUrl?.isNotEmpty == true
                  ? NetworkImage(user.profileImageUrl!)
                  : null,
              child: (user.profileImageUrl?.isEmpty != false)
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
