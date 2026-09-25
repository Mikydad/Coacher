import 'package:sidepal/features/auth/application/backup_card_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 26, 10);
  final yesterday = DateTime(2026, 9, 25, 18).millisecondsSinceEpoch;

  bool show({
    bool anonymous = true,
    bool hasGoal = true,
    int? completedAt,
    int dismissals = 0,
    int? lastDismissedAt,
    DateTime? at,
  }) => BackupCardPolicy.shouldShow(
    isAnonymous: anonymous,
    hasGoal: hasGoal,
    onboardingCompletedAtMs: completedAt ?? yesterday,
    dismissals: dismissals,
    lastDismissedAtMs: lastDismissedAt,
    now: at ?? now,
  );

  group('BackupCardPolicy', () {
    test('shows for a guest with a goal on a later day', () {
      expect(show(), isTrue);
    });

    test('never for registered users or without a goal', () {
      expect(show(anonymous: false), isFalse);
      expect(show(hasGoal: false), isFalse);
    });

    test('not on the day onboarding finished', () {
      expect(
        show(completedAt: DateTime(2026, 9, 26, 8).millisecondsSinceEpoch),
        isFalse,
      );
    });

    test('existing installs without a profile still qualify', () {
      expect(
        BackupCardPolicy.shouldShow(
          isAnonymous: true,
          hasGoal: true,
          onboardingCompletedAtMs: null,
          dismissals: 0,
          lastDismissedAtMs: null,
          now: now,
        ),
        isTrue,
      );
    });

    test('after one "Not now": hidden until seven days pass', () {
      final dismissedAt = now
          .subtract(const Duration(days: 3))
          .millisecondsSinceEpoch;
      expect(show(dismissals: 1, lastDismissedAt: dismissedAt), isFalse);
      final week = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      expect(show(dismissals: 1, lastDismissedAt: week), isTrue);
    });

    test('after the second "Not now": never again', () {
      final longAgo = now
          .subtract(const Duration(days: 90))
          .millisecondsSinceEpoch;
      expect(show(dismissals: 2, lastDismissedAt: longAgo), isFalse);
    });
  });
}
