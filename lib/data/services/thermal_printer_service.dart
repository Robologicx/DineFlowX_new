import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/models/order_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/services/thermal_reciept_builder.dart';

class ThermalPrinterService {
  /// 🔹 Fetch the IP address of the primary printer from Firestore
  Future<String?> getPrimaryPrinterIP() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('businesses')
        .doc(BusinessRepository.temporaryBusinesshId)
        .collection('branches')
        .doc(BusinessRepository.temporaryBranchId)
        .collection('printers')
        .where('isPrimary', isEqualTo: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first['ip'] as String?;
    } else {
      return null; // no primary printer set
    }
  }

  /// Print an order via LAN/Wi-Fi printer
  Future<void> printOrderLAN(
    OrderModel order, {
    required String type,
    int printerPort = 9100,
  }) async {
    Socket? socket;
    final printerIp = await getPrimaryPrinterIP();

    if (printerIp == null || printerIp.isEmpty) {
      throw Exception('No primary printer found in database');
    }
    try {
      // 1️⃣ Generate ESC/POS bytes
      final bytes = await ThermalReceiptBuilder.generateReceiptBytes(
        order,
        type: type,
      );

      // 2️⃣ Connect to printer
      socket = await Socket.connect(
        printerIp,
        printerPort,
        // timeout: const Duration(seconds: 5),
      );

      // 3️⃣ Send bytes
      socket.add(bytes);
      await socket.flush();

      // 4️⃣ Optional small delay
      await Future.delayed(const Duration(milliseconds: 500));
    } catch (e) {
      rethrow;
    } finally {
      socket?.destroy();
    }
  }
}
