import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/data/models/role_model.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/repositories/user_repository.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_text_field.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/user_profile_provider.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();

  // Add a Future variable to control the refresh
  Future<UserModel?>? _userFuture;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Method to load/refresh user data
  void _loadUserData() {
    setState(() {
      _userFuture = UserRepository().getUserById(
        FirebaseAuth.instance.currentUser!.uid,
      );
    });
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.pushNamed(ClientAppRoutes.shell);
          },
          icon: Icon(Icons.arrow_back),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 20, left: 28, right: 28),
        child: FutureBuilder(
          future: _userFuture, // Use the controllable future
          builder: (context, snapshot) {
            final userdate = snapshot.data;

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Some unexpected error occurred'),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserData,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (snapshot.data != null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text(
                        'Personal details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      SizedBox(width: 30),
                      GestureDetector(
                        onTap: () {
                          emailController.text = userdate!.email;
                          phoneController.text = userdate.phoneNumber ?? '';
                          addressController.text =
                              userdate.userLocationText ?? '';
                          nameController.text = userdate.name;
                          updateUserProfileDetails();
                        },
                        child: Icon(Icons.edit),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  _buildInfoCard(
                    isAddress: false,
                    subtitle: userdate!.name,
                    title: 'Name',
                    icon: Icons.person,
                  ),
                  SizedBox(height: 5),
                  _buildInfoCard(
                    isAddress: false,
                    subtitle: userdate.email,
                    title: 'Email',
                    icon: Icons.email,
                  ),
                  Divider(),
                  _buildInfoCard(
                    isAddress: false,
                    subtitle: userdate.phoneNumber ?? 'Not provided',
                    title: 'Phone',
                    icon: Icons.phone,
                  ),
                  Divider(),
                  _buildInfoCard(
                    isAddress: true,
                    subtitle: userdate.userLocationText ?? 'No address added',
                    icon: Icons.location_city,
                    title: 'Address',
                  ),
                ],
              );
            }

            return Center(child: Text('No user data found'));
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String subtitle,
    required bool isAddress,
    required IconData icon,
  }) {
    return SizedBox(
      width: MediaQuery.sizeOf(context).width * 0.8,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: ListTile(
            title: Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              subtitle,
              overflow: TextOverflow.ellipsis,
              maxLines: isAddress ? 2 : 1,
            ),
            leading: Icon(icon),
          ),
        ),
      ),
    );
  }

  void updateUserProfileDetails() {
    showDialog(
      useSafeArea: true,
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool isLoading = false; // Local loading state for the dialog

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                'Update your profile',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              insetPadding: EdgeInsets.zero,
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    CustomTextField(
                      keyBoardType: TextInputType.name,
                      controller: nameController,
                      hint: 'Name',
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      keyBoardType: TextInputType.emailAddress,
                      controller: emailController,
                      hint: 'Email',
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      keyBoardType: TextInputType.phone,
                      controller: phoneController,
                      hint: 'Phone',
                    ),
                    const SizedBox(height: 20),
                    CustomTextField(
                      keyBoardType: TextInputType.streetAddress,
                      controller: addressController,
                      hint: 'Address',
                    ),
                    const SizedBox(height: 20),
                    CustomButton(
                      text: isLoading ? 'Updating...' : 'Update',
                      onTap: isLoading
                          ? () {}
                          : () async {
                              setDialogState(() {
                                isLoading = true;
                              });
                              try {
                                // Update user in database
                                await UserRepository().updateUser(
                                  UserModel(
                                    uid: FirebaseAuth.instance.currentUser!.uid,
                                    name: nameController.text.trim(),
                                    email: emailController.text.trim(),
                                    phoneNumber: phoneController.text.trim(),
                                    userLocationText: addressController.text
                                        .trim(),
                                    role: RoleModel(
                                      id: FirebaseAuth
                                          .instance
                                          .currentUser!
                                          .uid,
                                      businessId: BusinessRepository
                                          .temporaryBusinesshId,
                                      name: nameController.text.trim(),
                                      permissions: [],
                                      createdAt: DateTime.now(),
                                      updatedAt: DateTime.now(),
                                    ),
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                    extraPermissions: {},
                                    primarybusinessId:
                                        BusinessRepository.temporaryBusinesshId,
                                    primaryBranchId:
                                        BusinessRepository.temporaryBranchId,
                                  ),
                                );

                                // Refresh the UI by reloading user data
                                _loadUserData();

                                // Show success message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Profile updated successfully!',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                }

                                Navigator.pop(context);
                              } catch (e) {
                                // Show error message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to update profile: $e',
                                      ),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 3),
                                    ),
                                  );
                                }

                                setDialogState(() {
                                  isLoading = false;
                                });
                              }
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
