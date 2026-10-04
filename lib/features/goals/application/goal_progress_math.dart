import '../../../core/utils/date_keys.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/user_goal.dart';
import 'goal_period_helpers.dart';

/// Progress of a goal inside its CURRENT evaluation window, in the goal's
/// own units (AI chat fix plan Phase 3.1). One definition for every reader:
/// the goal UI sums logged values over the window; the Coach prompt used to
/// print a count of "met" days against a value target ("Music: 0/25
/// minutes" for a goal with 10 minutes logged — review §1.1 #6).
class GoalWindowProgress {
  const GoalWindowProgress({
    required this.logged,
    required this.target,
    required this.unitLabel,
    required this.windowLabel,
    required this.windowStartKey,
    required this.windowEndKey,
    required this.daysLogged,
    required this.daysElapsed,
    required this.daysInWindow,
    required this.behindPace,
  });

  /// Sum of check-in values inside the window (legacy boolean-only
  /// check-ins count 1 each).
  final double logged;
  final double target;

  /// "minutes", "sessions", "km", the custom label, or "" for plain counts.
  final String unitLabel;

  /// "today" | "this week" | "this month" | "this period".
  final String windowLabel;
  final String windowStartKey;
  final String windowEndKey;

  /// Distinct days in the window with something logged.
  final int daysLogged;

  /// Calendar days of the window that have elapsed, including today.
  final int daysElapsed;
  final int daysInWindow;

  /// Logged is under the straight-line pace for the elapsed share of the
  /// window (single-day windows are never "behind" — the day is not over).
  final bool behindPace;

  bool get targetMet => target > 0 && logged >= target;

  String get loggedText => _fmt(logged);
  String get targetText => _fmt(target);

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);
}

abstract final class GoalProgressMath {
  static GoalWindowProgress compute(
    UserGoal goal,
    List<GoalCheckIn> checkIns,
    DateTime now,
  ) {
    final window = GoalPeriodHelpers.evaluationWindow(goal, now);
    final startKey = DateKeys.yyyymmdd(window.start);
    final endKey = DateKeys.yyyymmdd(window.end);
    final today = DateKeys.todayKey(now);

    var logged = 0.0;
    final loggedDays = <String>{};
    for (final c in checkIns) {
      if (c.dateKey.compareTo(startKey) < 0 || c.dateKey.compareTo(endKey) > 0) {
        continue;
      }
      final value = c.value ?? (c.metCommitment ? 1.0 : 0.0);
      if (value > 0) loggedDays.add(c.dateKey);
      logged += value;
    }

    final daysInWindow = window.end.difference(window.start).inDays + 1;
    final todayDate = DateKeys.parseLocalDateKey(today);
    final elapsedRaw = todayDate.difference(window.start).inDays + 1;
    final daysElapsed = elapsedRaw.clamp(0, daysInWindow);

    final target = goal.targetValue;
    final behind = daysInWindow > 1 &&
        target > 0 &&
        daysElapsed > 0 &&
        logged < target * (daysElapsed / daysInWindow) - 1e-9;

    return GoalWindowProgress(
      logged: logged,
      target: target,
      unitLabel: unitLabelFor(goal),
      windowLabel: windowLabelFor(goal),
      windowStartKey: startKey,
      windowEndKey: endKey,
      daysLogged: loggedDays.length,
      daysElapsed: daysElapsed,
      daysInWindow: daysInWindow,
      behindPace: behind,
    );
  }

  static String unitLabelFor(UserGoal goal) {
    final custom = goal.customLabel?.trim();
    if (custom != null && custom.isNotEmpty) return custom;
    return switch (goal.measurementKind) {
      MeasurementKind.minutes => 'minutes',
      MeasurementKind.sessions => 'sessions',
      MeasurementKind.distance => 'km',
      MeasurementKind.count => '',
      MeasurementKind.custom => '',
    };
  }

  static String windowLabelFor(UserGoal goal) => switch (goal.repeatCadence) {
    GoalRepeatCadence.daily => 'today',
    GoalRepeatCadence.weekly => 'this week',
    GoalRepeatCadence.monthly => 'this month',
    GoalRepeatCadence.off => 'this period',
  };

  static String cadenceLabelFor(UserGoal goal) => switch (goal.repeatCadence) {
    GoalRepeatCadence.daily => 'daily',
    GoalRepeatCadence.weekly => 'weekly',
    GoalRepeatCadence.monthly => 'monthly',
    GoalRepeatCadence.off => 'one-time',
  };
}
