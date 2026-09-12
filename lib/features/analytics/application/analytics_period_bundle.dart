import 'blended_discipline.dart';
import 'daily_analytics_engine.dart';

class AnalyticsPeriodBundle {
  const AnalyticsPeriodBundle({
    required this.goalHabitDay,
    required this.taskDay,
    required this.goalHabitWeek,
    required this.taskWeek,
    required this.goalHabitMonth,
    required this.taskMonth,
    this.goalHabitWeekSeries = const [],
    this.taskWeekSeries = const [],
    this.blendedWeekSeries = const [],
    this.blendedCurrentStreakDays = 0,
  });

  final DailyAnalyticsSnapshot goalHabitDay;
  final DailyAnalyticsSnapshot taskDay;

  /// Monday of the current ISO week → today (decision 2026-09-12; was a
  /// trailing 7-day window).
  final RollupAnalyticsSnapshot goalHabitWeek;
  final RollupAnalyticsSnapshot taskWeek;

  /// First of the calendar month → today.
  final RollupAnalyticsSnapshot goalHabitMonth;
  final RollupAnalyticsSnapshot taskMonth;

  /// One value per day, Monday → today (1–7 entries).
  final List<double> goalHabitWeekSeries;
  final List<double> taskWeekSeries;

  /// Blended value per day, Monday → today; quiet days are 0 so the Home
  /// sparkline (plain doubles) can draw them.
  final List<double> blendedWeekSeries;

  /// The app's single day streak: consecutive days ending today whose
  /// blended rate cleared the enforcement threshold (or were protected),
  /// walked back through the whole cache — not capped by the week window.
  final int blendedCurrentStreakDays;

  /// Today's blended rate; null when nothing was planned today.
  double? get blendedTodayRate => blendedDayRate(goalHabitDay, taskDay);
  double? get blendedWeekRate => blendedPeriodRate(goalHabitWeek, taskWeek);
  double? get blendedMonthRate => blendedPeriodRate(goalHabitMonth, taskMonth);
}
