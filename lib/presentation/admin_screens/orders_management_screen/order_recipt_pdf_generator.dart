// Features Included:
// ✅ Professional receipt layout with business header
// ✅ Order details (ID, date, time, type)
// ✅ Customer info (name, phone)
// ✅ Order-specific info (table/room for dining, address for delivery)
// ✅ Items table with qty, price, total
// ✅ Summary section with subtotal and grand total
// ✅ Tax calculation (commented out, ready to enable)
// ✅ Three options: Print, Save to Device, Share
// ✅ Direct printer support via Printing package
// ✅ Logo placeholder (replace with actual logo later)
// order_pdf_generator.dart
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/models/order_model.dart';

class OrderPdfGenerator {
  // Tax rate (commented out for later use)
  // static const double taxRate = 0.16; // 16% tax

  /// Generate PDF document
  static Future<pw.Document> generateOrderPdf({
    required OrderModel order,
    String? roomName,
    bool includeTax = false, // Set to true when you want to enable tax
  }) async {
    final pdf = pw.Document();
    final business = await BusinessRepository().getBusinessById(
      BusinessRepository.temporaryBusinesshId,
    );
    final businessName = business?.title.trim().isNotEmpty == true
        ? business!.title.trim()
        : 'Business';
    final businessLogo = business?.logoUrl?.trim().isNotEmpty == true
        ? await _tryLoadBusinessLogo(business!.logoUrl!.trim())
        : null;

    // Calculate amounts
    final subtotal = order.totalAmount;
    // final taxAmount = includeTax ? subtotal * taxRate : 0.0;
    // final grandTotal = subtotal + taxAmount;
    final grandTotal = subtotal; // Use this when tax is disabled
    final PdfPageFormat format = PdfPageFormat(80 * 200, double.infinity);

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(
                businessName: businessName,
                businessLogo: businessLogo,
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 2),
              pw.SizedBox(height: 20),
              // Order Information
              _buildOrderInfo(order),
              pw.SizedBox(height: 20),
              // Customer & Order Type Specific Info
              _buildCustomerInfo(order, roomName),
              pw.SizedBox(height: 20),
              // Items Table
              _buildItemsTable(order.items),
              pw.SizedBox(height: 20),
              // Summary Section
              _buildSummary(subtotal, grandTotal, includeTax),
              pw.SizedBox(height: 60),
              // Footer
              _buildFooter(businessName),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Build header with logo and business info
  static pw.Widget _buildHeader({
    required String businessName,
    pw.ImageProvider? businessLogo,
  }) {
    return pw.Column(
      children: [
        if (businessLogo != null)
          pw.Container(
            height: 56,
            width: 56,
            margin: const pw.EdgeInsets.only(bottom: 10),
            child: pw.Image(businessLogo, fit: pw.BoxFit.contain),
          ),
        pw.SizedBox(height: 10),
        pw.Text(
          businessName,
          style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
        ),
        // pw.SizedBox(height: 5),
        // pw.Text(
        //   businessAddress,
        //   style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        // ),
        // pw.Text(
        //   'Phone: $businessPhone | Email: $businessEmail',
        //   style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        // ),
      ],
    );
  }

  /// Build order information section
  static pw.Widget _buildOrderInfo(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey200,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'ORDER RECEIPT',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 5),
              pw.Text(
                'Order ID: ${order.orderId}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                _formatDate(order.createdAt),
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.Text(
                _formatTime(order.createdAt),
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 5),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: _getOrderTypeColor(order.orderType),
                  borderRadius: pw.BorderRadius.circular(4),
                ),
                child: pw.Text(
                  _formatOrderType(order.orderType),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build customer and order-specific information
  static pw.Widget _buildCustomerInfo(OrderModel order, String? roomName) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Customer Info
          _buildInfoRow('Customer:', order.userName),
          if (order.userPhoneNo != null && order.userPhoneNo!.isNotEmpty)
            _buildInfoRow('Phone:', order.userPhoneNo!),

          pw.SizedBox(height: 8),
          pw.Divider(),
          pw.SizedBox(height: 8),

          // Order Type Specific Info
          if (order.orderType == OrderType.dining) ...[
            _buildInfoRow('Table:', order.diningTable?.tableNumber ?? 'N/A'),
            if (roomName != null && roomName.isNotEmpty)
              _buildInfoRow('Room:', roomName),
            if (order.diningTable != null)
              _buildInfoRow('Seats:', '${order.diningTable!.seats}'),
            if (order.waiterName != null)
              _buildInfoRow('Waiter:', order.waiterName!),
          ] else if (order.orderType == OrderType.delivery) ...[
            _buildInfoRow('Delivery Address:', order.deliveryAddress ?? 'N/A'),
            if (order.deliveryLocation != null)
              _buildInfoRow(
                'Coordinates:',
                'Lat: ${order.deliveryLocation!.latitude.toStringAsFixed(6)}, '
                    'Lng: ${order.deliveryLocation!.longitude.toStringAsFixed(6)}',
              ),
          ],
        ],
      ),
    );
  }

  /// Build items table
  static pw.Widget _buildItemsTable(List<OrderItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(1),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header Row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: [
            _buildTableCell('#', isHeader: true),
            _buildTableCell('Item', isHeader: true),
            _buildTableCell('Qty', isHeader: true),
            _buildTableCell('Price', isHeader: true),
            _buildTableCell('Total', isHeader: true),
          ],
        ),
        // Item Rows
        ...items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final item = entry.value;
          final total = item.price * item.quantity;

          return pw.TableRow(
            children: [
              _buildTableCell(index.toString()),
              _buildTableCell(item.productName),
              _buildTableCell(item.quantity.toString()),
              _buildTableCell('Rs ${item.price.toStringAsFixed(2)}'),
              _buildTableCell('Rs ${total.toStringAsFixed(2)}'),
            ],
          );
        }),
      ],
    );
  }

  /// Build summary section
  static pw.Widget _buildSummary(
    double subtotal,
    double grandTotal,
    bool includeTax,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          _buildSummaryRow('Subtotal:', 'Rs ${subtotal.toStringAsFixed(2)}'),

          // Tax row (commented out for later use)
          // if (includeTax) ...[
          //   pw.SizedBox(height: 5),
          //   _buildSummaryRow(
          //     'Tax (${(taxRate * 100).toStringAsFixed(0)}%):',
          //     'Rs ${(subtotal * taxRate).toStringAsFixed(2)}',
          //   ),
          // ],
          pw.SizedBox(height: 8),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 8),
          _buildSummaryRow(
            'GRAND TOTAL:',
            'Rs ${grandTotal.toStringAsFixed(2)}',
            isBold: true,
            fontSize: 16,
          ),
        ],
      ),
    );
  }

  /// Build footer section
  static pw.Widget _buildFooter(String businessName) {
    return pw.Column(
      children: [
        pw.Divider(),
        pw.Text(
          'Thank you for your order!',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          businessName,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ],
    );
  }

  // Helper widgets
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 120,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _buildSummaryRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 12,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: fontSize,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Utility methods
  static String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  static String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String _formatOrderType(OrderType type) {
    return type.name.toUpperCase();
  }

  static PdfColor _getOrderTypeColor(OrderType type) {
    switch (type) {
      case OrderType.dining:
        return PdfColors.blue;
      case OrderType.takeaway:
        return PdfColors.orange;
      case OrderType.delivery:
        return PdfColors.green;
    }
  }

  static Future<pw.ImageProvider?> _tryLoadBusinessLogo(String url) async {
    try {
      return await networkImage(url);
    } catch (_) {
      return null;
    }
  }

  /// Save PDF to device
  static Future<File> savePdfToDevice(pw.Document pdf, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName.pdf');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  /// Print PDF directly
  static Future<void> printPdf(pw.Document pdf) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Order Receipt',
      // usePrinterSettings: Platform.isAndroid,
    );
  }

  /// Share PDF
  static Future<void> sharePdf(pw.Document pdf, String fileName) async {
    await Printing.sharePdf(bytes: await pdf.save(), filename: '$fileName.pdf');
  }
}
