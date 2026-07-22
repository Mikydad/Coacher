import 'package:sidepal/features/analytics/domain/models/delivery_decision.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('delivery_decision models', () {
    test('DeliveryDecision fromMap applies compatibility defaults', () {
      final decision = DeliveryDecision.fromMap(<String, dynamic>{
        'targetSurface': 'unknown',
      });

      expect(decision.targetSurface, DeliverySurface.none);
      expect(decision.shouldNotify, false);
      expect(decision.selectedPrimaryInsightId, isNull);
      expect(decision.schemaVersion, kDeliveryDecisionSchemaVersion);
    });

    test('DeliveryHistoryEntry toMap clamps confidence and keeps schema', () {
      final entry = DeliveryHistoryEntry(
        insightId: 'ins-1',
        surface: DeliverySurface.home,
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        deliveredAtMs: 1,
        priority: InsightPriority.medium,
        confidence: 2.0,
        suppressionStatus: DeliverySuppressionStatus.none,
        cooldownUntilMs: 2,
      );

      final map = entry.toMap();
      expect(map['confidence'], 1.0);
      expect(map['schemaVersion'], kDeliveryHistorySchemaVersion);
    });

    test('DeliveryHistoryEntry fromMap handles unknown enums', () {
      final entry = DeliveryHistoryEntry.fromMap(<String, dynamic>{
        'insightId': 'x',
        'surface': 'bad',
        'scopeType': 'bad',
        'scopeId': 's',
        'priority': 'bad',
        'suppressionStatus': 'bad',
      });

      expect(entry.surface, DeliverySurface.none);
      expect(entry.scopeType, InsightScopeType.entity);
      expect(entry.priority, InsightPriority.medium);
      expect(entry.suppressionStatus, DeliverySuppressionStatus.none);
    });
  });
}
