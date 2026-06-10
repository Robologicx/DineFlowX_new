// // import 'package:flutter/material.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hotel_management_system/data/models/user_model.dart';
// import 'package:hotel_management_system/state_management/app_providers.dart';

// class AddEditStaffDialog extends ConsumerStatefulWidget {
//   final String businessId;
//   final String branchId;
//   final UserModel? staff;

//   const AddEditStaffDialog({
//     super.key,
//     required this.businessId,
//     required this.branchId,
//     this.staff,
//   });

//   @override
//   ConsumerState<AddEditStaffDialog> createState() => _AddEditStaffDialogState();
// }

// class _AddEditStaffDialogState extends ConsumerState<AddEditStaffDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _emailController;
//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;

//   String? _selectedRoleId;
//   String? _selectedRoleName;
//   Map<String, String> _selectedExtraPermissions = {};

//   bool get _isEditMode => widget.staff != null;

//   @override
//   void initState() {
//     super.initState();
//     _emailController = TextEditingController(text: widget.staff?.email ?? '');
//     _nameController = TextEditingController(text: widget.staff?.name ?? '');
//     _phoneController = TextEditingController(
//       text: widget.staff?.phoneNumber ?? '',
//     );

//     if (_isEditMode) {
//       _selectedRoleId = widget.staff!.role.id;
//       _selectedRoleName = widget.staff!.role.name;
//       _selectedExtraPermissions = Map.from(widget.staff!.extraPermissions);
//     }
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _nameController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userStaffState = ref.watch(userProvider);

//     // Watch your role provider with params
//     final roleState = ref.watch(
//       roleProvider((businessId: widget.businessId, branchId: widget.branchId)),
//     );

//     // Watch your permission provider with params
//     final permissionState = ref.watch(
//       permissionProvider((
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//       )),
//     );

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final maxDialogWidth = constraints.maxWidth > 600
//             ? 500.0
//             : constraints.maxWidth * 0.9;

//         return Dialog(
//           child: SingleChildScrollView(
//             child: Container(
//               width: maxDialogWidth,
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(context).size.height * 0.85,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildHeader(context),
//                   Flexible(
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(24),
//                       child: _buildForm(context, roleState, permissionState),
//                     ),
//                   ),
//                   _buildActions(context, userStaffState),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.primaryContainer,
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(12),
//           topRight: Radius.circular(12),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             _isEditMode ? Icons.edit : Icons.person_add,
//             color: Theme.of(context).colorScheme.onPrimaryContainer,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               _isEditMode ? 'Edit Staff Member' : 'Add New Staff Member',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: Theme.of(context).colorScheme.onPrimaryContainer,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: Icon(
//               Icons.close,
//               color: Theme.of(context).colorScheme.onPrimaryContainer,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildForm(
//     BuildContext context,
//     dynamic roleState,
//     dynamic permissionState,
//   ) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Email Field
//           TextFormField(
//             controller: _emailController,
//             enabled: !_isEditMode,
//             decoration: InputDecoration(
//               labelText: 'Email Address *',
//               hintText: 'staff@example.com',
//               prefixIcon: const Icon(Icons.email),
//               border: const OutlineInputBorder(),
//               helperText: _isEditMode
//                   ? 'Email cannot be changed'
//                   : 'Invitation will be sent to this email',
//             ),
//             keyboardType: TextInputType.emailAddress,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Email is required';
//               }
//               if (!RegExp(
//                 r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
//               ).hasMatch(value)) {
//                 return 'Please enter a valid email';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),

//           // Name Field
//           TextFormField(
//             controller: _nameController,
//             decoration: const InputDecoration(
//               labelText: 'Full Name',
//               hintText: 'John Doe',
//               prefixIcon: Icon(Icons.person),
//               border: OutlineInputBorder(),
//             ),
//             validator: (value) {
//               if (value != null && value.isNotEmpty && value.length < 2) {
//                 return 'Name must be at least 2 characters';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),

//           // Phone Field
//           TextFormField(
//             controller: _phoneController,
//             decoration: const InputDecoration(
//               labelText: 'Phone Number',
//               hintText: '+92 300 1234567',
//               prefixIcon: Icon(Icons.phone),
//               border: OutlineInputBorder(),
//             ),
//             keyboardType: TextInputType.phone,
//           ),
//           const SizedBox(height: 24),

//           // Role Selection
//           Text(
//             'Assign Role *',
//             style: Theme.of(
//               context,
//             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),

//           // Roles Dropdown with manual state handling
//           _buildRolesDropdown(roleState),
//           const SizedBox(height: 24),

//           // Extra Permissions Section
//           Text(
//             'Extra Permissions (Optional)',
//             style: Theme.of(
//               context,
//             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Add permissions beyond the assigned role',
//             style: Theme.of(
//               context,
//             ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 12),

//           // Permissions Chips with manual state handling
//           _buildPermissionsChips(permissionState),
//           const SizedBox(height: 24),

//           // Info Box
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.surfaceVariant,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.info_outline,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     _isEditMode
//                         ? 'Changes will take effect immediately.'
//                         : 'An invitation email will be sent to the staff member.',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRolesDropdown(dynamic roleState) {
//     // Handle loading state
//     if (roleState.isLoading) {
//       return Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//             const SizedBox(width: 12),
//             const Text('Loading roles...'),
//           ],
//         ),
//       );
//     }

//     // Handle error state
//     if (roleState.error != null) {
//       return Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.red[50],
//           border: Border.all(color: Colors.red),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.error, color: Colors.red[700]),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'Error loading roles: ${roleState.error}',
//                 style: TextStyle(color: Colors.red[900]),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // Handle data state
//     final roles = roleState.roles;

//     if (roles.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.orange[50],
//           border: Border.all(color: Colors.orange),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.orange[700]),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'No roles available',
//                 style: TextStyle(color: Colors.orange[900]),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return DropdownButtonFormField<String>(
//       value: _selectedRoleId,
//       decoration: const InputDecoration(
//         labelText: 'Select Role',
//         prefixIcon: Icon(Icons.badge),
//         border: OutlineInputBorder(),
//       ),
//       items: roles
//           .map(
//             (role) => DropdownMenuItem(value: role.id, child: Text(role.name)),
//           )
//           .toList(),
//       onChanged: (value) {
//         if (value != null) {
//           final selectedRole = roles.firstWhere((r) => r.id == value);
//           setState(() {
//             _selectedRoleId = value;
//             _selectedRoleName = selectedRole.name;
//           });
//         }
//       },
//       validator: (value) {
//         if (value == null) {
//           return 'Please select a role';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildPermissionsChips(dynamic permissionState) {
//     // Handle loading state
//     if (permissionState.isLoading) {
//       return Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//             const SizedBox(width: 12),
//             const Text('Loading permissions...'),
//           ],
//         ),
//       );
//     }

//     // Handle error state
//     if (permissionState.error != null) {
//       return Text(
//         'Error loading permissions: ${permissionState.error}',
//         style: const TextStyle(color: Colors.red),
//       );
//     }

//     // Handle data state
//     final permissions = permissionState.permissions
//         .where((p) => p.isActive && p.isShowingToAllAdmins)
//         .toList();

//     if (permissions.isEmpty) {
//       return Text(
//         'No permissions available',
//         style: Theme.of(
//           context,
//         ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
//       );
//     }

//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: permissions
//           .map(
//             (permission) =>
//                 _buildPermissionChip(permission.id, permission.name),
//           )
//           .toList(),
//     );
//   }

//   Widget _buildPermissionChip(String permissionId, String permissionName) {
//     final isSelected = _selectedExtraPermissions.containsKey(permissionId);

//     return FilterChip(
//       label: Text(permissionName),
//       selected: isSelected,
//       onSelected: (selected) {
//         setState(() {
//           if (selected) {
//             _selectedExtraPermissions[permissionId] = permissionName;
//           } else {
//             _selectedExtraPermissions.remove(permissionId);
//           }
//         });
//       },
//       backgroundColor: Colors.transparent,
//       selectedColor: Theme.of(context).colorScheme.primaryContainer,
//       side: BorderSide(
//         color: isSelected
//             ? Theme.of(context).colorScheme.primary
//             : Colors.grey[300]!,
//       ),
//     );
//   }

//   Widget _buildActions(BuildContext context, dynamic staffState) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           TextButton(
//             onPressed: staffState.isLoading
//                 ? null
//                 : () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           const SizedBox(width: 12),
//           FilledButton(
//             onPressed: staffState.isLoading ? null : _handleSubmit,
//             child: staffState.isLoading
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : Text(_isEditMode ? 'Update' : 'Add Staff'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _handleSubmit() async {
//     if (!_formKey.currentState!.validate()) return;

//     final notifier = ref.read(userProvider.notifier);

//     bool success;

//     if (_isEditMode) {
//       success = await notifier.updateStaffMember(
//         uid: widget.staff!.uid,
//         roleId: _selectedRoleId!,
//         extraPermissions: _selectedExtraPermissions,
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//         name: _nameController.text.isNotEmpty ? _nameController.text : null,
//         phoneNumber: _phoneController.text.isNotEmpty
//             ? _phoneController.text
//             : null,
//       );
//     } else {
//       success = await notifier.addStaffMember(
//         email: _emailController.text.trim(),
//         roleId: _selectedRoleId!,
//         roleName: _selectedRoleName ?? 'Staff Member',
//         extraPermissions: _selectedExtraPermissions,
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//         name: _nameController.text.isNotEmpty ? _nameController.text : null,
//         phoneNumber: _phoneController.text.isNotEmpty
//             ? _phoneController.text
//             : null,
//       );
//     }

//     if (success && mounted) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             _isEditMode
//                 ? 'Staff member updated successfully'
//                 : 'Staff member added successfully',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }
// }

//-----------------------------DEEP SEEK----------------------------------//
// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hotel_management_system/data/models/user_model.dart';
// import 'package:hotel_management_system/state_management/app_providers.dart';
// import 'package:hotel_management_system/state_management/permission_provider.dart';
// import 'package:hotel_management_system/state_management/role_provider.dart';

// class AddEditStaffDialog extends ConsumerStatefulWidget {
//   final String businessId;
//   final String branchId;
//   final UserModel? staff;

//   const AddEditStaffDialog({
//     super.key,
//     required this.businessId,
//     required this.branchId,
//     this.staff,
//   });

//   @override
//   ConsumerState<AddEditStaffDialog> createState() => _AddEditStaffDialogState();
// }

// class _AddEditStaffDialogState extends ConsumerState<AddEditStaffDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _emailController;
//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;

//   String? _selectedRoleId;
//   String? _selectedRoleName;
//   Map<String, String> _selectedExtraPermissions = {};
//   bool _initialLoadComplete = false;

//   bool get _isEditMode => widget.staff != null;

//   @override
//   void initState() {
//     super.initState();
//     _emailController = TextEditingController(text: widget.staff?.email ?? '');
//     _nameController = TextEditingController(text: widget.staff?.name ?? '');
//     _phoneController = TextEditingController(
//       text: widget.staff?.phoneNumber ?? '',
//     );

//     if (_isEditMode) {
//       _selectedRoleId = widget.staff!.role.id;
//       _selectedRoleName = widget.staff!.role.name;
//       _selectedExtraPermissions = Map.from(widget.staff!.extraPermissions);
//     }
//   }

//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     // Initialize providers when dialog opens
//     _initializeProviders();
//   }

//   void _initializeProviders() {
//     if (!_initialLoadComplete) {
//       // Set business ID and load roles
//       final roleNotifier = ref.read(
//         roleProvider((
//           businessId: widget.businessId,
//           branchId: widget.branchId,
//         )).notifier,
//       );

//       // Set the business ID and trigger loading
//       roleNotifier.setBusinessId(widget.businessId);
//       roleNotifier.getAllRolesOfBuisness();

//       // Load permissions
//       final permissionNotifier = ref.read(
//         permissionProvider((
//           businessId: widget.businessId,
//           branchId: widget.branchId,
//         )).notifier,
//       );
//       permissionNotifier.loadPermissions();

//       _initialLoadComplete = true;
//     }
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _nameController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userStaffState = ref.watch(userProvider);

//     // Watch your role provider with params
//     final roleState = ref.watch(
//       roleProvider((businessId: widget.businessId, branchId: widget.branchId)),
//     );

//     // Watch your permission provider with params
//     final permissionState = ref.watch(
//       permissionProvider((
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//       )),
//     );

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final maxDialogWidth = constraints.maxWidth > 600
//             ? 500.0
//             : constraints.maxWidth * 0.9;

//         return Dialog(
//           child: SingleChildScrollView(
//             child: Container(
//               width: maxDialogWidth,
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(context).size.height * 0.85,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildHeader(context),
//                   Flexible(
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(24),
//                       child: _buildForm(context, roleState, permissionState),
//                     ),
//                   ),
//                   _buildActions(context, userStaffState),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.primaryContainer,
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(12),
//           topRight: Radius.circular(12),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             _isEditMode ? Icons.edit : Icons.person_add,
//             color: Theme.of(context).colorScheme.onPrimaryContainer,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               _isEditMode ? 'Edit Staff Member' : 'Add New Staff Member',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: Theme.of(context).colorScheme.onPrimaryContainer,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: Icon(
//               Icons.close,
//               color: Theme.of(context).colorScheme.onPrimaryContainer,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildForm(
//     BuildContext context,
//     RoleState roleState,
//     PermissionState permissionState,
//   ) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Email Field
//           TextFormField(
//             controller: _emailController,
//             enabled: !_isEditMode,
//             decoration: InputDecoration(
//               labelText: 'Email Address *',
//               hintText: 'staff@example.com',
//               prefixIcon: const Icon(Icons.email),
//               border: const OutlineInputBorder(),
//               helperText: _isEditMode
//                   ? 'Email cannot be changed'
//                   : 'Invitation will be sent to this email',
//             ),
//             keyboardType: TextInputType.emailAddress,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Email is required';
//               }
//               if (!RegExp(
//                 r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
//               ).hasMatch(value)) {
//                 return 'Please enter a valid email';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),

//           // Name Field
//           TextFormField(
//             controller: _nameController,
//             decoration: const InputDecoration(
//               labelText: 'Full Name',
//               hintText: 'John Doe',
//               prefixIcon: Icon(Icons.person),
//               border: OutlineInputBorder(),
//             ),
//             validator: (value) {
//               if (value != null && value.isNotEmpty && value.length < 2) {
//                 return 'Name must be at least 2 characters';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),

//           // Phone Field
//           TextFormField(
//             controller: _phoneController,
//             decoration: const InputDecoration(
//               labelText: 'Phone Number',
//               hintText: '+92 300 1234567',
//               prefixIcon: Icon(Icons.phone),
//               border: OutlineInputBorder(),
//             ),
//             keyboardType: TextInputType.phone,
//           ),
//           const SizedBox(height: 24),

//           // Role Selection
//           Text(
//             'Assign Role *',
//             style: Theme.of(
//               context,
//             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),

//           // Roles Dropdown with manual state handling
//           _buildRolesDropdown(roleState),
//           const SizedBox(height: 24),

//           // Extra Permissions Section
//           Text(
//             'Extra Permissions (Optional)',
//             style: Theme.of(
//               context,
//             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Add permissions beyond the assigned role',
//             style: Theme.of(
//               context,
//             ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 12),

//           // Permissions Chips with manual state handling
//           _buildPermissionsChips(permissionState),
//           const SizedBox(height: 24),

//           // Info Box
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.surfaceVariant,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.info_outline,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     _isEditMode
//                         ? 'Changes will take effect immediately.'
//                         : 'An invitation email will be sent to the staff member.',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildRolesDropdown(RoleState roleState) {
//     // Handle loading state
//     if (roleState.isLoading) {
//       return Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//             const SizedBox(width: 12),
//             const Text('Loading roles...'),
//           ],
//         ),
//       );
//     }

//     // Handle error state
//     if (roleState.error != null) {
//       return Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.red[50],
//           border: Border.all(color: Colors.red),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.error, color: Colors.red[700]),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 'Error loading roles: ${roleState.error}',
//                 style: TextStyle(color: Colors.red[900]),
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     // Handle data state
//     final roles = roleState.roles;

//     if (roles.isEmpty) {
//       return Container(
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: Colors.orange[50],
//           border: Border.all(color: Colors.orange),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           children: [
//             Icon(Icons.warning, color: Colors.orange[700]),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'No roles available',
//                     style: TextStyle(color: Colors.orange[900]),
//                   ),
//                   const SizedBox(height: 4),
//                   Text(
//                     'Please create roles first in the roles management section',
//                     style: TextStyle(color: Colors.orange[800], fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       );
//     }

//     return DropdownButtonFormField<String>(
//       value: _selectedRoleId,
//       decoration: const InputDecoration(
//         labelText: 'Select Role',
//         prefixIcon: Icon(Icons.badge),
//         border: OutlineInputBorder(),
//       ),
//       items: roles
//           .map(
//             (role) => DropdownMenuItem(value: role.id, child: Text(role.name)),
//           )
//           .toList(),
//       onChanged: (value) {
//         if (value != null) {
//           final selectedRole = roles.firstWhere((r) => r.id == value);
//           setState(() {
//             _selectedRoleId = value;
//             _selectedRoleName = selectedRole.name;
//           });
//         }
//       },
//       validator: (value) {
//         if (value == null) {
//           return 'Please select a role';
//         }
//         return null;
//       },
//     );
//   }

//   Widget _buildPermissionsChips(PermissionState permissionState) {
//     // Handle loading state
//     if (permissionState.isLoading) {
//       return Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Row(
//           children: [
//             const SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(strokeWidth: 2),
//             ),
//             const SizedBox(width: 12),
//             const Text('Loading permissions...'),
//           ],
//         ),
//       );
//     }

//     // Handle error state
//     if (permissionState.error != null) {
//       return Text(
//         'Error loading permissions: ${permissionState.error}',
//         style: const TextStyle(color: Colors.red),
//       );
//     }

//     // Handle data state
//     final permissions = permissionState.permissions
//         .where((p) => p.isActive && p.isShowingToAllAdmins)
//         .toList();

//     if (permissions.isEmpty) {
//       return Text(
//         'No permissions available',
//         style: Theme.of(
//           context,
//         ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
//       );
//     }

//     return Wrap(
//       spacing: 8,
//       runSpacing: 8,
//       children: permissions
//           .map(
//             (permission) =>
//                 _buildPermissionChip(permission.id, permission.name),
//           )
//           .toList(),
//     );
//   }

//   Widget _buildPermissionChip(String permissionId, String permissionName) {
//     final isSelected = _selectedExtraPermissions.containsKey(permissionId);

//     return FilterChip(
//       label: Text(permissionName),
//       selected: isSelected,
//       onSelected: (selected) {
//         setState(() {
//           if (selected) {
//             _selectedExtraPermissions[permissionId] = permissionName;
//           } else {
//             _selectedExtraPermissions.remove(permissionId);
//           }
//         });
//       },
//       backgroundColor: Colors.transparent,
//       selectedColor: Theme.of(context).colorScheme.primaryContainer,
//       side: BorderSide(
//         color: isSelected
//             ? Theme.of(context).colorScheme.primary
//             : Colors.grey[300]!,
//       ),
//     );
//   }

//   Widget _buildActions(BuildContext context, dynamic staffState) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           TextButton(
//             onPressed: staffState.isLoading
//                 ? null
//                 : () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           const SizedBox(width: 12),
//           FilledButton(
//             onPressed: staffState.isLoading ? null : _handleSubmit,
//             child: staffState.isLoading
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : Text(_isEditMode ? 'Update' : 'Add Staff'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _handleSubmit() async {
//     if (!_formKey.currentState!.validate()) return;

//     final notifier = ref.read(userProvider.notifier);

//     bool success;

//     if (_isEditMode) {
//       success = await notifier.updateStaffMember(
//         uid: widget.staff!.uid,
//         roleId: _selectedRoleId!,
//         extraPermissions: _selectedExtraPermissions,
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//         name: _nameController.text.isNotEmpty ? _nameController.text : null,
//         phoneNumber: _phoneController.text.isNotEmpty
//             ? _phoneController.text
//             : null,
//       );
//     } else {
//       success = await notifier.addStaffMember(
//         email: _emailController.text.trim(),
//         roleId: _selectedRoleId!,
//         roleName: _selectedRoleName ?? 'Staff Member',
//         extraPermissions: _selectedExtraPermissions,
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//         name: _nameController.text.isNotEmpty ? _nameController.text : null,
//         phoneNumber: _phoneController.text.isNotEmpty
//             ? _phoneController.text
//             : null,
//       );
//     }

//     if (success && mounted) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             _isEditMode
//                 ? 'Staff member updated successfully'
//                 : 'Staff member added successfully',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/user_model.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/permission_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/role_state_and_provider.dart';

class AddEditStaffDialog extends ConsumerStatefulWidget {
  final String businessId;
  final String branchId;
  final UserModel? staff;

  const AddEditStaffDialog({
    super.key,
    required this.businessId,
    required this.branchId,
    this.staff,
  });

  @override
  ConsumerState<AddEditStaffDialog> createState() => _AddEditStaffDialogState();
}

class _AddEditStaffDialogState extends ConsumerState<AddEditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;

  String? _selectedRoleId;
  String? _selectedRoleName;
  Map<String, String> _selectedExtraPermissions = {};

  bool get _isEditMode => widget.staff != null;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.staff?.email ?? '');
    _nameController = TextEditingController(text: widget.staff?.name ?? '');
    _phoneController = TextEditingController(
      text: widget.staff?.phoneNumber ?? '',
    );
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    if (_isEditMode) {
      _selectedRoleId = widget.staff!.role.id;
      _selectedRoleName = widget.staff!.role.name;
      _selectedExtraPermissions = Map.from(widget.staff!.extraPermissions);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final roleNotifier = ref.read(
        roleProvider((
          businessId: widget.businessId,
          branchId: widget.branchId,
        )).notifier,
      );
      roleNotifier.setBusinessId(widget.businessId);
      roleNotifier.getAllRolesOfBuisness();

      ref
          .read(
            roleProvider((
              businessId: widget.businessId,
              branchId: widget.branchId,
            )).notifier,
          )
          .getAllRolesOfBuisness();

      ref
          .read(
            permissionProvider((
              businessId: widget.businessId,
              branchId: widget.branchId,
            )).notifier,
          )
          .loadAllPermissions();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final staffState = ref.watch(userProvider);

    // Watch your role provider with params
    final rolesAsync = ref.watch(
      roleProvider((businessId: widget.businessId, branchId: widget.branchId)),
    );

    // Watch your permission provider with params
    final permissionsAsync = ref.watch(
      permissionProvider((
        businessId: widget.businessId,
        branchId: widget.branchId,
      )),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxDialogWidth = constraints.maxWidth > 600
            ? 500.0
            : constraints.maxWidth * 0.9;

        return Dialog(
          child: SingleChildScrollView(
            child: Container(
              width: maxDialogWidth,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(context),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildForm(context, rolesAsync, permissionsAsync),
                    ),
                  ),
                  _buildActions(context, staffState),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(12),
          topRight: Radius.circular(12),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isEditMode ? Icons.edit : Icons.person_add,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _isEditMode ? 'Edit Staff Member' : 'Add New Staff Member',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.close,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(
    BuildContext context,
    RoleState roleState,
    PermissionState permissionState,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            enabled: !_isEditMode,
            decoration: InputDecoration(
              labelText: 'Email Address *',
              hintText: 'staff@example.com',
              prefixIcon: const Icon(Icons.email),
              border: const OutlineInputBorder(),
              helperText: _isEditMode
                  ? 'Email cannot be changed'
                  : 'Staff will login with this email',
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              if (!RegExp(
                r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          if (!_isEditMode) ...[
            TextFormField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Password *',
                hintText: 'Minimum 6 characters',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (_isEditMode) return null;
                if (value == null || value.isEmpty) {
                  return 'Password is required';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _confirmPasswordController,
              decoration: const InputDecoration(
                labelText: 'Confirm Password *',
                hintText: 'Re-enter password',
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
              validator: (value) {
                if (_isEditMode) return null;
                if (value == null || value.isEmpty) {
                  return 'Please confirm password';
                }
                if (value != _passwordController.text) {
                  return 'Passwords do not match';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
          ],

          // Name Field
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              hintText: 'John Doe',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty && value.length < 2) {
                return 'Name must be at least 2 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Phone Field
          TextFormField(
            controller: _phoneController,
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: '+92 300 1234567',
              prefixIcon: Icon(Icons.phone),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),

          // Role Selection
          Text(
            'Assign Role *',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildRolesDropdown(context, roleState),
          const SizedBox(height: 24),

          // Extra Permissions Section
          Text(
            'Extra Permissions (Optional)',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Add permissions beyond the assigned role',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          _buildPermissionsChips(context, permissionState),
          const SizedBox(height: 24),

          // Info Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEditMode
                        ? 'Changes will take effect immediately.'
                        : 'Staff account is created now and can login immediately.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesDropdown(BuildContext context, RoleState roleState) {
    if (roleState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            const Text('Loading roles...'),
          ],
        ),
      );
    }

    if (roleState.error != null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[50],
          border: Border.all(color: Colors.red),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Error: ${roleState.error}',
                style: TextStyle(color: Colors.red[900], fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    final roles = roleState.roles;

    if (roles.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'No roles available',
                style: TextStyle(color: Colors.orange[900]),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      initialValue: _selectedRoleId,
      decoration: const InputDecoration(
        labelText: 'Select Role',
        prefixIcon: Icon(Icons.badge),
        border: OutlineInputBorder(),
      ),
      items: roles
          .map(
            (role) => DropdownMenuItem(value: role.id, child: Text(role.name)),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) {
          final selectedRole = roles.firstWhere((r) => r.id == value);
          setState(() {
            _selectedRoleId = value;
            _selectedRoleName = selectedRole.name;
          });
        }
      },
      validator: (value) {
        if (value == null) {
          return 'Please select a role';
        }
        return null;
      },
    );
  }

  // Widget _buildRolesDropdown(BuildContext context, RoleState roleState) {
  //   if (roleState.isLoading) {
  //     return Padding(
  //       padding: const EdgeInsets.all(16.0),
  //       child: Row(
  //         children: [
  //           const SizedBox(
  //             width: 20,
  //             height: 20,
  //             child: CircularProgressIndicator(strokeWidth: 2),
  //           ),
  //           const SizedBox(width: 12),
  //           const Text('Loading roles...'),
  //         ],
  //       ),
  //     );
  //   }

  //   if (roleState.error != null) {
  //     return Container(
  //       padding: const EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: Colors.red[50],
  //         border: Border.all(color: Colors.red),
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(Icons.error, color: Colors.red[700]),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Text(
  //               'Error loading roles: ${roleState.error}',
  //               style: TextStyle(color: Colors.red[900]),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   final roles = roleState.roles;

  //   if (roles.isEmpty) {
  //     return Container(
  //       padding: const EdgeInsets.all(12),
  //       decoration: BoxDecoration(
  //         color: Colors.orange[50],
  //         border: Border.all(color: Colors.orange),
  //         borderRadius: BorderRadius.circular(8),
  //       ),
  //       child: Row(
  //         children: [
  //           Icon(Icons.warning, color: Colors.orange[700]),
  //           const SizedBox(width: 8),
  //           Expanded(
  //             child: Text(
  //               'No roles available',
  //               style: TextStyle(color: Colors.orange[900]),
  //             ),
  //           ),
  //         ],
  //       ),
  //     );
  //   }

  //   return DropdownButtonFormField<String>(
  //     value: _selectedRoleId,
  //     decoration: const InputDecoration(
  //       labelText: 'Select Role',
  //       prefixIcon: Icon(Icons.badge),
  //       border: OutlineInputBorder(),
  //     ),
  //     items: roles
  //         .map(
  //           (role) => DropdownMenuItem(value: role.id, child: Text(role.name)),
  //         )
  //         .toList(),
  //     onChanged: (value) {
  //       if (value != null) {
  //         final selectedRole = roles.firstWhere((r) => r.id == value);
  //         setState(() {
  //           _selectedRoleId = value;
  //           _selectedRoleName = selectedRole.name;
  //         });
  //       }
  //     },
  //     validator: (value) {
  //       if (value == null) {
  //         return 'Please select a role';
  //       }
  //       return null;
  //     },
  //   );
  // }

  Widget _buildPermissionsChips(
    BuildContext context,
    PermissionState permissionState,
  ) {
    if (permissionState.isLoading) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
            const Text('Loading permissions...'),
          ],
        ),
      );
    }

    if (permissionState.error != null) {
      return Text(
        'Error: ${permissionState.error}',
        style: const TextStyle(color: Colors.red, fontSize: 12),
      );
    }

    final permissions = permissionState.permissions
        .where((p) => p.isActive && p.isShowingToAllAdmins)
        .toList();

    if (permissions.isEmpty) {
      return Text(
        'No additional permissions available',
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: permissions
          .map(
            (permission) =>
                _buildPermissionChip(permission.id, permission.name),
          )
          .toList(),
    );
  }

  Widget _buildActions(BuildContext context, dynamic staffState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: staffState.isLoading
                ? null
                : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          const SizedBox(width: 12),
          FilledButton(
            onPressed: staffState.isLoading ? null : _handleSubmit,
            child: staffState.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(_isEditMode ? 'Update' : 'Add Staff'),
          ),
        ],
      ),
    );
  }

  // Widget _buildActions(BuildContext context, dynamic staffState) {
  //   return Container(
  //     padding: const EdgeInsets.all(20),
  //     decoration: BoxDecoration(
  //       color: Theme.of(context).colorScheme.surface,
  //       border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
  //     ),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.end,
  //       children: [
  //         TextButton(
  //           onPressed: staffState.isLoading
  //               ? null
  //               : () => Navigator.pop(context),
  //           child: const Text('Cancel'),
  //         ),
  //         const SizedBox(width: 12),
  //         FilledButton(
  //           onPressed: staffState.isLoading ? null : _handleSubmit,
  //           child: staffState.isLoading
  //               ? const SizedBox(
  //                   width: 20,
  //                   height: 20,
  //                   child: CircularProgressIndicator(
  //                     strokeWidth: 2,
  //                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
  //                   ),
  //                 )
  //               : Text(_isEditMode ? 'Update' : 'Add Staff'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildPermissionChip(String permissionId, String permissionName) {
    final isSelected = _selectedExtraPermissions.containsKey(permissionId);

    return FilterChip(
      label: Text('$permissionId • $permissionName'),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedExtraPermissions[permissionId] = permissionName;
          } else {
            _selectedExtraPermissions.remove(permissionId);
          }
        });
      },
      backgroundColor: Colors.transparent,
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
      side: BorderSide(
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[300]!,
        width: 1.5,
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final notifier = ref.read(userProvider.notifier);

    bool success;

    if (_isEditMode) {
      success = await notifier.updateStaffMember(
        uid: widget.staff!.uid,
        roleId: _selectedRoleId!,
        extraPermissions: _selectedExtraPermissions,
        businessId: widget.businessId,
        branchId: widget.branchId,
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        phoneNumber: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : null,
      );
    } else {
      success = await notifier.addStaffMember(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        roleId: _selectedRoleId!,
        roleName: _selectedRoleName ?? 'Staff Member',
        extraPermissions: _selectedExtraPermissions,
        businessId: widget.businessId,
        branchId: widget.branchId,
        name: _nameController.text.isNotEmpty ? _nameController.text : null,
        phoneNumber: _phoneController.text.isNotEmpty
            ? _phoneController.text
            : null,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditMode
                ? 'Staff member updated successfully'
                : 'Staff member added successfully',
          ),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }

    if (mounted) {
      final error = ref.read(userProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error ??
                (_isEditMode
                    ? 'Failed to update staff member.'
                    : 'Failed to add staff member.'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // Future<void> _handleSubmit() async {
  //   if (!_formKey.currentState!.validate()) return;

  //   final notifier = ref.read(userNotifierProvider.notifier);

  //   bool success;

  //   if (_isEditMode) {
  //     success = await notifier.updateStaffMember(
  //       uid: widget.staff!.uid,
  //       roleId: _selectedRoleId!,
  //       extraPermissions: _selectedExtraPermissions,
  //       businessId: widget.businessId,
  //       branchId: widget.branchId,
  //       name: _nameController.text.isNotEmpty ? _nameController.text : null,
  //       phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
  //     );
  //   } else {
  //     success = await notifier.addStaffMember(
  //       email: _emailController.text.trim(),
  //       roleId: _selectedRoleId!,
  //       roleName: _selectedRoleName ?? 'Staff Member',
  //       extraPermissions: _selectedExtraPermissions,
  //       businessId: widget.businessId,
  //       branchId: widget.branchId,
  //       name: _nameController.text.isNotEmpty ? _nameController.text : null,
  //       phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
  //     );
  //   }

  //   if (success && mounted) {
  //     Navigator.pop(context);
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text(
  //           _isEditMode
  //               ? 'Staff member updated successfully'
  //               : 'Staff member added successfully',
  //         ),
  //         backgroundColor: Colors.green,
  //       ),
  //     );
  //   }
  // }
}

// ------------------COMMENTED CODE IS WRITTEN FOR STREAMS HANDING ASYNC VALUES------------------
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:hotel_management_system/data/models/user_model.dart';
// import 'package:hotel_management_system/state_management/app_providers.dart';

// class AddEditStaffDialog extends ConsumerStatefulWidget {
//   final String businessId;
//   final String branchId;
//   final UserModel? staff;

//   const AddEditStaffDialog({
//     super.key,
//     required this.businessId,
//     required this.branchId,
//     this.staff,
//   });

//   @override
//   ConsumerState<AddEditStaffDialog> createState() => _AddEditStaffDialogState();
// }

// class _AddEditStaffDialogState extends ConsumerState<AddEditStaffDialog> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _emailController;
//   late TextEditingController _nameController;
//   late TextEditingController _phoneController;

//   String? _selectedRoleId;
//   String? _selectedRoleName;
//   Map<String, String> _selectedExtraPermissions = {};

//   bool get _isEditMode => widget.staff != null;

//   @override
//   void initState() {
//     super.initState();
//     _emailController = TextEditingController(text: widget.staff?.email ?? '');
//     _nameController = TextEditingController(text: widget.staff?.name ?? '');
//     _phoneController = TextEditingController(
//       text: widget.staff?.phoneNumber ?? '',
//     );

//     if (_isEditMode) {
//       _selectedRoleId = widget.staff!.role.id;
//       _selectedRoleName = widget.staff!.role.name;
//       _selectedExtraPermissions = Map.from(widget.staff!.extraPermissions);
//     }
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _nameController.dispose();
//     _phoneController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final userStaffState = ref.watch(userProvider);

//     // Watch your role provider with params
//     final rolesAsync = ref.watch(
//       roleProvider((businessId: widget.businessId, branchId: widget.branchId)),
//     );

//     // Watch your permission provider with params
//     final permissionsAsync = ref.watch(
//       permissionProvider((
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//       )),
//     );

//     return LayoutBuilder(
//       builder: (context, constraints) {
//         final maxDialogWidth = constraints.maxWidth > 600
//             ? 500.0
//             : constraints.maxWidth * 0.9;

//         return Dialog(
//           child: SingleChildScrollView(
//             child: Container(
//               width: maxDialogWidth,
//               constraints: BoxConstraints(
//                 maxHeight: MediaQuery.of(context).size.height * 0.85,
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   _buildHeader(context),
//                   Flexible(
//                     child: SingleChildScrollView(
//                       padding: const EdgeInsets.all(24),
//                       child: _buildForm(context, rolesAsync, permissionsAsync),
//                     ),
//                   ),
//                   _buildActions(context, userStaffState),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _buildHeader(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.primaryContainer,
//         borderRadius: const BorderRadius.only(
//           topLeft: Radius.circular(12),
//           topRight: Radius.circular(12),
//         ),
//       ),
//       child: Row(
//         children: [
//           Icon(
//             _isEditMode ? Icons.edit : Icons.person_add,
//             color: Theme.of(context).colorScheme.onPrimaryContainer,
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               _isEditMode ? 'Edit Staff Member' : 'Add New Staff Member',
//               style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                 color: Theme.of(context).colorScheme.onPrimaryContainer,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//           IconButton(
//             onPressed: () => Navigator.pop(context),
//             icon: Icon(
//               Icons.close,
//               color: Theme.of(context).colorScheme.onPrimaryContainer,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildForm(
//     BuildContext context,
//     dynamic rolesAsync,
//     dynamic permissionsAsync,
//   ) {
//     return Form(
//       key: _formKey,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           // Email Field
//           TextFormField(
//             controller: _emailController,
//             enabled: !_isEditMode,
//             decoration: InputDecoration(
//               labelText: 'Email Address *',
//               hintText: 'staff@example.com',
//               prefixIcon: const Icon(Icons.email),
//               border: const OutlineInputBorder(),
//               helperText: _isEditMode
//                   ? 'Email cannot be changed'
//                   : 'Invitation will be sent to this email',
//             ),
//             keyboardType: TextInputType.emailAddress,
//             validator: (value) {
//               if (value == null || value.isEmpty) {
//                 return 'Email is required';
//               }
//               if (!RegExp(
//                 r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
//               ).hasMatch(value)) {
//                 return 'Please enter a valid email';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),

//           // Name Field
//           TextFormField(
//             controller: _nameController,
//             decoration: const InputDecoration(
//               labelText: 'Full Name',
//               hintText: 'John Doe',
//               prefixIcon: Icon(Icons.person),
//               border: OutlineInputBorder(),
//             ),
//             validator: (value) {
//               if (value != null && value.isNotEmpty && value.length < 2) {
//                 return 'Name must be at least 2 characters';
//               }
//               return null;
//             },
//           ),
//           const SizedBox(height: 16),

//           // Phone Field
//           TextFormField(
//             controller: _phoneController,
//             decoration: const InputDecoration(
//               labelText: 'Phone Number',
//               hintText: '+92 300 1234567',
//               prefixIcon: Icon(Icons.phone),
//               border: OutlineInputBorder(),
//             ),
//             keyboardType: TextInputType.phone,
//           ),
//           const SizedBox(height: 24),

//           // Role Selection
//           Text(
//             'Assign Role *',
//             style: Theme.of(
//               context,
//             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 12),

//           // Roles Dropdown with async handling
//           rolesAsync.when(
//             data: (roleState) {
//               final roles = roleState.roles;

//               if (roles.isEmpty) {
//                 return Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.orange[50],
//                     border: Border.all(color: Colors.orange),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(Icons.warning, color: Colors.orange[700]),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           'No roles available',
//                           style: TextStyle(color: Colors.orange[900]),
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               }

//               return DropdownButtonFormField<String>(
//                 value: _selectedRoleId,
//                 decoration: const InputDecoration(
//                   labelText: 'Select Role',
//                   prefixIcon: Icon(Icons.badge),
//                   border: OutlineInputBorder(),
//                 ),
//                 items: roles
//                     .map(
//                       (role) => DropdownMenuItem(
//                         value: role.id,
//                         child: Text(role.name),
//                       ),
//                     )
//                     .toList(),
//                 onChanged: (value) {
//                   if (value != null) {
//                     final selectedRole = roles.firstWhere((r) => r.id == value);
//                     setState(() {
//                       _selectedRoleId = value;
//                       _selectedRoleName = selectedRole.name;
//                     });
//                   }
//                 },
//                 validator: (value) {
//                   if (value == null) {
//                     return 'Please select a role';
//                   }
//                   return null;
//                 },
//               );
//             },
//             loading: () => Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                   const SizedBox(width: 12),
//                   const Text('Loading roles...'),
//                 ],
//               ),
//             ),
//             error: (error, stackTrace) => Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.red[50],
//                 border: Border.all(color: Colors.red),
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Row(
//                 children: [
//                   Icon(Icons.error, color: Colors.red[700]),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Text(
//                       'Error loading roles: $error',
//                       style: TextStyle(color: Colors.red[900]),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Extra Permissions Section
//           Text(
//             'Extra Permissions (Optional)',
//             style: Theme.of(
//               context,
//             ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Add permissions beyond the assigned role',
//             style: Theme.of(
//               context,
//             ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
//           ),
//           const SizedBox(height: 12),

//           // Permissions Chips with async handling
//           permissionsAsync.when(
//             data: (permissionState) {
//               final permissions = permissionState.permissions
//                   .where((p) => p.isActive && p.isShowingToAllAdmins)
//                   .toList();

//               if (permissions.isEmpty) {
//                 return Text(
//                   'No permissions available',
//                   style: Theme.of(
//                     context,
//                   ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
//                 );
//               }

//               return Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: permissions
//                     .map(
//                       (permission) =>
//                           _buildPermissionChip(permission.id, permission.name),
//                     )
//                     .toList(),
//               );
//             },
//             loading: () => Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Row(
//                 children: [
//                   const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                   const SizedBox(width: 12),
//                   const Text('Loading permissions...'),
//                 ],
//               ),
//             ),
//             error: (error, stackTrace) => Text(
//               'Error loading permissions: $error',
//               style: const TextStyle(color: Colors.red),
//             ),
//           ),
//           const SizedBox(height: 24),

//           // Info Box
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Theme.of(context).colorScheme.surfaceVariant,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 Icon(
//                   Icons.info_outline,
//                   color: Theme.of(context).colorScheme.primary,
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Text(
//                     _isEditMode
//                         ? 'Changes will take effect immediately.'
//                         : 'An invitation email will be sent to the staff member.',
//                     style: Theme.of(context).textTheme.bodySmall,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildPermissionChip(String permissionId, String permissionName) {
//     final isSelected = _selectedExtraPermissions.containsKey(permissionId);

//     return FilterChip(
//       label: Text(permissionName),
//       selected: isSelected,
//       onSelected: (selected) {
//         setState(() {
//           if (selected) {
//             _selectedExtraPermissions[permissionId] = permissionName;
//           } else {
//             _selectedExtraPermissions.remove(permissionId);
//           }
//         });
//       },
//       backgroundColor: Colors.transparent,
//       selectedColor: Theme.of(context).colorScheme.primaryContainer,
//       side: BorderSide(
//         color: isSelected
//             ? Theme.of(context).colorScheme.primary
//             : Colors.grey[300]!,
//       ),
//     );
//   }

//   Widget _buildActions(BuildContext context, dynamic staffState) {
//     return Container(
//       padding: const EdgeInsets.all(20),
//       decoration: BoxDecoration(
//         color: Theme.of(context).colorScheme.surface,
//         border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.end,
//         children: [
//           TextButton(
//             onPressed: staffState.isLoading
//                 ? null
//                 : () => Navigator.pop(context),
//             child: const Text('Cancel'),
//           ),
//           const SizedBox(width: 12),
//           FilledButton(
//             onPressed: staffState.isLoading ? null : _handleSubmit,
//             child: staffState.isLoading
//                 ? const SizedBox(
//                     width: 20,
//                     height: 20,
//                     child: CircularProgressIndicator(
//                       strokeWidth: 2,
//                       valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                     ),
//                   )
//                 : Text(_isEditMode ? 'Update' : 'Add Staff'),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _handleSubmit() async {
//     if (!_formKey.currentState!.validate()) return;

//     final notifier = ref.read(userProvider.notifier);

//     bool success;

//     if (_isEditMode) {
//       success = await notifier.updateStaffMember(
//         uid: widget.staff!.uid,
//         roleId: _selectedRoleId!,
//         extraPermissions: _selectedExtraPermissions,
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//         name: _nameController.text.isNotEmpty ? _nameController.text : null,
//         phoneNumber: _phoneController.text.isNotEmpty
//             ? _phoneController.text
//             : null,
//       );
//     } else {
//       success = await notifier.addStaffMember(
//         email: _emailController.text.trim(),
//         roleId: _selectedRoleId!,
//         roleName: _selectedRoleName ?? 'Staff Member',
//         extraPermissions: _selectedExtraPermissions,
//         businessId: widget.businessId,
//         branchId: widget.branchId,
//         name: _nameController.text.isNotEmpty ? _nameController.text : null,
//         phoneNumber: _phoneController.text.isNotEmpty
//             ? _phoneController.text
//             : null,
//       );
//     }

//     if (success && mounted) {
//       Navigator.pop(context);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//             _isEditMode
//                 ? 'Staff member updated successfully'
//                 : 'Staff member added successfully',
//           ),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }
// }
