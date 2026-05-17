import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../domain/models/analytics_event.dart';
import '../domain/models/detected_pattern.dart';
import 'insight_generation_recompute_service.dart';
import 'pattern_detection_orchestrator.dart';
import 'pattern_detection_pipeline.dart';

class PatternDetectionRecomputeService {
  PatternDetectionRecomputeService({
    required PatternDetectionOrchestrator orchestrator,
    this.onPatternsComputed,
    Duration debounce = const Duration(seconds: 2),
  }) : _orchestrator = orchestrator,
       _debounce = debounce;

  final PatternDetectionOrchestrator _orchestrator;
  final OnPatternsComputedCallback? onPatternsComputed;
  final Duration _debounce;
  final Map<String, int> _lastEntityRunAtMs = <String, int>{};
  String? _lastDailyRefreshDateKey;

  Future<void> onAnalyticsEventLogged(AnalyticsEvent event) async {
    final entityId = event.entityId.trim();
    if (entityId.isEmpty) return;
    await recomputeTouchedEntity(entityId: entityId);
    await maybeRunDailyFullRefresh();
  }

  Future<bool> recomputeTouchedEntity({
    required String entityId,
    DateTime? now,
  }) async {
    final key = entityId.trim();
    if (key.isEmpty) return false;
    final ts = now ?? DateTime.now();
    final last = _lastEntityRunAtMs[key];
    if (last != null &&
        ts.millisecondsSinceEpoch - last < _debounce.inMilliseconds) {
      return false;
    }
    _lastEntityRunAtMs[key] = ts.millisecondsSinceEpoch;
    try {
      final out = await _orchestrator.runForEntity(entityId: key, now: ts);
      if (out == null) return false;
      await onPatternsComputed?.call(
        dateKey: DateKeys.todayKey(ts),
        now: ts,
        fullRefresh: false,
        entityId: key,
        entityResult: out,
        batchResult: null,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> maybeRunDailyFullRefresh({DateTime? now}) async {
    final ts = now ?? DateTime.now();
    final dateKey = DateKeys.todayKey(ts);
    if (_lastDailyRefreshDateKey == dateKey) return false;
    return _runDailyFullRefresh(ts);
  }

  Future<bool> forceRunDailyFullRefresh({DateTime? now}) async {
    final ts = now ?? DateTime.now();
    return _runDailyFullRefresh(ts);
  }

  Future<bool> _runDailyFullRefresh(DateTime ts) async {
    final dateKey = DateKeys.todayKey(ts);
    try {
      final out = await _orchestrator.runBatch(now: ts);
      await onPatternsComputed?.call(
        dateKey: dateKey,
        now: ts,
        fullRefresh: true,
        entityId: '*',
        entityResult: null,
        batchResult: out,
      );
      _lastDailyRefreshDateKey = dateKey;
      return true;
    } catch (_) {
      return false;
    }
  }
}

final patternDetectionRecomputeServiceProvider =
    Provider<PatternDetectionRecomputeService>((ref) {
      final layer3 = ref.read(insightGenerationRecomputeServiceProvider);
      return PatternDetectionRecomputeService(
        orchestrator: ref.read(patternDetectionOrchestratorProvider),
        onPatternsComputed:
            ({
              required String dateKey,
              required DateTime now,
              required bool fullRefresh,
              required String entityId,
              required EntityPatternDetectionResult? entityResult,
              required PatternDetectionBatchResult? batchResult,
            }) async {
              if (fullRefresh) {
                final batch = batchResult;
                if (batch == null) return;
                final patternsByEntityId = <String, List<DetectedPattern>>{
                  for (final item in batch.entityResults)
                    item.entityId: item.patterns,
                };
                await layer3.recomputeBatch(
                  dateKey: dateKey,
                  patternsByEntityId: patternsByEntityId,
                  now: now,
                );
                return;
              }
              final result = entityResult;
              if (result == null) return;
              await layer3.recomputeEntity(
                entityId: entityId,
                patterns: result.patterns,
                now: now,
              );
            },
      );
    });

typedef OnPatternsComputedCallback =
    Future<void> Function({
      required String dateKey,
      required DateTime now,
      required bool fullRefresh,
      required String entityId,
      required EntityPatternDetectionResult? entityResult,
      required PatternDetectionBatchResult? batchResult,
    });
