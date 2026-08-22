import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Pre-warms the first spoken turn's network path the moment Voice Mode
/// opens (first-turn latency fix 2026-08-22).
///
/// The first turn after app launch paid three cold costs at once: the
/// Firebase ID-token fetch, the TLS handshake to Cloud Functions, and —
/// for endpoints without a warm instance — the function cold start itself.
/// A GET to each streaming endpoint spins the instance and leaves the
/// connection warm in the OS socket pool; the token fetch fills the auth
/// cache. All best-effort and fire-and-forget: a failed warmup costs
/// nothing but the latency it would have saved.
Future<void> warmVoiceEndpoints({
  required List<Uri> endpoints,
  required Future<String?> Function() idToken,
  http.Client Function()? clientFactory,
  Duration timeout = const Duration(seconds: 6),
}) async {
  final sw = Stopwatch()..start();
  await Future.wait([
    idToken().timeout(timeout).then<void>((_) {}, onError: (_) {}),
    for (final endpoint in endpoints)
      Future(() async {
        final client = (clientFactory ?? http.Client.new)();
        try {
          await client.get(endpoint).timeout(timeout);
        } catch (_) {
          // Offline / server hiccup — the real turn reports honestly.
        } finally {
          client.close();
        }
      }),
  ]);
  if (kDebugMode) {
    debugPrint('[voice-timing] warmup=${sw.elapsedMilliseconds}ms');
  }
}
