import '../../../core/utils/date_keys.dart';
import '../../profile/domain/models/user_profile_preference.dart';

/// Fixed local notification id — all coaching insight pushes replace this slot.
const int kCoachingInsightNotificationId = 0x434F494E; // 'COIN'

/// Max coaching insight pushes per calendar day (local).
const int kMaxCoachingInsightNotificationsPerDay = 3;

/// Minimum time between two coaching insight pushes on the same day.
const Duration kMinGapBetweenCoachingInsightNotifications = Duration(hours: 4);

enum CoachingInsightNotificationBlockReason {
  disabled,
  dailyCapReached,
  minGapNotElapsed,
}

class CoachingInsightNotificationSendEvaluation {
  const CoachingInsightNotificationSendEvaluation({
    required this.allowed,
    this.reason,
    this.sentCountToday = 0,
    this.nextEligibleAt,
  });

  final bool allowed;
  final CoachingInsightNotificationBlockReason? reason;
  final int sentCountToday;
  final DateTime? nextEligibleAt;
}

/// Normalizes budget fields for [now]'s calendar day.
UserProfilePreference coachingNotificationBudgetForDay(
  UserProfilePreference pref,
  DateTime now,
) {
  final today = DateKeys.todayKey(now);
  if (pref.coachingNotificationBudgetDateKey == today) {
    return pref;
  }
  return pref.copyWith(
    coachingNotificationBudgetDateKey: today,
    coachingNotificationSentAtMs: const <int>[],
  );
}

CoachingInsightNotificationSendEvaluation
evaluateCoachingInsightNotificationSend(
  UserProfilePreference pref,
  DateTime now,
) {
  final normalized = coachingNotificationBudgetForDay(pref, now);
  if (!normalized.coachingInsightNotificationsEnabled) {
    return const CoachingInsightNotificationSendEvaluation(
      allowed: false,
      reason: CoachingInsightNotificationBlockReason.disabled,
    );
  }

  final sent = List<int>.from(normalized.coachingNotificationSentAtMs)..sort();
  final count = sent.length;

  if (count >= kMaxCoachingInsightNotificationsPerDay) {
    return CoachingInsightNotificationSendEvaluation(
      allowed: false,
      reason: CoachingInsightNotificationBlockReason.dailyCapReached,
      sentCountToday: count,
    );
  }

  if (sent.isNotEmpty) {
    final lastMs = sent.last;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final nextEligible = last.add(kMinGapBetweenCoachingInsightNotifications);
    if (now.isBefore(nextEligible)) {
      return CoachingInsightNotificationSendEvaluation(
        allowed: false,
        reason: CoachingInsightNotificationBlockReason.minGapNotElapsed,
        sentCountToday: count,
        nextEligibleAt: nextEligible,
      );
    }
  }

  return CoachingInsightNotificationSendEvaluation(
    allowed: true,
    sentCountToday: count,
  );
}

UserProfilePreference recordCoachingInsightNotificationSent(
  UserProfilePreference pref,
  DateTime now,
) {
  final normalized = coachingNotificationBudgetForDay(pref, now);
  final sent = List<int>.from(normalized.coachingNotificationSentAtMs)
    ..add(now.millisecondsSinceEpoch)
    ..sort();
  return normalized.copyWith(
    coachingNotificationBudgetDateKey: DateKeys.todayKey(now),
    coachingNotificationSentAtMs: sent,
  );
}
