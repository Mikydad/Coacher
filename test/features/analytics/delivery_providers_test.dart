import 'package:sidepal/core/di/providers.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/analytics/application/delivery_providers.dart';
import 'package:sidepal/features/analytics/application/insight_generation_providers.dart';
import 'package:sidepal/features/analytics/data/delivery_repository.dart';
import 'package:sidepal/features/analytics/data/insight_cache_repository.dart';
import 'package:sidepal/features/analytics/domain/models/delivery_decision.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInsightCacheRepository implements InsightCacheRepository {
  _FakeInsightCacheRepository(this._items);

  List<GeneratedInsight> _items;

  void replaceItems(List<GeneratedInsight> items) {
    _items = List<GeneratedInsight>.from(items);
  }

  @override
  Future<List<GeneratedInsight>> listAll() async => _items;

  @override
  Future<List<GeneratedInsight>> listByScope({
    required InsightScopeType scopeType,
    required String scopeId,
  }) async {
    return _items
        .where((item) => item.scopeType == scopeType && item.scopeId == scopeId)
        .toList(growable: false);
  }

  @override
  Future<List<GeneratedInsight>> listByScopeAndDateWindow({
    required InsightScopeType scopeType,
    required String scopeId,
    String? startDateKey,
    String? endDateKey,
  }) async {
    return listByScope(scopeType: scopeType, scopeId: scopeId);
  }

  @override
  Future<void> upsertInsight(GeneratedInsight insight) async {}

  @override
  Future<void> upsertInsights(List<GeneratedInsight> insights) async {}

  @override
  Future<void> replaceScopeInsights({
    required InsightScopeType scopeType,
    required String scopeId,
    required List<GeneratedInsight> insights,
  }) async {}
}

class _FakeDeliveryRepository implements DeliveryRepository {
  final Map<String, DeliveryDecision> _decisions = <String, DeliveryDecision>{};
  final List<DeliveryHistoryEntry> _history = <DeliveryHistoryEntry>[];

  @override
  Future<void> upsertDecision({
    required String scopeId,
    required DeliverySurface surface,
    required DeliveryDecision decision,
  }) async {
    _decisions['${surface.name}::$scopeId'] = decision;
  }

  @override
  Future<DeliveryDecision?> readDecision({
    required String scopeId,
    required DeliverySurface surface,
  }) async {
    return _decisions['${surface.name}::$scopeId'];
  }

  @override
  Future<void> logHistory(DeliveryHistoryEntry entry) async {
    _history.add(entry);
  }

  @override
  Future<List<DeliveryHistoryEntry>> listHistoryForScope({
    required String scopeId,
    DeliverySurface? surface,
    int? fromDeliveredAtMs,
  }) async {
    return _history
        .where((entry) => entry.scopeId == scopeId)
        .where((entry) => surface == null || entry.surface == surface)
        .where((entry) => fromDeliveredAtMs == null || entry.deliveredAtMs >= fromDeliveredAtMs)
        .toList(growable: false);
  }
}

void main() {
  test('exposes today home/progress/notification decision APIs', () async {
    final today = DateKeys.todayKey();
    final insightRepo = _FakeInsightCacheRepository(<GeneratedInsight>[
      _insight(id: 'top', scopeId: today, priority: InsightPriority.high, confidence: 0.9),
    ]);
    final deliveryRepo = _FakeDeliveryRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        insightCacheRepositoryProvider.overrideWithValue(insightRepo),
        deliveryRepositoryProvider.overrideWithValue(deliveryRepo),
        layer4IsActiveFocusFlowProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await container.read(layer4RefreshTodayDeliveryProvider.future);
    await container.read(
      layer4DeliveryDecisionProvider(
        Layer4DecisionQuery(scopeId: today, surface: DeliverySurface.home),
      ).future,
    );
    await container.read(
      layer4DeliveryDecisionProvider(
        Layer4DecisionQuery(scopeId: today, surface: DeliverySurface.progress),
      ).future,
    );
    await container.read(
      layer4DeliveryDecisionProvider(
        Layer4DecisionQuery(scopeId: today, surface: DeliverySurface.notification),
      ).future,
    );

    final home = container.read(layer4TodayHomeDecisionProvider).requireValue;
    final progress = container.read(layer4TodayProgressDecisionProvider).requireValue;
    final notification = container
        .read(layer4TodayNotificationDecisionProvider)
        .requireValue;

    expect(home, isNotNull);
    expect(progress, isNotNull);
    expect(notification.decision, isNotNull);
    expect(notification.isEligible, isTrue);
    expect(home!.selectedPrimaryInsightId, 'top');
    expect(progress!.selectedPrimaryInsightId, 'top');
    expect(home.targetSurface, DeliverySurface.home);
    expect(progress.targetSurface, DeliverySurface.progress);
    expect(notification.decision!.targetSurface, DeliverySurface.notification);
    expect(notification.primaryInsightId, 'top');
  });

  test('exposes run metadata/history and updates after refresh', () async {
    final today = DateKeys.todayKey();
    final insightRepo = _FakeInsightCacheRepository(<GeneratedInsight>[
      _insight(id: 'top-1', scopeId: today, priority: InsightPriority.high, confidence: 0.85),
    ]);
    final deliveryRepo = _FakeDeliveryRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        insightCacheRepositoryProvider.overrideWithValue(insightRepo),
        deliveryRepositoryProvider.overrideWithValue(deliveryRepo),
        layer4IsActiveFocusFlowProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    await container.read(layer4RefreshTodayDeliveryProvider.future);
    container.invalidate(layer4RefreshTodayDeliveryProvider);
    await container.read(layer4RefreshTodayDeliveryProvider.future);

    await container.read(layer4RunMetadataProvider(today).future);
    await container.read(layer4HistoryProvider(today).future);
    final metadata = container.read(layer4TodayRunMetadataProvider).requireValue;
    final history = container.read(layer4TodayHistoryProvider).requireValue;

    expect(metadata.scopeId, today);
    expect(metadata.decisionsAvailable, 3);
    expect(metadata.historyCount, greaterThanOrEqualTo(1));
    expect(history, isNotEmpty);
  });

  test('refresh propagates updated Layer3 insights into Layer4 decisions', () async {
    final today = DateKeys.todayKey();
    final insightRepo = _FakeInsightCacheRepository(<GeneratedInsight>[
      _insight(
        id: 'low',
        scopeId: today,
        priority: InsightPriority.low,
        confidence: 0.95,
      ),
    ]);
    final deliveryRepo = _FakeDeliveryRepository();
    final container = ProviderContainer(
      overrides: <Override>[
        insightCacheRepositoryProvider.overrideWithValue(insightRepo),
        deliveryRepositoryProvider.overrideWithValue(deliveryRepo),
        layer4IsActiveFocusFlowProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    final query = Layer4DecisionQuery(
      scopeId: today,
      surface: DeliverySurface.home,
    );
    await container.read(layer4RefreshTodayDeliveryProvider.future);
    await container.read(layer4DeliveryDecisionProvider(query).future);
    var home = container.read(layer4DeliveryDecisionProvider(query)).valueOrNull;
    expect(home!.selectedPrimaryInsightId, 'low');

    insightRepo.replaceItems(<GeneratedInsight>[
      _insight(
        id: 'high',
        scopeId: today,
        priority: InsightPriority.high,
        confidence: 0.8,
      ),
    ]);
    container.invalidate(layer3DeliveryDayInsightsProvider(today));
    container.invalidate(layer4RefreshTodayDeliveryProvider);
    await container.read(layer4RefreshTodayDeliveryProvider.future);
    container.invalidate(layer4DeliveryDecisionProvider(query));
    await container.read(layer4DeliveryDecisionProvider(query).future);
    home = container.read(layer4DeliveryDecisionProvider(query)).valueOrNull;
    expect(home!.selectedPrimaryInsightId, 'high');
  });

  test('manual recompute provider triggers deterministic refresh sequence', () async {
    final today = DateKeys.todayKey();
    final insightRepo = _FakeInsightCacheRepository(<GeneratedInsight>[
      _insight(id: 'top', scopeId: today, priority: InsightPriority.high, confidence: 0.9),
    ]);
    final deliveryRepo = _FakeDeliveryRepository();
    var layer1Calls = 0;
    var layer2Calls = 0;
    final container = ProviderContainer(
      overrides: <Override>[
        insightCacheRepositoryProvider.overrideWithValue(insightRepo),
        deliveryRepositoryProvider.overrideWithValue(deliveryRepo),
        layer4IsActiveFocusFlowProvider.overrideWithValue(false),
        layer34RunLayer1RefreshProvider.overrideWithValue((DateTime _) async {
          layer1Calls += 1;
          return true;
        }),
        layer34RunLayer2RefreshProvider.overrideWithValue((DateTime _) async {
          layer2Calls += 1;
          return true;
        }),
      ],
    );
    addTearDown(container.dispose);

    final out = await container.read(layer34RecomputeNowProvider.future);
    final home = await container.read(
      layer4DeliveryDecisionProvider(
        Layer4DecisionQuery(scopeId: today, surface: DeliverySurface.home),
      ).future,
    );

    expect(layer1Calls, 1);
    expect(layer2Calls, 1);
    expect(out.layer1Refreshed, isTrue);
    expect(out.layer2Refreshed, isTrue);
    expect(home, isNotNull);
    expect(home!.selectedPrimaryInsightId, 'top');
  });
}

GeneratedInsight _insight({
  required String id,
  required String scopeId,
  InsightPriority priority = InsightPriority.high,
  double confidence = 0.9,
}) {
  return GeneratedInsight(
    insightId: id,
    scopeType: InsightScopeType.global,
    scopeId: scopeId,
    insightType: InsightType.streakRiskWarning,
    insightBucket: InsightBucket.risk,
    priority: priority,
    messageKey: 'k',
    message: 'm',
    action: InsightAction.focus,
    linkedPatternCodes: const <String>['streakRisk'],
    confidence: confidence,
    detectedAtMs: 100,
    sourceWindowStartDateKey: scopeId,
    sourceWindowEndDateKey: scopeId,
  );
}
