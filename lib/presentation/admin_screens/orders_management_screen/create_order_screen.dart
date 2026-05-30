// create_order_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hotel_management_system/data/services/thermal_printer_service.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/delivery_map_picker_dialog_for_taking_order.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/order_recipt_pdf_generator.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/product_selection_dialog_for_taking_order.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/table_selection_dialog.dart';
import 'package:hotel_management_system/routes/admin_app_routes.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:pdf/widgets.dart' as pw;

class CreateOrderScreen extends ConsumerStatefulWidget {
  final String businessId;
  final String branchId;

  const CreateOrderScreen({
    super.key,
    required this.businessId,
    required this.branchId,
  });

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _deliveryAddressController = TextEditingController();
  final _additionalNotesController = TextEditingController();
  LatLng? _deliveryLocation;
  OrderType _selectedOrderType = OrderType.dining;
  TableModel? _selectedTable;
  List<OrderItem> _orderItems = [];
  bool _isSubmitting = false;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _deliveryAddressController.dispose();
    _additionalNotesController.dispose();
    super.dispose();
  }

  double get _totalAmount {
    return _orderItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  void _showTableSelectionDialog() {
    // final tables = ref
    //     .read(
    //       tableProvider((
    //         businessId: widget.businessId,
    //         branchId: widget.branchId,
    //       )),
    //     )
    //     .tables;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => TableSelectionDialog(
        // availableTables: tables,
        businessId: widget.businessId,
        branchId: widget.branchId,
        currentTable: _selectedTable,
        onTableSelected: (selectedTable) {
          setState(() {
            _selectedTable = selectedTable;
          });
        },
      ),
    );
  }

  void _showProductSelectionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProductSelectionDialog(
        businessId: widget.businessId,
        branchId: widget.branchId,
        currentOrderItems: _orderItems,
        onProductsSelected: (selectedItems) {
          setState(() {
            _orderItems = selectedItems;
          });
        },
      ),
    );
  }

  void _showDeliveryMapPicker() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DeliveryMapPickerDialog(
        initialLocation: null, // or pass existing location if editing
        initialAddress: _deliveryAddressController.text,
        onLocationSelected: (location, address) {
          setState(() {
            _deliveryAddressController.text = address;
            // Store location if needed: _deliveryLocation = location;
          });
        },
      ),
    );
  }

  // Replace the _placeOrder() method in your CreateOrderScreen with this:

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation based on order type
    if (_selectedOrderType == OrderType.dining && _selectedTable == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a table for dining order'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Additional validation for delivery
    if (_selectedOrderType == OrderType.delivery) {
      if (_deliveryAddressController.text.trim().isEmpty &&
          _deliveryLocation == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please provide delivery address or select location from map',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(userProvider).selectedUser;
      if (user == null) {
        throw Exception('User not found');
      }

      // Create order model
      final order = OrderModel(
        orderId: '', // Will be generated by Firestore
        userId:
            null, //---------------------------------ONLY USED WHEN USER BY CLIENT APP MAKES ORDER-----------------------//
        userName: _customerNameController.text.trim(),
        userPhoneNo: _customerPhoneController.text.trim().isEmpty
            ? null
            : _customerPhoneController.text.trim(),
        orderType: _selectedOrderType,
        items: _orderItems,
        totalAmount: _totalAmount,
        orderStatus: OrderStatus.pending,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),

        // Delivery-specific fields
        deliveryAddress: _selectedOrderType == OrderType.delivery
            ? _deliveryAddressController.text.trim()
            : null,
        deliveryLocation: _selectedOrderType == OrderType.delivery
            ? _deliveryLocation
            : null,

        // Dining-specific fields
        diningTable: _selectedOrderType == OrderType.dining
            ? _selectedTable
            : null,
        waiterId: _selectedOrderType == OrderType.dining ? user.uid : null,
        waiterName: _selectedOrderType == OrderType.dining ? user.name : null,
        // Additional notes from user
        additionalNotes: _additionalNotesController.text.trim().isEmpty
            ? null
            : _additionalNotesController.text.trim(),
      );

      // Create order using order notifier
      final orderNotifier = ref.read(
        orderProvider((
          businessId: widget.businessId,
          branchId: widget.branchId,
          tableNotifier: ref.read(
            tableProvider((
              businessId: widget.businessId,
              branchId: widget.branchId,
            )).notifier,
          ),
        )).notifier,
      );

      await orderNotifier.createOrder(order);
      final orderState = ref.read(
        orderProvider((
          businessId: widget.businessId,
          branchId: widget.branchId,
          tableNotifier: ref.read(
            tableProvider((
              businessId: widget.businessId,
              branchId: widget.branchId,
            )).notifier,
          ),
        )),
      );

      final success = (!orderState.isLoading && orderState.error == null)
          ? true
          : false;
      setState(() => _isSubmitting = false);

      if (success && mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        try {
          await ThermalPrinterService().printOrderLAN(
            type: 'Waiter Copy',
            order,
          );
          await ThermalPrinterService().printOrderLAN(
            type: 'Customer Copy',
            order,
          );
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(e.toString())));
        }
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.green,
            content: Text('Printing Receipt....'),
          ),
        );

        Navigator.pop(context);
        // Show confirmation dialog and print recipt for kitchen
        // _showOrderConfirmationDialog(order);
      } else {
        // Show error from notifier
        final errorState = ref.read(
          orderProvider((
            businessId: widget.businessId,
            branchId: widget.branchId,
            tableNotifier: ref.read(
              tableProvider((
                businessId: widget.businessId,
                branchId: widget.branchId,
              )).notifier,
            ),
          )),
        );

        throw Exception(errorState.error ?? 'Failed to create order');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // void _showPrintConfirmationDialog(OrderModel order) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Order Placed Successfully'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(Icons.check_circle, size: 64, color: Colors.green),
  //           const SizedBox(height: 16),
  //           Text(
  //             'Order ID: ${order.orderId}',
  //             style: Theme.of(context).textTheme.titleMedium,
  //           ),
  //           const SizedBox(height: 8),
  //           const Text('Order has been placed successfully.'),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop(); // Close dialog
  //             Navigator.of(context).pop(); // Close create order screen
  //           },
  //           child: const Text('No'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () async {
  //             Navigator.of(context).pop(); // Close confirmation dialog

  //             // Show loading
  //             showDialog(
  //               context: context,
  //               barrierDismissible: false,
  //               builder: (context) =>
  //                   const Center(child: CircularProgressIndicator()),
  //             );

  //             try {
  //               // Generate PDF
  //               final pdf = await OrderPdfGenerator.generateOrderPdf(
  //                 order: order,
  //                 roomName: _selectedTable?.roomId != null
  //                     ? _getRoomName(_selectedTable!.roomId!)
  //                     : null,
  //                 includeTax: false, // Change to true when you want tax
  //               );

  //               // Close loading
  //               Navigator.of(context).pop();

  //               // Print automatically
  //               await OrderPdfGenerator.printPdf(pdf);

  //               // Show success message
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: const Text('Printing receipt...'),
  //                   backgroundColor: Colors.green,
  //                 ),
  //               );

  //               // Ask if the user wants to save or share the PDF
  //               _showSaveOrShareDialog(order, pdf);
  //             } catch (e) {
  //               Navigator.of(context).pop(); // Close loading
  //               ScaffoldMessenger.of(context).showSnackBar(
  //                 SnackBar(
  //                   content: Text('Error printing: $e'),
  //                   backgroundColor: Colors.red,
  //                 ),
  //               );
  //             }
  //           },
  //           child: const Text('Yes, Print'),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  void _showOrderConfirmationDialog(OrderModel order) {
    // Wait for 2 seconds and then trigger printing
    Future.delayed(const Duration(seconds: 2), () async {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        // Generate PDF
        // final pdf = await OrderPdfGenerator.generateOrderPdf(
        //   order: order,
        //   roomName: _selectedTable?.roomId != null
        //       ? _getRoomName(_selectedTable!.roomId!)
        //       : null,
        //   includeTax: false, // Change to true when you want tax
        // );

        // Close loading
        Navigator.of(context).pop();

        // Print automatically
        // await OrderPdfGenerator.printPdf(pdf);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Printing receipt...'),
            backgroundColor: Colors.green,
          ),
        );

        // Ask if the user wants to save or share the PDF
        // _showSaveOrShareDialog(order, pdf);
      } catch (e) {
        Navigator.of(context).pop(); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Order Placed Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text(
              'Order ID: ${order.orderId}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text('Order has been placed successfully.'),
            Row(children: [Text("Printing recipt in 2 seconds")]),
          ],
        ),
        // actions: [
        //   TextButton(
        //     onPressed: () {
        //       Navigator.of(context).pop(); // Close dialog
        //       Navigator.of(context).pop(); // Close create order screen
        //     },
        //     child: const Text('No'),
        //   ),
        //   ElevatedButton(
        //     onPressed: () {
        //       Navigator.of(context).pop(); // Close confirmation dialog

        //       // Wait for 2 seconds and then trigger printing
        //     },

        //   ),
        // ],
      ),
    );
  }

  void _showSaveOrShareDialog(OrderModel order, pw.Document pdf) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Receipt Printed'),
        content: const Text('Do you want to save, share, or close?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog

              // Save PDF to device
              try {
                final fileName =
                    'Order_${order.orderId}_${DateTime.now().millisecondsSinceEpoch}';
                final file = await OrderPdfGenerator.savePdfToDevice(
                  pdf,
                  fileName,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('PDF saved to: ${file.path}'),
                    backgroundColor: Colors.green,
                    action: SnackBarAction(
                      label: 'Open',
                      onPressed: () async {
                        await OrderPdfGenerator.printPdf(pdf);
                      },
                    ),
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error saving: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Save to Device'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop(); // Close dialog

              // Share PDF
              try {
                final fileName = 'Order_${order.orderId}';
                await OrderPdfGenerator.sharePdf(pdf, fileName);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error sharing: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Share PDF'),
          ),
        ],
      ),
    );
  }

  // void _showPrintConfirmationDialog(OrderModel order) {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('Order Placed Successfully'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Icon(Icons.check_circle, size: 64, color: Colors.green),
  //           const SizedBox(height: 16),
  //           Text(
  //             'Order ID: ${order.orderId}',
  //             style: Theme.of(context).textTheme.titleMedium,
  //           ),
  //           const SizedBox(height: 8),
  //           const Text('Would you like to print the receipt?'),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () {
  //             Navigator.of(context).pop(); // Close dialog
  //             Navigator.of(context).pop(); // Close create order screen
  //           },
  //           child: const Text('No'),
  //         ),
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.of(context).pop(); // Close confirmation dialog

  //             // Show print options
  //             showDialog(
  //               context: context,
  //               builder: (context) => PrintOptionsDialog(
  //                 order: order,
  //                 roomName: _selectedTable?.roomId != null
  //                     ? _getRoomName(_selectedTable!.roomId!)
  //                     : null,
  //               ),
  //             ).then((_) {
  //               // After printing, go back to order list
  //               Navigator.of(context).pop();
  //             });
  //           },
  //           child: const Text('Yes, Print'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Add helper method to get room name
  String? _getRoomName(String roomId) {
    final rooms = ref
        .read(
          roomProvider((
            businessId: widget.businessId,
            branchId: widget.branchId,
          )),
        )
        .rooms;

    try {
      final room = rooms.firstWhere((r) => r.id == roomId);
      return room.name;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            // onPressed: () async {
            //   _orderItems.isEmpty
            //       ? null
            //       : () async {
            //           // await ThermalPrinterService().printOrderLAN(
            //           //   OrderModel(
            //           //     orderId:
            //           //         'PREVIEW-${DateTime.now().millisecondsSinceEpoch}',
            //           //     userId: ref.read(userProvider).selectedUser!.uid,
            //           //     userName: _customerNameController.text.trim(),
            //           //     userPhoneNo:
            //           //         _customerPhoneController.text.trim().isEmpty
            //           //         ? null
            //           //         : _customerPhoneController.text.trim(),
            //           //     orderType: _selectedOrderType,
            //           //     items: _orderItems,
            //           //     totalAmount: _totalAmount,
            //           //     orderStatus: OrderStatus.pending,
            //           //     createdAt: DateTime.now(),
            //           //     updatedAt: DateTime.now(),
            //           //     deliveryAddress:
            //           //         _selectedOrderType == OrderType.delivery
            //           //         ? _deliveryAddressController.text.trim()
            //           //         : null,
            //           //     deliveryLocation:
            //           //         _selectedOrderType == OrderType.delivery
            //           //         ? _deliveryLocation
            //           //         : null,
            //           //     diningTable: _selectedOrderType == OrderType.dining
            //           //         ? _selectedTable
            //           //         : null,
            //           //     waiterId: _selectedOrderType == OrderType.dining
            //           //         ? ref.read(userProvider).selectedUser!.uid
            //           //         : null,
            //           //     waiterName: _selectedOrderType == OrderType.dining
            //           //         ? ref.read(userProvider).selectedUser!.name
            //           //         : null,
            //           //   ),
            //           //   type: '',
            //           // );

            //         };
            // },
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('We are Working on it..')));
            },
            tooltip: 'Print Order',
          ),
          IconButton(
            onPressed: () {
              Navigator.pushNamed(context, AdminAppRoutes.printer);
            },
            icon: Icon(Icons.add_circle),
            tooltip: 'Add Printer',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildOrderTypeSelector(),
                  const SizedBox(height: 24),
                  _buildCustomerInfoSection(),
                  const SizedBox(height: 12),
                  _buildAdditionalNotesSection(),
                  const SizedBox(height: 24),
                  if (_selectedOrderType == OrderType.dining)
                    _buildTableSelectionSection(),
                  if (_selectedOrderType == OrderType.delivery) ...[
                    _buildDeliveryAddressSection(),
                    const SizedBox(height: 24),
                  ],
                  _buildProductsSection(),
                  const SizedBox(height: 24),
                ],
              ),
              _buildOrderSummary(),
              const SizedBox(height: 24),

              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Type',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: OrderType.values.map((type) {
            final isSelected = _selectedOrderType == type;
            return ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getOrderTypeIcon(type),
                    size: 18,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(_formatOrderType(type)),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedOrderType = type;
                    _selectedTable = null;
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoSection() {
    final needsPhone = _selectedOrderType == OrderType.delivery;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Customer Information',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _customerNameController,
          decoration: InputDecoration(
            labelText: 'Customer Name *',
            hintText: 'Enter customer name',
            prefixIcon: const Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Customer name is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _customerPhoneController,
          decoration: InputDecoration(
            labelText: needsPhone
                ? 'Phone Number *'
                : 'Phone Number (Optional)',
            hintText: 'Enter phone number',
            prefixIcon: const Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          keyboardType: TextInputType.phone,
          validator: needsPhone
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Phone number is required for ${_formatOrderType(_selectedOrderType)}';
                  }
                  if (value.length < 10) {
                    return 'Enter valid phone number';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildAdditionalNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Notes',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _additionalNotesController,
          decoration: InputDecoration(
            labelText: 'Additional Notes (optional)',
            hintText: 'Any special instructions or notes',
            prefixIcon: const Icon(Icons.note),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildTableSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Table Selection',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _showTableSelectionDialog,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedTable == null
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.outline,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.table_restaurant,
                  color: _selectedTable == null
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _selectedTable == null
                      ? Text(
                          'Select a table *',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedTable!.tableNumber,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Text(
                              '${_selectedTable!.seats} seats',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDeliveryAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Address',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _deliveryAddressController,
          decoration: InputDecoration(
            labelText: 'Delivery Address *',
            hintText: 'Enter delivery address',
            prefixIcon: const Icon(Icons.location_on),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Delivery address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _showDeliveryMapPicker,
          icon: const Icon(Icons.map),
          label: const Text('Pick from Map'),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Products',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: _showProductSelectionDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Products'),
            ),
          ],
        ),
        if (_orderItems.isEmpty) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No products added yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderSummary() {
    if (_orderItems.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Order Summary',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._orderItems.map(
            (item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('${item.quantity}x'),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item.productName)),
                  Text(
                    'Rs ${(item.price * item.quantity).toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Amount',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                'Rs ${_totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSubmitting
                  ? null
                  : () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _placeOrder,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Place Order'),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getOrderTypeIcon(OrderType type) {
    switch (type) {
      case OrderType.dining:
        return Icons.restaurant;
      case OrderType.takeaway:
        return Icons.shopping_bag;
      case OrderType.delivery:
        return Icons.delivery_dining;
    }
  }

  String _formatOrderType(OrderType type) {
    return type.name[0].toUpperCase() + type.name.substring(1);
  }
}
