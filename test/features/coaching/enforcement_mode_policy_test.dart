import 'package:coach_for_life/features/coaching/application/enforcement_mode_policy.dart';
import 'package:coach_for_life/features/coaching/domain/models/enforcement_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── urgencyMultiplier ────────────────────────────────────────────────────

  group('EnforcementModePolicy.urgencyMultiplier', () {
    test('flexible → ×0.8', () {
      expect(
        EnforcementModePolicy.urgencyMultiplier(EnforcementMode.flexible),
        closeTo(0.8, 0.0001),
      );
    });

    test('disciplined → ×1.0 (baseline)', () {
      expect(
        EnforcementModePolicy.urgencyMultiplier(EnforcementMode.disciplined),
        closeTo(1.0, 0.0001),
      );
    });

    test('extreme → ×1.3', () {
      expect(
        EnforcementModePolicy.urgencyMultiplier(EnforcementMode.extreme),
        closeTo(1.3, 0.0001),
      );
    });

    test('flexible score is lower than disciplined', () {
      const base = 0.5;
      final f = base * EnforcementModePolicy.urgencyMultiplier(EnforcementMode.flexible);
      final d = base * EnforcementModePolicy.urgencyMultiplier(EnforcementMode.disciplined);
      expect(f, lessThan(d));
    });

    test('extreme score is higher than disciplined', () {
      const base = 0.5;
      final e = base * EnforcementModePolicy.urgencyMultiplier(EnforcementMode.extreme);
      final d = base * EnforcementModePolicy.urgencyMultiplier(EnforcementMode.disciplined);
      expect(e, greaterThan(d));
    });
  });

  // ─── missedDayGracePeriod ─────────────────────────────────────────────────

  group('EnforcementModePolicy.missedDayGracePeriod', () {
    test('flexible → 1 day grace', () {
      expect(
        EnforcementModePolicy.missedDayGracePeriod(EnforcementMode.flexible),
        1,
      );
    });

    test('disciplined → 0 grace', () {
      expect(
        EnforcementModePolicy.missedDayGracePeriod(EnforcementMode.disciplined),
        0,
      );
    });

    test('extreme → 0 grace', () {
      expect(
        EnforcementModePolicy.missedDayGracePeriod(EnforcementMode.extreme),
        0,
      );
    });
  });

  // ─── onlyOnTimeCompletionsCountForStreak ─────────────────────────────────

  group('EnforcementModePolicy.onlyOnTimeCompletionsCountForStreak', () {
    test('flexible → false', () {
      expect(
        EnforcementModePolicy.onlyOnTimeCompletionsCountForStreak(
          EnforcementMode.flexible,
        ),
        isFalse,
      );
    });

    test('disciplined → false', () {
      expect(
        EnforcementModePolicy.onlyOnTimeCompletionsCountForStreak(
          EnforcementMode.disciplined,
        ),
        isFalse,
      );
    });

    test('extreme → true', () {
      expect(
        EnforcementModePolicy.onlyOnTimeCompletionsCountForStreak(
          EnforcementMode.extreme,
        ),
        isTrue,
      );
    });
  });

  // ─── recoveryGapMinutes ───────────────────────────────────────────────────

  group('EnforcementModePolicy.recoveryGapMinutes', () {
    test('flexible → 120 min cool-down', () {
      expect(
        EnforcementModePolicy.recoveryGapMinutes(EnforcementMode.flexible),
        120,
      );
    });

    test('disciplined → 30 min', () {
      expect(
        EnforcementModePolicy.recoveryGapMinutes(EnforcementMode.disciplined),
        30,
      );
    });

    test('extreme → 0 (immediate)', () {
      expect(
        EnforcementModePolicy.recoveryGapMinutes(EnforcementMode.extreme),
        0,
      );
    });
  });
}
