import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';

class PrinterScreen extends StatelessWidget {
  const PrinterScreen({super.key});

  Future<void> _addPrinterDialog(BuildContext context) async {
    final TextEditingController ipController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isDesktop = screenWidth > 900;

        return AlertDialog(
          title: const Text("Add New Printer"),
          content: SizedBox(
            width: isDesktop ? 400 : double.maxFinite,
            child: TextField(
              controller: ipController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Printer IP Address",
                hintText: "e.g. 192.168.1.50",
                border: OutlineInputBorder(),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.print),
              label: const Text("Add Printer"),
              onPressed: () async {
                final ip = ipController.text.trim();
                if (ip.isNotEmpty) {
                  await FirebaseFirestore.instance
                      .collection('businesses')
                      .doc(BusinessRepository.temporaryBusinesshId)
                      .collection('branches')
                      .doc(BusinessRepository.temporaryBranchId)
                      .collection('printers')
                      .add({'ip': ip, 'isPrimary': false});
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePrinter(String docId) async {
    await FirebaseFirestore.instance
        .collection('businesses')
        .doc(BusinessRepository.temporaryBusinesshId)
        .collection('branches')
        .doc(BusinessRepository.temporaryBranchId)
        .collection('printers')
        .doc(docId)
        .delete();
  }

  Future<void> _setPrimary(String docId) async {
    final collection = FirebaseFirestore.instance
        .collection('businesses')
        .doc(BusinessRepository.temporaryBusinesshId)
        .collection('branches')
        .doc(BusinessRepository.temporaryBranchId)
        .collection('printers');

    final allDocs = await collection.get();

    for (var doc in allDocs.docs) {
      await doc.reference.update({'isPrimary': false});
    }

    await collection.doc(docId).update({'isPrimary': true});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;

        // 🧩 Responsive Breakpoints
        final bool isMobile = width < 600;
        final bool isTablet = width >= 600 && width < 1024;
        final bool isDesktop = width >= 1024;
        final bool isUltraWide = width > 1600;

        // 🧱 Adaptive paddings and layout spacing
        final double horizontalPadding = isUltraWide
            ? width * 0.2
            : isDesktop
            ? width * 0.15
            : isTablet
            ? width * 0.1
            : 16.0;

        final int crossAxisCount = isUltraWide
            ? 4
            : isDesktop
            ? 3
            : isTablet
            ? 2
            : 1;

        final double childAspectRatio = isUltraWide
            ? 3.8
            : isDesktop
            ? 3.2
            : isTablet
            ? 2.6
            : 2.2;

        return Scaffold(
          appBar: AppBar(
            title: const Text("Network Printers"),
            centerTitle: true,
          ),
          body: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('businesses')
                  .doc(BusinessRepository.temporaryBusinesshId)
                  .collection('branches')
                  .doc(BusinessRepository.temporaryBranchId)
                  .collection('printers')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final printers = snapshot.data?.docs ?? [];

                if (printers.isEmpty) {
                  return const Center(
                    child: Text(
                      "No printers added yet.\nTap the button below to add one.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // 🧩 Responsive layout switching
                if (isMobile) {
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 16),
                    itemCount: printers.length,
                    itemBuilder: (context, index) =>
                        _buildPrinterCard(context, printers[index], width),
                  );
                } else {
                  return GridView.builder(
                    padding: const EdgeInsets.only(top: 16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: childAspectRatio,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: printers.length,
                    itemBuilder: (context, index) =>
                        _buildPrinterCard(context, printers[index], width),
                  );
                }
              },
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addPrinterDialog(context),
            icon: const Icon(Icons.print, size: 26),
            label: const Text("Add Printer"),
          ),
        );
      },
    );
  }

  /// 🧱 Adaptive Printer Card
  Widget _buildPrinterCard(
    BuildContext context,
    QueryDocumentSnapshot doc,
    double width,
  ) {
    final ip = doc['ip'] ?? '';
    final isPrimary = doc['isPrimary'] ?? false;

    final bool isWide = width >= 600;
    final double iconSize = isWide ? 36 : 28;
    final double fontSize = isWide ? 16 : 14;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.print,
                  size: iconSize,
                  color: isPrimary ? Colors.indigo : Colors.grey,
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ip,
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isPrimary ? "Primary Printer" : "Secondary Printer",
                        style: TextStyle(
                          color: isPrimary ? Colors.indigo : Colors.grey,
                          fontSize: fontSize - 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    isPrimary ? Icons.star : Icons.star_border_outlined,
                    color: isPrimary ? Colors.amber : Colors.grey,
                  ),
                  tooltip: isPrimary
                      ? "Primary Printer (Active)"
                      : "Set as Primary",
                  onPressed: () => _setPrimary(doc.id),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: "Delete Printer",
                  onPressed: () => _deletePrinter(doc.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
