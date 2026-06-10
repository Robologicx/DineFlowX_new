import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:image/image.dart' as img;

class ThermalReceiptBuilder {
  /// Build ESC/POS bytes for a given order (80mm paper)
  static Future<Uint8List> generateReceiptBytes(
    OrderModel order, {
    required String type,
    String? businessName,
    String? businessLogoUrl,
  }) async {
    // Load capability profile for your printer
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // 1️⃣ Load logo
    Uint8List? logoBytes;
    final logoUrl = businessLogoUrl?.trim() ?? '';
    if (logoUrl.isNotEmpty) {
      logoBytes = await _loadNetworkBytes(logoUrl);
    }
    if (logoBytes != null) {
      final image = img.decodeImage(logoBytes);
      if (image != null) {
        bytes += generator.image(image, align: PosAlign.center); // small gap
      }
    }
    // 2️⃣ Header
    // bytes += generator.text(
    //   'ICE TOUCH',
    //   styles: PosStyles(
    //     align: PosAlign.center,
    //     bold: true,
    //     height: PosTextSize.size2,
    //     width: PosTextSize.size2,
    //   ),
    // );
    final effectiveBusinessName =
        (businessName != null && businessName.trim().isNotEmpty)
        ? businessName.trim()
        : 'Business';

    bytes += generator.text(
      effectiveBusinessName,
      styles: PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text('');
    bytes += generator.text(
      'ORDER RECEIPT',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text('');
    bytes += generator.text(type, styles: PosStyles(align: PosAlign.center));
    bytes += generator.text('Order ID: ${order.orderId}');
    bytes += generator.text('Date: ${_formatDateTime(order.createdAt)}');
    bytes += generator.text('Type: ${order.orderType.name.toUpperCase()}');
    bytes += generator.hr();

    // 3️⃣ Customer Info
    bytes += generator.text('Customer: ${order.userName}');
    if (order.userPhoneNo != null) {
      bytes += generator.text('Phone: ${order.userPhoneNo}');
    }
    if (order.orderType == OrderType.delivery) {
      bytes += generator.text('Delivery Address: ${order.deliveryAddress}');
    }

    bytes += generator.text('');

    // 4️⃣ Items
    for (var item in order.items) {
      final total = item.price * item.quantity;
      bytes += generator.text(
        item.productName,
        styles: PosStyles(align: PosAlign.left),
      );
      bytes += generator.row([
        PosColumn(text: 'Qty: ${item.quantity}', width: 4),
        PosColumn(
          text: 'Price: ${item.price.toStringAsFixed(2)}',
          width: 4,
          styles: PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text: 'Total: ${total.toStringAsFixed(2)}',
          width: 4,
          styles: PosStyles(align: PosAlign.right),
        ),
      ]);
      bytes += generator.text('');
    }
    bytes += generator.hr();

    // 5️⃣ Summary
    final subtotal = order.totalAmount;
    bytes += generator.row([
      PosColumn(text: 'Subtotal', width: 6),
      PosColumn(
        text: 'Rs ${subtotal.toStringAsFixed(2)}',
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'GRAND TOTAL', width: 6, styles: PosStyles(bold: true)),
      PosColumn(
        text: 'Rs ${subtotal.toStringAsFixed(2)}',
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    bytes += generator.text('');
    bytes += generator.text('');
    bytes += generator.text(
      'Thank you!',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      effectiveBusinessName,

      styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1),
    );

    // 6️⃣ Feed & cut
    bytes += generator.feed(2);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  static String _formatDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  /// Load asset image as bytes
  static Future<Uint8List?> _loadAssetBytes(String path) async {
    try {
      final data = await rootBundle.load(path);
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to load asset $path: $e');
      return null;
    }
  }

  static Future<Uint8List?> _loadNetworkBytes(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;
      final bundle = NetworkAssetBundle(uri);
      final data = await bundle.load(uri.toString());
      return data.buffer.asUint8List();
    } catch (e) {
      debugPrint('Failed to load network image $url: $e');
      return null;
    }
  }
}
