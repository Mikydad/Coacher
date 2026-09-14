import 'package:sidepal/features/analytics/application/insight_generation_providers.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/analytics/data/insight_cache_repository.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:sidepal/core/di/providers.dart';
import 'package:sidepal/features/goals/domain/models/goal_enums.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/no_op_goals_repository.dart';

class _GoalsRepo extends NoOpGoalsRepository {
  _GoalsRepo(this.goals);
  final Map<String, UserGoal> goals;

  @override
  Future<UserGoal?> getGoal(String goalId) async => goals[goalId];
}

UserGoal _goal({
  required String id,
  List<int>? weekdays,
  GoalStatus status = GoalStatus.active,
}) {
  return UserGoal(
    id: id,
    title: id,
    categoryId: 'study',
    repeatCadence: weekdays == null
        ? GoalRepeatCadence.off
        : GoalRepeatCadence.weekly,
    scheduledWeekdays: weekdays,
    status: status,
    measurementKind: MeasurementKind.sessions,
    targetValue: 1,
    intensity: 3,
    periodStartMs: DateTime(2026, 8, 1).millisecondsSinceEpoch,
    periodEndMs: DateTime(2026, 10, 31).millisecondsSinceEpoch,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

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

  test('reflection observations never enter the delivery surfaces — '
      'radar-only (P1-08)', () async {
    final today = DateKeys.todayKey();
    final repo = _FakeInsightCacheRepository(<GeneratedInsight>[
      _insight(
        id: 'reflection-1',
        scopeType: InsightScopeType.entity,
        scopeId: 'reflection',
        detectedAtMs: 100,
        insightType: InsightType.reflectionObservation,
        sourceWindowStartDateKey: today,
        sourceWindowEndDateKey: today,
      ),
      _insight(
        id: 'deterministic-1',
        scopeType: InsightScopeType.entity,
        scopeId: 'task-1',
        detectedAtMs: 100,
        sourceWindowStartDateKey: today,
        sourceWindowEndDateKey: today,
      ),
    ]);

    final delivery = await loadLayer3DeliveryInsightsForDay(repo, today);
    expect(
      delivery.map((i) => i.insightId),
      ['deterministic-1'],
      reason: 'reflection observations are radar-only',
    );

    // The radar row reads the reflection entity scope directly — the
    // observation must still be visible there.
    final container = ProviderContainer(
      overrides: <Override>[
        insightCacheRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    final radar = await container.read(
      layer3EntityInsightsProvider('reflection').future,
    );
    expect(radar.map((i) => i.insightId), ['reflection-1']);
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
  test('goal insights show only on days the goal is available '
      '(2026-09-15)', () async {
    // 2026-09-13 is a Sunday, 2026-09-14 a Monday.
    const sunday = '2026-09-13';
    const monday = '2026-09-14';
    final goals = _GoalsRepo({
      'weekdays': _goal(id: 'weekdays', weekdays: const [1, 2, 3, 4, 5]),
      'passive': _goal(id: 'passive'),
      'paused': _goal(id: 'paused', status: GoalStatus.paused),
    });
    final repo = _FakeInsightCacheRepository(<GeneratedInsight>[
      for (final scope in ['weekdays', 'passive', 'paused', 'task-1'])
        _insight(
          id: 'i-$scope',
          scopeType: InsightScopeType.entity,
          scopeId: scope,
          detectedAtMs: 100,
          sourceWindowStartDateKey: '2026-09-01',
          sourceWindowEndDateKey: '2026-09-30',
        ),
    ]);

    final onSunday = await loadLayer3DeliveryInsightsForDay(
      repo,
      sunday,
      goalsRepository: goals,
    );
    expect(
      onSunday.map((i) => i.insightId).toSet(),
      {'i-passive', 'i-task-1'},
      reason: 'a Mon–Fri goal is not coached on Sunday; paused never',
    );

    final onMonday = await loadLayer3DeliveryInsightsForDay(
      repo,
      monday,
      goalsRepository: goals,
    );
    expect(onMonday.map((i) => i.insightId).toSet(), {
      'i-weekdays',
      'i-passive',
      'i-task-1',
    });

    // No repository → no filtering (legacy callers / lookups unavailable).
    final unfiltered = await loadLayer3DeliveryInsightsForDay(repo, sunday);
    expect(unfiltered, hasLength(4));
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
  InsightType insightType = InsightType.streakRiskWarning,
}) {
  return GeneratedInsight(
    insightId: id,
    scopeType: scopeType,
    scopeId: scopeId,
    insightType: insightType,
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
