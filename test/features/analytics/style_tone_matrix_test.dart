import 'package:coach_for_life/features/analytics/application/ai_response_validator.dart';
import 'package:coach_for_life/features/analytics/application/deterministic_coaching_renderer.dart';
import 'package:coach_for_life/features/analytics/domain/models/ai_summary_response.dart';
import 'package:coach_for_life/features/analytics/domain/models/coaching_ai_payload.dart';
import 'package:coach_for_life/features/analytics/domain/models/current_coaching_focus.dart';
import 'package:coach_for_life/features/coaching/domain/models/coaching_style.dart';
import 'package:flutter_test/flutter_test.dart';

CoachingAiPayload _payload({
  CoachingStyle style = CoachingStyle.balanced,
  CoachingFraming framing = CoachingFraming.protection,
  FocusReason reason = FocusReason.imminentStreakRisk,
}) {
  return CoachingAiPayload(
    focusId: 'f1',
    focusReason: reason.name,
    framing: framing,
    summaryType: SummaryType.focus,
    primaryInsightType: 'streakRiskWarning',
    focusScore: 0.8,
    urgencyScore: 0.9,
    evaluationTrace: const ['trace1'],
    keyPatternCodes: const ['streakAtRisk'],
    topEvidence: const {},
    deliveryContext: const AiDeliveryContext(
      timingProfile: 'evening',
      localDateKey: '2026-07-15',
    ),
    generatedAtMs: 1000,
    promptVersion: 'v1.0.0',
    coachingStyle: style,
  );
}

AiSummaryResponse _response({
  CoachingTone tone = CoachingTone.assertive,
  CoachingFraming framing = CoachingFraming.protection,
}) {
  return AiSummaryResponse(
    focusId: 'f1',
    summaryType: SummaryType.focus,
    tone: tone,
    dailySummary: 'Your streak needs attention. Act now to protect it.',
    mainRecommendation: 'Complete a short session tonight.',
    framing: framing,
    generatedAtMs: 1000,
    promptVersion: 'v1.0.0',
  );
}

void main() {
  group('expectedToneFor — framing × style matrix', () {
    test('balanced column matches the legacy framing-only mapping', () {
      for (final framing in CoachingFraming.values) {
        expect(
          expectedToneFor(framing: framing, style: CoachingStyle.balanced),
          expectedToneForFraming(framing),
          reason: 'balanced must be backward compatible for $framing',
        );
      }
    });

    test('intense style is assertive for every framing', () {
      for (final framing in CoachingFraming.values) {
        expect(
          expectedToneFor(framing: framing, style: CoachingStyle.intense),
          CoachingTone.assertive,
        );
      }
    });

    test('supportive style softens protection and stabilization', () {
      expect(
        expectedToneFor(
          framing: CoachingFraming.protection,
          style: CoachingStyle.supportive,
        ),
        CoachingTone.supportive,
      );
      expect(
        expectedToneFor(
          framing: CoachingFraming.stabilization,
          style: CoachingStyle.supportive,
        ),
        CoachingTone.supportive,
      );
      expect(
        expectedToneFor(
          framing: CoachingFraming.consistency,
          style: CoachingStyle.supportive,
        ),
        CoachingTone.encouraging,
      );
    });

    test('disciplined style keeps recovery matter-of-fact', () {
      expect(
        expectedToneFor(
          framing: CoachingFraming.recovery,
          style: CoachingStyle.disciplined,
        ),
        CoachingTone.informative,
      );
    });
  });

  group('AiResponseValidator — style-aware tone check', () {
    const validator = AiResponseValidator();

    test('assertive protection passes for a balanced user', () {
      final result = validator.validate(
        response: _response(),
        payload: _payload(),
      );
      expect(result.isValid, isTrue);
    });

    test('assertive protection is rejected for a supportive user', () {
      final result = validator.validate(
        response: _response(tone: CoachingTone.assertive),
        payload: _payload(style: CoachingStyle.supportive),
      );
      expect(result.validationOutcome, AiSummaryValidationOutcome.toneMismatch);
    });

    test('supportive protection passes for a supportive user', () {
      final result = validator.validate(
        response: _response(tone: CoachingTone.supportive),
        payload: _payload(style: CoachingStyle.supportive),
      );
      expect(result.isValid, isTrue);
    });
  });

  group('DeterministicCoachingRenderer — style-aware tone', () {
    const renderer = DeterministicCoachingRenderer();

    test('fallback tone follows the framing × style matrix', () {
      final supportive = renderer.render(
        payload: _payload(style: CoachingStyle.supportive),
      );
      expect(supportive.tone, CoachingTone.supportive);
      expect(supportive.isFallback, isTrue);

      final intense = renderer.render(
        payload: _payload(style: CoachingStyle.intense),
      );
      expect(intense.tone, CoachingTone.assertive);

      final balanced = renderer.render(payload: _payload());
      expect(balanced.tone, CoachingTone.assertive);
    });
  });
}
