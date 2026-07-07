import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics_period_bundle.dart';
import 'analytics_period_bundle_notifier.dart';
import '../../../core/presentation/async_value_ui.dart';

/// Combined discipline rate for the weekly hero (0.0–1.0).
///
/// Average of goals/habits and tasks **week** weighted completion rates.
double disciplineRateWeek(AnalyticsPeriodBundle bundle) {
  return (bundle.goalHabitWeek.weightedCompletionRate +
          bundle.taskWeek.weightedCompletionRate) /
      2.0;
}

/// Display percent for the hero ring (0–100).
int disciplinePercentWeek(AnalyticsPeriodBundle bundle) {
  return (disciplineRateWeek(bundle) * 100).round().clamp(0, 100);
}

/// Leading scope label for the hero side card (whichever week rate is higher).
String disciplineTopCategoryLabel(AnalyticsPeriodBundle bundle) {
  final goal = bundle.goalHabitWeek.weightedCompletionRate;
  final task = bundle.taskWeek.weightedCompletionRate;
  if (task > goal + 0.05) return 'Task Integrity';
  if (goal > task + 0.05) return 'Goals & Habits';
  return 'Balanced Mix';
}

/// Week vs today combined delta for the hero side card (percentage points).
int disciplineWeekVsTodayDelta(AnalyticsPeriodBundle bundle) {
  final todayAvg =
      (bundle.goalHabitDay.weightedCompletionRate +
          bundle.taskDay.weightedCompletionRate) /
      2.0;
  final week = disciplineRateWeek(bundle);
  return ((week - todayAvg) * 100).round();
}

/// Habit + goal streak vs task streak (shown separately on Progress).
class DisciplineStreakSummary {
  const DisciplineStreakSummary({
    required this.goalHabitCurrentDays,
    required this.goalHabitBestDays,
    required this.taskCurrentDays,
    required this.taskBestDays,
  });

  final int goalHabitCurrentDays;
  final int goalHabitBestDays;
  final int taskCurrentDays;
  final int taskBestDays;
}

DisciplineStreakSummary disciplineStreakSummary(AnalyticsPeriodBundle bundle) {
  return DisciplineStreakSummary(
    goalHabitCurrentDays: bundle.goalHabitWeek.currentStreakDays,
    goalHabitBestDays: bundle.goalHabitWeek.bestStreakDays,
    taskCurrentDays: bundle.taskWeek.currentStreakDays,
    taskBestDays: bundle.taskWeek.bestStreakDays,
  );
}

/// Goals/habits current streak days — same metric as the Home hero card.
int homeDisplayStreakDays(AnalyticsPeriodBundle bundle) =>
    bundle.goalHabitWeek.currentStreakDays;

/// Shared streak count for Home and Profile heroes.
final homeDisplayStreakDaysProvider = Provider<int>((ref) {
  return ref
      .watch(analyticsPeriodBundleProvider)
      .when(
        data: homeDisplayStreakDays,
        loading: () => 0,
        error: (e, _) => swallowedAsyncError('discipline_score', e, 0),
      );
});

/// Weighted blend for internal scoring only (not shown as a single streak).
double disciplineBlendedStreakScore(AnalyticsPeriodBundle bundle) {
  final g = bundle.goalHabitWeek.currentStreakDays.toDouble();
  final t = bundle.taskWeek.currentStreakDays.toDouble();
  return g * 0.6 + t * 0.4;
}

@Deprecated('Use disciplineStreakSummary and show habit vs task separately')
int disciplineActiveStreakDays(AnalyticsPeriodBundle bundle) {
  return bundle.goalHabitWeek.currentStreakDays >
          bundle.taskWeek.currentStreakDays
      ? bundle.goalHabitWeek.currentStreakDays
      : bundle.taskWeek.currentStreakDays;
}
