import 'package:coach_for_life/features/analytics/application/data_maturity.dart';
import 'package:coach_for_life/features/analytics/application/insight_generation_recompute_service.dart';
import 'package:coach_for_life/features/analytics/data/analytics_repository.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_event.dart';
import 'package:coach_for_life/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:coach_for_life/features/analytics/domain/models/generated_insight.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryAnalyticsRepository implements AnalyticsRepository {
  _MemoryAnalyticsRepository(this._events);

  final List<AnalyticsEvent> _events;

  @override
  Future<List<AnalyticsEvent>> listEvents({
    String? entityId,
    String? dateKey,
    int? fromUpdatedAtMs,
    int? toUpdatedAtMs,
  }) async => _events;

  @override
  Future<void> hydrateRemoteEvents({List<String>? entityIds}) async {}

  @override
  Future<void> hydrateRemoteStatsCache({List<String>? scopeIds}) async {}

  @override
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  }) async => const [];

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {}
}

AnalyticsEvent _event({
  required String entityId,
  required String dateKey,
  int index = 0,
}) {
  return AnalyticsEvent(
    id: '$entityId-$dateKey-$index',
    type: AnalyticsEventType.taskCompleted,
    entityId: entityId,
    entityKind: 'task',
    dateKey: dateKey,
    timestampLocalIso: '${dateKey}T09:00:00',
    sourceSurface: 'test',
    idempotencyKey: '$entityId-$dateKey-$index',
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

/// [dayEvents] = events per dateKey (day 1 = 2026-07-01, day 2 = 07-02, …).
List<AnalyticsEvent> _entityDays(String entityId, List<int> dayEvents) {
  final out = <AnalyticsEvent>[];
  for (var day = 0; day < dayEvents.length; day++) {
    final dateKey = '2026-07-${(day + 1).toString().padLeft(2, '0')}';
    for (var i = 0; i < dayEvents[day]; i++) {
      out.add(_event(entityId: entityId, dateKey: dateKey, index: i));
    }
  }
  return out;
}

Future<DataMaturitySnapshot> _evaluate(List<AnalyticsEvent> events) {
  return DataMaturityEvaluator(
    analyticsRepository: _MemoryAnalyticsRepository(events),
  ).evaluate();
}

GeneratedInsight _insight({
  InsightType type = InsightType.streakRiskWarning,
  double confidence = 0.8,
}) {
  return GeneratedInsight(
    insightId: 'i-${type.name}',
    scopeType: InsightScopeType.entity,
    scopeId: 'habit-1',
    insightType: type,
    insightBucket: InsightBucket.risk,
    priority: InsightPriority.high,
    messageKey: 'k',
    message: 'm',
    action: InsightAction.doNow,
    linkedPatternCodes: const ['streakRisk'],
    confidence: confidence,
    detectedAtMs: 0,
    sourceWindowStartDateKey: '2026-07-01',
    sourceWindowEndDateKey: '2026-07-07',
  );
}

void main() {
  group('DataMaturityEvaluator — entity staging (3 days / 5 events)', () {
    test('no events at all → observing everywhere', () async {
      final snapshot = await _evaluate(const []);
      expect(snapshot.global.stage, DataMaturityStage.observing);
      expect(snapshot.forEntity('anything').stage, DataMaturityStage.observing);
    });

    test('day-one burst (5 events, 1 day) stays observing', () async {
      final snapshot = await _evaluate(_entityDays('h', [5]));
      expect(snapshot.forEntity('h').stage, DataMaturityStage.observing);
    });

    test('3 active days but only 4 events stays observing', () async {
      final snapshot = await _evaluate(_entityDays('h', [2, 1, 1]));
      expect(snapshot.forEntity('h').stage, DataMaturityStage.observing);
    });

    test('3 active days and 5 events reaches calibrating', () async {
      final snapshot = await _evaluate(_entityDays('h', [2, 2, 1]));
      expect(snapshot.forEntity('h').stage, DataMaturityStage.calibrating);
    });

    test('7 active days reaches established', () async {
      final snapshot = await _evaluate(_entityDays('h', [1, 1, 1, 1, 1, 1, 1]));
      expect(snapshot.forEntity('h').stage, DataMaturityStage.established);
    });
  });

  group('DataMaturityEvaluator — global staging (5 active days)', () {
    test('4 active days across entities is not established', () async {
      final snapshot = await _evaluate([
        ..._entityDays('a', [1, 1]),
        // Same first two days plus days 3-4 from another entity.
        ..._entityDays('b', [1, 1, 1, 1]),
      ]);
      expect(snapshot.global.stage, DataMaturityStage.calibrating);
      expect(snapshot.global.activeDaysObserved, 4);
      expect(snapshot.global.isEstablished, isFalse);
    });

    test('5 distinct active days is established', () async {
      final snapshot = await _evaluate(_entityDays('a', [1, 1, 1, 1, 1]));
      expect(snapshot.global.stage, DataMaturityStage.established);
      expect(snapshot.global.isEstablished, isTrue);
    });
  });

  group('gateInsightsByMaturity', () {
    const observing = EntityDataMaturity(
      stage: DataMaturityStage.observing,
      distinctActiveDays: 1,
      eventCount: 2,
    );
    const calibrating = EntityDataMaturity(
      stage: DataMaturityStage.calibrating,
      distinctActiveDays: 4,
      eventCount: 9,
    );
    const established = EntityDataMaturity(
      stage: DataMaturityStage.established,
      distinctActiveDays: 9,
      eventCount: 30,
    );

    test('null maturity (ungated) passes everything through untouched', () {
      final insights = [_insight()];
      final out = gateInsightsByMaturity(insights: insights, maturity: null);
      expect(out, same(insights));
    });

    test('observing produces nothing — day-one praise cannot leak', () {
      final out = gateInsightsByMaturity(
        insights: [
          _insight(type: InsightType.consistentBehaviorPraise),
          _insight(type: InsightType.streakRiskWarning),
        ],
        maturity: observing,
      );
      expect(out, isEmpty);
    });

    test('calibrating keeps only high-evidence risk types', () {
      final out = gateInsightsByMaturity(
        insights: [
          _insight(type: InsightType.streakRiskWarning),
          _insight(type: InsightType.consistentBehaviorPraise),
          _insight(type: InsightType.strongStreakPraise),
          _insight(type: InsightType.highestMomentumLeverage),
          _insight(type: InsightType.goalAtRisk),
        ],
        maturity: calibrating,
      );
      expect(out.map((i) => i.insightType), [
        InsightType.streakRiskWarning,
        InsightType.goalAtRisk,
      ]);
    });

    test('calibrating drops allowed types below the confidence floor', () {
      final out = gateInsightsByMaturity(
        insights: [
          _insight(type: InsightType.streakRiskWarning, confidence: 0.4),
        ],
        maturity: calibrating,
      );
      expect(out, isEmpty);
    });

    test('surviving insights carry the dataMaturity stamp', () {
      final calibrated = gateInsightsByMaturity(
        insights: [_insight()],
        maturity: calibrating,
      );
      expect(
        calibrated.single.supportingMetrics['dataMaturity'],
        'calibrating',
      );

      final establishedOut = gateInsightsByMaturity(
        insights: [_insight(type: InsightType.consistentBehaviorPraise)],
        maturity: established,
      );
      expect(
        establishedOut.single.supportingMetrics['dataMaturity'],
        'established',
      );
      // Established passes every type.
      expect(
        establishedOut.single.insightType,
        InsightType.consistentBehaviorPraise,
      );
    });
  });
}
