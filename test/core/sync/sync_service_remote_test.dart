import 'dart:io';

import 'package:coach_for_life/core/offline/offline_store.dart';
import 'package:coach_for_life/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';

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
    SyncService.debugClockForTests = null;
    SyncService.debugRemotePullForTests = null;
    SyncService.instance.debugResetQueueInMemoryOnly();
  });

  tearDown(() async {
    OfflineStore.clearDebugIsarOverrideForTests();
    SyncService.instance.resetRemoteSyncStateForTests();
    SyncService.debugClockForTests = null;
    SyncService.debugRemotePullForTests = null;
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
}
