import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/core/utils/offline_order_queue_service.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_button.dart';
import 'package:hotel_management_system/presentation/common_widgets/custom_text_field.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/client_cart_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/order_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/tenant_context_provider.dart';
import 'package:uuid/uuid.dart';

class CheckOutScreen extends ConsumerStatefulWidget {
  final List<OrderItem> items;
  final double totalAmount;
  const CheckOutScreen({
    super.key,
    required this.items,
    required this.totalAmount,
  });

  @override
  ConsumerState<CheckOutScreen> createState() => _CheckOutScreenState();
}

class _CheckOutScreenState extends ConsumerState<CheckOutScreen> {
  String selectedValue = 'Door delivery';
  OrderType type = OrderType.delivery;
  bool isLoading = false; // Add loading state

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  bool get isLoggedIn => FirebaseAuth.instance.currentUser != null;

  // Validator methods
  String? _nameValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your name';
    }

    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your phone number';
    }

    return null;
  }

  String? _addressValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your address';
    }

    return null;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final bool isMobile = screenWidth < 600;
    final bool isTablet = screenWidth >= 600 && screenWidth < 1024;
    final bool isDesktop = screenWidth >= 1024;

    final double maxContentWidth = isDesktop
        ? 800
        : isTablet
        ? 600
        : double.infinity;
    final double horizontalPadding = isMobile ? 16 : 24;
    final double verticalPadding = isMobile ? 16 : 24;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.goNamed(ClientAppRoutes.cartScreen);
          },
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Checkout'),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    // Address Section
                    Row(
                      children: [
                        Text(
                          'Address Details',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        CustomTextField(
                          keyBoardType: TextInputType.name,
                          controller: nameController,
                          validator: _nameValidator,
                          hint: 'Name',
                        ),

                        const SizedBox(height: 20),
                        CustomTextField(
                          validator: _phoneValidator,
                          keyBoardType: TextInputType.phone,
                          controller: phoneController,
                          hint: 'Phone',
                        ),
                        const SizedBox(height: 20),
                        CustomTextField(
                          keyBoardType: TextInputType.streetAddress,
                          controller: addressController,
                          validator: _addressValidator,
                          hint: 'Address',
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Delivery Method
                    _buildDeliveryMethodCard(context, isMobile: isMobile),
                    const SizedBox(height: 16),
                    // Total
                    Row(
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Spacer(),
                        Text(
                          '${widget.totalAmount} RS',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Confirm Button
                    CustomButton(
                      text: isLoading ? 'Placing Order...' : 'Confirm Order',
                      onTap: isLoading
                          ? () {}
                          : () async {
                              if (formKey.currentState!.validate()) {
                                setState(() {
                                  isLoading = true;
                                });

                                try {
                                  // Create the order model with optional email
                                  final order = OrderModel(
                                    orderId: Uuid().v4(),
                                    userId:
                                        '${nameController.text}${DateTime.now().millisecondsSinceEpoch}',
                                    userName: nameController.text,
                                    orderType: OrderType.delivery,
                                    userPhoneNo: phoneController.text,
                                    deliveryAddress: addressController.text,
                                    items: widget.items,
                                    totalAmount: widget.totalAmount,
                                    orderStatus: OrderStatus.pending,
                                    createdAt: DateTime.now(),
                                    updatedAt: DateTime.now(),
                                  );

                                  // Wait for the order to be created
                                  final hasInternet =
                                      await OfflineOrderQueueService.instance
                                          .hasInternetConnection();
                                  if (hasInternet) {
                                    await ref
                                        .read(orderNotifierProvider)
                                        .createOrder(order);
                                  } else {
                                    final tenantContext = ref.read(
                                      tenantContextProvider,
                                    );
                                    await OfflineOrderQueueService.instance
                                        .enqueueOrder(
                                          businessId: tenantContext.businessId,
                                          branchId: tenantContext.branchId,
                                          order: order,
                                        );
                                  }

                                  // Clear the cart after successful order
                                  ref.read(cartProvider.notifier).clearCart();

                                  // Show success dialog
                                  if (mounted) {
                                    _buildOrderSuccessDialogue();
                                  }
                                } catch (e) {
                                  // Show error message
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Failed to place order: $e',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() {
                                      isLoading = false;
                                    });
                                  }
                                }
                              }
                            },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressBox(
    BuildContext context, {
    required String name,
    required String address,
    required String phone,
    required String email,
    required bool isMobile,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 5,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 10 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Name: $name",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Text(
                "Email: $email",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Text(
                "Address: $address",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              Text(
                "Phone: $phone",
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliveryMethodCard(
    BuildContext context, {
    required bool isMobile,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 5,
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 8 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Type',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: isMobile ? 12 : 20),
              RadioListTile(
                value: 'Door delivery',
                groupValue: selectedValue,
                title: const Text('Door delivery'),
                onChanged: (value) {
                  setState(() {
                    selectedValue = value!;
                    type = OrderType.delivery;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _buildOrderSuccessDialogue() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (dialogContext) {
        return AlertDialog(
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 60, // Increased size for better visibility
                ),
                const SizedBox(height: 20),
                Text(
                  'Order placed successfully!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop(); // Close dialog
                      if (!mounted) return;
                      context.goNamed(
                        ClientAppRoutes.shell,
                      ); // Navigate to home
                    },
                    child: const Text('Continue Shopping'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
