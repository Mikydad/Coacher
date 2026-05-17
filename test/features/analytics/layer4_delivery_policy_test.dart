import 'package:coach_for_life/features/analytics/application/layer4_delivery_policy.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('layer4_delivery_policy', () {
    test('config has expected V1 constants', () {
      expect(kLayer4DeliveryPolicyConfig.version, kLayer4DeliveryPolicyConfigVersion);
      expect(kLayer4DeliveryPolicyConfig.selection.maxPrimary, 1);
      expect(kLayer4DeliveryPolicyConfig.selection.maxSecondary, 1);
      expect(kLayer4DeliveryPolicyConfig.cooldowns.lowPriorityHours, greaterThanOrEqualTo(24));
    });

    test('timing profile resolves post-completion first', () {
      final profile = resolveTimingProfile(
        now: DateTime(2026, 5, 7, 22),
        justCompletedTask: true,
      );
      expect(profile, DeliveryTimingProfile.postCompletion);
    });

    test('notification gate allows high/medium only by confidence', () {
      final high = _insight(priority: InsightPriority.high, confidence: 0.8);
      final medPass = _insight(priority: InsightPriority.medium, confidence: 0.75);
      final medFail = _insight(priority: InsightPriority.medium, confidence: 0.6);
      final low = _insight(priority: InsightPriority.low, confidence: 1.0);

      expect(passesNotificationGate(high), isTrue);
      expect(passesNotificationGate(medPass), isTrue);
      expect(passesNotificationGate(medFail), isFalse);
      expect(passesNotificationGate(low), isFalse);
    });

    test('candidate comparator is deterministic', () {
      final a = _insight(
        id: 'a',
        priority: InsightPriority.medium,
        confidence: 0.8,
        action: InsightAction.doNow,
      );
      final b = _insight(
        id: 'b',
        priority: InsightPriority.medium,
        confidence: 0.8,
        action: InsightAction.doNow,
      );
      final compare = compareDeliveryCandidates(
        a,
        b,
        profile: DeliveryTimingProfile.morning,
      );
      expect(compare, lessThan(0));
    });
  });
}

GeneratedInsight _insight({
  String id = 'x',
  InsightPriority priority = InsightPriority.high,
  double confidence = 0.9,
  InsightAction action = InsightAction.focus,
}) {
  return GeneratedInsight(
    insightId: id,
    scopeType: InsightScopeType.global,
    scopeId: '2026-05-07',
    insightType: InsightType.streakRiskWarning,
    insightBucket: InsightBucket.risk,
    priority: priority,
    messageKey: 'streak_risk_1',
    message: 'fallback',
    action: action,
    linkedPatternCodes: const <String>['streakRisk'],
    confidence: confidence,
    detectedAtMs: 1,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: '2026-05-07',
  );
}
