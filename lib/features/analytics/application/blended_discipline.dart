/// The one blended discipline number (decision 2026-09-12).
///
/// Every day on Progress, Home and Profile is scored the same way:
/// `0.6 × goals/habits weighted rate + 0.4 × tasks weighted rate`, using
/// only the scopes that were actually planned that day. Time-tracker data
/// never enters here.
///
/// Pure Dart; no clocks, no providers.
library;

import '../../coaching/application/enforcement_mode_policy.dart';
import '../../coaching/domain/models/enforcement_mode.dart';
import 'daily_analytics_engine.dart';

const double kBlendGoalWeight = 0.6;
const double kBlendTaskWeight = 0.4;

/// Blends two weighted completion ratios.
///
/// - both scopes planned → `0.6·goal + 0.4·task`
/// - only one planned   → that scope's rate (never capped at 60 % / 40 %)
/// - neither planned    → `null` — a quiet day, not a 0 % day
double? blendRates({
  required double goalWeightedCreated,
  required double goalWeightedCompleted,
  required double taskWeightedCreated,
  required double taskWeightedCompleted,
}) {
  final goalPlanned = goalWeightedCreated > 0;
  final taskPlanned = taskWeightedCreated > 0;
  if (!goalPlanned && !taskPlanned) return null;
  final goalRate = goalPlanned
      ? (goalWeightedCompleted / goalWeightedCreated).clamp(0.0, 1.0)
      : 0.0;
  final taskRate = taskPlanned
      ? (taskWeightedCompleted / taskWeightedCreated).clamp(0.0, 1.0)
      : 0.0;
  if (goalPlanned && taskPlanned) {
    return (kBlendGoalWeight * goalRate + kBlendTaskWeight * taskRate).clamp(
      0.0,
      1.0,
    );
  }
  return goalPlanned ? goalRate : taskRate;
}

/// Blended rate for one day from its two scope snapshots (either may be
/// missing from the cache).
double? blendedDayRate(DailyAnalyticsSnapshot? goal, DailyAnalyticsSnapshot? task) {
  return blendRates(
    goalWeightedCreated: goal?.weightedCreated ?? 0,
    goalWeightedCompleted: goal?.weightedCompleted ?? 0,
    taskWeightedCreated: task?.weightedCreated ?? 0,
    taskWeightedCompleted: task?.weightedCompleted ?? 0,
  );
}

/// Blended rate over a period from the two scope rollups. Weighted, not a
/// mean of day rates: a heavy day counts more than a light one, exactly as
/// `rollupDailyAnalytics` already does per scope.
double? blendedPeriodRate(
  RollupAnalyticsSnapshot goal,
  RollupAnalyticsSnapshot task,
) {
  return blendRates(
    goalWeightedCreated: goal.weightedCreated,
    goalWeightedCompleted: goal.weightedCompleted,
    taskWeightedCreated: task.weightedCreated,
    taskWeightedCompleted: task.weightedCompleted,
  );
}

/// How a day ring is drawn. See PRD §4.3.
enum RingState {
  /// Blended rate cleared the enforcement-mode streak threshold.
  qualified,

  /// Something was done, but below the threshold.
  partial,

  /// Something was planned, nothing was done.
  missed,

  /// Nothing was planned (or the day is not cached). Never a failure.
  quiet,

  /// Vacation / override day; excused for streaks (only when it did not
  /// qualify on its own — a qualified protected day is still qualified).
  protected,

  /// After today.
  future,
}

RingState ringStateFor({
  required double? blended,
  required bool isProtected,
  required bool isFuture,
  required EnforcementMode mode,
}) {
  if (isFuture) return RingState.future;
  if (blended != null &&
      EnforcementModePolicy.isStreakQualifyingDay(blended, mode)) {
    return RingState.qualified;
  }
  if (isProtected) return RingState.protected;
  if (blended == null) return RingState.quiet;
  if (blended <= 0) return RingState.missed;
  return RingState.partial;
}

/// Whether [dateKey] keeps a streak alive. Quiet days break it (decision
/// 2026-09-12, unchanged from the per-scope engine) unless protected.
bool blendedDayQualifies({
  required String dateKey,
  required double? blended,
  required Set<String> protectedDateKeys,
  required EnforcementMode mode,
}) {
  if (protectedDateKeys.contains(dateKey)) return true;
  if (blended == null) return false;
  return EnforcementModePolicy.isStreakQualifyingDay(blended, mode);
}

/// Longest run of qualifying days inside `[startDateKey, endDateKey]`
/// (inclusive, `yyyy-MM-dd`). Days after [todayKey] are ignored.
int blendedBestStreak({
  required Map<String, double?> ratesByDateKey,
  required String startDateKey,
  required String endDateKey,
  required String todayKey,
  required Set<String> protectedDateKeys,
  required EnforcementMode mode,
}) {
  var best = 0;
  var running = 0;
  final last = endDateKey.compareTo(todayKey) > 0 ? todayKey : endDateKey;
  for (final key in _dateKeysInclusive(startDateKey, last)) {
    final ok = blendedDayQualifies(
      dateKey: key,
      blended: ratesByDateKey[key],
      protectedDateKeys: protectedDateKeys,
      mode: mode,
    );
    if (ok) {
      running++;
      if (running > best) best = running;
    } else {
      running = 0;
    }
  }
  return best;
}

/// Consecutive qualifying days ending at [todayKey], walking back no
/// further than [earliestDateKey]. Returns the run length; when the run
/// reaches [earliestDateKey] the caller may read further back and continue.
int blendedCurrentStreak({
  required Map<String, double?> ratesByDateKey,
  required String todayKey,
  required String earliestDateKey,
  required Set<String> protectedDateKeys,
  required EnforcementMode mode,
}) {
  var run = 0;
  var cursor = _parse(todayKey);
  while (true) {
    final key = _fmt(cursor);
    if (key.compareTo(earliestDateKey) < 0) break;
    final ok = blendedDayQualifies(
      dateKey: key,
      blended: ratesByDateKey[key],
      protectedDateKeys: protectedDateKeys,
      mode: mode,
    );
    if (!ok) break;
    run++;
    cursor = DateTime(cursor.year, cursor.month, cursor.day - 1);
  }
  return run;
}

Iterable<String> _dateKeysInclusive(String from, String to) sync* {
  if (from.compareTo(to) > 0) return;
  var cursor = _parse(from);
  final last = _parse(to);
  while (!cursor.isAfter(last)) {
    yield _fmt(cursor);
    cursor = DateTime(cursor.year, cursor.month, cursor.day + 1);
  }
}

DateTime _parse(String key) {
  final p = key.split('-');
  return DateTime(int.parse(p[0]), int.parse(p[1]), int.parse(p[2]));
}

String _fmt(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final dd = d.day.toString().padLeft(2, '0');
  return '$y-$m-$dd';
}
