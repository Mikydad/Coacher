import '../../../core/utils/date_keys.dart';
import '../domain/models/analytics_event.dart';
import '../domain/models/behavior_feature_object.dart';

/// One completion with local schedule vs actual timestamps and the completion calendar day.
class CompletionTimingSample {
  const CompletionTimingSample({
    required this.completionDateKey,
    required this.scheduledAtLocal,
    required this.completedAtLocal,
  });

  /// Analytics event [dateKey] (`yyyy-MM-dd`) for this completion.
  final String completionDateKey;
  final DateTime scheduledAtLocal;
  final DateTime completedAtLocal;
}

class SessionEffortSample {
  const SessionEffortSample({
    required this.plannedMinutes,
    required this.actualMinutes,
    this.snoozeCount = 0,
  });

  final int plannedMinutes;
  final int actualMinutes;
  final int snoozeCount;
}

double computeCompletionRate({
  required int completedCount,
  required int opportunityCount,
}) {
  if (opportunityCount <= 0) return 0;
  final value = completedCount / opportunityCount;
  return value.clamp(0.0, 1.0);
}

/// Layer 1 time metrics: adherence vs flex vs late drift vs current overdue (see [BehaviorTimeMetrics]).
BehaviorTimeMetrics computeBehaviorTimeMetrics({
  required Set<String> keys7d,
  required Set<String> keys30d,
  required Set<String> scheduledDateKeysInFullWindow,
  required Set<String> completionDateKeys,
  required List<CompletionTimingSample> timingSamples,
  required bool hasScheduledOccurrenceToday,
  required DateTime? scheduledInstantToday,
  required bool completedToday,
  required DateTime nowLocal,
}) {
  final s7 = scheduledDateKeysInFullWindow.where(keys7d.contains).length;
  final s30 = scheduledDateKeysInFullWindow.where(keys30d.contains).length;

  final scheduledSet7 =
      scheduledDateKeysInFullWindow.where(keys7d.contains).toSet();
  final scheduledSet30 =
      scheduledDateKeysInFullWindow.where(keys30d.contains).toSet();

  var completedOnScheduled7 = 0;
  for (final d in scheduledSet7) {
    if (completionDateKeys.contains(d)) completedOnScheduled7++;
  }
  var completedOnScheduled30 = 0;
  for (final d in scheduledSet30) {
    if (completionDateKeys.contains(d)) completedOnScheduled30++;
  }

  final missed7 = (s7 - completedOnScheduled7).clamp(0, 999999);
  final missed30 = (s30 - completedOnScheduled30).clamp(0, 999999);

  final completionRate7d = s7 > 0
      ? computeCompletionRate(
          completedCount: completedOnScheduled7,
          opportunityCount: s7,
        )
      : 0.0;
  final completionRate30d = s30 > 0
      ? computeCompletionRate(
          completedCount: completedOnScheduled30,
          opportunityCount: s30,
        )
      : 0.0;

  final completionsIn7d = completionDateKeys.where(keys7d.contains).length;
  final completionsIn30d =
      completionDateKeys.where(keys30d.contains).length;
  final flex7 = completionsIn7d / 7.0;
  final flex30 = completionsIn30d / 30.0;

  final samples7 = timingSamples
      .where((s) => keys7d.contains(s.completionDateKey.trim()))
      .toList();
  final samples30 = timingSamples
      .where((s) => keys30d.contains(s.completionDateKey.trim()))
      .toList();

  final late7 = _lateCompletionRate(samples7);
  final late30 = _lateCompletionRate(samples30);
  final avgDelay = _avgLateDelayMinutes(samples7);

  var isOverdue = false;
  var minutesOverdue = 0;
  if (hasScheduledOccurrenceToday &&
      !completedToday &&
      scheduledInstantToday != null &&
      nowLocal.isAfter(scheduledInstantToday)) {
    isOverdue = true;
    minutesOverdue = nowLocal.difference(scheduledInstantToday).inMinutes;
    if (minutesOverdue < 0) minutesOverdue = 0;
    if (minutesOverdue > 999999) minutesOverdue = 999999;
  }

  return BehaviorTimeMetrics(
    scheduledOccurrences7d: s7,
    scheduledOccurrences30d: s30,
    missedScheduledCount7d: missed7,
    missedScheduledCount30d: missed30,
    completionRate7d: completionRate7d,
    completionRate30d: completionRate30d,
    flexCompletionFrequency7d: flex7.clamp(0.0, 1.0),
    flexCompletionFrequency30d: flex30.clamp(0.0, 1.0),
    lateCompletionRate7d: late7,
    lateCompletionRate30d: late30,
    avgCompletionDelayMinutes: avgDelay,
    isCurrentlyOverdue: isOverdue,
    minutesOverdue: minutesOverdue,
  );
}

/// Goals: "scheduled" = horizon-based opportunity counts in tail; completions = met check-in days.
BehaviorTimeMetrics computeGoalBehaviorTimeMetrics({
  required Set<String> keys7d,
  required Set<String> keys30d,
  required Set<String> completionDateKeys,
  required int scheduledOpportunities7d,
  required int scheduledOpportunities30d,
}) {
  final completed7 = completionDateKeys.where(keys7d.contains).length;
  final completed30 = completionDateKeys.where(keys30d.contains).length;

  final hit7 = completed7 < scheduledOpportunities7d
      ? completed7
      : scheduledOpportunities7d;
  final hit30 = completed30 < scheduledOpportunities30d
      ? completed30
      : scheduledOpportunities30d;

  final missed7 = (scheduledOpportunities7d - hit7).clamp(0, 999999);
  final missed30 = (scheduledOpportunities30d - hit30).clamp(0, 999999);

  final rate7 = scheduledOpportunities7d > 0
      ? computeCompletionRate(
          completedCount: completed7,
          opportunityCount: scheduledOpportunities7d,
        )
      : 0.0;
  final rate30 = scheduledOpportunities30d > 0
      ? computeCompletionRate(
          completedCount: completed30,
          opportunityCount: scheduledOpportunities30d,
        )
      : 0.0;

  final flex7 = completed7 / 7.0;
  final flex30 = completed30 / 30.0;

  return BehaviorTimeMetrics(
    scheduledOccurrences7d: scheduledOpportunities7d,
    scheduledOccurrences30d: scheduledOpportunities30d,
    missedScheduledCount7d: missed7,
    missedScheduledCount30d: missed30,
    completionRate7d: rate7,
    completionRate30d: rate30,
    flexCompletionFrequency7d: flex7.clamp(0.0, 1.0),
    flexCompletionFrequency30d: flex30.clamp(0.0, 1.0),
    lateCompletionRate7d: 0,
    lateCompletionRate30d: 0,
    avgCompletionDelayMinutes: 0,
    isCurrentlyOverdue: false,
    minutesOverdue: 0,
  );
}

double _lateCompletionRate(List<CompletionTimingSample> samples) {
  if (samples.isEmpty) return 0;
  var late = 0;
  for (final s in samples) {
    if (s.completedAtLocal.isAfter(s.scheduledAtLocal)) late++;
  }
  return (late / samples.length).clamp(0.0, 1.0);
}

int _avgLateDelayMinutes(List<CompletionTimingSample> samples) {
  var total = 0;
  var n = 0;
  for (final s in samples) {
    if (s.completedAtLocal.isAfter(s.scheduledAtLocal)) {
      total += s.completedAtLocal.difference(s.scheduledAtLocal).inMinutes;
      n++;
    }
  }
  if (n == 0) return 0;
  return (total / n).round();
}

BehaviorStreakMetrics computeFeatureStreakMetrics({
  required Set<String> completionDateKeys,
  required DateTime nowLocal,
}) {
  final today = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
  final ordered = completionDateKeys.toList()..sort();

  var currentStreak = 0;
  var cursor = today;
  while (completionDateKeys.contains(DateKeys.yyyymmdd(cursor))) {
    currentStreak++;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  var bestStreak = 0;
  var running = 0;
  DateTime? previousDay;
  for (final key in ordered) {
    final day = DateKeys.parseLocalDateKey(key);
    if (previousDay == null) {
      running = 1;
    } else {
      final diff = day.difference(previousDay).inDays;
      if (diff == 1) {
        running++;
      } else if (diff == 0) {
        // duplicate day key should not inflate streak
      } else {
        running = 1;
      }
    }
    if (running > bestStreak) bestStreak = running;
    previousDay = day;
  }

  final yesterday = today.subtract(const Duration(days: 1));
  final dayBeforeYesterday = today.subtract(const Duration(days: 2));
  final missedLast2Days =
      !completionDateKeys.contains(DateKeys.yyyymmdd(yesterday)) &&
      !completionDateKeys.contains(DateKeys.yyyymmdd(dayBeforeYesterday));

  var missedCount7d = 0;
  for (var i = 0; i < 7; i++) {
    final day = today.subtract(Duration(days: i));
    final key = DateKeys.yyyymmdd(day);
    if (!completionDateKeys.contains(key)) {
      missedCount7d++;
    }
  }

  return BehaviorStreakMetrics(
    currentStreak: currentStreak,
    longestStreak: bestStreak,
    missedLast2Days: missedLast2Days,
    missedCount7d: missedCount7d,
  );
}

BehaviorEffortMetrics computeFeatureEffortMetrics({
  required Iterable<SessionEffortSample> sessions,
  required int deferredEventCount,
}) {
  var totalSnooze = deferredEventCount.toDouble();
  var totalSessionMinutes = 0;
  var totalActualMinutes = 0;
  var totalPlannedMinutes = 0;
  var sessionCount = 0;
  for (final sample in sessions) {
    sessionCount++;
    totalSnooze += sample.snoozeCount.clamp(0, 9999);
    totalSessionMinutes += sample.actualMinutes.clamp(0, 999999);
    totalActualMinutes += sample.actualMinutes.clamp(0, 999999);
    totalPlannedMinutes += sample.plannedMinutes.clamp(0, 999999);
  }

  return BehaviorEffortMetrics(
    avgSnoozeCount: sessionCount == 0
        ? totalSnooze
        : totalSnooze / sessionCount,
    avgSessionDuration: sessionCount == 0
        ? 0
        : (totalSessionMinutes / sessionCount).round(),
    plannedVsActualRatio: totalPlannedMinutes == 0
        ? 0
        : totalActualMinutes / totalPlannedMinutes,
  );
}

BehaviorGoalMetrics computeFeatureGoalMetrics({
  required double progress,
  required double expectedProgress,
}) {
  final safeProgress = progress.clamp(0.0, 1.0);
  final safeExpected = expectedProgress.clamp(0.0, 1.0);
  return BehaviorGoalMetrics(
    progress: safeProgress,
    expectedProgress: safeExpected,
    gap: safeExpected - safeProgress,
  );
}

BehaviorContextFeatures computeFeatureContext({
  required Iterable<AnalyticsEvent> completionEvents,
  required bool isHabitAnchor,
  required int priority,
}) {
  final counts = <String, int>{'morning': 0, 'afternoon': 0, 'evening': 0};
  for (final event in completionEvents) {
    final parsed = DateTime.tryParse(event.timestampLocalIso);
    if (parsed == null) continue;
    final hour = parsed.toLocal().hour;
    final block = _timeBlockForHour(hour);
    counts[block] = (counts[block] ?? 0) + 1;
  }
  var bestBlock = 'morning';
  var bestCount = -1;
  counts.forEach((block, count) {
    if (count > bestCount) {
      bestCount = count;
      bestBlock = block;
    }
  });
  return BehaviorContextFeatures(
    bestTimeBlock: bestBlock,
    isHabitAnchor: isHabitAnchor,
    priority: priority.clamp(1, 5),
  );
}

String _timeBlockForHour(int hour) {
  if (hour >= 5 && hour < 11) return 'morning';
  if (hour >= 11 && hour < 17) return 'afternoon';
  if (hour >= 17 && hour < 23) return 'evening';
  return 'morning';
}
