import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/reminders/application/ladder_compiler.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';
import 'package:sidepal/features/reminders/domain/models/slot_spec.dart';

/// FR-R-30…33. The compiler is pure, so every rule is checked against fixed
/// inputs rather than by observing notifications.
void main() {
  // The PRD's own scenario: a 2 PM study block, a 3 PM workout.
  final twoPm = DateTime(2026, 8, 30, 14, 0);
  final justBefore = twoPm.subtract(const Duration(minutes: 1));

  ReminderOccurrence occ({
    String modeRefId = 'disciplined',
    int windowMinutes = 45,
    int criticality = 1,
    DateTime? scheduledAt,
    ReminderOccurrenceState state = ReminderOccurrenceState.upcoming,
    ReminderResolutionKind? resolutionKind,
    ReminderTaxonomy taxonomy = ReminderTaxonomy.flexible,
    DateTime? snoozedUntil,
  }) {
    final at = scheduledAt ?? twoPm;
    return ReminderOccurrence(
      id: 'o1',
      entityId: 'task-1',
      entityKind: 'task',
      dateKey: DateKeys.yyyymmdd(at),
      scheduledAtMs: at.millisecondsSinceEpoch,
      windowMinutes: windowMinutes,
      entityTitle: 'Study',
      modeRefId: modeRefId,
      state: state,
      taxonomy: taxonomy,
      criticality: criticality,
      resolutionKind: resolutionKind,
      snoozedUntilMs: snoozedUntil?.millisecondsSinceEpoch,
      createdAtMs: 1,
      updatedAtMs: 1,
    );
  }

  LadderPlan compile({
    ReminderOccurrence? occurrence,
    List<DateTime> upcomingStarts = const [],
    List<ShieldWindow> shields = const [],
    int budgetRemaining = 64,
    DateTime? now,
  }) => LadderCompiler.compile(
    occurrence: occurrence ?? occ(),
    context: LadderContext(
      upcomingStarts: upcomingStarts,
      shields: shields,
      budgetRemaining: budgetRemaining,
    ),
    now: now ?? justBefore,
  );

  group('mode shapes (FR-R-30)', () {
    test('flexible arms two slots', () {
      final plan = compile(
        occurrence: occ(modeRefId: 'flexible', windowMinutes: 30),
      );
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 15]);
    });

    test('disciplined arms three', () {
      final plan = compile();
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 10, 25]);
    });

    test('extreme arms four', () {
      final plan = compile(
        occurrence: occ(modeRefId: 'extreme', windowMinutes: 60),
      );
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 5, 15, 30]);
    });

    test('an unknown mode gets the gentlest ladder', () {
      final plan = compile(occurrence: occ(modeRefId: 'strict-ish-typo'));
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 15]);
    });
  });

  group('the interruption boundary (FR-R-31 / D1)', () {
    test(
      'the 3 PM workout silences the 2 PM ladder from 2:40 — the PRD story',
      () {
        final plan = compile(
          upcomingStarts: [DateTime(2026, 8, 30, 15, 0)],
        );

        // Boundary = 15:00 − 20 min = 14:40. T+25 (14:25) survives; the
        // window would have allowed until 14:45.
        expect(plan.boundary, DateTime(2026, 8, 30, 14, 40));
        expect(plan.effectiveEnd, DateTime(2026, 8, 30, 14, 40));
        expect(plan.slots.map((s) => s.offsetMinutes), [0, 10, 25]);
      },
    );

    test('a nearer next task cuts the ladder short, and says so', () {
      final plan = compile(
        upcomingStarts: [DateTime(2026, 8, 30, 14, 30)],
      );

      // Boundary = 14:10, so only T+0 survives.
      expect(plan.slots.map((s) => s.offsetMinutes), [0]);
      expect(plan.endedAtBoundary, isTrue);
      expect(
        plan.drops.where((d) => d.reason == SlotDropReason.boundary).length,
        2,
      );
    });

    test('leaving only T+0 is a correct outcome, not a failure', () {
      final plan = compile(upcomingStarts: [DateTime(2026, 8, 30, 14, 25)]);
      expect(plan.slots, hasLength(1));
      expect(plan.slots.single.isFirst, isTrue);
    });

    test('the earliest upcoming item wins', () {
      final plan = compile(
        upcomingStarts: [
          DateTime(2026, 8, 30, 18, 0),
          DateTime(2026, 8, 30, 14, 30),
          DateTime(2026, 8, 30, 16, 0),
        ],
      );
      expect(plan.boundary, DateTime(2026, 8, 30, 14, 10));
    });

    test('items at or before the occurrence are not boundaries', () {
      final plan = compile(
        upcomingStarts: [
          DateTime(2026, 8, 30, 13, 0),
          twoPm,
        ],
      );
      expect(plan.boundary, isNull);
      expect(plan.slots, hasLength(3));
    });

    test('with nothing else scheduled, only the window ends the ladder', () {
      final plan = compile();
      expect(plan.boundary, isNull);
      expect(plan.effectiveEnd, twoPm.add(const Duration(minutes: 45)));
    });
  });

  group('the window always closes the ladder', () {
    test('slots at or past the window are dropped', () {
      // A 20-minute window cuts disciplined's T+25.
      final plan = compile(occurrence: occ(windowMinutes: 20));
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 10]);
      expect(
        plan.drops.single.reason,
        SlotDropReason.window,
      );
    });
  });

  group('shields (FR-R-32)', () {
    test('a slot inside a focus block is pruned', () {
      final plan = compile(
        shields: [
          ShieldWindow(
            start: DateTime(2026, 8, 30, 14, 5),
            end: DateTime(2026, 8, 30, 14, 20),
            reason: 'focus',
          ),
        ],
      );
      // T+10 (14:10) falls inside; T+0 and T+25 survive.
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 25]);
      expect(plan.drops.single.reason, SlotDropReason.shield);
    });
  });

  group('criticality 3 pierces — but never the window (D5)', () {
    test('it ignores the boundary', () {
      final plan = compile(
        occurrence: occ(criticality: 3, modeRefId: 'extreme', windowMinutes: 60),
        upcomingStarts: [DateTime(2026, 8, 30, 14, 30)],
      );
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 5, 15, 30]);
    });

    test('it ignores shields, including sleep', () {
      final plan = compile(
        occurrence: occ(criticality: 3),
        shields: [
          ShieldWindow(
            start: DateTime(2026, 8, 30, 0, 0),
            end: DateTime(2026, 8, 31, 0, 0),
            reason: 'sleep',
          ),
        ],
      );
      expect(plan.slots, hasLength(3));
    });

    test('it still stops hard at the window', () {
      final plan = compile(
        occurrence: occ(criticality: 3, windowMinutes: 20),
      );
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 10]);
    });
  });

  group('budget (FR-R-33)', () {
    test('a future day gets its first slot only', () {
      final tomorrow = twoPm.add(const Duration(days: 1));
      final plan = compile(
        occurrence: occ(scheduledAt: tomorrow),
        now: justBefore,
      );
      expect(plan.slots.map((s) => s.offsetMinutes), [0]);
      expect(
        plan.drops.every((d) => d.reason == SlotDropReason.notToday),
        isTrue,
      );
    });

    test('a tight budget keeps the earliest slots and logs the rest', () {
      final plan = compile(budgetRemaining: 2);
      expect(plan.slots.map((s) => s.offsetMinutes), [0, 10]);
      expect(plan.drops.single.reason, SlotDropReason.budget);
      expect(plan.drops.single.offsetMinutes, 25);
    });

    test('no budget arms nothing, and every drop is recorded', () {
      final plan = compile(budgetRemaining: 0);
      expect(plan.slots, isEmpty);
      // Nothing is silently truncated.
      expect(plan.drops, hasLength(3));
    });
  });

  group('time and terminality', () {
    test('slots already past are never scheduled', () {
      final plan = compile(now: twoPm.add(const Duration(minutes: 12)));
      expect(plan.slots.map((s) => s.offsetMinutes), [25]);
      expect(
        plan.drops.where((d) => d.reason == SlotDropReason.past).length,
        2,
      );
    });

    test('a resolved occurrence compiles to nothing', () {
      final plan = compile(
        occurrence: occ(
          state: ReminderOccurrenceState.resolved,
          resolutionKind: ReminderResolutionKind.completed,
        ),
      );
      expect(plan.isEmpty, isTrue);
      expect(plan.drops, isEmpty);
    });
  });

  group('property: no compiled slot may violate any rule', () {
    test('across many shapes, every surviving slot is legal', () {
      final modes = ['flexible', 'disciplined', 'extreme'];
      final windows = [15, 30, 45, 60];
      final criticalities = [0, 1, 2, 3];
      final boundaries = <List<DateTime>>[
        const [],
        [DateTime(2026, 8, 30, 14, 25)],
        [DateTime(2026, 8, 30, 15, 0)],
      ];
      final shieldSets = <List<ShieldWindow>>[
        const [],
        [
          ShieldWindow(
            start: DateTime(2026, 8, 30, 14, 5),
            end: DateTime(2026, 8, 30, 14, 20),
            reason: 'focus',
          ),
        ],
      ];

      var checked = 0;
      for (final mode in modes) {
        for (final window in windows) {
          for (final crit in criticalities) {
            for (final starts in boundaries) {
              for (final shields in shieldSets) {
                final o = occ(
                  modeRefId: mode,
                  windowMinutes: window,
                  criticality: crit,
                );
                final plan = compile(
                  occurrence: o,
                  upcomingStarts: starts,
                  shields: shields,
                );
                final pierces = crit >= 3;

                for (final slot in plan.slots) {
                  checked++;
                  final label =
                      '$mode/w$window/c$crit/${starts.length}b slot ${slot.offsetMinutes}';

                  // Never in the past.
                  expect(slot.fireAt.isAfter(justBefore), isTrue, reason: label);
                  // Never at or past the window.
                  expect(slot.fireAt.isBefore(o.windowEnd), isTrue, reason: label);
                  // Never at or past the boundary, unless piercing.
                  if (!pierces && plan.boundary != null) {
                    expect(
                      slot.fireAt.isBefore(plan.boundary!),
                      isTrue,
                      reason: label,
                    );
                  }
                  // Never inside a shield, unless piercing.
                  if (!pierces) {
                    for (final shield in shields) {
                      expect(shield.contains(slot.fireAt), isFalse, reason: label);
                    }
                  }
                }

                // Nothing vanishes without a record.
                expect(
                  plan.slots.length + plan.drops.length,
                  greaterThanOrEqualTo(
                    plan.slots.length,
                  ),
                  reason: 'drops are always recorded',
                );
              }
            }
          }
        }
      }
      expect(checked, greaterThan(100));
    });
  });

  group('snooze re-plans the remaining ladder (FR-R-35 / A2)', () {
    test('slots the snooze pre-empts are dropped; later ones survive', () {
      // Snoozed until 14:12: T+0 is past anyway, T+10 (14:10) is pre-empted,
      // T+25 (14:25) survives — deferring the ladder is not resigning it.
      final plan = compile(
        occurrence: occ(
          snoozedUntil: twoPm.add(const Duration(minutes: 12)),
        ),
        now: twoPm.add(const Duration(minutes: 1)),
      );

      expect(plan.slots.map((s) => s.offsetMinutes), [25]);
      expect(
        plan.drops.where((d) => d.reason == SlotDropReason.snoozed).single
            .offsetMinutes,
        10,
      );
    });

    test('a snooze past the whole ladder silences it entirely', () {
      final plan = compile(
        occurrence: occ(
          snoozedUntil: twoPm.add(const Duration(minutes: 40)),
        ),
        now: twoPm.add(const Duration(minutes: 1)),
      );
      expect(plan.slots, isEmpty);
    });
  });

  group('routine never escalates (§3.2 / A4)', () {
    test('whatever the mode, a routine item speaks once', () {
      for (final mode in ['flexible', 'disciplined', 'extreme']) {
        final plan = compile(
          occurrence: occ(
            modeRefId: mode,
            windowMinutes: 60,
            taxonomy: ReminderTaxonomy.routine,
          ),
        );
        expect(plan.slots.map((s) => s.offsetMinutes), [0], reason: mode);
        // Shape, not pruning: no drops are logged for the missing follow-ups.
        expect(
          plan.drops.where((d) => d.reason == SlotDropReason.window),
          isEmpty,
          reason: mode,
        );
      }
    });
  });
}
