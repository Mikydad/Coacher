import '../../../core/utils/date_keys.dart';
import '../domain/models/analytics_event.dart';

enum HabitRiskLevel { low, medium, high }

class HabitKpiSnapshot {
  const HabitKpiSnapshot({
    required this.todayCompletionRate,
    required this.weeklyCompletionRate,
    required this.riskLevel,
    required this.completedDaysInWindow,
    required this.weeklySeries,
  });

  final double todayCompletionRate;
  final double weeklyCompletionRate;
  final HabitRiskLevel riskLevel;
  final int completedDaysInWindow;

  /// Ordered oldest -> newest (last 7 days), values are 0.0 or 1.0 in V1.
  final List<double> weeklySeries;
}

HabitKpiSnapshot computeHabitKpisFromEvents(
  Iterable<AnalyticsEvent> events, {
  DateTime? now,
}) {
  final base = now ?? DateTime.now();
  final today = DateTime(base.year, base.month, base.day);
  final outcomeByDate = <String, bool>{};
  for (final e in events) {
    if (e.entityKind != 'habit') continue;
    if (!_isValidDateKey(e.dateKey)) continue;
    switch (e.type) {
      case AnalyticsEventType.habitCompleted:
        outcomeByDate[e.dateKey] = true;
        break;
      case AnalyticsEventType.habitSkipped:
      case AnalyticsEventType.habitMissedWindow:
        outcomeByDate[e.dateKey] = outcomeByDate[e.dateKey] ?? false;
        break;
      case AnalyticsEventType.habitSnoozed:
      case AnalyticsEventType.taskStarted:
      case AnalyticsEventType.taskCompleted:
      case AnalyticsEventType.taskDeferred:
      case AnalyticsEventType.overlapOverride:
      case AnalyticsEventType.autoNextStarted:
        break;
    }
  }

  final todayKey = DateKeys.yyyymmdd(today);
  final completedToday = outcomeByDate[todayKey] == true;
  var completedInWindow = 0;
  final series = <double>[];
  for (var i = 0; i < 7; i++) {
    final key = DateKeys.yyyymmdd(today.subtract(Duration(days: 6 - i)));
    final done = outcomeByDate[key] == true;
    if (done) completedInWindow++;
    series.add(done ? 1.0 : 0.0);
  }

  final yesterdayKey = DateKeys.yyyymmdd(
    today.subtract(const Duration(days: 1)),
  );
  final twoDaysAgoKey = DateKeys.yyyymmdd(
    today.subtract(const Duration(days: 2)),
  );
  final missedYesterday = outcomeByDate[yesterdayKey] != true;
  final missedTwoDays =
      missedYesterday && (outcomeByDate[twoDaysAgoKey] != true);
  final risk = missedTwoDays
      ? HabitRiskLevel.high
      : missedYesterday
      ? HabitRiskLevel.medium
      : HabitRiskLevel.low;

  return HabitKpiSnapshot(
    todayCompletionRate: completedToday ? 1.0 : 0.0,
    weeklyCompletionRate: completedInWindow / 7.0,
    riskLevel: risk,
    completedDaysInWindow: completedInWindow,
    weeklySeries: series,
  );
}

bool _isValidDateKey(String key) {
  try {
    DateKeys.parseLocalDateKey(key);
    return true;
  } catch (_) {
    return false;
  }
}
