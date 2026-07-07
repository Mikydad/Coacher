import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../data/feature_cache_repository.dart';
import '../data/pattern_detection_repository.dart';
import '../domain/models/behavior_feature_object.dart';
import '../domain/models/detected_behavior_pattern.dart';
import '../domain/models/detected_pattern.dart';
import 'behavior_pattern_phase2.dart';
import 'pattern_aggregate_builder.dart';
import 'pattern_detection_debug.dart';
import 'pattern_detection_engine.dart';
import 'pattern_detection_pipeline.dart';

class PatternDetectionBatchResult {
  const PatternDetectionBatchResult({
    required this.entityResults,
    required this.snapshot,
    required this.canonicalSnapshot,
    required this.metadata,
    required this.canonicalMetadata,
  });

  final List<EntityPatternDetectionResult> entityResults;
  final GlobalPatternSnapshot snapshot;
  final GlobalBehaviorPatternSnapshot canonicalSnapshot;
  final PatternAggregateRunMetadata metadata;
  final BehaviorPatternPhase2AggregateRunMetadata canonicalMetadata;
}

class PatternDetectionOrchestrator {
  PatternDetectionOrchestrator({
    required FeatureCacheRepository featureCacheRepository,
    required PatternDetectionRepository patternRepository,
    required PatternDetectionDebugStore debugStore,
  }) : _featureCacheRepository = featureCacheRepository,
       _patternRepository = patternRepository,
       _debugStore = debugStore;

  final FeatureCacheRepository _featureCacheRepository;
  final PatternDetectionRepository _patternRepository;
  final PatternDetectionDebugStore _debugStore;
  final Map<String, String> _lastEntityFingerprintById = <String, String>{};
  final Map<String, String> _lastBatchFingerprintByDate = <String, String>{};

  Future<PatternDetectionBatchResult> runBatch({
    DateTime? now,
    bool persist = true,
  }) async {
    final ts = now ?? DateTime.now();
    final stopwatch = Stopwatch()..start();
    final features = await _featureCacheRepository.listAll();
    final dateKey = DateKeys.todayKey(ts);
    final batchFingerprint = _buildBatchFingerprint(features);
    final previousFingerprint = _lastBatchFingerprintByDate[dateKey];
    if (persist && previousFingerprint == batchFingerprint) {
      final existing = await _patternRepository.readGlobalSnapshot(
        dateKey: dateKey,
      );
      if (existing != null) {
        // Still compute per-entity results for downstream (Layer 3). Skipping
        // persistence must not yield an empty entityResults list — that blocked
        // insight regeneration when batch input was unchanged.
        final entityResults = _detectAllEntities(features, ts);
        stopwatch.stop();
        _debugStore.record(
          PatternDetectionDebugEvent(
            scope: PatternDetectionRunScope.batch,
            dateKey: dateKey,
            startedAtMs: ts.millisecondsSinceEpoch,
            elapsedMs: stopwatch.elapsedMilliseconds,
            entitiesProcessed: features.length,
            patternsEmitted: existing.totalPatternsEmitted,
            ruleErrors: 0,
            skippedUnchanged: true,
            success: true,
            note: 'batch_skipped_unchanged_input',
          ),
        );
        final storedCanonical = await _patternRepository
            .readGlobalBehaviorSnapshot(dateKey: dateKey);
        BehaviorPatternPhase2AggregateBuildResult? builtCanonical;
        if (storedCanonical == null) {
          builtCanonical = _buildCanonicalAggregate(
            dateKey: dateKey,
            entityResults: entityResults,
            entitiesProcessed: features.length,
            elapsedMs: stopwatch.elapsedMilliseconds,
            detectedAtMs: ts.millisecondsSinceEpoch,
          );
        }
        final canonicalSnapshot = storedCanonical ?? builtCanonical!.snapshot;
        final canonicalMetadata = storedCanonical != null
            ? _canonicalMetaFromSnapshot(
                storedCanonical,
                stopwatch.elapsedMilliseconds,
              )
            : builtCanonical!.metadata;
        return PatternDetectionBatchResult(
          entityResults: entityResults,
          snapshot: existing,
          canonicalSnapshot: canonicalSnapshot,
          metadata: PatternAggregateRunMetadata(
            entitiesProcessed: existing.totalEntitiesProcessed,
            patternsEmitted: existing.totalPatternsEmitted,
            elapsedMs: stopwatch.elapsedMilliseconds,
            schemaVersion: existing.schemaVersion,
          ),
          canonicalMetadata: canonicalMetadata,
        );
      }
    }

    final entityResults = _detectAllEntities(features, ts);
    final allPatterns = <DetectedPattern>[];
    var ruleErrors = 0;
    for (final result in entityResults) {
      ruleErrors += result.diagnostics
          .where((d) => d.status == RuleEvaluationStatus.error)
          .length;
      allPatterns.addAll(result.patterns);
    }

    final aggregate = buildGlobalPatternSnapshot(
      dateKey: dateKey,
      patterns: allPatterns,
      entitiesProcessed: features.length,
      elapsedMs: stopwatch.elapsedMilliseconds,
      detectedAtMs: ts.millisecondsSinceEpoch,
    );
    final aggregateCanonical = _buildCanonicalAggregate(
      dateKey: dateKey,
      entityResults: entityResults,
      entitiesProcessed: features.length,
      elapsedMs: stopwatch.elapsedMilliseconds,
      detectedAtMs: ts.millisecondsSinceEpoch,
    );
    stopwatch.stop();

    if (persist) {
      for (final entityResult in entityResults) {
        await _patternRepository.upsertEntityPatterns(
          entityId: entityResult.entityId,
          dateKey: dateKey,
          patterns: entityResult.patterns,
          updatedAtMs: ts.millisecondsSinceEpoch,
        );
        await _patternRepository.upsertEntityBehaviorPatterns(
          entityId: entityResult.entityId,
          dateKey: dateKey,
          patterns: entityResult.behaviorPatterns,
          updatedAtMs: ts.millisecondsSinceEpoch,
        );
      }
      await _patternRepository.upsertGlobalSnapshot(aggregate.snapshot);
      await _patternRepository.upsertGlobalBehaviorSnapshot(
        aggregateCanonical.snapshot,
      );
      _lastBatchFingerprintByDate[dateKey] = batchFingerprint;
    }

    _debugStore.record(
      PatternDetectionDebugEvent(
        scope: PatternDetectionRunScope.batch,
        dateKey: dateKey,
        startedAtMs: ts.millisecondsSinceEpoch,
        elapsedMs: aggregate.metadata.elapsedMs,
        entitiesProcessed: aggregate.metadata.entitiesProcessed,
        patternsEmitted: aggregate.metadata.patternsEmitted,
        ruleErrors: ruleErrors,
        skippedUnchanged: false,
        success: true,
      ),
    );

    return PatternDetectionBatchResult(
      entityResults: entityResults,
      snapshot: aggregate.snapshot,
      canonicalSnapshot: aggregateCanonical.snapshot,
      metadata: aggregate.metadata,
      canonicalMetadata: aggregateCanonical.metadata,
    );
  }

  Future<EntityPatternDetectionResult?> runForEntity({
    required String entityId,
    DateTime? now,
    bool persist = true,
  }) async {
    final key = entityId.trim();
    if (key.isEmpty) return null;
    final feature = await _featureCacheRepository.getByEntityId(key);
    if (feature == null) return null;
    final ts = now ?? DateTime.now();
    final dateKey = DateKeys.todayKey(ts);
    final featureFingerprint = _buildFeatureFingerprint(feature);
    final previousFingerprint = _lastEntityFingerprintById[key];
    if (persist && previousFingerprint == featureFingerprint) {
      final existing = await _patternRepository.readEntityPatterns(
        entityId: key,
        dateKey: dateKey,
      );
      var behavior = await _patternRepository.readEntityBehaviorPatterns(
        entityId: key,
        dateKey: dateKey,
      );
      if (behavior.isEmpty && existing.isNotEmpty) {
        final ctx = PatternDetectionContext(
          detectedAtMs: ts.millisecondsSinceEpoch,
        );
        behavior = wrapDetectedPatternsWithEvidence(
          feature: feature,
          detected: detectPatternsForFeature(feature: feature, context: ctx),
          context: ctx,
        );
        if (persist) {
          await _patternRepository.upsertEntityBehaviorPatterns(
            entityId: key,
            dateKey: dateKey,
            patterns: behavior,
            updatedAtMs: ts.millisecondsSinceEpoch,
          );
        }
      }
      _debugStore.record(
        PatternDetectionDebugEvent(
          scope: PatternDetectionRunScope.entity,
          dateKey: dateKey,
          startedAtMs: ts.millisecondsSinceEpoch,
          elapsedMs: 0,
          entitiesProcessed: 1,
          patternsEmitted: existing.length,
          ruleErrors: 0,
          skippedUnchanged: true,
          success: true,
          entityId: key,
          note: 'entity_skipped_unchanged_input',
        ),
      );
      return EntityPatternDetectionResult(
        entityId: key,
        patterns: existing,
        behaviorPatterns: behavior,
        diagnostics: const <RuleEvaluationDiagnostic>[
          RuleEvaluationDiagnostic(
            ruleCode: PatternCode.streakRisk,
            status: RuleEvaluationStatus.skipped,
            reason: 'unchanged_input_skipped',
          ),
        ],
        hasFatalError: false,
      );
    }

    final stopwatch = Stopwatch()..start();
    final result = runPatternDetectionForEntity(
      feature: feature,
      context: PatternDetectionContext(detectedAtMs: ts.millisecondsSinceEpoch),
    );
    stopwatch.stop();
    if (persist) {
      await _patternRepository.upsertEntityPatterns(
        entityId: key,
        dateKey: dateKey,
        patterns: result.patterns,
        updatedAtMs: ts.millisecondsSinceEpoch,
      );
      await _patternRepository.upsertEntityBehaviorPatterns(
        entityId: key,
        dateKey: dateKey,
        patterns: result.behaviorPatterns,
        updatedAtMs: ts.millisecondsSinceEpoch,
      );
      _lastEntityFingerprintById[key] = featureFingerprint;
    }
    final ruleErrors = result.diagnostics
        .where((d) => d.status == RuleEvaluationStatus.error)
        .length;
    _debugStore.record(
      PatternDetectionDebugEvent(
        scope: PatternDetectionRunScope.entity,
        dateKey: dateKey,
        startedAtMs: ts.millisecondsSinceEpoch,
        elapsedMs: stopwatch.elapsedMilliseconds,
        entitiesProcessed: 1,
        patternsEmitted: result.patterns.length,
        ruleErrors: ruleErrors,
        skippedUnchanged: false,
        success: !result.hasFatalError,
        entityId: key,
      ),
    );
    return result;
  }

  List<EntityPatternDetectionResult> _detectAllEntities(
    List<BehaviorFeatureObject> features,
    DateTime ts,
  ) {
    final ms = ts.millisecondsSinceEpoch;
    final out = <EntityPatternDetectionResult>[];
    for (final feature in features) {
      out.add(
        runPatternDetectionForEntity(
          feature: feature,
          context: PatternDetectionContext(detectedAtMs: ms),
        ),
      );
    }
    return out;
  }

  BehaviorPatternPhase2AggregateBuildResult _buildCanonicalAggregate({
    required String dateKey,
    required List<EntityPatternDetectionResult> entityResults,
    required int entitiesProcessed,
    required int elapsedMs,
    required int detectedAtMs,
  }) {
    final flat = <DetectedBehaviorPattern>[
      for (final r in entityResults) ...r.behaviorPatterns,
    ];
    return buildGlobalBehaviorPatternSnapshot(
      dateKey: dateKey,
      patterns: flat,
      entitiesProcessed: entitiesProcessed,
      elapsedMs: elapsedMs,
      detectedAtMs: detectedAtMs,
    );
  }

  BehaviorPatternPhase2AggregateRunMetadata _canonicalMetaFromSnapshot(
    GlobalBehaviorPatternSnapshot snapshot,
    int elapsedMs,
  ) {
    return BehaviorPatternPhase2AggregateRunMetadata(
      entitiesProcessed: snapshot.totalEntitiesProcessed,
      patternsEmitted: snapshot.totalPatternsEmitted,
      elapsedMs: elapsedMs < 0 ? 0 : elapsedMs,
      schemaVersion: snapshot.schemaVersion,
    );
  }
}

final patternDetectionRepositoryProvider = Provider<PatternDetectionRepository>(
  (ref) {
    return StatsBackedPatternDetectionRepository(
      ref.read(analyticsRepositoryProvider),
    );
  },
);

final patternDetectionOrchestratorProvider =
    Provider<PatternDetectionOrchestrator>((ref) {
      return PatternDetectionOrchestrator(
        featureCacheRepository: ref.read(featureCacheRepositoryProvider),
        patternRepository: ref.read(patternDetectionRepositoryProvider),
        debugStore: ref.read(patternDetectionDebugStoreProvider),
      );
    });

String _buildFeatureFingerprint(BehaviorFeatureObject feature) {
  return jsonEncode(feature.toMap());
}

String _buildBatchFingerprint(List<BehaviorFeatureObject> features) {
  final sorted = List<BehaviorFeatureObject>.from(features)
    ..sort((a, b) => a.entityId.compareTo(b.entityId));
  final payload = sorted.map((f) => f.toMap()).toList();
  return jsonEncode(payload);
}
