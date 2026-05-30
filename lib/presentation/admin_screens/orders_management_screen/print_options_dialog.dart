// print_options_dialog.dart
import 'package:flutter/material.dart';
import 'package:hotel_management_system/presentation/admin_screens/orders_management_screen/order_recipt_pdf_generator.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:hotel_management_system/data/models/order_model.dart';

class PrintOptionsDialog extends StatelessWidget {
  final OrderModel order;
  final String? roomName;

  const PrintOptionsDialog({super.key, required this.order, this.roomName});

  Future<void> _handlePrint(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF
      final pdf = await OrderPdfGenerator.generateOrderPdf(
        order: order,
        roomName: roomName,
        includeTax: false, // Change to true when you want tax
      );

      // Close loading
      Navigator.of(context).pop();

      // Print
      await OrderPdfGenerator.printPdf(pdf);

      Navigator.of(context).pop(); // Close options dialog
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error printing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleSave(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF
      final pdf = await OrderPdfGenerator.generateOrderPdf(
        order: order,
        roomName: roomName,
        includeTax: false,
      );

      // Save to device
      final fileName =
          'Order_${order.orderId}_${DateTime.now().millisecondsSinceEpoch}';
      final file = await OrderPdfGenerator.savePdfToDevice(pdf, fileName);

      // Close loading
      Navigator.of(context).pop();
      Navigator.of(context).pop(); // Close options dialog

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Open',
            onPressed: () async {
              // Open the saved PDF
              await OrderPdfGenerator.printPdf(
                pw.Document()..addPage(
                  pw.Page(
                    build: (context) =>
                        pw.Center(child: pw.Text('Opening saved PDF...')),
                  ),
                ),
              );
            },
          ),
        ),
      );
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleShare(BuildContext context) async {
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Generate PDF
      final pdf = await OrderPdfGenerator.generateOrderPdf(
        order: order,
        roomName: roomName,
        includeTax: false,
      );

      // Close loading
      Navigator.of(context).pop();

      // Share PDF
      final fileName = 'Order_${order.orderId}';
      await OrderPdfGenerator.sharePdf(pdf, fileName);

      Navigator.of(context).pop(); // Close options dialog
    } catch (e) {
      Navigator.of(context).pop(); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.print,
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Print Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how to handle the order receipt',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.print),
                title: const Text('Print Receipt'),
                subtitle: const Text('Send directly to printer'),
                onTap: () => _handlePrint(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.save),
                title: const Text('Save to Device'),
                subtitle: const Text('Save PDF to documents'),
                onTap: () => _handleSave(context),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.share),
                title: const Text('Share PDF'),
                subtitle: const Text('Share via other apps'),
                onTap: () => _handleShare(context),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
