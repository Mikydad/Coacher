import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Thrown on purpose by the hidden Crashlytics smoke test so the event is
/// unmistakable in the console (search "CrashlyticsTestException").
class CrashlyticsTestException implements Exception {
  CrashlyticsTestException(this.at);

  final DateTime at;

  @override
  String toString() =>
      'CrashlyticsTestException: manual test event at ${at.toIso8601String()}';
}

/// The two things the smoke test can do, behind an interface so the About &
/// Support widget is testable without a Firebase app.
///
/// Why this exists: Crashlytics silently received three crashes from build
/// 1.0.1 (2) that nobody could see (missing dSYMs, `errors.md` #25). A
/// trigger the tester can fire on demand is the only way to prove the
/// device → console loop end-to-end without waiting for a real crash.
abstract class CrashlyticsTestSink {
  /// Whether reports actually leave this device. Off in debug builds
  /// (`main.dart` gates on `!kDebugMode`), so the dialog can say so honestly
  /// instead of letting a tester wait for an event that will never arrive.
  bool get collectionEnabled;

  /// Records a non-fatal and pushes unsent reports right away. The app keeps
  /// running; the event shows in the console within a few minutes.
  Future<void> sendNonFatal();

  /// Forces a native crash. The report uploads on the NEXT launch — that is
  /// how Crashlytics works, not a bug.
  Future<void> crash();
}

class FirebaseCrashlyticsTestSink implements CrashlyticsTestSink {
  const FirebaseCrashlyticsTestSink();

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  @override
  bool get collectionEnabled => _crashlytics.isCrashlyticsCollectionEnabled;

  @override
  Future<void> sendNonFatal() async {
    final now = DateTime.now();
    await _crashlytics.setCustomKey('test_trigger', 'about_support_long_press');
    await _crashlytics.log('Manual Crashlytics smoke test (non-fatal)');
    await _crashlytics.recordError(
      CrashlyticsTestException(now),
      StackTrace.current,
      reason: 'Manual smoke test from About & Support',
      fatal: false,
    );
    await _crashlytics.sendUnsentReports();
  }

  @override
  Future<void> crash() async {
    await _crashlytics.log('Manual Crashlytics smoke test (fatal)');
    _crashlytics.crash();
  }
}

final crashlyticsTestSinkProvider = Provider<CrashlyticsTestSink>(
  (_) => const FirebaseCrashlyticsTestSink(),
);
