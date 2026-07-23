import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'notification_response_handler.dart';

/// Dart side of the Siri entry bridge (humanizing Phase 4, PRD §6):
/// "Hey Siri, talk to SidePal" → Coach sheet in Voice Mode.
///
/// The native AppIntent (ios/Runner/SiriVoiceEntry.swift) stamps a pending
/// flag in UserDefaults and posts an in-process event. This class consumes
/// the flag **idempotently** — native clears it on read — from three
/// triggers: app launch, app resume (Siri foregrounds the app, so resume
/// always fires), and the warm-path method-channel event. Whichever runs
/// first wins; the rest see `false` and do nothing.
class SiriVoiceEntry {
  SiriVoiceEntry._();

  static const _channel = MethodChannel('sidepal/siri_voice_entry');
  static bool _initialized = false;

  /// Installs the warm-path handler. Call once at startup.
  static void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'voiceEntryRequested') {
        await consumePendingVoiceEntry();
      }
      return null;
    });
  }

  /// Checks (and clears) the native pending flag; navigates when set.
  /// Safe everywhere: on platforms without the channel this is a no-op.
  static Future<void> consumePendingVoiceEntry() async {
    bool pending;
    try {
      pending =
          await _channel.invokeMethod<bool>('consumePendingVoiceEntry') ??
          false;
    } catch (e) {
      // Android / tests / channel not registered — nothing to consume.
      debugPrint('[SiriVoiceEntry] consume skipped: $e');
      return;
    }
    if (pending) {
      debugPrint('[SiriVoiceEntry] pending voice entry -> Coach Voice Mode');
      requestCoachVoiceEntryNavigation();
    }
  }
}
