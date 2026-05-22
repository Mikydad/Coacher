import 'package:coach_for_life/features/analytics/domain/models/coaching_ai_payload.dart';
import 'package:coach_for_life/features/analytics/domain/models/current_coaching_focus.dart';
import 'package:coach_for_life/features/coaching/domain/models/coaching_style.dart';
import 'package:flutter_test/flutter_test.dart';

// Shorthand helper.
CoachingFraming _framing(
  FocusReason reason,
  CoachingStyle style, {
  double focusScore = 0.7,
  double urgencyScore = 0.5,
}) {
  return deriveCoachingFraming(
    focusReason: reason,
    focusScore: focusScore,
    urgencyScore: urgencyScore,
    coachingStyle: style,
  );
}

void main() {
  // ─── imminentStreakRisk × CoachingStyle ────────────────────────────────────

  group('imminentStreakRisk', () {
    test('supportive → recovery (softer framing)', () {
      expect(
        _framing(FocusReason.imminentStreakRisk, CoachingStyle.supportive),
        CoachingFraming.recovery,
      );
    });

    test('balanced → protection', () {
      expect(
        _framing(FocusReason.imminentStreakRisk, CoachingStyle.balanced),
        CoachingFraming.protection,
      );
    });

    test('disciplined → protection', () {
      expect(
        _framing(FocusReason.imminentStreakRisk, CoachingStyle.disciplined),
        CoachingFraming.protection,
      );
    });

    test('intense → protection', () {
      expect(
        _framing(FocusReason.imminentStreakRisk, CoachingStyle.intense),
        CoachingFraming.protection,
      );
    });
  });

  // ─── highestMomentumLeverage — style-neutral ───────────────────────────────

  group('highestMomentumLeverage', () {
    for (final style in CoachingStyle.values) {
      test('$style → momentum', () {
        expect(
          _framing(FocusReason.highestMomentumLeverage, style),
          CoachingFraming.momentum,
        );
      });
    }
  });

  // ─── bestRecoveryOpportunity × CoachingStyle ──────────────────────────────

  group('bestRecoveryOpportunity', () {
    test('supportive → recovery', () {
      expect(
        _framing(FocusReason.bestRecoveryOpportunity, CoachingStyle.supportive),
        CoachingFraming.recovery,
      );
    });

    test('balanced → recovery', () {
      expect(
        _framing(FocusReason.bestRecoveryOpportunity, CoachingStyle.balanced),
        CoachingFraming.recovery,
      );
    });

    test('disciplined → recovery', () {
      expect(
        _framing(FocusReason.bestRecoveryOpportunity, CoachingStyle.disciplined),
        CoachingFraming.recovery,
      );
    });

    test('intense → stabilization', () {
      expect(
        _framing(FocusReason.bestRecoveryOpportunity, CoachingStyle.intense),
        CoachingFraming.stabilization,
      );
    });
  });

  // ─── goalDriftDetected × CoachingStyle ────────────────────────────────────

  group('goalDriftDetected', () {
    test('supportive → recovery', () {
      expect(
        _framing(FocusReason.goalDriftDetected, CoachingStyle.supportive),
        CoachingFraming.recovery,
      );
    });

    test('balanced → stabilization', () {
      expect(
        _framing(FocusReason.goalDriftDetected, CoachingStyle.balanced),
        CoachingFraming.stabilization,
      );
    });

    test('disciplined → stabilization', () {
      expect(
        _framing(FocusReason.goalDriftDetected, CoachingStyle.disciplined),
        CoachingFraming.stabilization,
      );
    });

    test('intense → protection', () {
      expect(
        _framing(FocusReason.goalDriftDetected, CoachingStyle.intense),
        CoachingFraming.protection,
      );
    });
  });

  // ─── consistencyBreakdownAlert × CoachingStyle ────────────────────────────

  group('consistencyBreakdownAlert', () {
    test('supportive → stabilization', () {
      expect(
        _framing(FocusReason.consistencyBreakdownAlert, CoachingStyle.supportive),
        CoachingFraming.stabilization,
      );
    });

    test('balanced → stabilization', () {
      expect(
        _framing(FocusReason.consistencyBreakdownAlert, CoachingStyle.balanced),
        CoachingFraming.stabilization,
      );
    });

    test('disciplined → protection', () {
      expect(
        _framing(
          FocusReason.consistencyBreakdownAlert,
          CoachingStyle.disciplined,
        ),
        CoachingFraming.protection,
      );
    });

    test('intense → protection', () {
      expect(
        _framing(FocusReason.consistencyBreakdownAlert, CoachingStyle.intense),
        CoachingFraming.protection,
      );
    });
  });

  // ─── Style-neutral reasons ─────────────────────────────────────────────────

  group('overdueItemCritical — urgency-driven, style-neutral', () {
    test('high urgency → protection regardless of style', () {
      for (final style in CoachingStyle.values) {
        expect(
          _framing(
            FocusReason.overdueItemCritical,
            style,
            urgencyScore: 0.7,
          ),
          CoachingFraming.protection,
          reason: 'style=$style',
        );
      }
    });

    test('low urgency → recovery regardless of style', () {
      for (final style in CoachingStyle.values) {
        expect(
          _framing(
            FocusReason.overdueItemCritical,
            style,
            urgencyScore: 0.4,
          ),
          CoachingFraming.recovery,
          reason: 'style=$style',
        );
      }
    });
  });

  group('default balanced matches legacy behaviour', () {
    test('imminentStreakRisk without style arg → protection', () {
      expect(
        deriveCoachingFraming(
          focusReason: FocusReason.imminentStreakRisk,
          focusScore: 0.8,
          urgencyScore: 0.9,
        ),
        CoachingFraming.protection,
      );
    });
  });
}
