import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/features/super_admin/application/super_admin_providers.dart';
import 'package:hotel_management_system/features/super_admin/domain/entities/super_admin_entities.dart';

class CreateBusinessWizardDialog extends ConsumerStatefulWidget {
  const CreateBusinessWizardDialog({super.key});

  @override
  ConsumerState<CreateBusinessWizardDialog> createState() =>
      _CreateBusinessWizardDialogState();
}

class _CreateBusinessWizardDialogState
    extends ConsumerState<CreateBusinessWizardDialog> {
  int _step = 0;
  bool _submitting = false;

  final _businessName = TextEditingController();
  String _industry = 'Restaurant';
  final _country = TextEditingController(text: 'Pakistan');
  final _city = TextEditingController();

  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _ownerPhone = TextEditingController();
  final _ownerPassword = TextEditingController();

  String _plan = 'Trial';

  final _maxBranches = TextEditingController(text: '1');
  final _maxUsers = TextEditingController(text: '5');
  final _maxOrders = TextEditingController(text: '500');
  final _storageMb = TextEditingController(text: '1024');

  bool _qrEnabled = true;
  bool _onlineEnabled = true;
  bool _customerAppEnabled = true;
  bool _hotelModuleEnabled = false;
  bool _inventoryEnabled = true;

  @override
  void dispose() {
    _businessName.dispose();
    _ownerName.dispose();
    _ownerEmail.dispose();
    _ownerPhone.dispose();
    _ownerPassword.dispose();
    _country.dispose();
    _city.dispose();
    _maxBranches.dispose();
    _maxUsers.dispose();
    _maxOrders.dispose();
    _storageMb.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 920,
        child: Stepper(
          currentStep: _step,
          onStepContinue: _onContinue,
          onStepCancel: _onCancel,
          controlsBuilder: (context, details) {
            final isLast = _step == 4;
            return Row(
              children: [
                ElevatedButton(
                  onPressed: _submitting ? null : details.onStepContinue,
                  child: Text(isLast ? 'Create Business' : 'Continue'),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: _submitting ? null : details.onStepCancel,
                  child: Text(_step == 0 ? 'Close' : 'Back'),
                ),
              ],
            );
          },
          steps: [
            Step(
              isActive: _step >= 0,
              title: const Text('Business Information'),
              content: Column(
                children: [
                  TextField(
                    controller: _businessName,
                    decoration: const InputDecoration(
                      labelText: 'Business Name',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _country,
                    decoration: const InputDecoration(labelText: 'Country'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: 'City'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _industry,
                    items:
                        const [
                              'Restaurant',
                              'Hotel',
                              'Cafe',
                              'Bakery',
                              'Food Court',
                              'Juice Bar',
                              'Retail',
                              'Custom',
                            ]
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(growable: false),
                    onChanged: (v) =>
                        setState(() => _industry = v ?? 'Restaurant'),
                    decoration: const InputDecoration(
                      labelText: 'Industry Type',
                    ),
                  ),
                ],
              ),
            ),
            Step(
              isActive: _step >= 1,
              title: const Text('Owner Information'),
              content: Column(
                children: [
                  TextField(
                    controller: _ownerName,
                    decoration: const InputDecoration(labelText: 'Owner Name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ownerEmail,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ownerPhone,
                    decoration: const InputDecoration(labelText: 'Phone'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ownerPassword,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                ],
              ),
            ),
            Step(
              isActive: _step >= 2,
              title: const Text('Subscription Plan'),
              content: DropdownButtonFormField<String>(
                initialValue: _plan,
                items:
                    const ['Trial', 'Basic', 'Premium', 'Enterprise', 'Custom']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(growable: false),
                onChanged: (v) => setState(() => _plan = v ?? 'Trial'),
                decoration: const InputDecoration(labelText: 'Selected Plan'),
              ),
            ),
            Step(
              isActive: _step >= 3,
              title: const Text('Business Limits'),
              content: Column(
                children: [
                  TextField(
                    controller: _maxBranches,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Branches',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _maxUsers,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Max Users'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _maxOrders,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max Orders Per Month',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _storageMb,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Storage Limit (MB)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _qrEnabled,
                    onChanged: (v) => setState(() => _qrEnabled = v),
                    title: const Text('QR Ordering Enabled'),
                  ),
                  SwitchListTile(
                    value: _onlineEnabled,
                    onChanged: (v) => setState(() => _onlineEnabled = v),
                    title: const Text('Online Ordering Enabled'),
                  ),
                  SwitchListTile(
                    value: _customerAppEnabled,
                    onChanged: (v) => setState(() => _customerAppEnabled = v),
                    title: const Text('Customer App Enabled'),
                  ),
                  SwitchListTile(
                    value: _hotelModuleEnabled,
                    onChanged: (v) => setState(() => _hotelModuleEnabled = v),
                    title: const Text('Hotel Module Enabled'),
                  ),
                  SwitchListTile(
                    value: _inventoryEnabled,
                    onChanged: (v) => setState(() => _inventoryEnabled = v),
                    title: const Text('Inventory Module Enabled'),
                  ),
                ],
              ),
            ),
            Step(
              isActive: _step >= 4,
              title: const Text('Create Business'),
              content: const Text(
                'This will create tenant, owner account, default branch, default settings, and subscription, then trigger welcome email.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onContinue() async {
    if (_step < 4) {
      final error = _validateCurrentStep();
      if (error != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
        return;
      }
      setState(() => _step++);
      return;
    }

    setState(() => _submitting = true);
    try {
      final request = CreateBusinessRequest(
        businessName: _businessName.text.trim(),
        industryType: _industry,
        country: _country.text.trim(),
        city: _city.text.trim(),
        ownerName: _ownerName.text.trim(),
        ownerEmail: _ownerEmail.text.trim(),
        ownerPhone: _ownerPhone.text.trim(),
        ownerPassword: _ownerPassword.text,
        selectedPlan: _plan,
        maxBranches: int.tryParse(_maxBranches.text) ?? 1,
        maxUsers: int.tryParse(_maxUsers.text) ?? 5,
        maxOrdersPerMonth: int.tryParse(_maxOrders.text) ?? 500,
        storageLimitMb: int.tryParse(_storageMb.text) ?? 1024,
        qrOrderingEnabled: _qrEnabled,
        onlineOrderingEnabled: _onlineEnabled,
        customerAppEnabled: _customerAppEnabled,
        hotelModuleEnabled: _hotelModuleEnabled,
        inventoryModuleEnabled: _inventoryEnabled,
      );

      final businessId = await ref
          .read(superAdminRepositoryProvider)
          .createBusinessTenant(request);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Business created successfully: $businessId')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create business: $e')));
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _onCancel() {
    if (_step == 0) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _step--);
  }

  String? _validateCurrentStep() {
    if (_step == 0) {
      if (_businessName.text.trim().isEmpty) {
        return 'Business name is required.';
      }
      if (_country.text.trim().isEmpty) {
        return 'Country is required.';
      }
      if (_city.text.trim().isEmpty) {
        return 'City is required.';
      }
    }

    if (_step == 1) {
      if (_ownerName.text.trim().isEmpty) {
        return 'Owner name is required.';
      }
      if (!_ownerEmail.text.contains('@')) {
        return 'Valid owner email is required.';
      }
      if (_ownerPhone.text.trim().length < 7) {
        return 'Valid owner phone is required.';
      }
      if (_ownerPassword.text.length < 6) {
        return 'Owner password must be at least 6 characters.';
      }
    }

    if (_step == 3) {
      if ((int.tryParse(_maxBranches.text) ?? 0) <= 0) {
        return 'Max branches must be greater than 0.';
      }
      if ((int.tryParse(_maxUsers.text) ?? 0) <= 0) {
        return 'Max users must be greater than 0.';
      }
      if ((int.tryParse(_maxOrders.text) ?? 0) <= 0) {
        return 'Max orders per month must be greater than 0.';
      }
      if ((int.tryParse(_storageMb.text) ?? 0) <= 0) {
        return 'Storage limit must be greater than 0.';
      }
    }

    return null;
  }
}
