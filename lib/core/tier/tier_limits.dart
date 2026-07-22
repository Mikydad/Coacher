import 'dart:convert';

/// Every Free/Pro tier limit in one place, remote-tunable as a single JSON
/// Remote Config parameter (`tier_limits_v1`) — see
/// `PRD/Monetization/prd-monetization-tiers.md` §7.
///
/// The compiled-in [defaults] are the launch values and the offline
/// fallback: a fresh install in airplane mode resolves these, never zero
/// and never unlimited.
///
/// [enforced] is the master kill switch. It ships `false` and stays false
/// until the Pro paywall exists — enforcing limits with no upgrade path
/// would wall users in with no door. Grandfathering needs no snapshot
/// logic: gates are creation-time count checks, so pre-existing over-limit
/// data is untouched and the cap binds naturally once the user deletes
/// down to it.
class TierLimits {
  const TierLimits({
    required this.enforced,
    required this.freeTasksPerDay,
    required this.freeGoals,
    required this.freeHabitAnchorsPerDay,
    required this.freeReminders,
    required this.freeAiInstructionsPerDay,
    required this.freePhotoStakesPerMonth,
    required this.freeCircles,
    required this.proCircles,
    required this.freeCircleMaxMembers,
    required this.proCircleMaxMembers,
    required this.mercyVetoFreePerMonth,
    required this.mercyVetoProPerMonth,
    required this.challengeFeeMinCents,
    required this.challengeFeePercent,
  });

  /// Master switch — no gate blocks anything while this is false.
  final bool enforced;

  /// New tasks a free user can plan for any single day.
  final int freeTasksPerDay;

  /// Active goals a free user can have (status == active).
  final int freeGoals;

  /// Habit Anchor tasks a free user can have on any single day ("5 active
  /// habits" — habits are Habit Anchor tasks in this codebase).
  final int freeHabitAnchorsPerDay;

  /// Active (enabled) reminder configurations; a recurring reminder is 1.
  final int freeReminders;

  /// Server-classified actionable AI messages per day (enforced by the
  /// aiChat Cloud Function; the client value is for UI messaging only).
  final int freeAiInstructionsPerDay;

  /// Activated photo-stake challenges per calendar month.
  final int freePhotoStakesPerMonth;

  /// Circles a free user can belong to (belong-to, not own). -1 = unlimited.
  final int freeCircles;

  /// Circles a Pro user can belong to. -1 = unlimited.
  final int proCircles;

  /// Max members in a circle created by a free / Pro user (server-enforced
  /// when circle tiering ships; carried here so all knobs live together).
  final int freeCircleMaxMembers;
  final int proCircleMaxMembers;

  /// Photo-stake mercy vetoes per month (server-enforced in stakeApplyVeto).
  final int mercyVetoFreePerMonth;
  final int mercyVetoProPerMonth;

  /// Money-challenge fee: greater of [challengeFeeMinCents] or
  /// [challengeFeePercent]% of the stake, per participant (Phase 4).
  final int challengeFeeMinCents;
  final int challengeFeePercent;

  /// Launch values — mirror PRD/Monetization/prd-monetization-tiers.md §4.
  static const TierLimits defaults = TierLimits(
    enforced: false,
    freeTasksPerDay: 5,
    freeGoals: 5,
    freeHabitAnchorsPerDay: 5,
    freeReminders: 5,
    freeAiInstructionsPerDay: 5,
    freePhotoStakesPerMonth: 3,
    freeCircles: 1,
    proCircles: -1,
    freeCircleMaxMembers: 5,
    proCircleMaxMembers: 8,
    mercyVetoFreePerMonth: 1,
    mercyVetoProPerMonth: 3,
    challengeFeeMinCents: 200,
    challengeFeePercent: 7,
  );

  /// Tolerant parse: any missing/mistyped field falls back to [defaults],
  /// unparseable input returns [defaults] wholesale. A bad console edit
  /// must never brick limits client-side.
  static TierLimits parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return defaults;
      return TierLimits.fromJson(decoded);
    } catch (_) {
      return defaults;
    }
  }

  factory TierLimits.fromJson(Map<String, dynamic> json) {
    bool b(String key, bool fallback) {
      final v = json[key];
      return v is bool ? v : fallback;
    }

    int i(String key, int fallback) {
      final v = json[key];
      return v is num ? v.toInt() : fallback;
    }

    const d = defaults;
    return TierLimits(
      enforced: b('enforced', d.enforced),
      freeTasksPerDay: i('freeTasksPerDay', d.freeTasksPerDay),
      freeGoals: i('freeGoals', d.freeGoals),
      freeHabitAnchorsPerDay: i(
        'freeHabitAnchorsPerDay',
        d.freeHabitAnchorsPerDay,
      ),
      freeReminders: i('freeReminders', d.freeReminders),
      freeAiInstructionsPerDay: i(
        'freeAiInstructionsPerDay',
        d.freeAiInstructionsPerDay,
      ),
      freePhotoStakesPerMonth: i(
        'freePhotoStakesPerMonth',
        d.freePhotoStakesPerMonth,
      ),
      freeCircles: i('freeCircles', d.freeCircles),
      proCircles: i('proCircles', d.proCircles),
      freeCircleMaxMembers: i('freeCircleMaxMembers', d.freeCircleMaxMembers),
      proCircleMaxMembers: i('proCircleMaxMembers', d.proCircleMaxMembers),
      mercyVetoFreePerMonth: i(
        'mercyVetoFreePerMonth',
        d.mercyVetoFreePerMonth,
      ),
      mercyVetoProPerMonth: i('mercyVetoProPerMonth', d.mercyVetoProPerMonth),
      challengeFeeMinCents: i('challengeFeeMinCents', d.challengeFeeMinCents),
      challengeFeePercent: i('challengeFeePercent', d.challengeFeePercent),
    );
  }

  Map<String, dynamic> toJson() => {
    'enforced': enforced,
    'freeTasksPerDay': freeTasksPerDay,
    'freeGoals': freeGoals,
    'freeHabitAnchorsPerDay': freeHabitAnchorsPerDay,
    'freeReminders': freeReminders,
    'freeAiInstructionsPerDay': freeAiInstructionsPerDay,
    'freePhotoStakesPerMonth': freePhotoStakesPerMonth,
    'freeCircles': freeCircles,
    'proCircles': proCircles,
    'freeCircleMaxMembers': freeCircleMaxMembers,
    'proCircleMaxMembers': proCircleMaxMembers,
    'mercyVetoFreePerMonth': mercyVetoFreePerMonth,
    'mercyVetoProPerMonth': mercyVetoProPerMonth,
    'challengeFeeMinCents': challengeFeeMinCents,
    'challengeFeePercent': challengeFeePercent,
  };
}
