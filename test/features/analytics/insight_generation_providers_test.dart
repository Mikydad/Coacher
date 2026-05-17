import 'package:coach_for_life/features/analytics/application/insight_generation_providers.dart';
import 'package:coach_for_life/core/utils/date_keys.dart';
import 'package:coach_for_life/features/analytics/data/insight_cache_repository.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:coach_for_life/core/di/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeInsightCacheRepository implements InsightCacheRepository {
  _FakeInsightCacheRepository(this._items);

  final List<GeneratedInsight> _items;

  @override
  Future<List<GeneratedInsight>> listAll() async => _items;

  @override
  Future<List<GeneratedInsight>> listByScope({
    required InsightScopeType scopeType,
    required String scopeId,
  }) async {
    return _items
        .where((item) => item.scopeType == scopeType && item.scopeId == scopeId)
        .toList();
  }

  @override
  Future<List<GeneratedInsight>> listByScopeAndDateWindow({
    required InsightScopeType scopeType,
    required String scopeId,
    String? startDateKey,
    String? endDateKey,
  }) async => listByScope(scopeType: scopeType, scopeId: scopeId);

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

void main() {
  test('providers return scoped insights and run metadata', () async {
    final repo = _FakeInsightCacheRepository(<GeneratedInsight>[
      _insight(
        id: 'entity-1',
        scopeType: InsightScopeType.entity,
        scopeId: 'task-1',
        detectedAtMs: 200,
      ),
      _insight(
        id: 'global-1',
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
        detectedAtMs: 250,
      ),
    ]);
    final container = ProviderContainer(
      overrides: <Override>[
        insightCacheRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final entityInsights = await container.read(
      layer3EntityInsightsProvider('task-1').future,
    );
    expect(entityInsights, hasLength(1));
    expect(entityInsights.single.scopeType, InsightScopeType.entity);

    final globalInsights = await container.read(
      layer3GlobalDayInsightsProvider('2026-05-07').future,
    );
    expect(globalInsights, hasLength(1));
    expect(globalInsights.single.scopeType, InsightScopeType.global);

    final metadata = await container.read(
      layer3RunMetadataProvider((
        scopeType: InsightScopeType.global,
        scopeId: '2026-05-07',
      )).future,
    );
    expect(metadata.insightsEmitted, 1);
    expect(metadata.lastRunAtMs, 250);
    expect(metadata.schemaVersion, kGeneratedInsightSchemaVersion);
  });

  test('home provider picks top prioritized global insight', () async {
    final today = DateKeys.todayKey();
    final repo = _FakeInsightCacheRepository(<GeneratedInsight>[
      _insight(
        id: 'low',
        scopeType: InsightScopeType.global,
        scopeId: today,
        detectedAtMs: 100,
        priority: InsightPriority.low,
        confidence: 0.9,
      ),
      _insight(
        id: 'high',
        scopeType: InsightScopeType.global,
        scopeId: today,
        detectedAtMs: 110,
        priority: InsightPriority.high,
        confidence: 0.5,
      ),
      _insight(
        id: 'medium',
        scopeType: InsightScopeType.global,
        scopeId: today,
        detectedAtMs: 120,
        priority: InsightPriority.medium,
        confidence: 0.8,
      ),
    ]);
    final container = ProviderContainer(
      overrides: <Override>[
        insightCacheRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(layer3DeliveryDayInsightsProvider(today).future);
    final vmAsync = container.read(homeLayer3InsightsProvider);
    expect(vmAsync.hasValue, isTrue);
    final vm = vmAsync.requireValue;
    expect(vm.topInsights, hasLength(3));
    expect(vm.primary, isNotNull);
    expect(vm.primary!.insightId, 'high');
  });

  test('home provider includes entity insights active on today', () async {
    final today = DateKeys.todayKey();
    final repo = _FakeInsightCacheRepository(<GeneratedInsight>[
      _insight(
        id: 'entity-x',
        scopeType: InsightScopeType.entity,
        scopeId: 'task-x',
        detectedAtMs: 100,
        priority: InsightPriority.high,
        confidence: 0.95,
        sourceWindowStartDateKey: today,
        sourceWindowEndDateKey: today,
      ),
    ]);
    final container = ProviderContainer(
      overrides: <Override>[
        insightCacheRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    await container.read(layer3DeliveryDayInsightsProvider(today).future);
    final vmAsync = container.read(homeLayer3InsightsProvider);
    expect(vmAsync.hasValue, isTrue);
    final vm = vmAsync.requireValue;
    expect(vm.primary, isNotNull);
    expect(vm.primary!.insightId, 'entity-x');
  });
}

GeneratedInsight _insight({
  required String id,
  required InsightScopeType scopeType,
  required String scopeId,
  required int detectedAtMs,
  InsightPriority priority = InsightPriority.high,
  double confidence = 0.9,
  String? sourceWindowStartDateKey,
  String? sourceWindowEndDateKey,
}) {
  return GeneratedInsight(
    insightId: id,
    scopeType: scopeType,
    scopeId: scopeId,
    insightType: InsightType.streakRiskWarning,
    insightBucket: InsightBucket.risk,
    priority: priority,
    messageKey: 'streak_risk_1',
    message: 'fallback',
    action: InsightAction.doNow,
    linkedPatternCodes: const <String>['streakRisk'],
    confidence: confidence,
    detectedAtMs: detectedAtMs,
    sourceWindowStartDateKey: sourceWindowStartDateKey ?? '2026-05-01',
    sourceWindowEndDateKey: sourceWindowEndDateKey ?? '2026-05-07',
  );
}
