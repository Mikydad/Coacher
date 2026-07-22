import 'package:sidepal/features/analytics/application/delivery_selection_engine.dart';
import 'package:sidepal/features/analytics/domain/models/delivery_decision.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('delivery_selection_engine', () {
    test('evaluates candidates and selects primary + optional secondary', () {
      final result = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(
            id: 'high',
            priority: InsightPriority.high,
            confidence: 0.8,
            action: InsightAction.doNow,
          ),
          _insight(
            id: 'medium',
            priority: InsightPriority.medium,
            confidence: 0.9,
            action: InsightAction.focus,
          ),
        ],
        context: DeliverySelectionContext(
          now: DateTime(2026, 5, 7, 9),
          scopeId: '2026-05-07',
          preferredSurface: DeliverySurface.home,
        ),
      );

      expect(result.decision.selectedPrimaryInsightId, 'high');
      expect(result.decision.selectedSecondaryInsightId, 'medium');
      expect(result.decision.targetSurface, DeliverySurface.home);
      expect(result.evaluations.length, 2);
      expect(result.decision.decisionReasonCodes, contains(DeliveryReasonCode.selectedPrimary));
      expect(result.suppressionDiagnostics.acceptedCount, 2);
      expect(result.suppressionDiagnostics.rejectedCount, 0);
    });

    test('returns deterministic no-delivery fallback when no candidate passes', () {
      final result = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(
            id: 'low-confidence',
            priority: InsightPriority.high,
            confidence: 0.1,
          ),
        ],
        context: DeliverySelectionContext(
          now: DateTime(2026, 5, 7, 9),
          scopeId: '2026-05-07',
        ),
      );

      expect(result.decision.selectedPrimaryInsightId, isNull);
      expect(result.decision.targetSurface, DeliverySurface.none);
      expect(result.decision.shouldNotify, isFalse);
      expect(
        result.decision.decisionReasonCodes,
        contains(DeliveryReasonCode.noEligibleCandidates),
      );
      expect(result.evaluations.first.accepted, isFalse);
      expect(result.suppressionDiagnostics.lowConfidenceSuppressed, 1);
    });

    test('includes decision reason codes for accepted and notify gate', () {
      final result = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(
            id: 'med-pass',
            priority: InsightPriority.medium,
            confidence: 0.8,
            action: InsightAction.reschedule,
          ),
        ],
        context: DeliverySelectionContext(
          now: DateTime(2026, 5, 7, 14),
          scopeId: '2026-05-07',
          preferredSurface: DeliverySurface.progress,
        ),
      );

      expect(result.decision.selectedPrimaryInsightId, 'med-pass');
      expect(result.decision.targetSurface, DeliverySurface.progress);
      expect(result.decision.shouldNotify, isTrue);
      expect(result.decision.decisionReasonCodes, contains(DeliveryReasonCode.routedToProgress));
      expect(result.decision.decisionReasonCodes, contains(DeliveryReasonCode.notifyGatePassed));
    });

    test('routes to notification when preferred and notify-eligible', () {
      final result = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(
            id: 'notif',
            priority: InsightPriority.high,
            confidence: 0.9,
            action: InsightAction.doNow,
          ),
        ],
        context: DeliverySelectionContext(
          now: DateTime(2026, 5, 7, 9),
          scopeId: '2026-05-07',
          preferredSurface: DeliverySurface.notification,
        ),
      );

      expect(result.decision.targetSurface, DeliverySurface.notification);
      expect(result.decision.shouldNotify, isTrue);
      expect(
        result.decision.decisionReasonCodes,
        contains(DeliveryReasonCode.routedToNotification),
      );
    });

    test('falls back to home when preferred notification is not eligible', () {
      final result = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(
            id: 'not-eligible',
            priority: InsightPriority.medium,
            confidence: 0.5,
            action: InsightAction.focus,
          ),
        ],
        context: DeliverySelectionContext(
          now: DateTime(2026, 5, 7, 9),
          scopeId: '2026-05-07',
          preferredSurface: DeliverySurface.notification,
        ),
      );

      expect(result.decision.targetSurface, DeliverySurface.home);
      expect(result.decision.shouldNotify, isFalse);
      expect(
        result.decision.decisionReasonCodes,
        contains(DeliveryReasonCode.routedToHome),
      );
      expect(
        result.decision.decisionReasonCodes,
        contains(DeliveryReasonCode.notifyGateBlocked),
      );
    });

    test('suppresses repeated insight by adaptive cooldown history', () {
      final now = DateTime(2026, 5, 7, 9);
      final result = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(
            id: 'repeat',
            priority: InsightPriority.high,
            confidence: 0.9,
          ),
        ],
        context: DeliverySelectionContext(
          now: now,
          scopeId: '2026-05-07',
          deliveryHistory: <DeliveryHistoryEntry>[
            DeliveryHistoryEntry(
              insightId: 'repeat',
              surface: DeliverySurface.home,
              scopeType: InsightScopeType.global,
              scopeId: '2026-05-07',
              deliveredAtMs: now.subtract(const Duration(hours: 2)).millisecondsSinceEpoch,
              priority: InsightPriority.high,
              confidence: 0.9,
              suppressionStatus: DeliverySuppressionStatus.none,
              cooldownUntilMs: now.add(const Duration(hours: 1)).millisecondsSinceEpoch,
            ),
          ],
        ),
      );

      expect(result.decision.selectedPrimaryInsightId, isNull);
      expect(
        result.decision.decisionReasonCodes,
        contains(DeliveryReasonCode.noEligibleCandidates),
      );
      expect(result.suppressionDiagnostics.cooldownSuppressed, 1);
    });

    test('applies adaptive cooldown windows by priority', () {
      final now = DateTime(2026, 5, 7, 18);
      final result = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(
            id: 'high-priority',
            priority: InsightPriority.high,
            confidence: 0.9,
          ),
          _insight(
            id: 'medium-priority',
            priority: InsightPriority.medium,
            confidence: 0.9,
          ),
          _insight(
            id: 'low-priority',
            priority: InsightPriority.low,
            confidence: 0.9,
          ),
        ],
        context: DeliverySelectionContext(
          now: now,
          scopeId: '2026-05-07',
          deliveryHistory: <DeliveryHistoryEntry>[
            DeliveryHistoryEntry(
              insightId: 'high-priority',
              surface: DeliverySurface.home,
              scopeType: InsightScopeType.global,
              scopeId: '2026-05-07',
              deliveredAtMs: now.subtract(const Duration(hours: 7)).millisecondsSinceEpoch,
              priority: InsightPriority.high,
              confidence: 0.9,
              suppressionStatus: DeliverySuppressionStatus.none,
              cooldownUntilMs: 0,
            ),
            DeliveryHistoryEntry(
              insightId: 'medium-priority',
              surface: DeliverySurface.home,
              scopeType: InsightScopeType.global,
              scopeId: '2026-05-07',
              deliveredAtMs: now.subtract(const Duration(hours: 15)).millisecondsSinceEpoch,
              priority: InsightPriority.medium,
              confidence: 0.9,
              suppressionStatus: DeliverySuppressionStatus.none,
              cooldownUntilMs: 0,
            ),
            DeliveryHistoryEntry(
              insightId: 'low-priority',
              surface: DeliverySurface.home,
              scopeType: InsightScopeType.global,
              scopeId: '2026-05-07',
              deliveredAtMs: now.subtract(const Duration(hours: 23)).millisecondsSinceEpoch,
              priority: InsightPriority.low,
              confidence: 0.9,
              suppressionStatus: DeliverySuppressionStatus.none,
              cooldownUntilMs: 0,
            ),
          ],
        ),
      );

      expect(result.decision.selectedPrimaryInsightId, isNull);
      expect(result.suppressionDiagnostics.cooldownSuppressed, 3);
    });

    test('uses deterministic tie-break for equal score candidates', () {
      final now = DateTime(2026, 5, 7, 11);
      final firstRun = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(
            id: 'aaa',
            priority: InsightPriority.high,
            confidence: 0.8,
          ),
          _insight(
            id: 'bbb',
            priority: InsightPriority.high,
            confidence: 0.8,
          ),
        ],
        context: DeliverySelectionContext(now: now, scopeId: '2026-05-07'),
      );
      final secondRun = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(
            id: 'bbb',
            priority: InsightPriority.high,
            confidence: 0.8,
          ),
          _insight(
            id: 'aaa',
            priority: InsightPriority.high,
            confidence: 0.8,
          ),
        ],
        context: DeliverySelectionContext(now: now, scopeId: '2026-05-07'),
      );

      expect(firstRun.decision.selectedPrimaryInsightId, 'aaa');
      expect(secondRun.decision.selectedPrimaryInsightId, 'aaa');
      expect(
        firstRun.decision.selectedPrimaryInsightId,
        secondRun.decision.selectedPrimaryInsightId,
      );
    });

    test('blocks delivery while active focus flow is running', () {
      final result = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(id: 'high', priority: InsightPriority.high, confidence: 0.9),
        ],
        context: DeliverySelectionContext(
          now: DateTime(2026, 5, 7, 9),
          scopeId: '2026-05-07',
          isActiveFocusFlow: true,
        ),
      );

      expect(result.decision.targetSurface, DeliverySurface.none);
      expect(
        result.decision.decisionReasonCodes,
        contains(DeliveryReasonCode.blockedByActiveFocus),
      );
      expect(result.suppressionDiagnostics.focusBlocked, 1);
      expect(result.evaluations.first.accepted, isFalse);
    });

    test('returns silent outcome when forceSilent is enabled', () {
      final result = selectDeliveryDecision(
        insights: <GeneratedInsight>[
          _insight(id: 'x', priority: InsightPriority.high, confidence: 0.9),
        ],
        context: DeliverySelectionContext(
          now: DateTime(2026, 5, 7, 9),
          scopeId: '2026-05-07',
          forceSilent: true,
        ),
      );

      expect(result.decision.targetSurface, DeliverySurface.none);
      expect(result.decision.shouldNotify, isFalse);
      expect(
        result.decision.decisionReasonCodes,
        contains(DeliveryReasonCode.silentModeActive),
      );
      expect(result.evaluations.first.accepted, isFalse);
    });
  });
}

GeneratedInsight _insight({
  required String id,
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
    messageKey: 'k',
    message: 'fallback',
    action: action,
    linkedPatternCodes: const <String>['streakRisk'],
    confidence: confidence,
    detectedAtMs: 1,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: '2026-05-07',
  );
}
