import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/services/thermal_reciept_builder.dart';

class ThermalPrinterService {
  /// Fetch primary printer settings (IP + optional paper profile).
  Future<Map<String, String>?> getPrimaryPrinterConfig({
    required String businessId,
    required String branchId,
  }) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('branches')
        .doc(branchId)
        .collection('printers')
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    final ip = (data['ip'] as String?)?.trim() ?? '';
    if (ip.isEmpty) return null;

    return <String, String>{
      'ip': ip,
      'paperProfile': _extractPaperProfile(data),
    };
  }

  /// Print an order via LAN/Wi-Fi printer
  Future<void> printOrderLAN(
    OrderModel order, {
    required String type,
    String? businessId,
    String? branchId,
    int printerPort = 9100,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (kIsWeb) {
      throw Exception(
        'LAN thermal printing is not supported on web. Please use Windows/Android app for direct printer access.',
      );
    }

    Socket? socket;
    final effectiveBusinessId =
        (businessId != null && businessId.trim().isNotEmpty)
        ? businessId.trim()
        : BusinessRepository.temporaryBusinesshId;
    final effectiveBranchId = (branchId != null && branchId.trim().isNotEmpty)
        ? branchId.trim()
        : BusinessRepository.temporaryBranchId;

    final printerConfig = await getPrimaryPrinterConfig(
      businessId: effectiveBusinessId,
      branchId: effectiveBranchId,
    ).timeout(timeout);
    final business = await BusinessRepository().getBusinessById(
      effectiveBusinessId,
    );

    final printerIp = printerConfig?['ip'] ?? '';
    if (printerIp.isEmpty) {
      throw Exception('Printer not connected.');
    }
    try {
      // 1️⃣ Generate ESC/POS bytes
      final bytes = await ThermalReceiptBuilder.generateReceiptBytes(
        order,
        type: type,
        businessName: business?.title,
        businessLogoUrl: business?.logoUrl,
        currencyCode: business?.currencyCode,
        paperProfile: printerConfig?['paperProfile'],
      ).timeout(timeout);

      // 2️⃣ Connect to printer
      socket = await Socket.connect(printerIp, printerPort, timeout: timeout);

      // 3️⃣ Send bytes
      socket.add(bytes);
      await socket.flush().timeout(timeout);

      // 4️⃣ Optional small delay
      await Future.delayed(const Duration(milliseconds: 300));
    } on SocketException {
      throw Exception('Printer not connected.');
    } on TimeoutException {
      throw Exception('Printer not responding.');
    } catch (_) {
      throw Exception('Printer problem.');
    } finally {
      socket?.destroy();
    }
  }

  String _extractPaperProfile(Map<String, dynamic> data) {
    final stringFields = [
      data['paperProfile'],
      data['paperSize'],
      data['paperWidth'],
    ];

    for (final field in stringFields) {
      if (field is String && field.trim().isNotEmpty) {
        return field.trim();
      }
    }

    final widthInch = data['paperWidthInch'];
    if (widthInch is num) {
      if (widthInch >= 4) return '4inch';
      if (widthInch >= 3) return '80mm';
      return '58mm';
    }

    final widthMm = data['paperWidthMm'];
    if (widthMm is num) {
      if (widthMm >= 80) return '80mm';
      if (widthMm >= 72) return '72mm';
      return '58mm';
    }

    // Default to widest supported profile for "4-inch style" receipts.
    return '80mm';
  }
}
