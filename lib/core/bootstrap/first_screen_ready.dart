import 'dart:async';

import 'package:flutter/foundation.dart';

/// "The first screen is usable" — completed by the first-launch gate the
/// moment it reveals the app, whatever the reason (already seeded, fresh
/// account, critical phases merged, or the reveal cap).
///
/// The deferred bootstrap waits on this before its non-essential tail
/// (push registration, circle streaks, memory extraction, the thinking
/// loop, per-user maintenance): those all open network connections that
/// competed with the seed pull on a slow link (2026-09-22). They release
/// on first-screen-ready, not on the end of the whole background pull.
abstract final class FirstScreenReady {
  static Completer<void> _ready = Completer<void>();

  static Future<void> get future => _ready.future;
  static bool get isReady => _ready.isCompleted;

  /// Idempotent — the gate can reveal more than once per process (it
  /// remounts after an account switch); only the first call is logged.
  static void mark(String reason) {
    if (_ready.isCompleted) return;
    _ready.complete();
    // Boot breadcrumb that survives release (debugPrint is silenced there).
    // ignore: avoid_print
    print('[boot] first screen ready: $reason');
  }

  /// Resolves on readiness or after [timeout], never throws: a boot where
  /// the gate never mounts (registered-auth landing screen) must still run
  /// its deferred work.
  static Future<void> wait({required Duration timeout}) =>
      _ready.future.timeout(timeout, onTimeout: () {});

  @visibleForTesting
  static void resetForTests() {
    _ready = Completer<void>();
  }
}
