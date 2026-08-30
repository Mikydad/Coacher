import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/reminders/application/recovery_view.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// FR-R-50 (ordering, one row per open item), FR-R-40..42 (per-mode
/// affordances) and FR-R-52 (routine misses are a digest line, not rows).
void main() {
  final now = DateTime(2026, 8, 30, 18, 0);
  final todayKey = DateKeys.todayKey(now);

  ReminderOccurrence occ({
    required String id,
    String? title,
    ReminderOccurrenceState state = ReminderOccurrenceState.overdue,
    ReminderTaxonomy taxonomy = ReminderTaxonomy.flexible,
    int criticality = 1,
    String modeRefId = 'flexible',
    DateTime? overdueSince,
    DateTime? scheduledAt,
    ReminderResolutionKind? resolutionKind,
    String? dismissedForDayKey,
  }) {
    final at = scheduledAt ?? DateTime(2026, 8, 30, 14, 0);
    return ReminderOccurrence(
      id: id,
      entityId: id,
      entityKind: 'task',
      dateKey: DateKeys.yyyymmdd(at),
      scheduledAtMs: at.millisecondsSinceEpoch,
      windowMinutes: 30,
      entityTitle: title ?? id,
      modeRefId: modeRefId,
      state: state,
      taxonomy: taxonomy,
      criticality: criticality,
      overdueSinceMs: (overdueSince ?? at.add(const Duration(minutes: 30)))
          .millisecondsSinceEpoch,
      resolutionKind: resolutionKind,
      dismissedForDayKey: dismissedForDayKey,
      createdAtMs: 1,
      updatedAtMs: 1,
    );
  }

  group('ordering (FR-R-50)', () {
    test('criticality descending beats how long it has waited', () {
      final view = RecoveryViewBuilder.build([
        occ(
          id: 'old-but-minor',
          criticality: 0,
          overdueSince: DateTime(2026, 8, 30, 9, 0),
        ),
        occ(
          id: 'recent-but-critical',
          criticality: 3,
          overdueSince: DateTime(2026, 8, 30, 17, 0),
        ),
      ], now: now);

      expect(
        view.rows.map((r) => r.occurrence.entityId),
        ['recent-but-critical', 'old-but-minor'],
      );
    });

    test('within a criticality, the longest-waiting comes first', () {
      final view = RecoveryViewBuilder.build([
        occ(id: 'newer', overdueSince: DateTime(2026, 8, 30, 16, 0)),
        occ(id: 'older', overdueSince: DateTime(2026, 8, 30, 10, 0)),
      ], now: now);

      expect(view.rows.map((r) => r.occurrence.entityId), ['older', 'newer']);
    });

    test('exact ties fall back to the title so the order never jitters', () {
      final same = DateTime(2026, 8, 30, 10, 0);
      final view = RecoveryViewBuilder.build([
        occ(id: 'b', title: 'Banana', overdueSince: same),
        occ(id: 'a', title: 'Apple', overdueSince: same),
      ], now: now);

      expect(view.rows.map((r) => r.title), ['Apple', 'Banana']);
    });
  });

  group('what belongs on the card', () {
    test('only overdue items become rows', () {
      final view = RecoveryViewBuilder.build([
        occ(id: 'due', state: ReminderOccurrenceState.due),
        occ(id: 'upcoming', state: ReminderOccurrenceState.upcoming),
        occ(id: 'active', state: ReminderOccurrenceState.active),
        occ(id: 'overdue'),
      ], now: now);

      expect(view.rows.map((r) => r.occurrence.entityId), ['overdue']);
    });

    test('a resolved item never appears', () {
      final view = RecoveryViewBuilder.build([
        occ(
          id: 'done',
          state: ReminderOccurrenceState.resolved,
          resolutionKind: ReminderResolutionKind.completed,
        ),
      ], now: now);

      expect(view.isEmpty, isTrue);
    });
  });

  group('per-mode affordances (FR-R-40..42)', () {
    test('mode decides insistence', () {
      final view = RecoveryViewBuilder.build([
        occ(id: 'f', modeRefId: 'flexible'),
        occ(id: 'd', modeRefId: 'disciplined'),
        occ(id: 'e', modeRefId: 'extreme'),
      ], now: now);

      final byId = {
        for (final r in view.rows) r.occurrence.entityId: r.insistence,
      };
      expect(byId['f'], RecoveryInsistence.dismissible);
      expect(byId['d'], RecoveryInsistence.persistent);
      expect(byId['e'], RecoveryInsistence.demanding);
    });

    test('an unknown mode degrades to the gentlest', () {
      final view = RecoveryViewBuilder.build([
        occ(id: 'x', modeRefId: 'strict-ish-typo'),
      ], now: now);
      expect(view.rows.single.insistence, RecoveryInsistence.dismissible);
    });

    test('only Flexible can be dismissed', () {
      expect(RecoveryInsistence.dismissible.canDismiss, isTrue);
      expect(RecoveryInsistence.persistent.canDismiss, isFalse);
      expect(RecoveryInsistence.demanding.canDismiss, isFalse);
    });
  });

  group('dismissal (FR-R-40)', () {
    test('a Flexible row dismissed today is hidden today', () {
      final view = RecoveryViewBuilder.build([
        occ(id: 'waved', dismissedForDayKey: todayKey),
      ], now: now);
      expect(view.rows, isEmpty);
    });

    test('yesterday\'s dismissal does not carry over', () {
      final view = RecoveryViewBuilder.build([
        occ(id: 'waved', dismissedForDayKey: '2026-08-29'),
      ], now: now);
      expect(view.rows, hasLength(1));
    });

    test(
      'a Disciplined or Extreme row ignores a dismissal outright — the '
      'contract is the mode\'s, not the row\'s history',
      () {
        final view = RecoveryViewBuilder.build([
          occ(
            id: 'd',
            modeRefId: 'disciplined',
            dismissedForDayKey: todayKey,
          ),
          occ(id: 'e', modeRefId: 'extreme', dismissedForDayKey: todayKey),
        ], now: now);

        expect(view.rows, hasLength(2));
      },
    );
  });

  group('routine misses are a digest, not rows (FR-R-52)', () {
    ReminderOccurrence routineMiss(String title, {DateTime? at}) => occ(
      id: title,
      title: title,
      taxonomy: ReminderTaxonomy.routine,
      state: ReminderOccurrenceState.resolved,
      resolutionKind: ReminderResolutionKind.expired,
      scheduledAt: at,
    );

    test('today\'s routine misses collapse into one line', () {
      final view = RecoveryViewBuilder.build([
        routineMiss('Water'),
        routineMiss('Stretch'),
      ], now: now);

      expect(view.rows, isEmpty);
      expect(view.routineDigestLine, 'Missed today: Stretch, Water');
      expect(view.isNotEmpty, isTrue);
    });

    test('more than two are counted, not listed', () {
      final view = RecoveryViewBuilder.build([
        routineMiss('Water'),
        routineMiss('Stretch'),
        routineMiss('Vitamins'),
        routineMiss('Walk'),
      ], now: now);

      expect(view.routineDigestLine, 'Missed today: Stretch, Vitamins and 2 more');
    });

    test('an older routine miss is not dredged up', () {
      final view = RecoveryViewBuilder.build([
        routineMiss('Water', at: DateTime(2026, 8, 28, 9, 0)),
      ], now: now);

      expect(view.isEmpty, isTrue);
    });

    test('a routine item never becomes a row even if left overdue', () {
      final view = RecoveryViewBuilder.build([
        occ(id: 'water', taxonomy: ReminderTaxonomy.routine),
      ], now: now);

      expect(view.rows, isEmpty);
      expect(view.routineDigestLine, isNull);
    });

    test('rows and the digest coexist', () {
      final view = RecoveryViewBuilder.build([
        occ(id: 'study', title: 'Study'),
        routineMiss('Water'),
      ], now: now);

      expect(view.rows, hasLength(1));
      expect(view.routineDigestLine, 'Missed today: Water');
    });
  });

  test('an empty pool renders nothing', () {
    expect(RecoveryViewBuilder.build(const [], now: now).isEmpty, isTrue);
  });
}
