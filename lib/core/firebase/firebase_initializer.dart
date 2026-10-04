import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';

class FirebaseInitializer {
  const FirebaseInitializer._();

  /// Returns whether a Firebase app is available afterwards. Boot never
  /// depends on it (audit M10): the Isar-only app must still reach its
  /// first frame, and the deferred bootstrap retries.
  static Future<bool> initialize() async {
    if (Firebase.apps.isNotEmpty) {
      return true;
    }
    var initialized = false;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('Firebase initialized successfully.');
      initialized = true;
    } catch (error, stackTrace) {
      debugPrint('Firebase init with explicit options failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    if (!initialized) {
      // Fallback for cases where platform config is auto-discovered.
      try {
        await Firebase.initializeApp();
        debugPrint('Firebase initialized successfully (fallback init).');
        initialized = true;
      } catch (error, stackTrace) {
        debugPrint('Firebase fallback init failed: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    }

    if (initialized) await _activateAppCheck();
    return initialized;
  }

  /// Audit H10 — device attestation for the paid AI endpoints. Release
  /// builds use App Attest with the DeviceCheck fallback (older devices);
  /// debug/profile builds use the debug provider (register its token in
  /// the console for the simulator). Activation is best-effort: the app
  /// must boot without it, and the server's `ai_enforce_app_check` flag
  /// stays off until attested builds have shipped.
  static Future<void> _activateAppCheck() async {
    try {
      await FirebaseAppCheck.instance
          .activate(
            appleProvider: kReleaseMode
                ? AppleProvider.appAttestWithDeviceCheckFallback
                : AppleProvider.debug,
            androidProvider: kReleaseMode
                ? AndroidProvider.playIntegrity
                : AndroidProvider.debug,
          )
          .timeout(const Duration(seconds: 4));
      debugPrint('App Check activated.');
    } catch (error) {
      debugPrint('App Check activation skipped: $error');
    }
  }
}
