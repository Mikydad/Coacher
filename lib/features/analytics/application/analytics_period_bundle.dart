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
  });

  final DailyAnalyticsSnapshot goalHabitDay;
  final DailyAnalyticsSnapshot taskDay;
  final RollupAnalyticsSnapshot goalHabitWeek;
  final RollupAnalyticsSnapshot taskWeek;
  final RollupAnalyticsSnapshot goalHabitMonth;
  final RollupAnalyticsSnapshot taskMonth;
  final List<double> goalHabitWeekSeries;
  final List<double> taskWeekSeries;
}
