import 'package:sidepal/features/analytics/application/pattern_detection_pipeline.dart';
import 'package:sidepal/features/analytics/application/pattern_layer2_compatibility.dart';
import 'package:sidepal/features/analytics/data/analytics_repository.dart';
import 'package:sidepal/features/analytics/data/pattern_detection_repository.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_event.dart';
import 'package:sidepal/features/analytics/domain/models/analytics_stats_cache.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:sidepal/features/analytics/domain/models/detected_behavior_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/detected_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/pattern_taxonomy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/behavior_time_metrics_fixture.dart';

class _MemoryAnalyticsRepository implements AnalyticsRepository {
  final Map<String, AnalyticsStatsCache> _stats = {};

  @override
  Future<void> hydrateRemoteEvents({List<String>? entityIds}) async {}

  @override
  Future<void> hydrateRemoteStatsCache({List<String>? scopeIds}) async {}

  @override
  Future<List<AnalyticsEvent>> listEvents({
    String? entityId,
    String? dateKey,
    int? fromUpdatedAtMs,
    int? toUpdatedAtMs,
  }) async => const <AnalyticsEvent>[];

  @override
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  }) async {
    return _stats.values.where((s) {
      if (scopeType != null &&
          scopeType.isNotEmpty &&
          s.scopeType != scopeType) {
        return false;
      }
      if (scopeId != null && scopeId.isNotEmpty && s.scopeId != scopeId) {
        return false;
      }
      if (dateKey != null && dateKey.isNotEmpty && s.dateKey != dateKey) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<void> logEvent(AnalyticsEvent event) async {}

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {
    _stats[stats.id] = stats;
  }
}

void main() {
  group('pattern_layer2_canonical_migration', () {
    test('canonical stats persistence roundtrips through repository', () async {
      final analytics = _MemoryAnalyticsRepository();
      final repo = StatsBackedPatternDetectionRepository(analytics);
      final p = DetectedBehaviorPattern(
        entityId: 'e1',
        entityKind: BehaviorEntityKind.habit,
        patternCode: PatternCode.streakRisk,
        patternGroup: PatternGroup.streakConsistency,
        taxonomyFamily: PatternTaxonomyFamily.streakConsistency,
        severity: 0.7,
        confidence: 0.8,
        detectedAtMs: 42,
        sourceWindowStartDateKey: '2026-05-01',
        sourceWindowEndDateKey: '2026-05-07',
        evidence: const [
          PatternMetricEvidence(metricPath: 'x', valueSerialized: '1'),
        ],
      );
      await repo.upsertEntityBehaviorPatterns(
        entityId: 'e1',
        dateKey: '2026-05-07',
        patterns: [p],
        updatedAtMs: 100,
      );
      final back = await repo.readEntityBehaviorPatterns(
        entityId: 'e1',
        dateKey: '2026-05-07',
      );
      expect(back, hasLength(1));
      expect(back.single.patternCode, PatternCode.streakRisk);
      expect(back.single.evidence.single.metricPath, 'x');
      final global = GlobalBehaviorPatternSnapshot(
        dateKey: '2026-05-07',
        entries: const [],
        totalEntitiesProcessed: 1,
        totalPatternsEmitted: 0,
        weightedAverageSeverity: 0,
        detectedAtMs: 200,
      );
      await repo.upsertGlobalBehaviorSnapshot(global);
      final g = await repo.readGlobalBehaviorSnapshot(dateKey: '2026-05-07');
      expect(g!.dateKey, '2026-05-07');
      expect(g.totalEntitiesProcessed, 1);
    });

    test('compat adapter roundtrips codes/severity from pipeline canonical rows', () {
      final feature = BehaviorFeatureObject(
        entityId: 'habit-1',
        entityKind: BehaviorEntityKind.habit,
        timeMetrics: testBehaviorTimeMetrics(
          scheduledOccurrences7d: 7,
          completionRate7d: 0.35,
          lateCompletionRate7d: 0.75,
          avgCompletionDelayMinutes: 30,
        ),
        streakMetrics: const BehaviorStreakMetrics(
          currentStreak: 0,
          longestStreak: 3,
          missedLast2Days: true,
          missedCount7d: 4,
        ),
        effortMetrics: const BehaviorEffortMetrics(
          avgSnoozeCount: 0.2,
          avgSessionDuration: 10,
          plannedVsActualRatio: 1,
        ),
        goalMetrics: const BehaviorGoalMetrics(
          progress: 0.5,
          expectedProgress: 0.5,
          gap: 0,
        ),
        contextFeatures: const BehaviorContextFeatures(
          bestTimeBlock: 'morning',
          isHabitAnchor: true,
          priority: 2,
        ),
        computedAtMs: 1,
        windowStartDateKey: '2026-05-01',
        windowEndDateKey: '2026-05-07',
      );
      final out = runPatternDetectionForEntity(feature: feature);
      expect(out.patterns.length, out.behaviorPatterns.length);
      for (var i = 0; i < out.patterns.length; i++) {
        final leg = out.patterns[i];
        final can = out.behaviorPatterns[i];
        expect(leg.patternCode, can.patternCode);
        expect(leg.severity, closeTo(can.severity, 0.00001));
        expect(leg.confidence, closeTo(can.confidence, 0.00001));
        final round = detectedPatternFromCanonical(can);
        expect(round.patternCode, leg.patternCode);
        expect(round.metadata['layer2Canonical'], true);
      }
    });
  });
}
