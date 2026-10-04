import 'dart:async';
import 'dart:io';

import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/post_sync_refresh_coordinator.dart';
import 'package:sidepal/core/sync/remote_isar_merge.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/core/telemetry/nonfatal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';

import '../../support/isar_test_harness.dart';

void main() {
  // Do not use [TestWidgetsFlutterBinding] here: it mocks HTTP and breaks
  // [Isar.initializeIsarCore(download: true)].

  Isar? isar;
  Directory? dir;

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    OfflineStore.debugIsarOverride = isar;
    SyncService.instance.resetRemoteSyncStateForTests();
    PostSyncRefreshCoordinator.instance.resetForTests();
    SyncService.debugClockForTests = null;
    SyncService.debugRemotePullForTests = null;
    SyncService.debugUidForTests = 'test-user';
    SyncService.instance.debugResetQueueInMemoryOnly();
  });

  tearDown(() async {
    OfflineStore.clearDebugIsarOverrideForTests();
    SyncService.instance.resetRemoteSyncStateForTests();
    PostSyncRefreshCoordinator.instance.resetForTests();
    SyncService.debugClockForTests = null;
    SyncService.debugRemotePullForTests = null;
    SyncService.debugUidForTests = null;
    final i = isar;
    final d = dir;
    isar = null;
    dir = null;
    if (i != null && d != null) {
      await closeTempIsar(i, d);
    }
  });

  test('debounces non-forced sync within 30 seconds', () async {
    var pulls = 0;
    final t0 = DateTime.utc(2026, 1, 1, 12);
    SyncService.debugClockForTests = () => t0;
    SyncService.debugRemotePullForTests = (_) async {
      pulls++;
    };

    await SyncService.instance.syncFromRemote();
    expect(pulls, 1);

    await SyncService.instance.syncFromRemote();
    expect(pulls, 1);

    SyncService.debugClockForTests = () => t0.add(const Duration(seconds: 31));
    await SyncService.instance.syncFromRemote();
    expect(pulls, 2);
  });

  test('concurrent callers share one in-flight pull', () async {
    var pulls = 0;
    SyncService.debugRemotePullForTests = (_) async {
      pulls++;
      await Future<void>.delayed(const Duration(milliseconds: 40));
    };

    await Future.wait([
      SyncService.instance.syncFromRemote(force: true),
      SyncService.instance.syncFromRemote(force: true),
    ]);

    expect(pulls, 1);
  });

  test('force:true bypasses debounce', () async {
    var pulls = 0;
    final t0 = DateTime.utc(2026, 1, 1, 12);
    SyncService.debugClockForTests = () => t0;
    SyncService.debugRemotePullForTests = (_) async {
      pulls++;
    };

    await SyncService.instance.syncFromRemote(force: true);
    await SyncService.instance.syncFromRemote(force: true);
    expect(pulls, 2);
  });

  test(
    'bypassThrottle (Home sync button) skips the debounce, keeps cursors',
    () async {
      var calls = 0;
      final t0 = DateTime(2026, 1, 1, 12);
      SyncService.debugClockForTests = () => t0;
      SyncService.debugRemotePullForTests = (_) async {
        calls++;
      };
      await SyncService.instance.syncFromRemote(bypassThrottle: true);
      await SyncService.instance.syncFromRemote(
        bypassThrottle: true,
        timeout: const Duration(seconds: 20),
      );
      expect(calls, 2);
    },
  );

  test(
    'uid change supersedes an in-flight pull instead of joining it',
    () async {
      var pulls = 0;
      SyncService.debugRemotePullForTests = (_) async {
        pulls++;
        await Future<void>.delayed(const Duration(milliseconds: 40));
      };

      // User A's pull starts, then user B signs in and forces a sync while
      // A's pull is still running. B must get its own pull, not A's result.
      final pullA = SyncService.instance.syncFromRemote(force: true);
      SyncService.debugUidForTests = 'test-user-b';
      final pullB = SyncService.instance.syncFromRemote(force: true);
      await Future.wait([pullA, pullB]);

      expect(pulls, 2);
    },
  );

  test('no signed-in user skips the pull', () async {
    var pulls = 0;
    SyncService.debugRemotePullForTests = (_) async {
      pulls++;
    };

    SyncService.debugUidForTests = null;
    // Firebase is not initialized in VM tests, so a null test uid means
    // "signed out" and the pull must be skipped.
    final result = await SyncService.instance.syncFromRemote(force: true);

    expect(result, isFalse);
    expect(pulls, 0);
  });

  // ── First-screen signal (2026-09-22) ────────────────────────────────────────

  test('firstScreenReady settles when the pull is skipped (no user)', () async {
    SyncService.debugRemotePullForTests = (_) async {};
    SyncService.debugUidForTests = null;
    final ready = Completer<void>();

    final result = await SyncService.instance.syncFromRemote(
      force: true,
      firstScreenReady: ready,
    );

    expect(result, isFalse);
    expect(ready.isCompleted, isTrue);
  });

  test('firstScreenReady settles when the override pull finishes', () async {
    final gate = Completer<void>();
    SyncService.debugRemotePullForTests = (_) => gate.future;
    final ready = Completer<void>();

    final pull = SyncService.instance.syncFromRemote(
      force: true,
      firstScreenReady: ready,
    );
    await Future<void>.delayed(Duration.zero);
    expect(ready.isCompleted, isFalse);

    gate.complete();
    expect(await pull, isTrue);
    expect(ready.isCompleted, isTrue);
  });

  test(
    "a joiner is wired to the in-flight pull's first-screen signal",
    () async {
      final gate = Completer<void>();
      SyncService.debugRemotePullForTests = (_) => gate.future;

      final first = SyncService.instance.syncFromRemote(force: true);
      final joinerReady = Completer<void>();
      final joiner = SyncService.instance.syncFromRemote(
        force: true,
        firstScreenReady: joinerReady,
      );
      await Future<void>.delayed(Duration.zero);
      expect(joinerReady.isCompleted, isFalse);

      gate.complete();
      await Future.wait([first, joiner]);
      expect(joinerReady.isCompleted, isTrue);
    },
  );

  // ── Full-pull promotion backoff (2026-09-22) ────────────────────────────────

  test(
    'a failed forced pull records the failure; a later success clears it',
    () async {
      final t0 = DateTime.utc(2026, 1, 1, 12);
      SyncService.debugClockForTests = () => t0;
      SyncService.debugRemotePullForTests = (_) async =>
          throw StateError('boom');

      expect(await SyncService.instance.syncFromRemote(force: true), isFalse);
      expect(SyncService.instance.lastFullPullFailedAtForTests, t0);

      SyncService.debugRemotePullForTests = (_) async {};
      expect(await SyncService.instance.syncFromRemote(force: true), isTrue);
      expect(SyncService.instance.lastFullPullFailedAtForTests, isNull);
    },
  );

  // ── Failure reporting (2026-09-24) ──────────────────────────────────────────

  group('pull failures and the non-fatal funnel', () {
    late List<String> reported;

    setUp(() {
      reported = [];
      NonfatalReporter.debugOverride = NonfatalReporter(
        sink: (error, stack, reason) async => reported.add('$reason|$error'),
      );
    });

    tearDown(() => NonfatalReporter.debugOverride = null);

    test('a genuine failure is reported once under sync.remotePull', () async {
      SyncService.debugRemotePullForTests = (_) async =>
          throw StateError('boom');
      expect(await SyncService.instance.syncFromRemote(force: true), isFalse);
      expect(reported, hasLength(1));
      expect(reported.single, startsWith('sync.remotePull|'));
    });

    test('the uid-changed abort is swallowed and NOT reported', () async {
      SyncService.debugRemotePullForTests = (_) async =>
          throw SyncAbortedUidChanged();
      expect(await SyncService.instance.syncFromRemote(force: true), isFalse);
      expect(reported, isEmpty);
    });
  });

  test('isFullPullDue: daily, held back for 5 minutes after a failure', () {
    final now = DateTime.utc(2026, 1, 2, 12);
    final dayAgo = now
        .subtract(const Duration(hours: 25))
        .millisecondsSinceEpoch;
    final hourAgo = now
        .subtract(const Duration(hours: 1))
        .millisecondsSinceEpoch;

    expect(SyncService.isFullPullDue(now: now, lastFullPullMs: dayAgo), isTrue);
    expect(
      SyncService.isFullPullDue(now: now, lastFullPullMs: hourAgo),
      isFalse,
    );
    expect(
      SyncService.isFullPullDue(
        now: now,
        lastFullPullMs: dayAgo,
        lastFailedAt: now.subtract(const Duration(minutes: 2)),
      ),
      isFalse,
    );
    expect(
      SyncService.isFullPullDue(
        now: now,
        lastFullPullMs: dayAgo,
        lastFailedAt: now.subtract(const Duration(minutes: 6)),
      ),
      isTrue,
    );
  });
}
