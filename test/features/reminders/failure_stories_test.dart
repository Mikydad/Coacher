import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/reminders/application/ladder_compiler.dart';
import 'package:sidepal/features/reminders/application/reminder_copy_bank.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_health.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';
import 'package:sidepal/features/reminders/domain/models/slot_spec.dart';

/// FR-R-71 names the failure stories this system must have. Each one gets a
/// test here, because "it degrades gracefully" is a claim, and an untested
/// claim about failure is the kind that turns out to be false exactly when it
/// matters.
void main() {
  final twoPm = DateTime(2026, 8, 30, 14, 0);

  ReminderOccurrence occ({
    String modeRefId = 'disciplined',
    int windowMinutes = 45,
    int criticality = 1,
    String? title = 'Study',
  }) => ReminderOccurrence(
    id: 'o1',
    entityId: 't1',
    entityKind: 'task',
    dateKey: '2026-08-30',
    scheduledAtMs: twoPm.millisecondsSinceEpoch,
    windowMinutes: windowMinutes,
    entityTitle: title,
    modeRefId: modeRefId,
    criticality: criticality,
    createdAtMs: 1,
    updatedAtMs: 1,
  );

  group('"AI endpoint down → the heuristic stands, silently"', () {
    test('the copy bank needs no network and no model', () {
      // Nothing here is async. There is no call to fail.
      final copy = ReminderCopyBank.forSlot(
        entityTitle: 'Study',
        modeRefId: 'extreme',
        ladderPosition: 2,
      );
      expect(copy.body.trim(), isNotEmpty);
    });

    test('a slot compiled today carries its string for tonight', () {
      final plan = LadderCompiler.compile(
        occurrence: occ(),
        context: const LadderContext(),
        now: twoPm.subtract(const Duration(hours: 1)),
      );
      // Written now, delivered later, with nothing left to resolve.
      for (final slot in plan.slots) {
        expect(slot.body.trim(), isNotEmpty);
        expect(slot.title.trim(), isNotEmpty);
      }
    });
  });

  group('"budget cap hit → deterministic drop order, every drop logged"', () {
    test('an exhausted queue drops the deepest slots and records each one', () {
      final plan = LadderCompiler.compile(
        occurrence: occ(modeRefId: 'extreme', windowMinutes: 60),
        context: const LadderContext(budgetRemaining: 1),
        now: twoPm.subtract(const Duration(minutes: 1)),
      );

      expect(plan.slots.map((s) => s.offsetMinutes), [0]);
      expect(
        plan.drops.where((d) => d.reason == SlotDropReason.budget),
        hasLength(3),
      );
    });

    test('a completely full queue is silent but never SILENTLY silent', () {
      final plan = LadderCompiler.compile(
        occurrence: occ(),
        context: const LadderContext(budgetRemaining: 0),
        now: twoPm.subtract(const Duration(minutes: 1)),
      );
      expect(plan.slots, isEmpty);
      // Nothing vanished without a record.
      expect(plan.drops, isNotEmpty);
    });
  });

  group('"timezone unresolved → health notice + retry"', () {
    test('it is a fault the Home hint raises', () {
      const health = ReminderHealth(
        permitted: true,
        pendingCount: 3,
        pendingCap: 56,
        timeZoneResolved: false,
        timeZoneFailureReason: 'channel unavailable',
      );
      expect(health.isHealthy, isFalse);
      expect(health.faults.single.severity, ReminderHealthSeverity.degraded);
      expect(health.summaryLine, 'Timezone unresolved');
    });
  });

  group('"OS permission revoked → the user is told, not left guessing"', () {
    test('it is the most severe fault and leads the summary', () {
      const health = ReminderHealth(
        permitted: false,
        pendingCount: 3,
        pendingCap: 56,
        timeZoneResolved: true,
      );
      expect(health.faults.first.severity, ReminderHealthSeverity.blocking);
      expect(health.summaryLine, 'Not allowed to notify');
    });
  });

  group('"[L-PUSH] unavailable → the local floor still holds"', () {
    test('an unregistered device is context, never a fault', () {
      const health = ReminderHealth(
        permitted: true,
        pendingCount: 3,
        pendingCap: 56,
        timeZoneResolved: true,
        pushRegistered: false,
      );
      // Push is an additive floor (PRD §5). Its absence must not raise the
      // hint, or every offline user would see a warning about a feature that
      // was never promised.
      expect(health.isHealthy, isTrue);
      expect(health.faults, isEmpty);
    });
  });

  group('degenerate data cannot break delivery', () {
    test('a titleless occurrence still produces a sayable slot', () {
      final plan = LadderCompiler.compile(
        occurrence: occ(title: null),
        context: const LadderContext(),
        now: twoPm.subtract(const Duration(minutes: 1)),
      );
      expect(plan.slots, isNotEmpty);
      for (final slot in plan.slots) {
        expect(slot.title.trim(), isNotEmpty);
        expect(slot.body, contains('your task'));
      }
    });

    test('a zero-length window arms nothing rather than misfiring', () {
      final plan = LadderCompiler.compile(
        occurrence: occ(windowMinutes: 0),
        context: const LadderContext(),
        now: twoPm.subtract(const Duration(minutes: 1)),
      );
      expect(plan.slots, isEmpty);
      expect(plan.drops, isNotEmpty);
    });

    test('a boundary before the occurrence does not invert the window', () {
      final plan = LadderCompiler.compile(
        occurrence: occ(),
        context: LadderContext(
          upcomingStarts: [twoPm.subtract(const Duration(hours: 3))],
        ),
        now: twoPm.subtract(const Duration(minutes: 1)),
      );
      // A past item is not "the next" one; the window alone applies.
      expect(plan.boundary, isNull);
      expect(plan.slots, isNotEmpty);
    });
  });
}
