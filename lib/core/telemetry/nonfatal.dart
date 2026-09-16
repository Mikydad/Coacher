import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Sanitized, rate-limited non-fatal reporting (pre-launch audit M10).
///
/// Release builds silence `debugPrint`, so every "swallowed" failure —
/// a sync pull that failed, an analytics refresh that threw, a dropped
/// outbox op — was invisible in production even though Crashlytics was
/// wired for fatals. This funnel records them as non-fatals with a stack
/// and a feature tag, WITHOUT the error message (task titles, transcript
/// fragments and uids ride in messages), capped per session and deduped
/// per site so an outage cannot flood the console.
class NonfatalReporter {
  NonfatalReporter({
    Future<void> Function(Object error, StackTrace stack, String reason)?
    sink,
    this.maxPerSession = 20,
    this.dedupeWindow = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _sink = sink ?? _crashlyticsSink,
       _now = now ?? DateTime.now;

  final Future<void> Function(Object error, StackTrace stack, String reason)
  _sink;
  final int maxPerSession;
  final Duration dedupeWindow;
  final DateTime Function() _now;

  int _sent = 0;
  final Map<String, DateTime> _lastByKey = {};

  int get sentCount => _sent;

  /// Reports [error] raised at [where] (a stable feature tag such as
  /// `sync.remotePull`). Never throws, never blocks the caller.
  Future<void> report(
    String where,
    Object error, [
    StackTrace? stack,
  ]) async {
    try {
      final key = '$where|${error.runtimeType}|${_code(error)}';
      final now = _now();
      final last = _lastByKey[key];
      if (last != null && now.difference(last) < dedupeWindow) return;
      if (_sent >= maxPerSession) return;
      _lastByKey[key] = now;
      _sent++;
      await _sink(
        SanitizedNonfatal(where, error.runtimeType.toString(), _code(error)),
        stack ?? StackTrace.current,
        where,
      );
    } catch (e) {
      debugPrint('[Nonfatal] report failed: $e');
    }
  }

  static String? _code(Object error) {
    if (error is FirebaseException) return error.code;
    return null;
  }

  static Future<void> _crashlyticsSink(
    Object error,
    StackTrace stack,
    String reason,
  ) async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseCrashlytics.instance.recordError(
      error,
      stack,
      reason: reason,
      fatal: false,
    );
  }

  /// Process-wide instance (swap in tests via [debugOverride]).
  static NonfatalReporter? debugOverride;
  static final NonfatalReporter _instance = NonfatalReporter();
  static NonfatalReporter get instance => debugOverride ?? _instance;
}

/// The payload-free error Crashlytics receives: feature tag + error type
/// (+ Firebase code). The original message never leaves the device.
class SanitizedNonfatal implements Exception {
  const SanitizedNonfatal(this.where, this.errorType, this.code);

  final String where;
  final String errorType;
  final String? code;

  @override
  String toString() =>
      'SanitizedNonfatal($where: $errorType${code == null ? '' : '/$code'})';
}

/// Convenience for call sites.
void reportNonfatal(String where, Object error, [StackTrace? stack]) {
  // Fire and forget — never block the caller on telemetry.
  // ignore: discarded_futures
  NonfatalReporter.instance.report(where, error, stack);
}
