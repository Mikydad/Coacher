import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../context_override/application/context_override_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../data/analytics_repository.dart';
import 'daily_analytics_engine.dart';
import 'analytics_period_bundle.dart';
import 'daily_analytics_providers.dart'
    show
        readCachedDailySnapshot,
        readCachedSnapshotMap,
        computeBlendedCurrentStreakDays,
        blendedWeekSeriesOf,
        isoWeekStartOf;
import 'streak_protection.dart';

DailyAnalyticsSnapshot emptyDailySnapshot(String dateKey) {
  return DailyAnalyticsSnapshot(
    dateKey: dateKey,
    createdCount: 0,
    completedCount: 0,
    weightedCreated: 0,
    weightedCompleted: 0,
    completionRate: 0,
    weightedCompletionRate: 0,
    schemaVersion: 3,
  );
}

/// One snapshot per calendar day of the range, cache only (one range
/// query); days without a cache row are empty.
Future<List<DailyAnalyticsSnapshot>> _readCachedDailyRange(
  AnalyticsRepository repo, {
  required String scopeType,
  required DateTime startInclusive,
  required DateTime endInclusive,
}) async {
  final cached = await readCachedSnapshotMap(
    repo,
    scopeType: scopeType,
    fromDateKey: DateKeys.yyyymmdd(startInclusive),
    toDateKey: DateKeys.yyyymmdd(endInclusive),
  );
  final results = <DailyAnalyticsSnapshot>[];
  for (
    var day = DateTime(
      startInclusive.year,
      startInclusive.month,
      startInclusive.day,
    );
    !day.isAfter(endInclusive);
    day = DateTime(day.year, day.month, day.day + 1)
  ) {
    final dateKey = DateKeys.yyyymmdd(day);
    results.add(cached[dateKey] ?? emptyDailySnapshot(dateKey));
  }
  return results;
}

/// Builds a bundle from persisted daily snapshots only (no live recompute).
///
/// Returns `null` when today's goal/habit or task daily cache is missing
/// (true first visit — caller should compute fresh and show a skeleton).
Future<AnalyticsPeriodBundle?> loadCachedAnalyticsPeriodBundle(Ref ref) async {
  final now = DateTime.now();
  final todayKey = DateKeys.todayKey(now);
  final repo = ref.read(analyticsRepositoryProvider);

  final todayGoalHabit = await readCachedDailySnapshot(
    repo,
    scopeType: goalHabitDailyScope,
    dateKey: todayKey,
  );
  final todayTask = await readCachedDailySnapshot(
    repo,
    scopeType: taskDailyScope,
    dateKey: todayKey,
  );
  if (todayGoalHabit == null || todayTask == null) return null;

  // Monday of the current ISO week → today (decision 2026-09-12).
  final weekStart = isoWeekStartOf(now);
  final endDay = DateTime(now.year, now.month, now.day);

  final weekGoalHabitRange = await _readCachedDailyRange(
    repo,
    scopeType: goalHabitDailyScope,
    startInclusive: weekStart,
    endInclusive: endDay,
  );
  final weekTaskRange = await _readCachedDailyRange(
    repo,
    scopeType: taskDailyScope,
    startInclusive: weekStart,
    endInclusive: endDay,
  );

  final monthStart = DateTime(now.year, now.month, 1);
  final monthGoalHabitRange = await _readCachedDailyRange(
    repo,
    scopeType: goalHabitDailyScope,
    startInclusive: monthStart,
    endInclusive: endDay,
  );
  final monthTaskRange = await _readCachedDailyRange(
    repo,
    scopeType: taskDailyScope,
    startInclusive: monthStart,
    endInclusive: endDay,
  );

  final blendedStreak = await computeBlendedCurrentStreakDays(
    ref,
    now: now,
    todayGoalHabit: todayGoalHabit,
    todayTask: todayTask,
  );

  return _assembleBundle(
    ref: ref,
    now: now,
    weekStart: weekStart,
    monthStart: monthStart,
    endDay: endDay,
    todayGoalHabit: todayGoalHabit,
    todayTask: todayTask,
    weekGoalHabitRange: weekGoalHabitRange,
    weekTaskRange: weekTaskRange,
    monthGoalHabitRange: monthGoalHabitRange,
    monthTaskRange: monthTaskRange,
    blendedCurrentStreakDays: blendedStreak,
  );
}

AnalyticsPeriodBundle _assembleBundle({
  required Ref ref,
  required DateTime now,
  required DateTime weekStart,
  required DateTime monthStart,
  required DateTime endDay,
  required DailyAnalyticsSnapshot todayGoalHabit,
  required DailyAnalyticsSnapshot todayTask,
  required List<DailyAnalyticsSnapshot> weekGoalHabitRange,
  required List<DailyAnalyticsSnapshot> weekTaskRange,
  required List<DailyAnalyticsSnapshot> monthGoalHabitRange,
  required List<DailyAnalyticsSnapshot> monthTaskRange,
  required int blendedCurrentStreakDays,
}) {
  final enforcementMode = ref.read(defaultEnforcementModeProvider);
  final attention = ref.read(attentionStateProvider).valueOrNull;
  final protectedWeek = buildStreakProtectedDateKeys(
    attention: attention,
    rangeStartInclusive: weekStart,
    rangeEndInclusive: endDay,
  );
  final protectedMonth = buildStreakProtectedDateKeys(
    attention: attention,
    rangeStartInclusive: monthStart,
    rangeEndInclusive: endDay,
  );

  return AnalyticsPeriodBundle(
    goalHabitDay: todayGoalHabit,
    taskDay: todayTask,
    goalHabitWeek: rollupDailyAnalytics(
      snapshots: weekGoalHabitRange,
      now: now,
      enforcementMode: enforcementMode,
      protectedDateKeys: protectedWeek,
    ),
    taskWeek: rollupDailyAnalytics(
      snapshots: weekTaskRange,
      now: now,
      enforcementMode: enforcementMode,
      protectedDateKeys: protectedWeek,
    ),
    goalHabitMonth: rollupDailyAnalytics(
      snapshots: monthGoalHabitRange,
      now: now,
      enforcementMode: enforcementMode,
      protectedDateKeys: protectedMonth,
    ),
    taskMonth: rollupDailyAnalytics(
      snapshots: monthTaskRange,
      now: now,
      enforcementMode: enforcementMode,
      protectedDateKeys: protectedMonth,
    ),
    goalHabitWeekSeries: weekGoalHabitRange
        .map((d) => d.weightedCompletionRate.clamp(0.0, 1.0))
        .toList(),
    taskWeekSeries: weekTaskRange
        .map((d) => d.weightedCompletionRate.clamp(0.0, 1.0))
        .toList(),
    blendedWeekSeries: blendedWeekSeriesOf(weekGoalHabitRange, weekTaskRange),
    blendedCurrentStreakDays: blendedCurrentStreakDays,
  );
}
