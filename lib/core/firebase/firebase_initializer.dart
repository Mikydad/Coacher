import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseInitializer {
  const FirebaseInitializer._();

  static Future<void> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      return;
    }
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully.');
      return;
    } catch (error, stackTrace) {
      debugPrint('Firebase init with explicit options failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    // Fallback for cases where platform config is auto-discovered.
    try {
      await Firebase.initializeApp();
      debugPrint('Firebase initialized successfully (fallback init).');
    } catch (error, stackTrace) {
      debugPrint('Firebase fallback init failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }
}
