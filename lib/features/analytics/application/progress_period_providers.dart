import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/tier/tier_providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../context_override/application/context_override_providers.dart';
import '../../goals/application/goals_providers.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../profile/application/profile_providers.dart';
import '../data/analytics_range_reads.dart';
import '../domain/progress_period.dart';
import 'daily_analytics_engine.dart';
import 'daily_analytics_providers.dart';
import 'progress_period_series.dart';
import 'streak_protection.dart';

/// Local-first series for one [ProgressPeriod]: cached snapshots publish
/// immediately (two range reads); today is recomputed live; uncached past
/// days are backfilled in the background and persisted, then the series is
/// republished. Same shape as `AnalyticsPeriodBundleNotifier`.
class ProgressPeriodSeriesNotifier
    extends FamilyAsyncNotifier<ProgressPeriodSeries, ProgressPeriod> {
  int _generation = 0;

  @override
  Future<ProgressPeriodSeries> build(ProgressPeriod arg) async {
    // Same triggers as the bundle: local writes ARE the update.
    ref.watch(goalsStreamProvider);
    ref.watch(todayAllTasksRowsProvider);
    ref.watch(defaultEnforcementModeProvider);
    ref.watch(attentionStateProvider);

    final generation = ++_generation;
    final now = DateTime.now();
    final todayKey = DateKeys.todayKey(now);

    // Today always live (habit completion is a hybrid source). Watched
    // before the first await so Riverpod tracks the dependency reliably.
    Future<DailyAnalyticsSnapshot>? todayGoal;
    Future<DailyAnalyticsSnapshot>? todayTask;
    if (arg.contains(todayKey)) {
      todayGoal = ref.watch(dailyGoalHabitAnalyticsProvider(todayKey).future);
      todayTask = ref.watch(dailyTaskAnalyticsProvider(todayKey).future);
    }

    final series = await _assemble(
      arg,
      now: now,
      todayKey: todayKey,
      todayGoal: todayGoal,
      todayTask: todayTask,
    );

    if (_needsBackfill(arg, series, todayKey) &&
        ref.read(tierGateProvider).canViewProgressHistory) {
      unawaited(_backfill(arg, generation, series, now: now));
    }
    return series;
  }

  Future<ProgressPeriodSeries> _assemble(
    ProgressPeriod period, {
    required DateTime now,
    required String todayKey,
    Future<DailyAnalyticsSnapshot>? todayGoal,
    Future<DailyAnalyticsSnapshot>? todayTask,
  }) async {
    final repo = ref.read(analyticsRepositoryProvider);
    final goals = await readCachedSnapshotMap(
      repo,
      scopeType: goalHabitDailyScope,
      fromDateKey: period.startDateKey,
      toDateKey: period.endDateKey,
    );
    final tasks = await readCachedSnapshotMap(
      repo,
      scopeType: taskDailyScope,
      fromDateKey: period.startDateKey,
      toDateKey: period.endDateKey,
    );

    int? streakFromToday;
    if (period.contains(todayKey)) {
      final g = await (todayGoal ??
          ref.read(dailyGoalHabitAnalyticsProvider(todayKey).future));
      final t = await (todayTask ??
          ref.read(dailyTaskAnalyticsProvider(todayKey).future));
      goals[todayKey] = g;
      tasks[todayKey] = t;
      streakFromToday = await computeBlendedCurrentStreakDays(
        ref,
        now: now,
        todayGoalHabit: g,
        todayTask: t,
      );
    }

    final previous = period.previous;
    final prevGoals = await readCachedSnapshotMap(
      repo,
      scopeType: goalHabitDailyScope,
      fromDateKey: previous.startDateKey,
      toDateKey: previous.endDateKey,
    );
    final prevTasks = await readCachedSnapshotMap(
      repo,
      scopeType: taskDailyScope,
      fromDateKey: previous.startDateKey,
      toDateKey: previous.endDateKey,
    );
    final previousRate = blendedRateOverDays(
      previous.dateKeys.where((k) => k.compareTo(todayKey) <= 0),
      prevGoals,
      prevTasks,
    );

    final attention = ref.read(attentionStateProvider).valueOrNull;
    return assembleProgressPeriodSeries(
      period: period,
      goalByKey: goals,
      taskByKey: tasks,
      protectedDateKeys: buildStreakProtectedDateKeys(
        attention: attention,
        rangeStartInclusive: period.start,
        rangeEndInclusive: period.end,
      ),
      mode: ref.read(defaultEnforcementModeProvider),
      now: now,
      previousPeriodRate: previousRate,
      currentStreakFromToday: streakFromToday,
    );
  }

  /// Past days in the period with no cache row for either scope.
  bool _needsBackfill(
    ProgressPeriod period,
    ProgressPeriodSeries series,
    String todayKey,
  ) {
    return series.days.any(
      (d) =>
          d.dateKey.compareTo(todayKey) < 0 && (d.goal == null || d.task == null),
    );
  }

  Future<void> _backfill(
    ProgressPeriod period,
    int generation,
    ProgressPeriodSeries current, {
    required DateTime now,
  }) async {
    try {
      final repo = ref.read(analyticsRepositoryProvider);
      final todayKey = DateKeys.todayKey(now);
      // Nothing before the first cached day can exist: that is the user's
      // first day of use.
      final earliestGoal = await readEarliestStatsDateKey(
        repo,
        scopeType: goalHabitDailyScope,
      );
      final earliestTask = await readEarliestStatsDateKey(
        repo,
        scopeType: taskDailyScope,
      );
      final earliest = [
        earliestGoal,
        earliestTask,
      ].whereType<String>().fold<String?>(
        null,
        (a, b) => a == null || b.compareTo(a) < 0 ? b : a,
      );
      if (earliest == null) return;

      var computed = 0;
      for (final d in current.days) {
        if (d.dateKey.compareTo(todayKey) >= 0) break;
        if (d.dateKey.compareTo(earliest) < 0) continue;
        if (d.goal == null) {
          await computeAndPersistDailySnapshot(
            ref,
            scopeType: goalHabitDailyScope,
            dateKey: d.dateKey,
          );
          computed++;
        }
        if (d.task == null) {
          await computeAndPersistDailySnapshot(
            ref,
            scopeType: taskDailyScope,
            dateKey: d.dateKey,
          );
          computed++;
        }
        if (computed % 10 == 0) {
          // Yield so a year of misses never starves the UI thread.
          await Future<void>.delayed(Duration.zero);
        }
        if (generation != _generation) return;
      }
      if (computed == 0 || generation != _generation) return;
      final fresh = await _assemble(period, now: now, todayKey: todayKey);
      if (generation != _generation) return;
      state = AsyncData(fresh);
    } catch (e) {
      // Cached series stays on screen; never silent (repo rule).
      debugPrint('progress_period_series: swallowed backfill error: $e');
    }
  }
}

final progressPeriodSeriesProvider = AsyncNotifierProvider.family<
  ProgressPeriodSeriesNotifier,
  ProgressPeriodSeries,
  ProgressPeriod
>(ProgressPeriodSeriesNotifier.new);
