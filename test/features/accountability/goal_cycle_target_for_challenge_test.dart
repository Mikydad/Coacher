import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/accountability/domain/models/stake_challenge.dart';

/// A challenge's target is per ACTION DAY; the goal it mints carries a
/// per-CYCLE target (2026-09-22): "60 min a day × Mon/Wed/Fri/Sat/Sun"
/// must read "300 minutes (per week)" on the goal page, not 60.
void main() {
  test('weekly: per-day target × scheduled weekdays', () {
    expect(
      goalCycleTargetForChallenge(
        unitTarget: 60,
        cadence: 'weekly',
        scheduledWeekdays: const {1, 3, 5, 6, 7},
      ),
      300,
    );
  });

  test('monthly: per-day target × month days', () {
    expect(
      goalCycleTargetForChallenge(
        unitTarget: 10,
        cadence: 'monthly',
        repeatDaysOfMonth: const {1, 15},
      ),
      20,
    );
  });

  test('daily and every-N-days: unchanged (one action day per cycle)', () {
    expect(goalCycleTargetForChallenge(unitTarget: 60, cadence: 'daily'), 60);
    expect(
      goalCycleTargetForChallenge(unitTarget: 60, cadence: 'daily', interval: 3),
      60,
    );
  });

  test('an empty schedule never zeroes the target', () {
    expect(goalCycleTargetForChallenge(unitTarget: 60, cadence: 'weekly'), 60);
  });
}
