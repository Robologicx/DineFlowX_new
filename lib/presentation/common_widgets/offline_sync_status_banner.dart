import 'package:flutter/material.dart';
import 'package:hotel_management_system/core/sync/connectivity_service.dart';
import 'package:hotel_management_system/core/utils/offline_firestore_write_queue_service.dart';

class OfflineSyncStatusBanner extends StatelessWidget {
  const OfflineSyncStatusBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ConnectivityService.instance.isOnlineNotifier,
      builder: (context, isOnline, _) {
        return ValueListenableBuilder<OfflineFirestoreWriteSyncStatus>(
          valueListenable: OfflineFirestoreWriteQueueService.statusNotifier,
          builder: (context, status, __) {
            if (isOnline && status.pendingWrites == 0) {
              return const SizedBox.shrink();
            }

            final pending = status.pendingWrites;
            final bg = isOnline
                ? const Color(0xFF9A6A00)
                : const Color(0xFFB3261E);
            final icon = isOnline ? Icons.sync : Icons.wifi_off_rounded;
            final label = isOnline ? 'Syncing' : 'Offline';
            final semanticText = isOnline
                ? 'Syncing, $pending pending changes'
                : 'Offline mode, $pending pending changes';

            return SafeArea(
              bottom: false,
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8, right: 10),
                  child: Semantics(
                    label: semanticText,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x26000000),
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: Colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.1,
                            ),
                          ),
                          if (pending > 0) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$pending',
                                style: TextStyle(
                                  color: bg,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
