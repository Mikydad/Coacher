import 'package:coach_for_life/features/analytics/application/daily_analytics_engine.dart';
import 'package:coach_for_life/features/analytics/application/daily_analytics_providers.dart';
import 'package:coach_for_life/features/analytics/application/discipline_score.dart';
import 'package:flutter_test/flutter_test.dart';

RollupAnalyticsSnapshot _rollup({
  required double weightedCompletionRate,
  int streak = 0,
}) {
  return RollupAnalyticsSnapshot(
    daysCount: 7,
    createdCount: 10,
    completedCount: 5,
    weightedCreated: 10,
    weightedCompleted: 5,
    completionRate: weightedCompletionRate,
    weightedCompletionRate: weightedCompletionRate,
    currentStreakDays: streak,
    bestStreakDays: 12,
  );
}

DailyAnalyticsSnapshot _day(double rate) {
  return DailyAnalyticsSnapshot(
    dateKey: '20260523',
    createdCount: 4,
    completedCount: 2,
    weightedCreated: 4,
    weightedCompleted: 2,
    completionRate: rate,
    weightedCompletionRate: rate,
    schemaVersion: 2,
  );
}

AnalyticsPeriodBundle _bundle({
  double goalWeek = 0.6,
  double taskWeek = 0.4,
  double goalDay = 0.2,
  double taskDay = 0.8,
}) {
  return AnalyticsPeriodBundle(
    goalHabitDay: _day(goalDay),
    taskDay: _day(taskDay),
    goalHabitWeek: _rollup(weightedCompletionRate: goalWeek, streak: 4),
    taskWeek: _rollup(weightedCompletionRate: taskWeek, streak: 5),
    goalHabitMonth: _rollup(weightedCompletionRate: 0.22),
    taskMonth: _rollup(weightedCompletionRate: 0.67),
  );
}

void main() {
  group('disciplineScore', () {
    test('disciplinePercentWeek averages goal and task week rates', () {
      final bundle = _bundle(goalWeek: 0.6, taskWeek: 0.4);
      expect(disciplinePercentWeek(bundle), 50);
    });

    test('disciplineStreakSummary exposes habit and task separately', () {
      final bundle = _bundle(goalWeek: 0.6, taskWeek: 0.4);
      final s = disciplineStreakSummary(bundle);
      expect(s.goalHabitCurrentDays, 4);
      expect(s.taskCurrentDays, 5);
    });

    test('disciplineTopCategoryLabel picks leading scope', () {
      expect(
        disciplineTopCategoryLabel(_bundle(goalWeek: 0.8, taskWeek: 0.3)),
        'Goals & Habits',
      );
      expect(
        disciplineTopCategoryLabel(_bundle(goalWeek: 0.2, taskWeek: 0.9)),
        'Task Integrity',
      );
    });
  });
}
