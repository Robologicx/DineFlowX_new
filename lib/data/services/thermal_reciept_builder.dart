import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotel_management_system/core/utils/currency_formatter.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:image/image.dart' as img;

class ThermalReceiptBuilder {
  static const Duration _logoLoadTimeout = Duration(seconds: 2);

  /// Build ESC/POS bytes for a given order.
  ///
  /// Note: esc_pos_utils_plus supports 58/72/80mm. For 4-inch printers,
  /// we use the widest supported profile (80mm) for best visual match.
  static Future<Uint8List> generateReceiptBytes(
    OrderModel order, {
    required String type,
    String? businessName,
    String? businessLogoUrl,
    String? currencyCode,
    String? paperProfile,
  }) async {
    // Load capability profile for your printer
    final profile = await CapabilityProfile.load();
    final paperSize = _resolvePaperSize(paperProfile);
    final generator = Generator(paperSize, profile);
    List<int> bytes = [];

    // 1️⃣ Load logo
    Uint8List? logoBytes;
    final logoUrl = businessLogoUrl?.trim() ?? '';
    if (logoUrl.isNotEmpty && !kIsWeb) {
      logoBytes = await _loadNetworkBytes(
        logoUrl,
      ).timeout(_logoLoadTimeout, onTimeout: () => null);
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
      styles: PosStyles(align: PosAlign.center, bold: true),
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
    final qtyCol = paperSize == PaperSize.mm58 ? 3 : 4;
    final moneyCol = paperSize == PaperSize.mm58 ? 4 : 4;
    final totalCol = 12 - qtyCol - moneyCol;

    for (var item in order.items) {
      final total = item.price * item.quantity;
      bytes += generator.text(
        item.productName,
        styles: PosStyles(align: PosAlign.left),
      );
      bytes += generator.row([
        PosColumn(text: 'Qty: ${item.quantity}', width: qtyCol),
        PosColumn(
          text:
              'Price: ${CurrencyFormatter.formatAmount(item.price, currencyCode: currencyCode)}',
          width: moneyCol,
          styles: PosStyles(align: PosAlign.right),
        ),
        PosColumn(
          text:
              'Total: ${CurrencyFormatter.formatAmount(total, currencyCode: currencyCode)}',
          width: totalCol,
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
        text: CurrencyFormatter.formatAmount(
          subtotal,
          currencyCode: currencyCode,
        ),
        width: 6,
        styles: PosStyles(align: PosAlign.right),
      ),
    ]);
    bytes += generator.row([
      PosColumn(text: 'GRAND TOTAL', width: 6, styles: PosStyles(bold: true)),
      PosColumn(
        text: CurrencyFormatter.formatAmount(
          subtotal,
          currencyCode: currencyCode,
        ),
        width: 6,
        styles: PosStyles(align: PosAlign.right, bold: true),
      ),
    ]);

    bytes += generator.text('');
    bytes += generator.text('');
    bytes += generator.text(
      'Thank you for your order!',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      effectiveBusinessName,

      styles: PosStyles(align: PosAlign.center, height: PosTextSize.size1),
    );
    bytes += generator.text(
      'Powered by RoboLogicx',
      styles: PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'www.robologicx.org',
      styles: PosStyles(align: PosAlign.center),
    );

    // 6️⃣ Feed & cut
    bytes += generator.feed(2);
    bytes += generator.cut();

    return Uint8List.fromList(bytes);
  }

  static String _formatDateTime(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  static PaperSize _resolvePaperSize(String? paperProfile) {
    final normalized = paperProfile?.toLowerCase().trim() ?? '';
    if (normalized.contains('58')) return PaperSize.mm58;
    if (normalized.contains('72')) return PaperSize.mm72;
    if (normalized.contains('4') || normalized.contains('80')) {
      return PaperSize.mm80;
    }
    return PaperSize.mm80;
  }

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
      if (kIsWeb) return null;
      final uri = Uri.tryParse(url);
      if (uri == null) return null;
      final bundle = NetworkAssetBundle(uri);
      final data = await bundle.load(uri.toString());
      return data.buffer.asUint8List();
    } on UnsupportedError {
      return null;
    } catch (e) {
      debugPrint('Failed to load network image $url: $e');
      return null;
    }
  }
}
