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
import 'package:hotel_management_system/core/utils/currency_formatter.dart';

class OrderPdfGenerator {
  // Tax rate (commented out for later use)
  // static const double taxRate = 0.16; // 16% tax

  /// Generate PDF document
  static Future<pw.Document> generateOrderPdf({
    required OrderModel order,
    String? businessId,
    String? roomName,
    bool includeTax = false, // Set to true when you want to enable tax
  }) async {
    final pdf = pw.Document();
    final effectiveBusinessId =
        (businessId != null && businessId.trim().isNotEmpty)
        ? businessId.trim()
        : BusinessRepository.temporaryBusinesshId;
    final business = await BusinessRepository().getBusinessById(
      effectiveBusinessId,
    );
    final businessName = business?.title.trim().isNotEmpty == true
        ? business!.title.trim()
        : 'Business';
    final currencyCode = business?.currencyCode;
    final businessLogo = business?.logoUrl?.trim().isNotEmpty == true
        ? await _tryLoadBusinessLogo(business!.logoUrl!.trim())
        : null;

    // Calculate amounts
    final subtotal = order.totalAmount;
    // final taxAmount = includeTax ? subtotal * taxRate : 0.0;
    // final grandTotal = subtotal + taxAmount;
    final grandTotal = subtotal; // Use this when tax is disabled
    final itemCount = order.items.isEmpty ? 1 : order.items.length;
    const baseHeightMm = 150.0;
    const perItemHeightMm = 8.0;
    final estimatedHeightMm = (baseHeightMm + (itemCount * perItemHeightMm))
        .clamp(220.0, 1200.0)
        .toDouble();

    final PdfPageFormat format = PdfPageFormat(
      80 * PdfPageFormat.mm,
      estimatedHeightMm * PdfPageFormat.mm,
      marginLeft: 0,
      marginRight: 0,
      marginTop: 0,
      marginBottom: 0,
    );

    pdf.addPage(
      pw.Page(
        pageFormat: format,
        margin: pw.EdgeInsets.symmetric(horizontal: 4 * PdfPageFormat.mm),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: _buildHeader(
                  businessName: businessName,
                  businessLogo: businessLogo,
                ),
              ),
              pw.SizedBox(height: 6),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 6),
              _buildOrderInfo(order),
              pw.SizedBox(height: 6),
              _buildCustomerInfo(order, roomName),
              pw.SizedBox(height: 6),
              _buildItemsTable(order.items, currencyCode: currencyCode),
              pw.SizedBox(height: 6),
              _buildSummary(
                subtotal,
                grandTotal,
                includeTax,
                currencyCode: currencyCode,
              ),
              pw.SizedBox(height: 8),
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
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      mainAxisSize: pw.MainAxisSize.min,
      children: [
        if (businessLogo != null)
          pw.Container(
            height: 128,
            width: 128,
            margin: const pw.EdgeInsets.only(bottom: 6),
            child: pw.Image(businessLogo, fit: pw.BoxFit.contain),
          ),
        pw.SizedBox(height: 2),
        pw.Text(
          businessName,
          textAlign: pw.TextAlign.center,
          style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  /// Build order information section
  static pw.Widget _buildOrderInfo(OrderModel order) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'ORDER RECEIPT',
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            'Order ID: ${order.orderId}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Date: ${_formatDate(order.createdAt)} ${_formatTime(order.createdAt)}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Type: ${_formatOrderType(order.orderType)}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  /// Build customer and order-specific information
  static pw.Widget _buildCustomerInfo(OrderModel order, String? roomName) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Customer Info
          _buildInfoRow('Customer:', order.userName),
          if (order.userPhoneNo != null && order.userPhoneNo!.isNotEmpty)
            _buildInfoRow('Phone:', order.userPhoneNo!),

          pw.SizedBox(height: 3),
          pw.Divider(),
          pw.SizedBox(height: 3),

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
  static pw.Widget _buildItemsTable(
    List<OrderItem> items, {
    String? currencyCode,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Divider(),
        ...items.map((item) {
          final total = item.price * item.quantity;
          return pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  item.productName,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Qty: ${item.quantity}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      'Price: ${CurrencyFormatter.formatAmount(item.price, currencyCode: currencyCode)}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                    pw.Text(
                      'Total: ${CurrencyFormatter.formatAmount(total, currencyCode: currencyCode)}',
                      style: const pw.TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
        pw.Divider(),
      ],
    );
  }

  /// Build summary section
  static pw.Widget _buildSummary(
    double subtotal,
    double grandTotal,
    bool includeTax, {
    String? currencyCode,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Column(
        children: [
          _buildSummaryRow(
            'Subtotal:',
            CurrencyFormatter.formatAmount(
              subtotal,
              currencyCode: currencyCode,
            ),
          ),

          // Tax row (commented out for later use)
          // if (includeTax) ...[
          //   pw.SizedBox(height: 5),
          //   _buildSummaryRow(
          //     'Tax (${(taxRate * 100).toStringAsFixed(0)}%):',
          //     'Rs ${(subtotal * taxRate).toStringAsFixed(2)}',
          //   ),
          // ],
          pw.SizedBox(height: 3),
          pw.Divider(thickness: 2),
          pw.SizedBox(height: 3),
          _buildSummaryRow(
            'GRAND TOTAL:',
            CurrencyFormatter.formatAmount(
              grandTotal,
              currencyCode: currencyCode,
            ),
            isBold: true,
            fontSize: 11,
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
          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          businessName,
          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          'Powered by RoboLogicx',
          style: const pw.TextStyle(fontSize: 7),
        ),
        pw.Text('www.robologicx.org', style: const pw.TextStyle(fontSize: 7)),
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
            width: 58,
            child: pw.Text(
              label,
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: const pw.TextStyle(fontSize: 8)),
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
