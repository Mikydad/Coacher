import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/reminders/application/reminder_occurrence_service.dart';
import 'package:sidepal/features/reminders/data/reminder_occurrence_repository.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

// ── In-memory fakes (no Isar needed: the service is pure orchestration) ──────

class _FakeOccurrences implements ReminderOccurrenceRepository {
  final Map<String, ReminderOccurrence> rows = {};

  @override
  Future<ReminderOccurrence?> findByKey({
    required String entityKind,
    required String entityId,
    required String dateKey,
  }) async => rows[ReminderOccurrence.keyFor(entityKind, entityId, dateKey)];

  @override
  Future<List<ReminderOccurrence>> listForEntity(String entityId) async =>
      rows.values.where((o) => o.entityId == entityId).toList()
        ..sort((a, b) => b.scheduledAtMs.compareTo(a.scheduledAtMs));

  @override
  Future<List<ReminderOccurrence>> listUnresolved() async =>
      rows.values.where((o) => !o.isResolved).toList()
        ..sort((a, b) => a.scheduledAtMs.compareTo(b.scheduledAtMs));

  @override
  Future<List<ReminderOccurrence>> listInRange({
    required int startMs,
    required int endMs,
  }) async => rows.values
      .where((o) => o.scheduledAtMs >= startMs && o.scheduledAtMs < endMs)
      .toList();

  @override
  Future<void> upsert(ReminderOccurrence o) async =>
      rows[o.occurrenceKey] = o;

  @override
  Future<void> upsertAll(Iterable<ReminderOccurrence> os) async {
    for (final o in os) {
      rows[o.occurrenceKey] = o;
    }
  }

  @override
  Future<void> deleteForEntity(String entityId) async =>
      rows.removeWhere((_, o) => o.entityId == entityId);

  @override
  Future<void> pruneResolvedOlderThan(Duration age) async {}

  @override
  Stream<List<ReminderOccurrence>> watchUnresolved() => const Stream.empty();

  @override
  Stream<List<ReminderOccurrence>> watchRecoveryPool({
    required int todayStartMs,
  }) => const Stream.empty();

  @override
  Stream<List<ReminderOccurrence>> watchForEntity(String entityId) =>
      const Stream.empty();
}

class _FakeReminders implements ReminderRepository {
  _FakeReminders([List<ReminderConfig>? seed])
    : rows = [...?seed];
  final List<ReminderConfig> rows;

  @override
  Future<List<ReminderConfig>> listAllReminders() async => rows;

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> ids) async =>
      rows.where((r) => ids.contains(r.taskId)).toList();

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {}

  @override
  Future<void> deleteRemindersForTask(String taskId) async =>
      rows.removeWhere((r) => r.taskId == taskId);

  @override
  Future<void> upsertReminder(ReminderConfig r) async {
    final i = rows.indexWhere((x) => x.id == r.id);
    if (i >= 0) {
      rows[i] = r;
    } else {
      rows.add(r);
    }
  }
}

void main() {
  // "Now" is 6 PM; the study block was at 2 PM and its window closed at 2:30.
  final now = DateTime(2026, 8, 30, 18, 0);
  final twoPm = DateTime(2026, 8, 30, 14, 0);

  ReminderConfig config({
    String taskId = 't1',
    bool enabled = true,
    DateTime? at,
    String modeRefId = 'flexible',
  }) => ReminderConfig(
    id: 'r-$taskId',
    taskId: taskId,
    taskTitle: 'Study',
    enabled: enabled,
    scheduledAtIso: (at ?? twoPm).toIso8601String(),
    modeRefId: modeRefId,
    createdAtMs: 1,
    updatedAtMs: 1,
  );

  ReminderOccurrenceService service(
    _FakeOccurrences occ,
    _FakeReminders rem, {
    DateTime? clock,
  }) => ReminderOccurrenceService(
    occurrences: occ,
    reminders: rem,
    now: () => clock ?? now,
  );

  group('sweep — backfill', () {
    test('an enabled config scheduled today gets an occurrence', () async {
      final occ = _FakeOccurrences();
      final result = await service(occ, _FakeReminders([config()])).sweep();

      expect(result.created, 1);
      final made = occ.rows.values.single;
      expect(made.entityId, 't1');
      expect(made.entityKind, 'task');
      // Snapshot from the config, which carries the stable answer.
      expect(made.classificationSource, ClassificationSource.heuristic);
      expect(made.taxonomy, ReminderTaxonomy.flexible);
      expect(made.criticality, 1);
      // D2: flexible windows are 30 minutes.
      expect(made.windowMinutes, 30);
    });

    test('window length follows the mode (D2)', () async {
      final occ = _FakeOccurrences();
      await service(
        occ,
        _FakeReminders([
          config(taskId: 'a', modeRefId: 'disciplined'),
          config(taskId: 'b', modeRefId: 'extreme'),
        ]),
      ).sweep();

      expect(
        occ.rows.values.firstWhere((o) => o.entityId == 'a').windowMinutes,
        45,
      );
      expect(
        occ.rows.values.firstWhere((o) => o.entityId == 'b').windowMinutes,
        60,
      );
    });

    test('a disabled config is not backfilled', () async {
      final occ = _FakeOccurrences();
      final r = await service(
        occ,
        _FakeReminders([config(enabled: false)]),
      ).sweep();
      expect(r.created, 0);
      expect(occ.rows, isEmpty);
    });

    test(
      'configs from before today are NOT resurrected as a wall of misses',
      () async {
        final occ = _FakeOccurrences();
        final r = await service(
          occ,
          _FakeReminders([
            config(taskId: 'ancient', at: DateTime(2026, 5, 1, 9, 0)),
            config(taskId: 'yesterday', at: DateTime(2026, 8, 29, 9, 0)),
          ]),
        ).sweep();

        expect(r.created, 0);
        expect(occ.rows, isEmpty);
      },
    );

    test('the backfill is idempotent', () async {
      final occ = _FakeOccurrences();
      final rem = _FakeReminders([config()]);

      expect((await service(occ, rem).sweep()).created, 1);
      expect((await service(occ, rem).sweep()).created, 0);
      expect(occ.rows, hasLength(1));
    });
  });

  group('sweep — advance', () {
    test('a missed flexible occurrence becomes overdue retroactively', () async {
      final occ = _FakeOccurrences();
      final rem = _FakeReminders([config()]);

      final result = await service(occ, rem).sweep();

      final o = occ.rows.values.single;
      expect(o.state, ReminderOccurrenceState.overdue);
      // Overdue since 2:30 PM — when the window closed, not 6 PM when we looked.
      expect(
        o.overdueSinceMs,
        twoPm.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      );
      expect(result.nowOverdue, 1);
    });

    test('a still-future occurrence stays upcoming', () async {
      final occ = _FakeOccurrences();
      final rem = _FakeReminders([
        config(at: DateTime(2026, 8, 30, 21, 0)),
      ]);

      await service(occ, rem).sweep();

      expect(occ.rows.values.single.state, ReminderOccurrenceState.upcoming);
    });

    test('a sweep with nothing to do reports no work', () async {
      final r = await service(_FakeOccurrences(), _FakeReminders()).sweep();
      expect(r.didWork, isFalse);
    });
  });

  group('lifecycle gestures (FR-R-13)', () {
    test('resolving marks the open occurrence completed', () async {
      final occ = _FakeOccurrences();
      final rem = _FakeReminders([config()]);
      final svc = service(occ, rem);
      await svc.sweep();

      final resolved = await svc.resolveForEntity(
        't1',
        kind: ReminderResolutionKind.completed,
      );

      expect(resolved!.state, ReminderOccurrenceState.resolved);
      expect(resolved.resolutionKind, ReminderResolutionKind.completed);
      expect(resolved.resolvedAtMs, now.millisecondsSinceEpoch);
      expect(await occ.listUnresolved(), isEmpty);
    });

    test('a reschedule reason is carried onto the record', () async {
      final occ = _FakeOccurrences();
      final rem = _FakeReminders([config(modeRefId: 'extreme')]);
      final svc = service(occ, rem);
      await svc.sweep();

      final resolved = await svc.resolveForEntity(
        't1',
        kind: ReminderResolutionKind.rescheduled,
        reason: 'meeting ran over',
      );

      expect(resolved!.resolutionReason, 'meeting ran over');
    });

    test('markActive sets active and stops the ladder', () async {
      final occ = _FakeOccurrences();
      final rem = _FakeReminders([
        config(at: DateTime(2026, 8, 30, 17, 50)),
      ]);
      final svc = service(occ, rem);
      await svc.sweep();

      final active = await svc.markActiveForEntity('t1');
      expect(active!.state, ReminderOccurrenceState.active);
    });

    test('deleting an entity clears it off the Recovery Card', () async {
      final occ = _FakeOccurrences();
      final rem = _FakeReminders([config()]);
      final svc = service(occ, rem);
      await svc.sweep();
      expect(await occ.listUnresolved(), hasLength(1));

      await svc.deleteForEntity('t1');
      expect(await occ.listUnresolved(), isEmpty);
    });

    test('resolving an entity with no occurrence is a safe no-op', () async {
      final svc = service(_FakeOccurrences(), _FakeReminders());
      expect(
        await svc.resolveForEntity(
          'nobody',
          kind: ReminderResolutionKind.completed,
        ),
        isNull,
      );
    });
  });

  group('ensureForConfig — the save path', () {
    test('creates the occurrence immediately, not at the next sweep', () async {
      final occ = _FakeOccurrences();
      final svc = service(occ, _FakeReminders());

      final made = await svc.ensureForConfig(config());

      expect(made, isNotNull);
      expect(occ.rows, hasLength(1));
    });

    test('editing the time updates the same day row in place', () async {
      final occ = _FakeOccurrences();
      final svc = service(occ, _FakeReminders());
      await svc.ensureForConfig(config());

      final moved = await svc.ensureForConfig(
        config(at: DateTime(2026, 8, 30, 17, 45)),
      );

      expect(occ.rows, hasLength(1));
      expect(
        moved!.scheduledAtMs,
        DateTime(2026, 8, 30, 17, 45).millisecondsSinceEpoch,
      );
      // 17:45 + 30 min window is still open at 18:00.
      expect(moved.state, ReminderOccurrenceState.due);
    });

    test('an already-resolved day is never reopened by a config edit', () async {
      final occ = _FakeOccurrences();
      final svc = service(occ, _FakeReminders());
      await svc.ensureForConfig(config());
      await svc.resolveForEntity(
        't1',
        kind: ReminderResolutionKind.completed,
      );

      final again = await svc.ensureForConfig(config());

      expect(again!.state, ReminderOccurrenceState.resolved);
    });

    test('a disabled config produces nothing', () async {
      final occ = _FakeOccurrences();
      final svc = service(occ, _FakeReminders());
      expect(await svc.ensureForConfig(config(enabled: false)), isNull);
      expect(occ.rows, isEmpty);
    });
  });

  group('consecutiveReschedules — D4 release valve', () {
    ReminderOccurrence resolved(
      String id,
      DateTime at,
      ReminderResolutionKind kind,
    ) => ReminderOccurrence(
      id: id,
      entityId: 't1',
      entityKind: 'task',
      dateKey: ReminderOccurrence.dateKeyFor(at.millisecondsSinceEpoch),
      scheduledAtMs: at.millisecondsSinceEpoch,
      windowMinutes: 30,
      entityTitle: 'Study',
      state: ReminderOccurrenceState.resolved,
      resolutionKind: kind,
      createdAtMs: 1,
      updatedAtMs: 1,
    );

    test('counts a run of reschedules', () async {
      final occ = _FakeOccurrences();
      for (var i = 1; i <= 3; i++) {
        final o = resolved(
          'r$i',
          twoPm.subtract(Duration(days: i)),
          ReminderResolutionKind.rescheduled,
        );
        occ.rows[o.occurrenceKey] = o;
      }
      final svc = service(occ, _FakeReminders());

      expect(await svc.consecutiveReschedules('t1'), 3);
    });

    test('actually doing it once breaks the streak', () async {
      final occ = _FakeOccurrences();
      final recent = resolved(
        'r1',
        twoPm.subtract(const Duration(days: 1)),
        ReminderResolutionKind.rescheduled,
      );
      final done = resolved(
        'r2',
        twoPm.subtract(const Duration(days: 2)),
        ReminderResolutionKind.completed,
      );
      final older = resolved(
        'r3',
        twoPm.subtract(const Duration(days: 3)),
        ReminderResolutionKind.rescheduled,
      );
      for (final o in [recent, done, older]) {
        occ.rows[o.occurrenceKey] = o;
      }
      final svc = service(occ, _FakeReminders());

      // Only the run since the last completion counts.
      expect(await svc.consecutiveReschedules('t1'), 1);
    });

    test("today's still-open occurrence does not break the streak", () async {
      final occ = _FakeOccurrences();
      final open = ReminderOccurrence(
        id: 'open',
        entityId: 't1',
        entityKind: 'task',
        dateKey: ReminderOccurrence.dateKeyFor(twoPm.millisecondsSinceEpoch),
        scheduledAtMs: twoPm.millisecondsSinceEpoch,
        windowMinutes: 30,
        entityTitle: 'Study',
        state: ReminderOccurrenceState.overdue,
        createdAtMs: 1,
        updatedAtMs: 1,
      );
      final moved = resolved(
        'r1',
        twoPm.subtract(const Duration(days: 1)),
        ReminderResolutionKind.rescheduled,
      );
      occ.rows[open.occurrenceKey] = open;
      occ.rows[moved.occurrenceKey] = moved;
      final svc = service(occ, _FakeReminders());

      expect(await svc.consecutiveReschedules('t1'), 1);
    });

    test('no history means no streak', () async {
      final svc = service(_FakeOccurrences(), _FakeReminders());
      expect(await svc.consecutiveReschedules('t1'), 0);
    });
  });

  group('closeWindowNow — "Wrong time" (FR-R-35 / A8)', () {
    test('a flexible task goes straight to Overdue, stamped to now', () async {
      final occ = _FakeOccurrences();
      final svc = service(occ, _FakeReminders([config()]));
      await svc.sweep();
      // The sweep already made it overdue (window long past); reset to due
      // to model the user hitting Wrong time DURING the window.
      final open = occ.rows.values.single;
      occ.rows[open.occurrenceKey] = open.copyWith(
        state: ReminderOccurrenceState.due,
        overdueSinceMs: null,
      );

      final closed = await svc.closeWindowNow('t1');

      expect(closed!.state, ReminderOccurrenceState.overdue);
      // Stamped to NOW: the user just declared the window over — this is the
      // one overdue stamp that is not retroactive, because the close itself
      // happened now.
      expect(closed.overdueSinceMs, now.millisecondsSinceEpoch);
    });

    test('a time-sensitive task expires — never mentioned again', () async {
      final occ = _FakeOccurrences();
      final svc = service(
        occ,
        _FakeReminders([config(taskId: 'meds')]),
      );
      await svc.sweep();
      final open = occ.rows.values.single;
      occ.rows[open.occurrenceKey] = open.copyWith(
        state: ReminderOccurrenceState.due,
        taxonomy: ReminderTaxonomy.timeSensitive,
      );

      final closed = await svc.closeWindowNow('meds');

      expect(closed!.state, ReminderOccurrenceState.resolved);
      expect(closed.resolutionKind, ReminderResolutionKind.expired);
    });

    test('no open occurrence is a safe no-op', () async {
      final svc = service(_FakeOccurrences(), _FakeReminders());
      expect(await svc.closeWindowNow('nobody'), isNull);
    });
  });

  group('recordSnooze (A2)', () {
    test('stamps where the snooze re-plans to', () async {
      final occ = _FakeOccurrences();
      final svc = service(occ, _FakeReminders([config()]));
      await svc.sweep();

      final until = now.add(const Duration(minutes: 12));
      final snoozed = await svc.recordSnooze('t1', until: until);

      expect(snoozed!.snoozedUntilMs, until.millisecondsSinceEpoch);
    });
  });
}
