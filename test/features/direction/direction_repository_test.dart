import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:sidepal/core/local_db/isar_collections/isar_direction_entry.dart';
import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/direction/data/direction_lww_merge.dart';
import 'package:sidepal/features/direction/data/direction_repository.dart';
import 'package:sidepal/features/direction/domain/direction_periods.dart';
import 'package:sidepal/features/direction/domain/models/direction_entry.dart';

import '../../support/isar_test_harness.dart';

void main() {
  Isar? isar;
  Directory? dir;
  var clock = 1000;
  late DirectionRepository repo;

  final sep = DirectionPeriods.current(
    DirectionHorizon.month,
    DateTime(2026, 9, 11),
  );

  setUp(() async {
    SyncService.debugSkipQueuePersistenceForTests = true;
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    OfflineStore.debugIsarOverride = isar;
    clock = 1000;
    repo = DirectionRepository(now: () => clock);
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

  test('setText creates the row and the watch stream emits it', () async {
    final first = repo.watchAll().firstWhere((rows) => rows.isNotEmpty);
    final saved = await repo.setText(sep, '  Get SidePal ready for launch ');
    expect(saved, isNotNull);
    expect(saved!.id, 'dir_month_2026-09');
    expect(saved.text, 'Get SidePal ready for launch');
    final rows = await first;
    expect(rows.single.id, 'dir_month_2026-09');
  });

  test('same text → no-op (no updatedAtMs bump, no new row)', () async {
    await repo.setText(sep, 'Launch');
    clock = 2000;
    final again = await repo.setText(sep, ' Launch ');
    expect(again!.updatedAtMs, 1000);
    expect(await isar!.isarDirectionEntrys.count(), 1);
  });

  test('empty text on a missing row creates nothing', () async {
    expect(await repo.setText(sep, '   '), isNull);
    expect(await isar!.isarDirectionEntrys.count(), 0);
  });

  test('clearing keeps the row (history) with a fresh stamp', () async {
    await repo.setText(sep, 'Launch');
    clock = 5000;
    final cleared = await repo.setText(sep, '');
    expect(cleared!.isEmpty, isTrue);
    expect(cleared.updatedAtMs, 5000);
    expect(cleared.createdAtMs, 1000);
    expect(await isar!.isarDirectionEntrys.count(), 1);
  });

  test('deterministic id: the same period on two writes is ONE row', () async {
    await repo.setText(sep, 'A');
    clock = 2000;
    await repo.setText(sep, 'B');
    final all = await repo.fetchAllOnce();
    expect(all.length, 1);
    expect(all.single.text, 'B');
    expect(all.single.createdAtMs, 1000);
  });

  test('history: a new period is a new row, the old one is untouched',
      () async {
    final aug = DirectionPeriods.previous(sep);
    await repo.setText(aug, 'August focus');
    clock = 2000;
    await repo.setText(sep, 'September focus');
    expect(await isar!.isarDirectionEntrys.count(), 2);
    expect((await repo.get(DirectionHorizon.month, '2026-08'))!.text,
        'August focus');
  });

  test('over-long text throws before touching Isar', () async {
    await expectLater(
      repo.setText(sep, 'a' * (kDirectionMaxChars + 1)),
      throwsArgumentError,
    );
    expect(await isar!.isarDirectionEntrys.count(), 0);
  });

  group('LWW merge', () {
    test('older remote is ignored, newer remote applied', () async {
      await repo.setText(sep, 'Local');
      final older = DirectionEntry.forPeriod(sep, text: 'Stale', nowMs: 500);
      expect(await mergeDirectionEntryLwwIntoIsar(isar!, older), isFalse);
      expect((await repo.get(sep.horizon, sep.key))!.text, 'Local');

      final newer = DirectionEntry.forPeriod(sep, text: 'Remote', nowMs: 9000);
      expect(await mergeDirectionEntryLwwIntoIsar(isar!, newer), isTrue);
      expect((await repo.get(sep.horizon, sep.key))!.text, 'Remote');
      expect(await isar!.isarDirectionEntrys.count(), 1);
    });

    test('a newer remote clear beats a stale local edit', () async {
      await repo.setText(sep, 'Local edit');
      final clear = DirectionEntry.forPeriod(sep, text: '', nowMs: 9000);
      expect(await mergeDirectionEntryLwwIntoIsar(isar!, clear), isTrue);
      expect((await repo.get(sep.horizon, sep.key))!.isEmpty, isTrue);
    });

    test('equal stamps do not overwrite', () async {
      await repo.setText(sep, 'Local');
      final same = DirectionEntry.forPeriod(sep, text: 'Other', nowMs: 1000);
      expect(await mergeDirectionEntryLwwIntoIsar(isar!, same), isFalse);
    });
  });
}
