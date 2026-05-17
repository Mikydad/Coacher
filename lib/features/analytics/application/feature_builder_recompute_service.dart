import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../data/feature_cache_repository.dart';
import '../domain/models/analytics_event.dart';
import 'feature_builder_orchestrator.dart';
import 'pattern_detection_recompute_service.dart';

class FeatureBuilderRecomputeService {
  FeatureBuilderRecomputeService({
    required FeatureBuilderOrchestrator orchestrator,
    required FeatureCacheRepository cacheRepository,
    this.onFeatureComputed,
    Duration debounce = const Duration(seconds: 2),
  }) : _orchestrator = orchestrator,
       _cacheRepository = cacheRepository,
       _debounce = debounce;

  final FeatureBuilderOrchestrator _orchestrator;
  final FeatureCacheRepository _cacheRepository;
  final OnFeatureComputedCallback? onFeatureComputed;
  final Duration _debounce;

  final Map<String, int> _lastEntityRecomputeAtMs = <String, int>{};
  String? _lastDailyRefreshDateKey;

  Future<void> onAnalyticsEventLogged(AnalyticsEvent event) async {
    final entityId = event.entityId.trim();
    if (entityId.isEmpty) return;
    await recomputeTouchedEntity(entityId: entityId);
    await maybeRunDailyFullRefresh(now: DateTime.now());
  }

  Future<bool> recomputeTouchedEntity({
    required String entityId,
    DateTime? now,
  }) async {
    final key = entityId.trim();
    if (key.isEmpty) return false;
    final ts = now ?? DateTime.now();
    final last = _lastEntityRecomputeAtMs[key];
    if (last != null &&
        ts.millisecondsSinceEpoch - last < _debounce.inMilliseconds) {
      return false;
    }
    _lastEntityRecomputeAtMs[key] = ts.millisecondsSinceEpoch;
    try {
      final entityResult = await _orchestrator.runForEntity(
        entityId: key,
        now: ts,
      );
      if (entityResult == null) return false;
      await _cacheRepository.upsertFeature(entityResult.feature);
      await onFeatureComputed?.call(entityId: key, now: ts, fullRefresh: false);
      return true;
    } catch (_) {
      // Never block user flows due to background recompute failures.
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
      final batch = await _orchestrator.runBatch(now: ts);
      await _cacheRepository.upsertFeatures(
        batch.assembly.featuresByEntityId.values.toList(),
      );
      await onFeatureComputed?.call(entityId: '*', now: ts, fullRefresh: true);
      _lastDailyRefreshDateKey = dateKey;
      return true;
    } catch (_) {
      // Keep experience resilient; daily refresh retries on next opportunity.
      return false;
    }
  }
}

final featureBuilderRecomputeServiceProvider =
    Provider<FeatureBuilderRecomputeService>((ref) {
      final layer2 = ref.read(patternDetectionRecomputeServiceProvider);
      return FeatureBuilderRecomputeService(
        orchestrator: ref.read(featureBuilderOrchestratorProvider),
        cacheRepository: ref.read(featureCacheRepositoryProvider),
        onFeatureComputed:
            ({
              required String entityId,
              required DateTime now,
              required bool fullRefresh,
            }) async {
              if (fullRefresh) {
                await layer2.maybeRunDailyFullRefresh(now: now);
                return;
              }
              await layer2.recomputeTouchedEntity(entityId: entityId, now: now);
            },
      );
    });

typedef OnFeatureComputedCallback =
    Future<void> Function({
      required String entityId,
      required DateTime now,
      required bool fullRefresh,
    });
