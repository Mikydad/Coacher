import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/reminders/application/reminder_state_machine.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// FR-R-11 / FR-R-12. Pure transitions against an injected clock — no I/O,
/// no repository, no ambient DateTime.now().
void main() {
  // The 2 PM study block from the PRD's user stories.
  final scheduledAt = DateTime(2026, 8, 30, 14, 0);

  ReminderOccurrence occurrence({
    ReminderOccurrenceState state = ReminderOccurrenceState.upcoming,
    ReminderTaxonomy taxonomy = ReminderTaxonomy.flexible,
    int windowMinutes = 30,
    String modeRefId = 'disciplined',
    int? overdueSinceMs,
    int criticality = 1,
  }) => ReminderOccurrence(
    id: 'occ1',
    entityId: 'task1',
    entityKind: 'task',
    dateKey: ReminderOccurrence.dateKeyFor(
      scheduledAt.millisecondsSinceEpoch,
    ),
    scheduledAtMs: scheduledAt.millisecondsSinceEpoch,
    windowMinutes: windowMinutes,
    entityTitle: 'Study',
    modeRefId: modeRefId,
    state: state,
    taxonomy: taxonomy,
    criticality: criticality,
    overdueSinceMs: overdueSinceMs,
    createdAtMs: scheduledAt.millisecondsSinceEpoch,
    updatedAtMs: scheduledAt.millisecondsSinceEpoch,
  );

  group('advance — the window', () {
    test('before the scheduled time it is upcoming', () {
      final o = ReminderStateMachine.advance(
        occurrence(),
        now: scheduledAt.subtract(const Duration(hours: 1)),
      );
      expect(o.state, ReminderOccurrenceState.upcoming);
    });

    test('at the scheduled time it becomes due', () {
      final o = ReminderStateMachine.advance(occurrence(), now: scheduledAt);
      expect(o.state, ReminderOccurrenceState.due);
    });

    test('inside the window it stays due', () {
      final o = ReminderStateMachine.advance(
        occurrence(state: ReminderOccurrenceState.due),
        now: scheduledAt.add(const Duration(minutes: 29)),
      );
      expect(o.state, ReminderOccurrenceState.due);
    });

    test('an active occurrence is not knocked back to due', () {
      final o = ReminderStateMachine.advance(
        occurrence(state: ReminderOccurrenceState.active),
        now: scheduledAt.add(const Duration(minutes: 10)),
      );
      expect(o.state, ReminderOccurrenceState.active);
    });
  });

  group('advance — retroactive overdue (FR-R-12)', () {
    test(
      'a flexible occurrence noticed hours late is overdue since its '
      'windowEnd, not since the app opened',
      () {
        // Window closed at 14:30. The user opens the app at 18:00.
        final o = ReminderStateMachine.advance(
          occurrence(state: ReminderOccurrenceState.due),
          now: DateTime(2026, 8, 30, 18, 0),
        );

        expect(o.state, ReminderOccurrenceState.overdue);
        expect(
          o.overdueSinceMs,
          scheduledAt.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
        );
        // emphatically not 18:00
        expect(
          o.overdueSinceMs,
          isNot(DateTime(2026, 8, 30, 18, 0).millisecondsSinceEpoch),
        );
      },
    );

    test('the app never having been alive at windowEnd changes nothing', () {
      // Straight from upcoming — the app was closed for the whole window.
      final o = ReminderStateMachine.advance(
        occurrence(),
        now: DateTime(2026, 8, 31, 9, 0), // next morning
      );
      expect(o.state, ReminderOccurrenceState.overdue);
      expect(
        o.overdueSinceMs,
        scheduledAt.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      );
    });

    test('overdueSinceMs is stamped once and never moves', () {
      final first = ReminderStateMachine.advance(
        occurrence(state: ReminderOccurrenceState.due),
        now: DateTime(2026, 8, 30, 15, 0),
      );
      final later = ReminderStateMachine.advance(
        first,
        now: DateTime(2026, 8, 30, 23, 0),
      );
      expect(later.overdueSinceMs, first.overdueSinceMs);
      expect(identical(later, first), isTrue); // nothing to write
    });

    test('an active occurrence still goes overdue once the window closes', () {
      // Started but never finished: it needs resolution like any other miss.
      final o = ReminderStateMachine.advance(
        occurrence(state: ReminderOccurrenceState.active),
        now: scheduledAt.add(const Duration(hours: 2)),
      );
      expect(o.state, ReminderOccurrenceState.overdue);
    });

    test('the window length follows the mode (D2)', () {
      // Extreme's 60-minute window is still open where flexible's 30 is not.
      final at45 = scheduledAt.add(const Duration(minutes: 45));
      expect(
        ReminderStateMachine.advance(
          occurrence(windowMinutes: 60),
          now: at45,
        ).state,
        ReminderOccurrenceState.due,
      );
      expect(
        ReminderStateMachine.advance(
          occurrence(windowMinutes: 30),
          now: at45,
        ).state,
        ReminderOccurrenceState.overdue,
      );
    });
  });

  group('advance — taxonomy decides what a closed window means (§3.2)', () {
    test('timeSensitive expires instead of nagging', () {
      final o = ReminderStateMachine.advance(
        occurrence(
          taxonomy: ReminderTaxonomy.timeSensitive,
          state: ReminderOccurrenceState.due,
        ),
        now: DateTime(2026, 8, 30, 21, 0),
      );

      expect(o.state, ReminderOccurrenceState.resolved);
      expect(o.resolutionKind, ReminderResolutionKind.expired);
      expect(o.isOverdue, isFalse);
      // Logged as missed at the moment it stopped being useful.
      expect(
        o.resolvedAtMs,
        scheduledAt.add(const Duration(minutes: 30)).millisecondsSinceEpoch,
      );
    });

    test('routine expires silently too (it aggregates into the digest)', () {
      final o = ReminderStateMachine.advance(
        occurrence(
          taxonomy: ReminderTaxonomy.routine,
          state: ReminderOccurrenceState.due,
        ),
        now: DateTime(2026, 8, 30, 21, 0),
      );
      expect(o.state, ReminderOccurrenceState.resolved);
      expect(o.resolutionKind, ReminderResolutionKind.expired);
    });

    test('flexible is the only class that becomes overdue', () {
      final o = ReminderStateMachine.advance(
        occurrence(taxonomy: ReminderTaxonomy.flexible),
        now: DateTime(2026, 8, 30, 21, 0),
      );
      expect(o.state, ReminderOccurrenceState.overdue);
    });
  });

  group('resolution is terminal', () {
    test('a resolved occurrence is never reopened by advance', () {
      final done = ReminderStateMachine.resolve(
        occurrence(state: ReminderOccurrenceState.due),
        kind: ReminderResolutionKind.completed,
        now: scheduledAt.add(const Duration(minutes: 5)),
      );

      final later = ReminderStateMachine.advance(
        done,
        now: DateTime(2026, 9, 5, 12, 0),
      );

      expect(identical(later, done), isTrue);
      expect(later.state, ReminderOccurrenceState.resolved);
      expect(later.resolutionKind, ReminderResolutionKind.completed);
    });

    test('resolvedAtMs is the real moment, not retroactive', () {
      final at = DateTime(2026, 8, 30, 19, 30);
      final o = ReminderStateMachine.resolve(
        occurrence(state: ReminderOccurrenceState.overdue),
        kind: ReminderResolutionKind.completed,
        now: at,
      );
      expect(o.resolvedAtMs, at.millisecondsSinceEpoch);
    });

    test('a blank reason is stored as null, not as whitespace', () {
      final o = ReminderStateMachine.resolve(
        occurrence(),
        kind: ReminderResolutionKind.skipped,
        reason: '   ',
        now: scheduledAt,
      );
      expect(o.resolutionReason, isNull);
    });

    test('a real reason is trimmed and kept', () {
      final o = ReminderStateMachine.resolve(
        occurrence(),
        kind: ReminderResolutionKind.rescheduled,
        reason: '  meeting ran over  ',
        now: scheduledAt,
      );
      expect(o.resolutionReason, 'meeting ran over');
    });

    test('resolve is idempotent', () {
      final first = ReminderStateMachine.resolve(
        occurrence(),
        kind: ReminderResolutionKind.completed,
        now: scheduledAt,
      );
      final second = ReminderStateMachine.resolve(
        first,
        kind: ReminderResolutionKind.skipped,
        now: scheduledAt.add(const Duration(hours: 1)),
      );
      expect(second.resolutionKind, ReminderResolutionKind.completed);
    });
  });

  group('requiresResolutionReason — modes as contracts (FR-R-42)', () {
    test('extreme demands a reason to reschedule or skip', () {
      final o = occurrence(modeRefId: 'extreme');
      expect(
        ReminderStateMachine.requiresResolutionReason(
          o,
          ReminderResolutionKind.rescheduled,
        ),
        isTrue,
      );
      expect(
        ReminderStateMachine.requiresResolutionReason(
          o,
          ReminderResolutionKind.skipped,
        ),
        isTrue,
      );
    });

    test('extreme never demands a reason for doing it', () {
      expect(
        ReminderStateMachine.requiresResolutionReason(
          occurrence(modeRefId: 'extreme'),
          ReminderResolutionKind.completed,
        ),
        isFalse,
      );
    });

    test('flexible and disciplined never demand one', () {
      for (final mode in ['flexible', 'disciplined']) {
        expect(
          ReminderStateMachine.requiresResolutionReason(
            occurrence(modeRefId: mode),
            ReminderResolutionKind.rescheduled,
          ),
          isFalse,
          reason: mode,
        );
      }
    });
  });

  group('markActive / advanceLadder', () {
    test('markActive sets active and is idempotent', () {
      final a = ReminderStateMachine.markActive(
        occurrence(state: ReminderOccurrenceState.due),
        now: scheduledAt,
      );
      expect(a.state, ReminderOccurrenceState.active);
      expect(
        identical(ReminderStateMachine.markActive(a, now: scheduledAt), a),
        isTrue,
      );
    });

    test('markActive cannot revive a resolved occurrence', () {
      final done = ReminderStateMachine.resolve(
        occurrence(),
        kind: ReminderResolutionKind.completed,
        now: scheduledAt,
      );
      expect(
        ReminderStateMachine.markActive(done, now: scheduledAt).state,
        ReminderOccurrenceState.resolved,
      );
    });

    test('advanceLadder climbs and stops at resolution', () {
      final one = ReminderStateMachine.advanceLadder(
        occurrence(),
        now: scheduledAt,
      );
      expect(one.ladderPosition, 1);

      final done = ReminderStateMachine.resolve(
        one,
        kind: ReminderResolutionKind.completed,
        now: scheduledAt,
      );
      expect(
        ReminderStateMachine.advanceLadder(done, now: scheduledAt)
            .ladderPosition,
        1,
      );
    });
  });

  group('advanceAll returns only the write set', () {
    test('unchanged occurrences are omitted', () {
      final settled = ReminderStateMachine.resolve(
        occurrence(),
        kind: ReminderResolutionKind.completed,
        now: scheduledAt,
      );
      final moving = occurrence(state: ReminderOccurrenceState.due);

      final changed = ReminderStateMachine.advanceAll(
        [settled, moving],
        now: DateTime(2026, 8, 30, 20, 0),
      );

      expect(changed.length, 1);
      expect(changed.single.state, ReminderOccurrenceState.overdue);
    });
  });
}
