/// When the Home "Back up your SidePal" card shows for a guest
/// (decision log 2026-09-25).
///
/// Guest data survives reinstalls on iOS (keychain) but not on Android, so
/// the account prompt needs a real trigger instead of a vague "when you're
/// ready": once the guest owns a goal and comes back on a later day, once;
/// again seven days after a "Not now"; never after the second dismissal —
/// Profile's Connect account stays the way back.
abstract final class BackupCardPolicy {
  static const int maxDismissals = 2;
  static const Duration reprompt = Duration(days: 7);

  static bool shouldShow({
    required bool isAnonymous,
    required bool hasGoal,
    required int? onboardingCompletedAtMs,
    required int dismissals,
    required int? lastDismissedAtMs,
    required DateTime now,
  }) {
    if (!isAnonymous || !hasGoal) return false;
    if (dismissals >= maxDismissals) return false;
    if (onboardingCompletedAtMs != null &&
        _sameLocalDay(
          DateTime.fromMillisecondsSinceEpoch(onboardingCompletedAtMs),
          now,
        )) {
      return false;
    }
    if (dismissals == 0) return true;
    final last = lastDismissedAtMs;
    if (last == null) return true;
    return now.difference(DateTime.fromMillisecondsSinceEpoch(last)) >=
        reprompt;
  }

  static bool _sameLocalDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
