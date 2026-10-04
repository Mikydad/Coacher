import 'tier_limits.dart';

/// The account's subscription tier. Free until a Pro entitlement says
/// otherwise (source of truth becomes RevenueCat when the paywall ships).
enum UserTier { free, pro }

/// Thrown by non-UI creation paths (e.g. AI action executor) when a free
/// limit blocks the action. [toString] is user-facing — it surfaces
/// verbatim in the AI chat failure list.
class TierLimitException implements Exception {
  TierLimitException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Pure creation-time gate decisions: current count vs. the free limit.
/// No I/O — callers supply counts, which keeps every rule unit-testable.
///
/// Client gates are UI politeness; anything touching money, stakes, or AI
/// quota is authoritatively enforced server-side against the same
/// `tier_limits_v1` values.
class TierGate {
  const TierGate({required this.limits, required this.tier});

  final TierLimits limits;
  final UserTier tier;

  /// True when no gate can block: enforcement off, or Pro account.
  /// Callers use this to skip count queries entirely.
  bool get isBypassed => !limits.enforced || tier == UserTier.pro;

  bool _allows(int currentCount, int freeLimit) =>
      isBypassed || freeLimit < 0 || currentCount < freeLimit;

  bool canCreateTaskForDay(int tasksPlannedThatDay) =>
      _allows(tasksPlannedThatDay, limits.freeTasksPerDay);

  bool canAddHabitAnchorForDay(int anchorsThatDay) =>
      _allows(anchorsThatDay, limits.freeHabitAnchorsPerDay);

  bool canCreateGoal(int activeGoalCount) =>
      _allows(activeGoalCount, limits.freeGoals);

  /// Progress history (Week, Month, Quarter, Year views) is Pro; the Day
  /// view is free (decision 2026-09-12). Home's weekly bar and Profile's
  /// THIS WEEK stat are single numbers, not history, and stay free.
  bool get canViewProgressHistory => isBypassed;

  /// Time insights are Pro (decision 2026-09-27): the Day summary totals,
  /// AI observations, planned vs actual, the Direction mirror, and the Week
  /// view. Logging and the Day timeline itself stay free and unlimited.
  bool get canViewTimeInsights => isBypassed;

  /// Time-log export (Day / Week / Month file share) is Pro with the rest
  /// of the insights (decision 2026-09-27; free since 2026-09-15).
  bool get canExportTimeLog => isBypassed;

  /// [createdThisWeek] = promises created since Monday 00:00 local that
  /// still exist, excluding AI-noticed dormant radar items.
  bool canCreatePromiseThisWeek(int createdThisWeek) =>
      _allows(createdThisWeek, limits.freePromisesPerWeek);

  bool canCreateReminder(int activeReminderCount) =>
      _allows(activeReminderCount, limits.freeReminders);

  /// Solo photo + public stakes that activated this calendar month.
  bool canCreateStakeThisMonth(int activatedThisMonth) =>
      _allows(activatedThisMonth, limits.freeStakesPerMonth);

  /// Max circles the user may belong to. [legacyLimit] is the pre-tier
  /// app-wide cap that continues to apply while enforcement is off.
  /// -1 means unlimited.
  int maxJoinedCircles({required int legacyLimit}) {
    if (!limits.enforced) return legacyLimit;
    return tier == UserTier.pro ? limits.proCircles : limits.freeCircles;
  }
}
