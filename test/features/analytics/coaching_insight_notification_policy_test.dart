import 'package:coach_for_life/features/analytics/application/coaching_insight_notification_policy.dart';
import 'package:coach_for_life/features/coaching/domain/models/enforcement_mode.dart';
import 'package:coach_for_life/features/profile/domain/models/user_profile_preference.dart';
import 'package:flutter_test/flutter_test.dart';

UserProfilePreference _pref({
  bool enabled = true,
  String dateKey = '2026-05-26',
  List<int> sent = const [],
}) {
  return UserProfilePreference(
    id: kUserProfilePreferenceId,
    displayName: '',
    defaultEnforcementMode: EnforcementMode.disciplined,
    updatedAtMs: 0,
    coachingInsightNotificationsEnabled: enabled,
    coachingNotificationBudgetDateKey: dateKey,
    coachingNotificationSentAtMs: sent,
  );
}

void main() {
  test('blocks when disabled', () {
    final now = DateTime(2026, 5, 26, 10);
    final result = evaluateCoachingInsightNotificationSend(
      _pref(enabled: false),
      now,
    );
    expect(result.allowed, isFalse);
    expect(result.reason, CoachingInsightNotificationBlockReason.disabled);
  });

  test('blocks after daily cap', () {
    final now = DateTime(2026, 5, 26, 20);
    final sent = List.generate(
      kMaxCoachingInsightNotificationsPerDay,
      (i) => DateTime(2026, 5, 26, 8 + i * 5).millisecondsSinceEpoch,
    );
    final result = evaluateCoachingInsightNotificationSend(
      _pref(sent: sent),
      now,
    );
    expect(result.allowed, isFalse);
    expect(result.reason, CoachingInsightNotificationBlockReason.dailyCapReached);
  });

  test('blocks when min gap not elapsed', () {
    final now = DateTime(2026, 5, 26, 12);
    final last = DateTime(2026, 5, 26, 10).millisecondsSinceEpoch;
    final result = evaluateCoachingInsightNotificationSend(
      _pref(sent: [last]),
      now,
    );
    expect(result.allowed, isFalse);
    expect(result.reason, CoachingInsightNotificationBlockReason.minGapNotElapsed);
  });

  test('allows after min gap and records send', () {
    final first = DateTime(2026, 5, 26, 8);
    var pref = _pref();
    expect(
      evaluateCoachingInsightNotificationSend(pref, first).allowed,
      isTrue,
    );
    pref = recordCoachingInsightNotificationSent(pref, first);
    final second = DateTime(2026, 5, 26, 13);
    expect(
      evaluateCoachingInsightNotificationSend(pref, second).allowed,
      isTrue,
    );
    pref = recordCoachingInsightNotificationSent(pref, second);
    expect(pref.coachingNotificationSentAtMs.length, 2);
  });

  test('resets sent list on new calendar day', () {
    final pref = _pref(
      dateKey: '2026-05-25',
      sent: [DateTime(2026, 5, 25, 9).millisecondsSinceEpoch],
    );
    final now = DateTime(2026, 5, 26, 9);
    final normalized = coachingNotificationBudgetForDay(pref, now);
    expect(normalized.coachingNotificationSentAtMs, isEmpty);
    expect(normalized.coachingNotificationBudgetDateKey, '2026-05-26');
  });
}
