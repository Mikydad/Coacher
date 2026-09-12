/// The Progress period browser's read model: one blended point per calendar
/// day of a [ProgressPeriod] plus the period's rollup numbers.
///
/// Pure assembly — the provider feeds it cache maps; no I/O here.
library;

import '../../../core/utils/date_keys.dart';
import '../../coaching/domain/models/enforcement_mode.dart';
import '../domain/progress_period.dart';
import 'blended_discipline.dart';
import 'daily_analytics_engine.dart';

class ProgressDayPoint {
  const ProgressDayPoint({
    required this.dateKey,
    required this.goal,
    required this.task,
    required this.blended,
    required this.state,
  });

  final String dateKey;

  /// Cached scope snapshots; null when the day was never cached.
  final DailyAnalyticsSnapshot? goal;
  final DailyAnalyticsSnapshot? task;

  /// 0.0–1.0, or null when nothing was planned (quiet).
  final double? blended;
  final RingState state;

  double? get goalRate =>
      (goal?.weightedCreated ?? 0) > 0 ? goal!.weightedCompletionRate : null;
  double? get taskRate =>
      (task?.weightedCreated ?? 0) > 0 ? task!.weightedCompletionRate : null;
}

class ProgressPeriodSeries {
  const ProgressPeriodSeries({
    required this.period,
    required this.days,
    required this.periodRate,
    required this.goalRate,
    required this.taskRate,
    required this.daysMet,
    required this.daysPlanned,
    required this.currentStreak,
    required this.bestStreak,
    required this.previousPeriodRate,
    required this.monthRates,
  });

  final ProgressPeriod period;

  /// One point per calendar day, first → last (future days included, as
  /// [RingState.future]).
  final List<ProgressDayPoint> days;

  /// Weighted blended rate over the period; null when nothing was planned.
  final double? periodRate;
  final double? goalRate;
  final double? taskRate;

  /// Days whose ring is [RingState.qualified] / days with anything planned.
  final int daysMet;
  final int daysPlanned;

  /// Only meaningful when the period contains today; null otherwise.
  final int? currentStreak;
  final int bestStreak;

  /// Same rollup for the previous period (cache only), for the delta chip.
  final double? previousPeriodRate;

  /// Quarter: 3 entries; year: 12; otherwise empty. Null = quiet month.
  final List<double?> monthRates;

  /// Percentage-point delta vs the previous period, or null when either
  /// side is quiet.
  int? get deltaPoints {
    final a = periodRate;
    final b = previousPeriodRate;
    if (a == null || b == null) return null;
    return ((a - b) * 100).round();
  }

  ProgressDayPoint? pointFor(String dateKey) {
    for (final d in days) {
      if (d.dateKey == dateKey) return d;
    }
    return null;
  }
}

/// Weighted blended rate over a set of days (sums, then blend).
double? blendedRateOverDays(
  Iterable<String> dateKeys,
  Map<String, DailyAnalyticsSnapshot> goalByKey,
  Map<String, DailyAnalyticsSnapshot> taskByKey,
) {
  var gc = 0.0, gd = 0.0, tc = 0.0, td = 0.0;
  for (final k in dateKeys) {
    final g = goalByKey[k];
    final t = taskByKey[k];
    if (g != null) {
      gc += g.weightedCreated;
      gd += g.weightedCompleted;
    }
    if (t != null) {
      tc += t.weightedCreated;
      td += t.weightedCompleted;
    }
  }
  return blendRates(
    goalWeightedCreated: gc,
    goalWeightedCompleted: gd,
    taskWeightedCreated: tc,
    taskWeightedCompleted: td,
  );
}

double? _scopeRateOverDays(
  Iterable<String> dateKeys,
  Map<String, DailyAnalyticsSnapshot> byKey,
) {
  var created = 0.0, completed = 0.0;
  for (final k in dateKeys) {
    final s = byKey[k];
    if (s == null) continue;
    created += s.weightedCreated;
    completed += s.weightedCompleted;
  }
  if (created <= 0) return null;
  return (completed / created).clamp(0.0, 1.0);
}

ProgressPeriodSeries assembleProgressPeriodSeries({
  required ProgressPeriod period,
  required Map<String, DailyAnalyticsSnapshot> goalByKey,
  required Map<String, DailyAnalyticsSnapshot> taskByKey,
  required Set<String> protectedDateKeys,
  required EnforcementMode mode,
  required DateTime now,
  double? previousPeriodRate,

  /// Blended current streak walked back from today through the whole
  /// cache (see `computeBlendedCurrentStreakDays`); ignored when the period
  /// does not contain today.
  int? currentStreakFromToday,
}) {
  final todayKey = DateKeys.todayKey(now);
  final keys = period.dateKeys;
  final rates = <String, double?>{};
  final days = <ProgressDayPoint>[];
  var daysMet = 0;
  var daysPlanned = 0;

  for (final k in keys) {
    final g = goalByKey[k];
    final t = taskByKey[k];
    final isFuture = k.compareTo(todayKey) > 0;
    final blended = isFuture ? null : blendedDayRate(g, t);
    rates[k] = blended;
    final state = ringStateFor(
      blended: blended,
      isProtected: protectedDateKeys.contains(k),
      isFuture: isFuture,
      mode: mode,
    );
    if (blended != null) daysPlanned++;
    if (state == RingState.qualified) daysMet++;
    days.add(
      ProgressDayPoint(
        dateKey: k,
        goal: g,
        task: t,
        blended: blended,
        state: state,
      ),
    );
  }

  final pastKeys = keys.where((k) => k.compareTo(todayKey) <= 0);
  final containsToday = period.contains(todayKey);

  final monthRates = <double?>[];
  if (period.horizon == ProgressHorizon.quarter ||
      period.horizon == ProgressHorizon.year) {
    final byMonth = <String, List<String>>{};
    for (final k in pastKeys) {
      byMonth.putIfAbsent(k.substring(0, 7), () => []).add(k);
    }
    var cursor = DateTime(period.start.year, period.start.month, 1);
    while (!cursor.isAfter(period.end)) {
      final mk = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
      final mKeys = byMonth[mk];
      monthRates.add(
        mKeys == null ? null : blendedRateOverDays(mKeys, goalByKey, taskByKey),
      );
      cursor = DateTime(cursor.year, cursor.month + 1, 1);
    }
  }

  return ProgressPeriodSeries(
    period: period,
    days: days,
    periodRate: blendedRateOverDays(pastKeys, goalByKey, taskByKey),
    goalRate: _scopeRateOverDays(pastKeys, goalByKey),
    taskRate: _scopeRateOverDays(pastKeys, taskByKey),
    daysMet: daysMet,
    daysPlanned: daysPlanned,
    currentStreak: containsToday ? (currentStreakFromToday ?? 0) : null,
    bestStreak: blendedBestStreak(
      ratesByDateKey: rates,
      startDateKey: period.startDateKey,
      endDateKey: period.endDateKey,
      todayKey: todayKey,
      protectedDateKeys: protectedDateKeys,
      mode: mode,
    ),
    previousPeriodRate: previousPeriodRate,
    monthRates: monthRates,
  );
}
