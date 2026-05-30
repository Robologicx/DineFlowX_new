import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';
import 'package:universal_html/html.dart' as html;
import 'package:path_provider/path_provider.dart';

class QRDownloadService {
  static Future<void> downloadQRCode(Uint8List bytes, String fileName) async {
    if (kIsWeb) {
      await _downloadForWeb(bytes, fileName);
    } else {
      await _downloadForMobile(bytes, fileName);
    }
  }

  static Future<void> _downloadForWeb(Uint8List bytes, String fileName) async {
    try {
      // Convert to base64
      final base64 = base64Encode(bytes);
      final url = 'data:image/png;base64,$base64';

      // Create anchor element
      final anchor = html.AnchorElement(href: url)
        ..download = fileName
        ..style.display = 'none';

      // Add to document and trigger click
      html.document.body?.append(anchor);
      anchor.click();

      // Remove the anchor element after click
      anchor.remove();

      debugPrint('QR code downloaded successfully on web: $fileName');
    } catch (e) {
      debugPrint('Web download failed: $e');
      rethrow;
    }
  }

  static Future<void> _downloadForMobile(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');

      // Write file
      await file.writeAsBytes(bytes);

      // Save to gallery
      final success = await GallerySaver.saveImage(
        file.path,
        albumName: 'QR Codes',
      );

      if (success == true) {
        debugPrint('QR code saved to gallery: $fileName');
      } else {
        throw Exception('Gallery saver returned false');
      }
    } catch (e) {
      debugPrint('Mobile download failed: $e');
      rethrow;
    }
  }
}
