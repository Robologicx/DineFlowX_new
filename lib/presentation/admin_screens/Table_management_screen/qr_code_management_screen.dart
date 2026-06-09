import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hotel_management_system/data/models/table_model.dart';
import 'package:hotel_management_system/presentation/admin_screens/qr/qr_download_service.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/loading_indicator.dart';
import 'package:hotel_management_system/state_management/app_providers.dart';
import 'package:hotel_management_system/state_management/room_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/table_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/tenant_context_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class QRCodeGenerationScreen extends ConsumerStatefulWidget {
  const QRCodeGenerationScreen({super.key});

  @override
  ConsumerState<QRCodeGenerationScreen> createState() =>
      _QRCodeGenerationScreenState();
}

class _QRCodeGenerationScreenState
    extends ConsumerState<QRCodeGenerationScreen> {
  String? _selectedRoomFilter;
  late TableNotifier tableNotifier;
  late RoomNotifier roomNotifier;
  String _loadedBusinessId = '';
  String _loadedBranchId = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _loadForCurrentTenant(),
    );
  }

  Future<void> _loadForCurrentTenant() async {
    final tenant = ref.read(tenantContextProvider);
    final businessId = tenant.businessId.trim();
    final branchId = tenant.branchId.trim();
    if (businessId.isEmpty || branchId.isEmpty) {
      return;
    }
    if (_loadedBusinessId == businessId && _loadedBranchId == branchId) {
      return;
    }

    _loadedBusinessId = businessId;
    _loadedBranchId = branchId;

    tableNotifier = ref.read(
      tableProvider((businessId: businessId, branchId: branchId)).notifier,
    );
    await tableNotifier.loadAllTables();

    roomNotifier = ref.read(
      roomProvider((businessId: businessId, branchId: branchId)).notifier,
    );
    roomNotifier.setBusinessContext(businessId, branchId);
    await roomNotifier.loadAllRooms();
  }

  void _handleRoomFilter(String? roomId) {
    setState(() => _selectedRoomFilter = roomId);
    final tenant = ref.read(tenantContextProvider);
    final businessId = tenant.businessId.trim();
    final branchId = tenant.branchId.trim();
    final notifier = ref.read(
      tableProvider((businessId: businessId, branchId: branchId)).notifier,
    );

    if (roomId == null) {
      notifier.loadAllTables();
    } else {
      notifier.getTablesByRoom(roomId);
    }
  }

  Future<Uint8List?> _captureQrImage(GlobalKey qrKey) async {
    try {
      final RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      if (kDebugMode) {
        print('Error capturing QR image: $e');
      }
      return null;
    }
  }

  void _showQRDialog(TableModel table, String qrData) {
    final qrKey = GlobalKey();

    Future<void> downloadQRCode() async {
      try {
        final Uint8List? pngBytes = await _captureQrImage(qrKey);

        if (pngBytes == null) {
          throw Exception('Failed to capture QR code image');
        }

        final fileName = "${table.tableNumber}_QR.png";

        await QRDownloadService.downloadQRCode(pngBytes, fileName);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '✅ QR code for ${table.tableNumber} downloaded successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Failed to download QR: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (kDebugMode) {
          print('Download error: $e');
        }
      }
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('QR Code - ${table.tableNumber}'),
        content: SizedBox(
          width: 350,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RepaintBoundary(
                key: qrKey,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: QrImageView(
                    data: qrData,
                    version: QrVersions.auto,
                    size: 280,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Table: ${table.tableNumber}',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Seats: ${table.seats}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: downloadQRCode,
            child: const Text('Download QR'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = ref.watch(tenantContextProvider);
    final businessId = tenant.businessId.trim();
    final branchId = tenant.branchId.trim();

    if (businessId.isNotEmpty && branchId.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadForCurrentTenant();
      });
    }

    final tableState = ref.watch(
      tableProvider((businessId: businessId, branchId: branchId)),
    );
    final user = ref.read(userProvider);

    if (user.selectedUser == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(title: const Text('QR Code Generation')),
      body: Column(
        children: [
          if (tableState.isLoading)
            const Expanded(child: LoadingIndicator())
          else if (tableState.tables.isEmpty)
            _buildEmptyState()
          else
            Expanded(child: _buildQRGrid(tableState)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No tables available',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQRGrid(TableState tableState) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        if (constraints.maxWidth > 1200) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 800) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 0.75,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: tableState.tables.length,
          itemBuilder: (context, index) {
            final table = tableState.tables[index];
            return _buildQRCard(table);
          },
        );
      },
    );
  }

  Widget _buildQRCard(TableModel table) {
    final tenant = ref.read(tenantContextProvider);
    final businessId = tenant.businessId.trim();
    final branchId = tenant.branchId.trim();
    final notifier = ref.read(
      tableProvider((businessId: businessId, branchId: branchId)).notifier,
    );
    final qrData = notifier.generateQRCodeData(table.id);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _showQRDialog(table, qrData),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                table.tableNumber,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '${table.seats} seats',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap to enlarge',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
