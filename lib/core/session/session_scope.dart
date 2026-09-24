import 'dart:async';

import 'package:flutter/foundation.dart';

/// The client-side account boundary (pre-launch audit H2–H6, 2026-09-15).
///
/// One Isar database and one process serve every account that signs in on
/// the device, so "which account is this write for?" cannot be answered by
/// looking at Firebase Auth alone: during logout the outgoing user is still
/// authenticated while the wipe runs, and a job that awaited the network
/// before the wipe would happily persist after it. The generation counter
/// is bumped SYNCHRONOUSLY the moment a teardown starts; long-running jobs
/// capture a [SessionToken] when they begin and re-check it before every
/// local write. A stale token means "this account's session is over —
/// drop the result", never "resolve the uid again".
///
/// Pattern mirrors `UnifiedRecomputeGraph`'s flush generation.
abstract final class SessionScope {
  static int _generation = 0;
  static bool _tearingDown = false;
  static Completer<void>? _idle;

  /// Current session generation. Captured by jobs via [capture].
  static int get generation => _generation;

  /// True from [beginTeardown] until [endTeardown]: the outgoing account is
  /// being wiped and nothing may start new user-scoped work (a stash
  /// finalization triggered by provider disposal, for instance).
  static bool get isTearingDown => _tearingDown;

  /// Resolves once no teardown is running — at once outside one. For work
  /// that must judge the INCOMING account (the Getting Started tour's
  /// new-vs-existing probe, 2026-09-23): a provider invalidated at the start
  /// of an account switch is rebuilt while the outgoing account's rows are
  /// still in Isar, so it awaits this before reading anything.
  static Future<void> get whenIdle =>
      _tearingDown ? (_idle ??= Completer<void>()).future : Future.value();

  /// Marks the start of a logout / account switch / deletion. Idempotent
  /// within one teardown (calling it twice bumps twice, which is harmless:
  /// nothing captured before either bump is valid afterwards).
  static int beginTeardown() {
    _tearingDown = true;
    return ++_generation;
  }

  /// The wipe finished; the next account's jobs may capture fresh tokens.
  static void endTeardown() {
    _tearingDown = false;
    _idle?.complete();
    _idle = null;
  }

  static bool isCurrent(int generation) =>
      !_tearingDown && generation == _generation;

  static SessionToken capture() => SessionToken(_generation);

  @visibleForTesting
  static void resetForTests() {
    _generation = 0;
    _tearingDown = false;
    _idle = null;
  }
}

/// A job's claim on the session it started in.
class SessionToken {
  const SessionToken(this.generation);

  final int generation;

  bool get isCurrent => SessionScope.isCurrent(generation);

  /// Throws [StaleSessionError] when the session has ended since capture —
  /// call before every local write in a job that awaited anything.
  void ensureCurrent(String what) {
    if (!isCurrent) throw StaleSessionError(what);
  }
}

class StaleSessionError extends StateError {
  StaleSessionError(String what)
    : super(
        '$what: the signed-in session ended mid-job — result dropped so it '
        'cannot land in another account\'s local data.',
      );
}
