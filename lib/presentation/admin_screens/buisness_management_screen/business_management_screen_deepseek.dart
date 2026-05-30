import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/buisness_model.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/buisness_state_and_notifier.dart';

// Import your business model and providers here
// import 'path/to/your/business_model.dart';
// import 'path/to/your/business_providers.dart';

class BusinessManagementScreen extends ConsumerStatefulWidget {
  const BusinessManagementScreen({super.key});

  @override
  ConsumerState<BusinessManagementScreen> createState() =>
      _BusinessManagementScreenState();
}

class _BusinessManagementScreenState
    extends ConsumerState<BusinessManagementScreen> {
  @override
  void initState() {
    super.initState();
    // Load businesses when the screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(businessProvider.notifier).loadBusinesses();
    });
  }

  @override
  Widget build(BuildContext context) {
    final businessState = ref.watch(businessProvider);
    final businessNotifier = ref.read(businessProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to create business screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BusinessFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _buildBody(businessState, businessNotifier),
    );
  }

  Widget _buildBody(BusinessState state, BusinessNotifier notifier) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => notifier.loadBusinesses(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.businesses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('No businesses found'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BusinessFormScreen(),
                  ),
                );
              },
              child: const Text('Create Business'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: state.businesses.length,
      itemBuilder: (context, index) {
        final business = state.businesses[index];
        return _BusinessListItem(
          business: business,
          isSelected: state.selectedBusiness?.id == business.id,
          onTap: () => notifier.selectBusiness(business.id),
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    BusinessFormScreen(businessId: business.id),
              ),
            );
          },
          onDelete: () => _showDeleteDialog(context, business, notifier),
        );
      },
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    BusinessModel business,
    BusinessNotifier notifier,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Business'),
          content: Text(
            'Are you sure you want to delete ${business.title}? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                notifier.softDeleteBusiness(business.id);
                Navigator.of(context).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class _BusinessListItem extends StatelessWidget {
  final BusinessModel business;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _BusinessListItem({
    required this.business,
    required this.isSelected,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSelected
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: business.logoUrl != null
            ? CircleAvatar(
                backgroundImage: NetworkImage(business.logoUrl!),
                radius: 20,
              )
            : CircleAvatar(radius: 20, child: Text(business.title[0])),
        title: Text(business.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (business.industryType.isNotEmpty)
              Text('Industry: ${business.industryType}'),
            if (business.city != null) Text('City: ${business.city}'),
            Text(
              business.isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                color: business.isActive
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: ListTile(leading: Icon(Icons.edit), title: Text('Edit')),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete),
                title: Text('Delete'),
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else if (value == 'delete') {
              onDelete();
            }
          },
        ),
        onTap: onTap,
      ),
    );
  }
}

// Create/Edit Business Form Screen
class BusinessFormScreen extends ConsumerStatefulWidget {
  final String? businessId;

  const BusinessFormScreen({super.key, this.businessId});

  @override
  ConsumerState<BusinessFormScreen> createState() => _BusinessFormScreenState();
}

class _BusinessFormScreenState extends ConsumerState<BusinessFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _taxPercentageController;

  BusinessModel? _existingBusiness;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _addressController = TextEditingController();
    _cityController = TextEditingController();
    _taxPercentageController = TextEditingController();

    // If editing, load the business data
    if (widget.businessId != null) {
      _loadBusinessData();
    }
  }

  Future<void> _loadBusinessData() async {
    setState(() => _isLoading = true);
    try {
      // business = await ref.read(businessProvider.notifier).
      final business = ref
          .read(businessProvider.notifier)
          .getSelectedBusiness();
      // .getBusinessById(widget.businessId!);
      if (business == null) return;
      setState(() {
        _existingBusiness = business;
        _titleController.text = business.title;
        _descriptionController.text = business.description ?? '';
        _phoneController.text = business.phone ?? '';
        _emailController.text = business.email ?? '';
        _addressController.text = business.address ?? '';
        _cityController.text = business.city ?? '';
        _taxPercentageController.text = business.taxPercentage.toString();
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load business: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _taxPercentageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.businessId != null ? 'Edit Business' : 'Create Business',
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a business name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      decoration: const InputDecoration(
                        labelText: 'Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _taxPercentageController,
                      decoration: const InputDecoration(
                        labelText: 'Tax Percentage',
                        border: OutlineInputBorder(),
                        suffixText: '%',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submitForm,
                      child: const Text('Save Business'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final business = BusinessModel(
        id: _existingBusiness?.id ?? 'demoBusinessId',
        ownerId:
            _existingBusiness?.ownerId ??
            'current_user_id', // You need to get the current user ID
        title: _titleController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        phone: _phoneController.text.isEmpty ? null : _phoneController.text,
        email: _emailController.text.isEmpty ? null : _emailController.text,
        address: _addressController.text.isEmpty
            ? null
            : _addressController.text,
        city: _cityController.text.isEmpty ? null : _cityController.text,
        taxPercentage: double.tryParse(_taxPercentageController.text) ?? 0.0,
        // Add other fields as needed
      );

      final notifier = ref.read(businessProvider.notifier);
      if (widget.businessId != null) {
        notifier.updateBusiness(business);
      } else {
        notifier.addBusiness(business);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.businessId != null
                ? 'Business updated successfully'
                : 'Business created successfully',
          ),
        ),
      );

      // Navigate back
      Navigator.of(context).pop();
    }
  }
}
