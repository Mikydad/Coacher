import 'package:sidepal/features/analytics/application/delivery_orchestrator.dart';
import 'package:sidepal/features/analytics/data/delivery_repository.dart';
import 'package:sidepal/features/analytics/domain/models/delivery_decision.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('delivery_orchestrator', () {
    test('runs scope decision and persists snapshot/history', () async {
      final repo = _MemoryDeliveryRepository();
      final orchestrator = DeliveryOrchestrator(repository: repo);
      final now = DateTime(2026, 5, 7, 9);

      final result = await orchestrator.runForScope(
        scopeId: '2026-05-07',
        insights: <GeneratedInsight>[
          _insight(id: 'high', priority: InsightPriority.high, confidence: 0.9),
          _insight(id: 'medium', priority: InsightPriority.medium, confidence: 0.8),
        ],
        preferredSurface: DeliverySurface.home,
        now: now,
      );

      expect(result.selectionResult.decision.selectedPrimaryInsightId, 'high');
      expect(repo.decisions, hasLength(1));
      expect(repo.history, hasLength(1));
      expect(repo.history.single.insightId, 'high');
    });

    test('supports batch reevaluation metadata + deterministic outputs', () async {
      final repo = _MemoryDeliveryRepository();
      final orchestrator = DeliveryOrchestrator(repository: repo);
      final now = DateTime(2026, 5, 7, 21);

      final result = await orchestrator.runBatch(
        insightsByScope: <String, List<GeneratedInsight>>{
          '2026-05-07': <GeneratedInsight>[
            _insight(id: 'a', priority: InsightPriority.high, confidence: 0.8),
          ],
          'task-1': <GeneratedInsight>[
            _insight(
              id: 'b',
              scopeType: InsightScopeType.entity,
              scopeId: 'task-1',
              priority: InsightPriority.medium,
              confidence: 0.7,
            ),
          ],
        },
        preferredSurface: DeliverySurface.progress,
        now: now,
      );

      expect(result.metadata.scopesProcessed, 2);
      expect(result.metadata.scopesErrored, 0);
      expect(result.metadata.decisionsPersisted, 2);
      expect(result.metadata.historyLogged, 2);
      expect(result.scopeResults, hasLength(2));
      expect(repo.decisions, hasLength(2));
      expect(repo.history, hasLength(2));
      expect(
        result.scopeResults.map((entry) => entry.selectionResult.decision.targetSurface),
        everyElement(DeliverySurface.progress),
      );
    });
  });
}

class _MemoryDeliveryRepository implements DeliveryRepository {
  final Map<String, DeliveryDecision> decisions = <String, DeliveryDecision>{};
  final List<DeliveryHistoryEntry> history = <DeliveryHistoryEntry>[];

  @override
  Future<void> upsertDecision({
    required String scopeId,
    required DeliverySurface surface,
    required DeliveryDecision decision,
  }) async {
    decisions['${surface.name}::$scopeId'] = decision;
  }

  @override
  Future<DeliveryDecision?> readDecision({
    required String scopeId,
    required DeliverySurface surface,
  }) async {
    return decisions['${surface.name}::$scopeId'];
  }

  @override
  Future<void> logHistory(DeliveryHistoryEntry entry) async {
    history.add(entry);
  }

  @override
  Future<List<DeliveryHistoryEntry>> listHistoryForScope({
    required String scopeId,
    DeliverySurface? surface,
    int? fromDeliveredAtMs,
  }) async {
    return history
        .where((entry) => entry.scopeId == scopeId)
        .where((entry) => surface == null || entry.surface == surface)
        .where((entry) => fromDeliveredAtMs == null || entry.deliveredAtMs >= fromDeliveredAtMs)
        .toList(growable: false);
  }
}

GeneratedInsight _insight({
  required String id,
  InsightScopeType scopeType = InsightScopeType.global,
  String scopeId = '2026-05-07',
  InsightPriority priority = InsightPriority.high,
  double confidence = 0.8,
}) {
  return GeneratedInsight(
    insightId: id,
    scopeType: scopeType,
    scopeId: scopeId,
    insightType: InsightType.streakRiskWarning,
    insightBucket: InsightBucket.risk,
    priority: priority,
    messageKey: 'k',
    message: 'm',
    action: InsightAction.focus,
    linkedPatternCodes: const <String>['streakRisk'],
    confidence: confidence,
    detectedAtMs: 1,
    sourceWindowStartDateKey: '2026-05-01',
    sourceWindowEndDateKey: '2026-05-07',
  );
}
