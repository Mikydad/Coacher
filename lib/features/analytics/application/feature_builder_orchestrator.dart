import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/models/behavior_feature_object.dart';
import 'feature_builder_assembler.dart';
import 'feature_builder_input_adapters.dart';

class FeatureBatchTelemetry {
  const FeatureBatchTelemetry({
    required this.startedAtMs,
    required this.elapsedMs,
    required this.totalEntities,
    required this.successCount,
    required this.failureCount,
  });

  final int startedAtMs;
  final int elapsedMs;
  final int totalEntities;
  final int successCount;
  final int failureCount;
}

class FeatureBatchResult {
  const FeatureBatchResult({required this.assembly, required this.telemetry});

  final FeatureAssemblyResult assembly;
  final FeatureBatchTelemetry telemetry;
}

class FeatureEntityResult {
  const FeatureEntityResult({
    required this.entityId,
    required this.feature,
    required this.telemetry,
  });

  final String entityId;
  final BehaviorFeatureObject feature;
  final FeatureBatchTelemetry telemetry;
}

class FeatureBuilderOrchestrator {
  const FeatureBuilderOrchestrator({
    required FeatureBuilderInputAdapters adapters,
    FeatureBuilderAssembler assembler = const FeatureBuilderAssembler(),
  }) : _adapters = adapters,
       _assembler = assembler;

  final FeatureBuilderInputAdapters _adapters;
  final FeatureBuilderAssembler _assembler;

  Future<FeatureBatchResult> runBatch({
    int trailingDays = 30,
    DateTime? now,
  }) async {
    final stopwatch = Stopwatch()..start();
    final startedAtMs = DateTime.now().millisecondsSinceEpoch;
    final bundle = await _adapters.load(now: now, trailingDays: trailingDays);
    final assembly = _assembler.assemble(inputs: bundle, now: now);
    stopwatch.stop();
    final totalEntities =
        bundle.taskSeedsById.length + bundle.goalSeedsById.length;
    final successCount = assembly.featuresByEntityId.length;
    final failureCount = (totalEntities - successCount) < 0
        ? 0
        : totalEntities - successCount;
    return FeatureBatchResult(
      assembly: assembly,
      telemetry: FeatureBatchTelemetry(
        startedAtMs: startedAtMs,
        elapsedMs: stopwatch.elapsedMilliseconds,
        totalEntities: totalEntities,
        successCount: successCount,
        failureCount: failureCount,
      ),
    );
  }

  Future<FeatureEntityResult?> runForEntity({
    required String entityId,
    int trailingDays = 30,
    DateTime? now,
  }) async {
    final key = entityId.trim();
    if (key.isEmpty) return null;
    final batch = await runBatch(trailingDays: trailingDays, now: now);
    final feature = batch.assembly.featuresByEntityId[key];
    if (feature == null) return null;
    return FeatureEntityResult(
      entityId: key,
      feature: feature,
      telemetry: batch.telemetry,
    );
  }
}

final featureBuilderAssemblerProvider = Provider<FeatureBuilderAssembler>((
  ref,
) {
  return const FeatureBuilderAssembler();
});

final featureBuilderOrchestratorProvider = Provider<FeatureBuilderOrchestrator>(
  (ref) {
    return FeatureBuilderOrchestrator(
      adapters: ref.read(featureBuilderInputAdaptersProvider),
      assembler: ref.read(featureBuilderAssemblerProvider),
    );
  },
);
