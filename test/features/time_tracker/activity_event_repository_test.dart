import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_activity_event.dart';
import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/time_tracker/data/activity_event_lww_merge.dart';
import 'package:sidepal/features/time_tracker/data/activity_event_repository.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';

import '../../support/isar_test_harness.dart';

void main() {
  Isar? isar;
  Directory? dir;
  var clock = 1000;
  late ActivityEventRepository repo;

  final day = DateTime(2026, 9, 12);
  int at(int h, [int m = 0]) =>
      DateTime(day.year, day.month, day.day, h, m).millisecondsSinceEpoch;

  ActivityEvent make(String text, int startMs, {int? intended}) =>
      ActivityEvent.create(
        text: text,
        startedAtMs: startMs,
        nowMs: clock,
        intendedMinutes: intended,
      );

  setUp(() async {
    SyncService.debugSkipQueuePersistenceForTests = true;
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    OfflineStore.debugIsarOverride = isar;
    clock = 1000;
    repo = ActivityEventRepository(now: () => clock);
  });

  tearDown(() async {
    SyncService.debugSkipQueuePersistenceForTests = false;
    OfflineStore.clearDebugIsarOverrideForTests();
    final i = isar;
    final d = dir;
    isar = null;
    dir = null;
    if (i != null && d != null) {
      await closeTempIsar(i, d);
    }
  });

  test('upsert stamps updatedAtMs and watchDay emits sorted by start', () async {
    final first = repo.watchDay('2026-09-12').firstWhere((r) => r.length == 2);
    clock = 2000;
    await repo.upsert(make('Planning', at(22, 9)));
    clock = 3000;
    final saved = await repo.upsert(make('Scrolling', at(22, 3)));
    expect(saved.updatedAtMs, 3000);
    final rows = await first;
    expect(rows.map((e) => e.text), ['Scrolling', 'Planning']);
  });

  test('watchDay is per calendar day and excludes tombstones', () async {
    await repo.upsert(make('Today', at(10)));
    final tomorrowMs = at(2) + const Duration(days: 1).inMilliseconds;
    await repo.upsert(make('Tomorrow 2am', tomorrowMs));
    final deleted = await repo.upsert(make('Gone', at(11)));
    await repo.softDelete(deleted.id);

    expect((await repo.fetchDayOnce('2026-09-12')).map((e) => e.text), ['Today']);
    expect((await repo.fetchDayOnce('2026-09-13')).map((e) => e.text),
        ['Tomorrow 2am']);
    expect(await isar!.isarActivityEvents.count(), 3, reason: 'tombstone kept');
  });

  test('softDelete tombstones with a fresh stamp; second call is a no-op',
      () async {
    final e = await repo.upsert(make('X', at(9)));
    clock = 5000;
    await repo.softDelete(e.id);
    final row = await repo.getById(e.id);
    expect(row!.active, isFalse);
    expect(row.updatedAtMs, 5000);
    clock = 6000;
    await repo.softDelete(e.id);
    expect((await repo.getById(e.id))!.updatedAtMs, 5000);
  });

  test('setEnd writes an explicit end; rejects end <= start; no-op if same',
      () async {
    final e = await repo.upsert(make('Focus', at(19, 42)));
    expect(await repo.setEnd(e.id, at(19, 42)), isNotNull);
    expect((await repo.getById(e.id))!.endedAtMs, isNull);
    clock = 2000;
    final ended = await repo.setEnd(e.id, at(20, 27));
    expect(ended!.endedAtMs, at(20, 27));
    expect(ended.updatedAtMs, 2000);
    clock = 3000;
    await repo.setEnd(e.id, at(20, 27));
    expect((await repo.getById(e.id))!.updatedAtMs, 2000);
    expect(await repo.setEnd('missing', at(21)), isNull);
  });

  test('invalid events throw before touching Isar', () async {
    await expectLater(repo.upsert(make('   ', at(9))), throwsArgumentError);
    expect(await isar!.isarActivityEvents.count(), 0);
  });

  test('watchRecentSince and watchLatest', () async {
    await repo.upsert(make('Old', at(8)));
    await repo.upsert(make('New', at(12)));
    final recent = await repo.watchRecentSince(at(10)).first;
    expect(recent.map((e) => e.text), ['New']);
    final latest = await repo.watchLatest().first;
    expect(latest!.text, 'New');
  });

  group('LWW merge', () {
    test('older remote ignored, newer applied, tombstone wins', () async {
      final e = await repo.upsert(make('Local', at(9)));
      final older = e.copyWith(text: 'Stale', updatedAtMs: 500);
      expect(await mergeActivityEventLwwIntoIsar(isar!, older), isFalse);
      final newer = e.copyWith(text: 'Remote', updatedAtMs: 9000);
      expect(await mergeActivityEventLwwIntoIsar(isar!, newer), isTrue);
      expect((await repo.getById(e.id))!.text, 'Remote');
      final tomb = e.copyWith(active: false, updatedAtMs: 9500);
      expect(await mergeActivityEventLwwIntoIsar(isar!, tomb), isTrue);
      expect((await repo.fetchDayOnce('2026-09-12')), isEmpty);
      expect(await isar!.isarActivityEvents.count(), 1);
    });

    test('equal stamps do not overwrite', () async {
      final e = await repo.upsert(make('Local', at(9)));
      final same = e.copyWith(text: 'Other');
      expect(await mergeActivityEventLwwIntoIsar(isar!, same), isFalse);
    });
  });
}
