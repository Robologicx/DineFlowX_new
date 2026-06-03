import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

Future<void> configureFirestoreOfflineSupport() async {
  final firestore = FirebaseFirestore.instance;

  try {
    firestore.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('Firestore offline persistence enabled.');
  } catch (e) {
    debugPrint('Firestore offline persistence setup skipped: $e');
  }
}
