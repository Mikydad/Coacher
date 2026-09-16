import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Best-effort App Check token for the manual HTTP streams (audit H10).
///
/// The `cloud_functions` callables attach the token themselves once App
/// Check is activated; the two `onRequest` voice endpoints are plain HTTP
/// and must send `X-Firebase-AppCheck` by hand. Never throws and never
/// blocks a turn: while attestation is unavailable (simulator without a
/// debug token, plugin not initialised, network) the header is simply
/// omitted and the server's `ai_enforce_app_check` flag decides.
Future<String?> appCheckHeaderToken({
  Duration timeout = const Duration(seconds: 3),
}) async {
  if (Firebase.apps.isEmpty) return null;
  try {
    return await FirebaseAppCheck.instance.getToken().timeout(timeout);
  } catch (e) {
    debugPrint('[AppCheck] token unavailable: $e');
    return null;
  }
}
