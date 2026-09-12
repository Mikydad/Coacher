import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/time_tracker/application/time_tracker_actions.dart';
import '../features/time_tracker/application/time_tracker_providers.dart';
import '../features/time_tracker/domain/models/activity_event.dart';
import '../features/time_tracker/presentation/track_activity_sheet.dart';
import 'app_navigator.dart';
import 'application/main_tab_navigation.dart';

/// Dart side of the Siri "Log activity" bridge (Time Tracker V1.1):
/// "Hey Siri, log Gym in SidePal" → one activity event, timestamp = now,
/// and a Home snackbar `Logged Gym at 7:42 PM`.
///
/// Mirrors [SiriVoiceEntry]: the native AppIntent (SiriVoiceEntry.swift)
/// stamps a pending payload and posts an in-process event; this class
/// consumes it **idempotently** (native clears on read) from launch,
/// resume, and the warm event. Empty text never logs — the capture sheet
/// opens instead, so Siri can never write a blank entry.
class SiriLogActivity {
  SiriLogActivity._();

  static const _channel = MethodChannel('sidepal/siri_log_activity');
  static bool _initialized = false;

  /// Installs the warm-path handler. Call once at startup.
  static void init() {
    if (_initialized) return;
    _initialized = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'logRequested') {
        await consumePendingLog();
      }
      return null;
    });
  }

  /// Checks (and clears) the native pending payload; logs when set.
  /// Safe everywhere: on platforms without the channel this is a no-op.
  static Future<void> consumePendingLog() async {
    Map<Object?, Object?>? pending;
    try {
      pending = await _channel.invokeMethod<Map<Object?, Object?>>(
        'consumePendingLog',
      );
    } catch (e) {
      debugPrint('[SiriLogActivity] consume skipped: $e');
      return;
    }
    if (pending == null) return;
    final container = appRootProviderContainer;
    if (container == null) return;
    await handlePayload(
      pending,
      actions: container.read(timeTrackerActionsProvider),
      now: DateTime.now(),
      onLogged: _announce,
      onNeedsText: _openSheet,
    );
  }

  /// Pure-ish core, testable without the channel: logs the event from a
  /// `{text, minutes?}` payload. Returns the saved event, or null when the
  /// text was empty (then [onNeedsText] ran instead).
  static Future<ActivityEvent?> handlePayload(
    Map<Object?, Object?> payload, {
    required TimeTrackerActions actions,
    required DateTime now,
    void Function(ActivityEvent event)? onLogged,
    void Function()? onNeedsText,
  }) async {
    var text = (payload['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) {
      debugPrint('[SiriLogActivity] empty text -> capture sheet');
      onNeedsText?.call();
      return null;
    }
    if (text.length > kActivityTextMaxChars) {
      text = text.substring(0, kActivityTextMaxChars);
    }
    final minutesRaw = payload['minutes'];
    final minutes = minutesRaw is num ? minutesRaw.toInt() : null;
    final intended =
        minutes != null && minutes >= 1 && minutes <= kActivityIntendedMaxMinutes
        ? minutes
        : null;
    final event = ActivityEvent.create(
      text: text,
      startedAtMs: now.millisecondsSinceEpoch,
      nowMs: now.millisecondsSinceEpoch,
      intendedMinutes: intended,
    );
    try {
      final saved = await actions.log(event);
      debugPrint('[SiriLogActivity] logged "${saved.text}"');
      onLogged?.call(saved);
      return saved;
    } catch (e) {
      debugPrint('[SiriLogActivity] log failed: $e');
      return null;
    }
  }

  static void _announce(ActivityEvent event) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = appNavigatorKey.currentContext;
      if (context == null) return;
      final loc = MaterialLocalizations.of(context);
      final clock = loc.formatTimeOfDay(
        TimeOfDay.fromDateTime(
          DateTime.fromMillisecondsSinceEpoch(event.startedAtMs),
        ),
        alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
      );
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text('Logged ${event.text} at $clock'),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }

  static void _openSheet() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = appNavigatorKey.currentContext;
      if (context == null) return;
      unawaited(showTrackActivitySheet(context));
    });
  }
}
