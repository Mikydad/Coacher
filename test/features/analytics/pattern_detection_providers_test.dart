import 'package:sidepal/features/analytics/application/pattern_detection_orchestrator.dart';
import 'package:sidepal/features/analytics/application/pattern_detection_providers.dart';
import 'package:sidepal/features/analytics/data/pattern_detection_repository.dart';
import 'package:sidepal/features/analytics/domain/models/behavior_feature_object.dart';
import 'package:sidepal/features/analytics/domain/models/detected_behavior_pattern.dart';
import 'package:sidepal/features/analytics/domain/models/detected_pattern.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePatternRepo implements PatternDetectionRepository {
  _FakePatternRepo({required this.entityPatterns, required this.snapshot});

  final List<DetectedPattern> entityPatterns;
  final GlobalPatternSnapshot? snapshot;

  @override
  Future<List<DetectedPattern>> readEntityPatterns({
    required String entityId,
    required String dateKey,
  }) async => entityPatterns;

  @override
  Future<GlobalPatternSnapshot?> readGlobalSnapshot({
    required String dateKey,
  }) async => snapshot;

  @override
  Future<void> upsertEntityPatterns({
    required String entityId,
    required String dateKey,
    required List<DetectedPattern> patterns,
    required int updatedAtMs,
  }) async {}

  @override
  Future<void> upsertEntityBehaviorPatterns({
    required String entityId,
    required String dateKey,
    required List<DetectedBehaviorPattern> patterns,
    required int updatedAtMs,
  }) async {}

  @override
  Future<List<DetectedBehaviorPattern>> readEntityBehaviorPatterns({
    required String entityId,
    required String dateKey,
  }) async => const [];

  @override
  Future<void> upsertGlobalBehaviorSnapshot(
    GlobalBehaviorPatternSnapshot snapshot,
  ) async {}

  @override
  Future<GlobalBehaviorPatternSnapshot?> readGlobalBehaviorSnapshot({
    required String dateKey,
  }) async => null;

  @override
  Future<void> upsertGlobalSnapshot(GlobalPatternSnapshot snapshot) async {}
}

void main() {
  test('providers return entity patterns and run metadata', () async {
    final repo = _FakePatternRepo(
      entityPatterns: const [
        DetectedPattern(
          entityId: 'a',
          entityKind: BehaviorEntityKind.habit,
          patternCode: PatternCode.streakRisk,
          patternGroup: PatternGroup.streakConsistency,
          severity: 0.9,
          confidence: 1.0,
          detectedAtMs: 1,
          sourceWindowStartDateKey: '2026-05-01',
          sourceWindowEndDateKey: '2026-05-07',
        ),
      ],
      snapshot: const GlobalPatternSnapshot(
        dateKey: '2026-05-07',
        entries: [
          GlobalPatternAggregateEntry(
            patternCode: PatternCode.streakRisk,
            patternGroup: PatternGroup.streakConsistency,
            entityCount: 1,
            occurrenceCount: 1,
            averageSeverity: 0.9,
            maxSeverity: 0.9,
            averageConfidence: 1.0,
          ),
        ],
        totalEntitiesProcessed: 1,
        totalPatternsEmitted: 1,
        weightedAverageSeverity: 0.9,
        detectedAtMs: 1,
      ),
    );

    final container = ProviderContainer(
      overrides: [patternDetectionRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final entityAsync = await container.read(
      layer2EntityPatternsProvider(
        const Layer2EntityPatternsQuery(entityId: 'a', dateKey: '2026-05-07'),
      ).future,
    );
    expect(entityAsync.length, 1);
    expect(entityAsync.single.patternCode, PatternCode.streakRisk);

    final meta = await container.read(
      layer2RunMetadataProvider('2026-05-07').future,
    );
    expect(meta.entitiesProcessed, 1);
    expect(meta.patternsEmitted, 1);
    expect(meta.schemaVersion, kGlobalPatternSnapshotSchemaVersion);
  });
}
