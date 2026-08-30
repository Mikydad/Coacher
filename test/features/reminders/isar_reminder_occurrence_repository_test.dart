import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:sidepal/core/offline/offline_store.dart';
import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/reminders/data/isar_reminder_occurrence_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

import '../../support/isar_test_harness.dart';

void main() {
  Isar? isar;
  Directory? dir;
  const repo = IsarReminderOccurrenceRepository();

  final day = DateTime(2026, 8, 30, 14, 0);

  ReminderOccurrence occurrence({
    String id = 'occ-1',
    String entityId = 'task-1',
    String entityKind = 'task',
    DateTime? scheduledAt,
    ReminderOccurrenceState state = ReminderOccurrenceState.due,
    int updatedAtMs = 100,
  }) {
    final at = scheduledAt ?? day;
    return ReminderOccurrence(
      id: id,
      entityId: entityId,
      entityKind: entityKind,
      dateKey: ReminderOccurrence.dateKeyFor(at.millisecondsSinceEpoch),
      scheduledAtMs: at.millisecondsSinceEpoch,
      windowMinutes: 30,
      entityTitle: 'Study',
      modeRefId: 'disciplined',
      state: state,
      createdAtMs: 1,
      updatedAtMs: updatedAtMs,
    );
  }

  setUp(() async {
    final opened = await openTempIsar();
    isar = opened.isar;
    dir = opened.dir;
    OfflineStore.debugIsarOverride = isar;
    SyncService.debugSkipQueuePersistenceForTests = true;
    SyncService.instance.debugResetQueueInMemoryOnly();
  });

  tearDown(() async {
    OfflineStore.clearDebugIsarOverrideForTests();
    SyncService.debugSkipQueuePersistenceForTests = false;
    SyncService.instance.debugResetQueueInMemoryOnly();
    final i = isar;
    final d = dir;
    isar = null;
    dir = null;
    if (i != null && d != null) await closeTempIsar(i, d);
  });

  test('round-trips every field through Isar', () async {
    final o = occurrence().copyWith(
      taxonomy: ReminderTaxonomy.timeSensitive,
      criticality: 3,
      classificationSource: ClassificationSource.user,
      classifierVersion: 2,
      ladderPosition: 4,
      overdueSinceMs: 999,
      resolutionKind: ReminderResolutionKind.skipped,
      resolutionReason: 'meeting ran over',
      resolvedAtMs: 1234,
    );
    await repo.upsert(o);

    final back = (await repo.listForEntity('task-1')).single;
    expect(back.id, o.id);
    expect(back.taxonomy, ReminderTaxonomy.timeSensitive);
    expect(back.criticality, 3);
    expect(back.classificationSource, ClassificationSource.user);
    expect(back.classifierVersion, 2);
    expect(back.ladderPosition, 4);
    expect(back.overdueSinceMs, 999);
    expect(back.resolutionKind, ReminderResolutionKind.skipped);
    expect(back.resolutionReason, 'meeting ran over');
    expect(back.resolvedAtMs, 1234);
    expect(back.windowMinutes, 30);
    expect(back.modeRefId, 'disciplined');
  });

  test(
    're-arming the same entity on the same day updates ONE row, never two',
    () async {
      await repo.upsert(occurrence(id: 'occ-a'));
      // A second device / a re-arm writes a different occurrence id for the
      // same entity+day. The composite key must collapse them.
      await repo.upsert(
        occurrence(
          id: 'occ-b',
          state: ReminderOccurrenceState.overdue,
          updatedAtMs: 200,
        ),
      );

      final all = await repo.listForEntity('task-1');
      expect(all, hasLength(1));
      expect(all.single.state, ReminderOccurrenceState.overdue);
    },
  );

  test('the same entity on different days gets separate rows', () async {
    await repo.upsert(occurrence(id: 'occ-a'));
    await repo.upsert(
      occurrence(
        id: 'occ-b',
        scheduledAt: day.add(const Duration(days: 1)),
      ),
    );
    expect(await repo.listForEntity('task-1'), hasLength(2));
  });

  test('the same day for different entity kinds does not collide', () async {
    await repo.upsert(occurrence(id: 'occ-t', entityId: 'x'));
    await repo.upsert(
      occurrence(id: 'occ-g', entityId: 'x', entityKind: 'goal'),
    );
    expect(await repo.listForEntity('x'), hasLength(2));
  });

  test('listUnresolved excludes resolved occurrences', () async {
    await repo.upsert(occurrence(id: 'occ-open', entityId: 'a'));
    await repo.upsert(
      occurrence(
        id: 'occ-done',
        entityId: 'b',
        state: ReminderOccurrenceState.resolved,
      ),
    );

    final open = await repo.listUnresolved();
    expect(open, hasLength(1));
    expect(open.single.entityId, 'a');
  });

  test('findByKey locates the day row', () async {
    await repo.upsert(occurrence());
    final found = await repo.findByKey(
      entityKind: 'task',
      entityId: 'task-1',
      dateKey: ReminderOccurrence.dateKeyFor(day.millisecondsSinceEpoch),
    );
    expect(found, isNotNull);
    expect(found!.id, 'occ-1');

    expect(
      await repo.findByKey(
        entityKind: 'task',
        entityId: 'task-1',
        dateKey: '2026-01-01',
      ),
      isNull,
    );
  });

  test('listInRange is half-open on the upper bound', () async {
    await repo.upsert(occurrence(id: 'a', entityId: 'a'));
    await repo.upsert(
      occurrence(
        id: 'b',
        entityId: 'b',
        scheduledAt: day.add(const Duration(days: 2)),
      ),
    );

    final inRange = await repo.listInRange(
      startMs: day.millisecondsSinceEpoch,
      endMs: day.add(const Duration(days: 2)).millisecondsSinceEpoch,
    );
    expect(inRange.map((o) => o.entityId), ['a']);
  });

  test('upsertAll writes the whole sweep', () async {
    await repo.upsertAll([
      occurrence(id: 'a', entityId: 'a'),
      occurrence(id: 'b', entityId: 'b'),
      occurrence(id: 'c', entityId: 'c'),
    ]);
    expect(await repo.listUnresolved(), hasLength(3));
  });

  test('upsertAll on an empty set is a no-op', () async {
    await repo.upsertAll(const []);
    expect(await repo.listUnresolved(), isEmpty);
  });

  test('deleteForEntity removes every day row for that entity', () async {
    await repo.upsert(occurrence(id: 'a'));
    await repo.upsert(
      occurrence(id: 'b', scheduledAt: day.add(const Duration(days: 1))),
    );
    await repo.upsert(occurrence(id: 'c', entityId: 'other'));

    await repo.deleteForEntity('task-1');

    expect(await repo.listForEntity('task-1'), isEmpty);
    expect(await repo.listForEntity('other'), hasLength(1));
  });

  test('pruneResolvedOlderThan keeps unresolved history', () async {
    final old = DateTime.now().subtract(const Duration(days: 40));
    await repo.upsert(
      occurrence(
        id: 'old-done',
        entityId: 'a',
        scheduledAt: old,
        state: ReminderOccurrenceState.resolved,
      ),
    );
    await repo.upsert(
      occurrence(
        id: 'old-open',
        entityId: 'b',
        scheduledAt: old,
        state: ReminderOccurrenceState.overdue,
      ),
    );

    await repo.pruneResolvedOlderThan(const Duration(days: 30));

    expect(await repo.listForEntity('a'), isEmpty);
    expect(await repo.listForEntity('b'), hasLength(1));
  });

  test('watchUnresolved emits the current set and then updates', () async {
    final emissions = <List<ReminderOccurrence>>[];
    final sub = repo.watchUnresolved().listen(emissions.add);

    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(emissions.first, isEmpty);

    await repo.upsert(occurrence());
    await Future<void>.delayed(const Duration(milliseconds: 100));

    expect(emissions.last, hasLength(1));
    expect(emissions.last.single.entityId, 'task-1');

    await sub.cancel();
  });
}
