import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/reminders/application/ladder_compiler.dart';
import 'package:sidepal/features/reminders/application/recovery_view.dart';
import 'package:sidepal/features/reminders/application/reminder_classifier.dart';
import 'package:sidepal/features/reminders/application/reminder_copy_bank.dart';
import 'package:sidepal/features/reminders/application/reminder_occurrence_service.dart';
import 'package:sidepal/features/reminders/application/reminder_state_machine.dart';
import 'package:sidepal/features/reminders/data/reminder_occurrence_repository.dart';
import 'package:sidepal/features/reminders/data/reminder_repository.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_config.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// FR-R-70: the definition of done for every feature in this PRD.
///
/// This walks the PRD's own user story end to end with **no network of any
/// kind** — no Firestore double, no HTTP double, no AI double, because there
/// is nothing to double. Every step below is local code reading local state:
/// classification, occurrence creation, state transitions, ladder
/// compilation, copy, and the Recovery Card's contents.
///
/// If a future change puts the network on any of these paths, this test
/// cannot fail — it will not compile, because the network has no seam here.
/// That is the point.
class _Occurrences implements ReminderOccurrenceRepository {
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
  Future<void> upsert(ReminderOccurrence o) async => rows[o.occurrenceKey] = o;

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
  Stream<List<ReminderOccurrence>> watchForEntity(String entityId) =>
      const Stream.empty();

  @override
  Stream<List<ReminderOccurrence>> watchRecoveryPool({
    required int todayStartMs,
  }) => const Stream.empty();
}

class _Reminders implements ReminderRepository {
  final List<ReminderConfig> rows = [];

  @override
  Future<List<ReminderConfig>> listAllReminders() async => rows;

  @override
  Future<List<ReminderConfig>> getRemindersForTasks(List<String> ids) async =>
      rows.where((r) => ids.contains(r.taskId)).toList();

  @override
  Future<void> hydrateFromRemoteForTasks(List<String> taskIds) async {
    fail('the save path must never reach the network (C8)');
  }

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
  // The PRD's story: a 2 PM study block, a 3 PM workout.
  final twoPm = DateTime(2026, 8, 30, 14, 0);
  final threePm = DateTime(2026, 8, 30, 15, 0);

  test(
    'airplane mode: create → classify → compile → boundary → overdue → '
    'recover → resolve, with nothing on the network',
    () async {
      final occurrences = _Occurrences();
      final reminders = _Reminders();
      var clock = twoPm.subtract(const Duration(hours: 1)); // 13:00

      final service = ReminderOccurrenceService(
        occurrences: occurrences,
        reminders: reminders,
        now: () => clock,
      );

      // ── 1. The user creates "Study for 1 hour" at 2 PM ──────────────────
      final classification = ReminderClassifier.classify(
        title: 'Study for 1 hour',
        hasReminderTime: true,
        durationMinutes: 60,
        category: 'Study',
      );
      // Offline, synchronous, no round trip.
      expect(classification.taxonomy, ReminderTaxonomy.flexible);
      expect(classification.criticality, 1);

      final config = ReminderConfig(
        id: 'r1',
        taskId: 'study',
        taskTitle: 'Study',
        enabled: true,
        scheduledAtIso: twoPm.toIso8601String(),
        modeRefId: 'disciplined',
        taxonomy: classification.taxonomy,
        criticality: classification.criticality,
        classificationSource: ClassificationSource.heuristic,
        createdAtMs: clock.millisecondsSinceEpoch,
        updatedAtMs: clock.millisecondsSinceEpoch,
      );
      await reminders.upsertReminder(config);

      // ── 2. Saving arms the occurrence immediately ───────────────────────
      final created = await service.ensureForConfig(config);
      expect(created, isNotNull);
      expect(created!.state, ReminderOccurrenceState.upcoming);
      expect(created.windowMinutes, 45); // D2: disciplined

      // ── 3. The ladder compiles against the real plan ────────────────────
      // The 3 PM workout is the interruption boundary.
      final plan = LadderCompiler.compile(
        occurrence: created,
        context: LadderContext(upcomingStarts: [threePm]),
        now: clock,
      );

      // Disciplined's T+0/T+10/T+25 all fit before 14:40.
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 10, 25]);
      expect(plan.boundary, DateTime(2026, 8, 30, 14, 40));
      // Every slot already knows what it will say (FR-R-34).
      for (final slot in plan.slots) {
        expect(slot.body.trim(), isNotEmpty);
        expect(slot.body, contains('Study'));
      }
      expect(plan.slots.first.body, 'Time for Study.');
      expect(plan.slots.last.body, contains('Last call'));

      // ── 4. The window closes unattended while the app is DEAD ───────────
      // Nothing ran between 14:00 and 18:00 — no app, no server, no push.
      clock = DateTime(2026, 8, 30, 18, 0);

      final sweep = await service.sweep();
      expect(sweep.nowOverdue, 1);

      final overdue = (await occurrences.listUnresolved()).single;
      expect(overdue.state, ReminderOccurrenceState.overdue);
      // Retroactive: overdue since the window closed at 14:45, not since 18:00.
      expect(
        overdue.overdueSinceMs,
        twoPm.add(const Duration(minutes: 45)).millisecondsSinceEpoch,
      );

      // ── 5. It surfaces on the Recovery Card ─────────────────────────────
      final view = RecoveryViewBuilder.build(
        await occurrences.listUnresolved(),
        now: clock,
      );
      expect(view.rows, hasLength(1));
      expect(view.rows.single.title, 'Study');
      // Disciplined asks for a disposition and cannot be waved away.
      expect(view.rows.single.insistence, RecoveryInsistence.persistent);
      expect(view.rows.single.insistence.canDismiss, isFalse);

      // ── 6. The user does it ─────────────────────────────────────────────
      final resolved = await service.resolveForEntity(
        'study',
        kind: ReminderResolutionKind.completed,
      );
      expect(resolved!.state, ReminderOccurrenceState.resolved);
      expect(resolved.resolvedAtMs, clock.millisecondsSinceEpoch);

      // ── 7. And it is gone, for good ─────────────────────────────────────
      expect(await occurrences.listUnresolved(), isEmpty);
      expect(
        RecoveryViewBuilder.build(
          await occurrences.listUnresolved(),
          now: clock,
        ).isEmpty,
        isTrue,
      );

      // A resolved occurrence is terminal: a later sweep cannot reopen it.
      clock = DateTime(2026, 8, 31, 9, 0);
      await service.sweep();
      expect(await occurrences.listUnresolved(), isEmpty);
    },
  );

  test(
    'airplane mode: a time-sensitive miss expires quietly instead of nagging',
    () async {
      final occurrences = _Occurrences();
      final reminders = _Reminders();
      var clock = twoPm.subtract(const Duration(minutes: 30));

      final service = ReminderOccurrenceService(
        occurrences: occurrences,
        reminders: reminders,
        now: () => clock,
      );

      // "Call the bank when they open" classifies itself, offline.
      final classification = ReminderClassifier.classify(
        title: 'Call the bank when they open',
        hasReminderTime: true,
      );
      expect(classification.taxonomy, ReminderTaxonomy.timeSensitive);

      await service.ensureForConfig(
        ReminderConfig(
          id: 'r2',
          taskId: 'bank',
          taskTitle: 'Call the bank',
          enabled: true,
          scheduledAtIso: twoPm.toIso8601String(),
          modeRefId: 'flexible',
          taxonomy: classification.taxonomy,
          criticality: classification.criticality,
          createdAtMs: 1,
          updatedAtMs: 1,
        ),
      );

      clock = DateTime(2026, 8, 30, 21, 0);
      await service.sweep();

      final row = (await occurrences.listForEntity('bank')).single;
      // Expired, not overdue: it is logged as missed and never mentioned.
      expect(row.state, ReminderOccurrenceState.resolved);
      expect(row.resolutionKind, ReminderResolutionKind.expired);

      final view = RecoveryViewBuilder.build([row], now: clock);
      expect(view.rows, isEmpty);
      expect(view.routineDigestLine, isNull);
    },
  );

  test('airplane mode: the copy bank never needs the network', () {
    // Every string a slot can deliver is available synchronously, which is
    // what lets a slot be written hours before it fires.
    for (final mode in ['flexible', 'disciplined', 'extreme']) {
      for (var step = 0; step < 4; step++) {
        final copy = ReminderCopyBank.forSlot(
          entityTitle: 'Study',
          modeRefId: mode,
          ladderPosition: step,
        );
        expect(copy.body.trim(), isNotEmpty);
      }
    }
  });

  test('airplane mode: the state machine has no I/O to fail', () {
    // A pure function of (occurrence, now): there is nothing here that can be
    // offline, which is the structural guarantee behind FR-R-70.
    final occurrence = ReminderOccurrence(
      id: 'o',
      entityId: 'e',
      entityKind: 'task',
      dateKey: DateKeys.yyyymmdd(twoPm),
      scheduledAtMs: twoPm.millisecondsSinceEpoch,
      windowMinutes: 30,
      createdAtMs: 1,
      updatedAtMs: 1,
    );
    final advanced = ReminderStateMachine.advance(
      occurrence,
      now: DateTime(2026, 8, 30, 23, 0),
    );
    expect(advanced.state, ReminderOccurrenceState.overdue);
  });
}
