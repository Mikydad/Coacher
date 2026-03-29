import 'package:coach_for_life/core/utils/date_keys.dart';
import 'package:coach_for_life/features/goals/application/goal_period_helpers.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_enums.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_categories.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:flutter_test/flutter_test.dart';

UserGoal _goalForMarch2025() {
  final b = GoalPeriodHelpers.localCalendarMonthBounds(2025, 3);
  return UserGoal(
    id: 'g1',
    title: 'Test',
    categoryId: GoalCategories.study,
    horizon: GoalHorizon.monthly,
    status: GoalStatus.active,
    measurementKind: MeasurementKind.minutes,
    targetValue: 30,
    intensity: 3,
    periodStartMs: b.startMs,
    periodEndMs: b.endMs,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

void main() {
  test('March 2025 has 31 calendar days', () {
    final g = _goalForMarch2025();
    expect(GoalPeriodHelpers.totalCalendarDaysInPeriod(g), 31);
  });

  test('isDateKeyInPeriod for March boundaries', () {
    final g = _goalForMarch2025();
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-03-01'), true);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-03-31'), true);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-02-28'), false);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-04-01'), false);
  });

  test('daysElapsedInPeriodThrough caps at period end', () {
    final g = _goalForMarch2025();
    final april = DateTime(2025, 4, 10);
    expect(GoalPeriodHelpers.daysElapsedInPeriodThrough(g, april), 31);
  });

  test('DateKeys.parseLocalDateKey round-trip', () {
    final d = DateTime(2025, 1, 5);
    final k = DateKeys.yyyymmdd(d);
    expect(DateKeys.parseLocalDateKey(k), DateTime(2025, 1, 5));
  });

  test('localDurationDayCount: 30 days from Mar 1 ends Mar 30 inclusive', () {
    final b = GoalPeriodHelpers.localDurationDayCount(DateTime(2025, 3, 1), 30);
    final g = UserGoal(
      id: 'g2',
      title: 'Test',
      categoryId: GoalCategories.study,
      horizon: GoalHorizon.monthly,
      status: GoalStatus.active,
      measurementKind: MeasurementKind.minutes,
      targetValue: 30,
      intensity: 3,
      periodStartMs: b.startMs,
      periodEndMs: b.endMs,
      periodMode: GoalPeriodMode.durationDays,
      durationDays: 30,
      createdAtMs: 0,
      updatedAtMs: 0,
    );
    expect(GoalPeriodHelpers.totalCalendarDaysInPeriod(g), 30);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-03-30'), true);
    expect(GoalPeriodHelpers.isDateKeyInPeriod(g, '2025-03-31'), false);
  });
}
