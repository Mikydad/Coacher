import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/local_db/isar_collections/isar_delivery_decision_snapshot.dart';
import '../../../core/local_db/isar_collections/isar_delivery_history_entry.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/models/delivery_decision.dart';
import '../domain/models/generated_insight.dart';
import 'delivery_orchestrator.dart';
import 'feature_builder_recompute_service.dart';
import 'insight_generation_providers.dart';
import 'layer4_delivery_policy.dart';
import 'pattern_detection_providers.dart';
import 'pattern_detection_orchestrator.dart';
import 'pattern_detection_recompute_service.dart';

class Layer4DecisionQuery {
  const Layer4DecisionQuery({required this.scopeId, required this.surface});

  final String scopeId;
  final DeliverySurface surface;

  @override
  bool operator ==(Object other) {
    return other is Layer4DecisionQuery &&
        other.scopeId == scopeId &&
        other.surface == surface;
  }

  @override
  int get hashCode => Object.hash(scopeId, surface);
}

class Layer4RunMetadata {
  const Layer4RunMetadata({
    required this.scopeId,
    required this.lastRunAtMs,
    required this.schemaVersion,
    required this.decisionsAvailable,
    required this.historyCount,
  });

  final String scopeId;
  final int lastRunAtMs;
  final int schemaVersion;
  final int decisionsAvailable;
  final int historyCount;
}

class Layer4NotificationDecisionViewModel {
  const Layer4NotificationDecisionViewModel({
    required this.decision,
    required this.isEligible,
    required this.primaryInsightId,
  });

  final DeliveryDecision? decision;
  final bool isEligible;
  final String? primaryInsightId;
}

class Layer4RefreshResult {
  const Layer4RefreshResult({
    required this.scopeId,
    required this.refreshedAtMs,
    required this.decisionsPersisted,
    required this.historyLogged,
  });

  final String scopeId;
  final int refreshedAtMs;
  final int decisionsPersisted;
  final int historyLogged;
}

class Layer34RecomputeResult {
  const Layer34RecomputeResult({
    required this.triggeredAtMs,
    required this.layer1Refreshed,
    required this.layer2Refreshed,
    required this.layer2CanonicalPatternsEmitted,
    required this.layer4Refresh,
  });

  final int triggeredAtMs;
  final bool layer1Refreshed;
  final bool layer2Refreshed;
  /// From persisted canonical global snapshot (0 if none).
  final int layer2CanonicalPatternsEmitted;
  final Layer4RefreshResult layer4Refresh;
}

Stream<T> _watchLayer4State<T>(
  Ref ref, {
  required Future<T> Function() loader,
}) {
  final isar = ref.watch(offlineStoreProvider).isar;
  if (isar == null) {
    return Stream.fromFuture(loader());
  }

  final controller = StreamController<T>.broadcast();

  Future<void> emit() async {
    try {
      final value = await loader();
      if (!controller.isClosed) controller.add(value);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  unawaited(emit());
  final decisionSub = isar.isarDeliveryDecisionSnapshots
      .watchLazy(fireImmediately: false)
      .listen((_) => unawaited(emit()));
  final historySub = isar.isarDeliveryHistoryEntrys
      .watchLazy(fireImmediately: false)
      .listen((_) => unawaited(emit()));

  ref.onDispose(() async {
    await decisionSub.cancel();
    await historySub.cancel();
    await controller.close();
  });

  return controller.stream;
}

final deliveryOrchestratorProvider = Provider<DeliveryOrchestrator>((ref) {
  return DeliveryOrchestrator(repository: ref.watch(deliveryRepositoryProvider));
});

final layer4IsActiveFocusFlowProvider = Provider<bool>((ref) {
  // Scoped watch: recompute only when the active/inactive answer flips, not
  // on every 1-second `elapsed` tick of the execution state.
  return ref.watch(
    executionControllerProvider.select(
      (s) => s.phase.name == 'inProgress' || s.phase.name == 'paused',
    ),
  );
});

final layer4RefreshTodayDeliveryProvider = FutureProvider<Layer4RefreshResult>((
  ref,
) async {
  final today = DateKeys.todayKey();
  final insights =
      await ref.watch(layer3DeliveryDayInsightsProvider(today).future);
  final orchestrator = ref.read(deliveryOrchestratorProvider);
  final repository = ref.read(deliveryRepositoryProvider);
  final isActiveFocusFlow = ref.read(layer4IsActiveFocusFlowProvider);
  final now = DateTime.now();

  final homeResult = await orchestrator.runForScope(
    scopeId: today,
    insights: insights,
    preferredSurface: DeliverySurface.home,
    isActiveFocusFlow: isActiveFocusFlow,
    now: now,
    persist: false,
  );
  final progressResult = await orchestrator.runForScope(
    scopeId: today,
    insights: insights,
    preferredSurface: DeliverySurface.progress,
    isActiveFocusFlow: isActiveFocusFlow,
    now: now,
    persist: false,
  );
  final notificationResult = await orchestrator.runForScope(
    scopeId: today,
    insights: insights,
    preferredSurface: DeliverySurface.notification,
    isActiveFocusFlow: isActiveFocusFlow,
    now: now,
    persist: false,
  );

  final results = <DeliveryOrchestratorScopeResult>[
    homeResult,
    progressResult,
    notificationResult,
  ];
  var decisionsPersisted = 0;
  var historyLogged = 0;
  for (final result in results) {
    await repository.upsertDecision(
      scopeId: today,
      surface: result.surface,
      decision: result.selectionResult.decision,
    );
    decisionsPersisted += 1;
  }

  final primaryInsightId = results
      .map((result) => result.selectionResult.decision.selectedPrimaryInsightId)
      .whereType<String>()
      .firstWhere((id) => id.trim().isNotEmpty, orElse: () => '');
  if (primaryInsightId.isNotEmpty) {
    final insight = insights.firstWhere(
      (item) => item.insightId == primaryInsightId,
      orElse: () => insights.first,
    );
    await repository.logHistory(
      DeliveryHistoryEntry(
        insightId: insight.insightId,
        surface: homeResult.selectionResult.decision.targetSurface,
        scopeType: insight.scopeType,
        scopeId: insight.scopeId,
        deliveredAtMs: now.millisecondsSinceEpoch,
        priority: insight.priority,
        confidence: insight.confidence,
        suppressionStatus: DeliverySuppressionStatus.none,
        cooldownUntilMs: now
            .add(Duration(hours: cooldownHoursForPriority(insight.priority)))
            .millisecondsSinceEpoch,
      ),
    );
    historyLogged = 1;
  }
  return Layer4RefreshResult(
    scopeId: today,
    refreshedAtMs: now.millisecondsSinceEpoch,
    decisionsPersisted: decisionsPersisted,
    historyLogged: historyLogged,
  );
});

final layer34RecomputeNowProvider = FutureProvider<Layer34RecomputeResult>((ref) async {
  final now = DateTime.now();
  final today = DateKeys.todayKey(now);
  final layer1Refreshed = await ref.read(layer34RunLayer1RefreshProvider)(now);
  final layer2Refreshed = await ref.read(layer34RunLayer2RefreshProvider)(now);
  ref.invalidate(layer3DeliveryDayInsightsProvider(today));
  ref.invalidate(layer3TodayRunMetadataProvider);
  ref.invalidate(layer4RefreshTodayDeliveryProvider);
  ref.invalidate(layer2GlobalCanonicalSnapshotProvider(today));
  final layer4 = await ref.read(layer4RefreshTodayDeliveryProvider.future);
  var layer2CanonicalPatternsEmitted = 0;
  try {
    layer2CanonicalPatternsEmitted = (await ref
            .read(patternDetectionRepositoryProvider)
            .readGlobalBehaviorSnapshot(dateKey: today))
        ?.totalPatternsEmitted ??
        0;
  } catch (_) {
    layer2CanonicalPatternsEmitted = 0;
  }
  return Layer34RecomputeResult(
    triggeredAtMs: now.millisecondsSinceEpoch,
    layer1Refreshed: layer1Refreshed,
    layer2Refreshed: layer2Refreshed,
    layer2CanonicalPatternsEmitted: layer2CanonicalPatternsEmitted,
    layer4Refresh: layer4,
  );
});

final layer34RunLayer1RefreshProvider =
    Provider<Future<bool> Function(DateTime)>((ref) {
      final service = ref.read(featureBuilderRecomputeServiceProvider);
      return (DateTime now) => service.forceRunDailyFullRefresh(now: now);
    });

final layer34RunLayer2RefreshProvider =
    Provider<Future<bool> Function(DateTime)>((ref) {
      final service = ref.read(patternDetectionRecomputeServiceProvider);
      return (DateTime now) => service.forceRunDailyFullRefresh(now: now);
    });

final layer4DeliveryDecisionProvider =
    StreamProvider.family<DeliveryDecision?, Layer4DecisionQuery>((ref, query) {
      final scopeId = query.scopeId.trim();
      if (scopeId.isEmpty) return Stream.value(null);
      return _watchLayer4State(
        ref,
        loader: () {
          return ref.read(deliveryRepositoryProvider).readDecision(
            scopeId: scopeId,
            surface: query.surface,
          );
        },
      );
    });

final layer4HistoryProvider =
    StreamProvider.family<List<DeliveryHistoryEntry>, String>((ref, scopeId) {
      final key = scopeId.trim();
      if (key.isEmpty) return Stream.value(const <DeliveryHistoryEntry>[]);
      return _watchLayer4State(
        ref,
        loader: () {
          return ref.read(deliveryRepositoryProvider).listHistoryForScope(
            scopeId: key,
          );
        },
      );
    });

final layer4RunMetadataProvider =
    StreamProvider.family<Layer4RunMetadata, String>((ref, scopeId) {
      final key = scopeId.trim();
      if (key.isEmpty) {
        return Stream.value(
          const Layer4RunMetadata(
            scopeId: '',
            lastRunAtMs: 0,
            schemaVersion: kDeliveryDecisionSchemaVersion,
            decisionsAvailable: 0,
            historyCount: 0,
          ),
        );
      }
      return _watchLayer4State(
        ref,
        loader: () async {
          final repo = ref.read(deliveryRepositoryProvider);
          final home = await repo.readDecision(
            scopeId: key,
            surface: DeliverySurface.home,
          );
          final progress = await repo.readDecision(
            scopeId: key,
            surface: DeliverySurface.progress,
          );
          final notification = await repo.readDecision(
            scopeId: key,
            surface: DeliverySurface.notification,
          );
          final history = await repo.listHistoryForScope(scopeId: key);
          final decisions = <DeliveryDecision?>[home, progress, notification];
          var lastRunAtMs = 0;
          var schemaVersion = kDeliveryDecisionSchemaVersion;
          var available = 0;
          for (final decision in decisions) {
            if (decision == null) continue;
            available += 1;
            if (decision.evaluatedAtMs > lastRunAtMs) {
              lastRunAtMs = decision.evaluatedAtMs;
            }
            if (decision.schemaVersion > schemaVersion) {
              schemaVersion = decision.schemaVersion;
            }
          }
          return Layer4RunMetadata(
            scopeId: key,
            lastRunAtMs: lastRunAtMs,
            schemaVersion: schemaVersion,
            decisionsAvailable: available,
            historyCount: history.length,
          );
        },
      );
    });

final layer4TodayHomeDecisionProvider = Provider<AsyncValue<DeliveryDecision?>>((
  ref,
) {
  ref.watch(layer4RefreshTodayDeliveryProvider);
  final today = DateKeys.todayKey();
  return ref.watch(
    layer4DeliveryDecisionProvider(
      Layer4DecisionQuery(scopeId: today, surface: DeliverySurface.home),
    ),
  );
});

final layer4TodayProgressDecisionProvider =
    Provider<AsyncValue<DeliveryDecision?>>((ref) {
      ref.watch(layer4RefreshTodayDeliveryProvider);
      final today = DateKeys.todayKey();
      return ref.watch(
        layer4DeliveryDecisionProvider(
          Layer4DecisionQuery(scopeId: today, surface: DeliverySurface.progress),
        ),
      );
    });

final layer4TodayNotificationDecisionProvider =
    Provider<AsyncValue<Layer4NotificationDecisionViewModel>>((ref) {
      ref.watch(layer4RefreshTodayDeliveryProvider);
      final today = DateKeys.todayKey();
      final decisionAsync = ref.watch(
        layer4DeliveryDecisionProvider(
          Layer4DecisionQuery(
            scopeId: today,
            surface: DeliverySurface.notification,
          ),
        ),
      );
      return decisionAsync.whenData((decision) {
        return Layer4NotificationDecisionViewModel(
          decision: decision,
          isEligible: decision?.shouldNotify ?? false,
          primaryInsightId: decision?.selectedPrimaryInsightId,
        );
      });
    });

final layer4TodayRunMetadataProvider = Provider<AsyncValue<Layer4RunMetadata>>((
  ref,
) {
  ref.watch(layer4RefreshTodayDeliveryProvider);
  final today = DateKeys.todayKey();
  return ref.watch(layer4RunMetadataProvider(today));
});

final layer4TodayHistoryProvider =
    Provider<AsyncValue<List<DeliveryHistoryEntry>>>((ref) {
      ref.watch(layer4RefreshTodayDeliveryProvider);
      final today = DateKeys.todayKey();
      return ref.watch(layer4HistoryProvider(today));
    });

/// Re-run Layer 4 selection after Layer 3 cache may change (e.g. task completed).
void invalidateTodayCoachingDelivery(WidgetRef ref) {
  final today = DateKeys.todayKey();
  ref.invalidate(layer3DeliveryDayInsightsProvider(today));
  ref.invalidate(layer4RefreshTodayDeliveryProvider);
}

void invalidateTodayCoachingDeliveryFromContainer(ProviderContainer container) {
  final today = DateKeys.todayKey();
  container.invalidate(layer3DeliveryDayInsightsProvider(today));
  container.invalidate(layer4RefreshTodayDeliveryProvider);
}

/// Drop Layer 1 feature row, Layer 3 entity insights, and refresh Layer 4 for a goal
/// that is no longer an active coaching subject (completed or deleted).
Future<void> clearEntityCoachingCachesForGoal(WidgetRef ref, String goalId) async {
  final id = goalId.trim();
  if (id.isEmpty) return;
  await ref.read(featureCacheRepositoryProvider).deleteByEntityId(id);
  await ref.read(insightCacheRepositoryProvider).replaceScopeInsights(
    scopeType: InsightScopeType.entity,
    scopeId: id,
    insights: const <GeneratedInsight>[],
  );
  invalidateTodayCoachingDelivery(ref);
}
