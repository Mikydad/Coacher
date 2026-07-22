import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/accountability/domain/models/stake_challenge.dart';

StakeChallenge _challenge({
  required StakeFrozenGoal goal,
  int? createdAtMs,
}) {
  return StakeChallenge(
    id: 'c',
    type: StakeChallengeType.practice,
    status: StakeChallengeStatus.active,
    creatorUid: 'u',
    circleId: '',
    participants: const [],
    frozenGoal: goal,
    deadlineMs: 0,
    createdAtMs: createdAtMs ?? DateTime(2026, 7, 20, 14).millisecondsSinceEpoch,
    updatedAtMs: 0,
  );
}

void main() {
  group('unitIndexAt (schedule-aware, 2026-07-22)', () {
    test('legacy daily doc (no schedule fields) matches days-since-creation',
        () {
      final c = _challenge(
        goal: const StakeFrozenGoal(
          title: 't', unitKind: 'minutes', unitTarget: 60, totalUnits: 7),
        createdAtMs: DateTime(2026, 7, 20, 23, 50).millisecondsSinceEpoch,
      );
      expect(c.unitIndexAt(DateTime(2026, 7, 20, 23, 59)), 0);
      expect(c.unitIndexAt(DateTime(2026, 7, 21, 0, 1)), 1);
      expect(c.unitIndexAt(DateTime(2026, 7, 26)), 6);
    });

    test('future start: -1 before day 0, index 0 on the start date', () {
      final c = _challenge(
        goal: StakeFrozenGoal(
          title: 't',
          unitKind: 'count',
          unitTarget: 3,
          totalUnits: 5,
          startDateMs: DateTime(2026, 7, 25).millisecondsSinceEpoch,
        ),
      );
      expect(c.unitIndexAt(DateTime(2026, 7, 24)), -1);
      expect(c.unitIndexAt(DateTime(2026, 7, 25)), 0);
      expect(c.unitIndexAt(DateTime(2026, 7, 26)), 1);
    });

    test('weekly Mon/Wed/Fri: non-action days are -1, indices skip them', () {
      // 2026-07-20 is a Monday.
      final c = _challenge(
        goal: StakeFrozenGoal(
          title: 't',
          unitKind: 'count',
          unitTarget: 3,
          totalUnits: 6,
          cadence: 'weekly',
          scheduledWeekdays: const [
            DateTime.monday, DateTime.wednesday, DateTime.friday],
          startDateMs: DateTime(2026, 7, 20).millisecondsSinceEpoch,
        ),
      );
      expect(c.unitIndexAt(DateTime(2026, 7, 20)), 0); // Mon
      expect(c.unitIndexAt(DateTime(2026, 7, 21)), -1); // Tue — off day
      expect(c.unitIndexAt(DateTime(2026, 7, 22)), 1); // Wed
      expect(c.unitIndexAt(DateTime(2026, 7, 24)), 2); // Fri
      expect(c.unitIndexAt(DateTime(2026, 7, 27)), 3); // next Mon
    });

    test('every-2-days: alternating action days', () {
      final c = _challenge(
        goal: StakeFrozenGoal(
          title: 't',
          unitKind: 'minutes',
          unitTarget: 30,
          totalUnits: 4,
          interval: 2,
          startDateMs: DateTime(2026, 7, 20).millisecondsSinceEpoch,
        ),
      );
      expect(c.unitIndexAt(DateTime(2026, 7, 20)), 0);
      expect(c.unitIndexAt(DateTime(2026, 7, 21)), -1);
      expect(c.unitIndexAt(DateTime(2026, 7, 22)), 1);
      expect(c.unitIndexAt(DateTime(2026, 7, 26)), 3);
    });

    test('monthly picked days', () {
      final c = _challenge(
        goal: StakeFrozenGoal(
          title: 't',
          unitKind: 'count',
          unitTarget: 1,
          totalUnits: 2,
          cadence: 'monthly',
          repeatDaysOfMonth: const [1, 15],
          startDateMs: DateTime(2026, 7, 10).millisecondsSinceEpoch,
        ),
      );
      expect(c.unitIndexAt(DateTime(2026, 7, 14)), -1);
      expect(c.unitIndexAt(DateTime(2026, 7, 15)), 0);
      expect(c.unitIndexAt(DateTime(2026, 8, 1)), 1);
    });
  });

  group('countChallengeActionDays', () {
    test('daily interval 1 = calendar span', () {
      expect(
        countChallengeActionDays(
          start: DateTime(2026, 7, 22),
          end: DateTime(2026, 7, 28),
          cadence: 'daily',
        ),
        7,
      );
    });

    test('every-2-days over 7 calendar days = 4', () {
      expect(
        countChallengeActionDays(
          start: DateTime(2026, 7, 22),
          end: DateTime(2026, 7, 28),
          cadence: 'daily',
          interval: 2,
        ),
        4,
      );
    });

    test('weekly Mon/Wed/Fri across two weeks', () {
      expect(
        countChallengeActionDays(
          start: DateTime(2026, 7, 20), // Monday
          end: DateTime(2026, 7, 31), // Friday next week
          cadence: 'weekly',
          scheduledWeekdays: const {
            DateTime.monday, DateTime.wednesday, DateTime.friday},
        ),
        6,
      );
    });

    test('agrees with unitIndexAt: last action day index == count - 1', () {
      final start = DateTime(2026, 7, 20);
      final end = DateTime(2026, 7, 31);
      const weekdays = [DateTime.monday, DateTime.wednesday, DateTime.friday];
      final count = countChallengeActionDays(
        start: start,
        end: end,
        cadence: 'weekly',
        scheduledWeekdays: weekdays.toSet(),
      );
      final c = _challenge(
        goal: StakeFrozenGoal(
          title: 't',
          unitKind: 'count',
          unitTarget: 1,
          totalUnits: count,
          cadence: 'weekly',
          scheduledWeekdays: weekdays,
          startDateMs: start.millisecondsSinceEpoch,
        ),
      );
      expect(c.unitIndexAt(end), count - 1);
    });

    test('empty weekly selection yields zero action days', () {
      expect(
        countChallengeActionDays(
          start: DateTime(2026, 7, 22),
          end: DateTime(2026, 7, 28),
          cadence: 'weekly',
        ),
        0,
      );
    });
  });
}
