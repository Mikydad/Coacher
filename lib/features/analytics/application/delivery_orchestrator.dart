import '../data/delivery_repository.dart';
import '../domain/models/delivery_decision.dart';
import '../domain/models/generated_insight.dart';
import 'delivery_selection_engine.dart';
import 'layer4_delivery_policy.dart';

class DeliveryOrchestratorScopeResult {
  const DeliveryOrchestratorScopeResult({
    required this.scopeId,
    required this.surface,
    required this.selectionResult,
  });

  final String scopeId;
  final DeliverySurface surface;
  final DeliverySelectionResult selectionResult;
}

class DeliveryOrchestratorBatchMetadata {
  const DeliveryOrchestratorBatchMetadata({
    required this.scopesProcessed,
    required this.scopesErrored,
    required this.decisionsPersisted,
    required this.historyLogged,
    required this.elapsedMs,
    required this.schemaVersion,
  });

  final int scopesProcessed;
  final int scopesErrored;
  final int decisionsPersisted;
  final int historyLogged;
  final int elapsedMs;
  final int schemaVersion;
}

class DeliveryOrchestratorBatchResult {
  const DeliveryOrchestratorBatchResult({
    required this.scopeResults,
    required this.metadata,
  });

  final List<DeliveryOrchestratorScopeResult> scopeResults;
  final DeliveryOrchestratorBatchMetadata metadata;
}

class DeliveryOrchestrator {
  const DeliveryOrchestrator({required DeliveryRepository repository})
    : _repository = repository;

  final DeliveryRepository _repository;

  Future<DeliveryOrchestratorScopeResult> runForScope({
    required String scopeId,
    required List<GeneratedInsight> insights,
    required DeliverySurface preferredSurface,
    bool isActiveFocusFlow = false,
    bool forceSilent = false,
    DateTime? now,
    bool persist = true,
  }) async {
    final ts = now ?? DateTime.now();
    final key = scopeId.trim();
    final history = await _repository.listHistoryForScope(scopeId: key);

    final selection = selectDeliveryDecision(
      insights: insights,
      context: DeliverySelectionContext(
        now: ts,
        scopeId: key,
        preferredSurface: preferredSurface,
        isActiveFocusFlow: isActiveFocusFlow,
        forceSilent: forceSilent,
        deliveryHistory: history,
      ),
    );

    if (persist) {
      await _repository.upsertDecision(
        scopeId: key,
        surface: preferredSurface,
        decision: selection.decision,
      );
      final primaryId = selection.decision.selectedPrimaryInsightId;
      if (primaryId != null && primaryId.trim().isNotEmpty) {
        final primary = insights.firstWhere(
          (insight) => insight.insightId == primaryId,
          orElse: () => insights.first,
        );
        final cooldownHours = cooldownHoursForPriority(primary.priority);
        await _repository.logHistory(
          DeliveryHistoryEntry(
            insightId: primary.insightId,
            surface: selection.decision.targetSurface,
            scopeType: primary.scopeType,
            scopeId: primary.scopeId,
            deliveredAtMs: ts.millisecondsSinceEpoch,
            priority: primary.priority,
            confidence: primary.confidence,
            suppressionStatus: DeliverySuppressionStatus.none,
            cooldownUntilMs: ts
                .add(Duration(hours: cooldownHours))
                .millisecondsSinceEpoch,
          ),
        );
      }
    }

    return DeliveryOrchestratorScopeResult(
      scopeId: key,
      surface: preferredSurface,
      selectionResult: selection,
    );
  }

  Future<DeliveryOrchestratorBatchResult> runBatch({
    required Map<String, List<GeneratedInsight>> insightsByScope,
    required DeliverySurface preferredSurface,
    bool isActiveFocusFlow = false,
    bool forceSilent = false,
    DateTime? now,
    bool persist = true,
  }) async {
    final ts = now ?? DateTime.now();
    final stopwatch = Stopwatch()..start();
    final results = <DeliveryOrchestratorScopeResult>[];
    var errors = 0;
    var persisted = 0;
    var historyLogged = 0;

    for (final entry in insightsByScope.entries) {
      try {
        final result = await runForScope(
          scopeId: entry.key,
          insights: entry.value,
          preferredSurface: preferredSurface,
          isActiveFocusFlow: isActiveFocusFlow,
          forceSilent: forceSilent,
          now: ts,
          persist: persist,
        );
        if (persist) {
          persisted += 1;
          if (result.selectionResult.decision.selectedPrimaryInsightId !=
              null) {
            historyLogged += 1;
          }
        }
        results.add(result);
      } catch (_) {
        errors += 1;
      }
    }
    stopwatch.stop();

    return DeliveryOrchestratorBatchResult(
      scopeResults: results,
      metadata: DeliveryOrchestratorBatchMetadata(
        scopesProcessed: insightsByScope.length,
        scopesErrored: errors,
        decisionsPersisted: persisted,
        historyLogged: historyLogged,
        elapsedMs: stopwatch.elapsedMilliseconds,
        schemaVersion: kDeliveryDecisionSchemaVersion,
      ),
    );
  }
}
