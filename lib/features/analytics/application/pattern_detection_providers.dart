import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/local_db/isar_collections/isar_analytics_stats.dart';
import '../../../core/utils/date_keys.dart';
import '../domain/models/detected_behavior_pattern.dart';
import '../domain/models/detected_pattern.dart';
import 'pattern_detection_orchestrator.dart';

class Layer2EntityPatternsQuery {
  const Layer2EntityPatternsQuery({
    required this.entityId,
    required this.dateKey,
  });

  final String entityId;
  final String dateKey;

  @override
  bool operator ==(Object other) {
    return other is Layer2EntityPatternsQuery &&
        other.entityId == entityId &&
        other.dateKey == dateKey;
  }

  @override
  int get hashCode => Object.hash(entityId, dateKey);
}

class Layer2RunMetadata {
  const Layer2RunMetadata({
    required this.dateKey,
    required this.lastRunAtMs,
    required this.schemaVersion,
    required this.entitiesProcessed,
    required this.patternsEmitted,
  });

  final String dateKey;
  final int lastRunAtMs;
  final int schemaVersion;
  final int entitiesProcessed;
  final int patternsEmitted;
}

Stream<T> _watchLayer2Stats<T>(
  Ref ref, {
  required Future<T> Function() loader,
}) {
  final isar = ref.watch(offlineStoreProvider).isar;
  if (isar == null) {
    return Stream.fromFuture(loader());
  }

  final controller = StreamController<T>.broadcast();

  Future<void> emit() async {
    try {
      final value = await loader();
      if (!controller.isClosed) controller.add(value);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  unawaited(emit());
  final sub = isar.isarAnalyticsStats
      .watchLazy(fireImmediately: false)
      .listen((_) => unawaited(emit()));

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
}

final layer2EntityPatternsProvider =
    StreamProvider.family<List<DetectedPattern>, Layer2EntityPatternsQuery>((
      ref,
      query,
    ) {
      return _watchLayer2Stats(
        ref,
        loader: () {
          return ref
              .read(patternDetectionRepositoryProvider)
              .readEntityPatterns(
                entityId: query.entityId.trim(),
                dateKey: query.dateKey.trim(),
              );
        },
      );
    });

final layer2GlobalSnapshotProvider =
    StreamProvider.family<GlobalPatternSnapshot?, String>((ref, dateKey) {
      return _watchLayer2Stats(
        ref,
        loader: () {
          return ref
              .read(patternDetectionRepositoryProvider)
              .readGlobalSnapshot(dateKey: dateKey.trim());
        },
      );
    });

final layer2EntityCanonicalPatternsProvider =
    StreamProvider.family<
      List<DetectedBehaviorPattern>,
      Layer2EntityPatternsQuery
    >((ref, query) {
      return _watchLayer2Stats(
        ref,
        loader: () {
          return ref
              .read(patternDetectionRepositoryProvider)
              .readEntityBehaviorPatterns(
                entityId: query.entityId.trim(),
                dateKey: query.dateKey.trim(),
              );
        },
      );
    });

final layer2GlobalCanonicalSnapshotProvider =
    StreamProvider.family<GlobalBehaviorPatternSnapshot?, String>((
      ref,
      dateKey,
    ) {
      return _watchLayer2Stats(
        ref,
        loader: () {
          return ref
              .read(patternDetectionRepositoryProvider)
              .readGlobalBehaviorSnapshot(dateKey: dateKey.trim());
        },
      );
    });

final layer2RunMetadataProvider =
    StreamProvider.family<Layer2RunMetadata, String>((ref, dateKey) {
      return _watchLayer2Stats(
        ref,
        loader: () async {
          final snapshot = await ref
              .read(patternDetectionRepositoryProvider)
              .readGlobalSnapshot(dateKey: dateKey.trim());
          if (snapshot == null) {
            return Layer2RunMetadata(
              dateKey: dateKey.trim(),
              lastRunAtMs: 0,
              schemaVersion: kGlobalPatternSnapshotSchemaVersion,
              entitiesProcessed: 0,
              patternsEmitted: 0,
            );
          }
          return Layer2RunMetadata(
            dateKey: snapshot.dateKey,
            lastRunAtMs: snapshot.detectedAtMs,
            schemaVersion: snapshot.schemaVersion,
            entitiesProcessed: snapshot.totalEntitiesProcessed,
            patternsEmitted: snapshot.totalPatternsEmitted,
          );
        },
      );
    });

final layer2TodayGlobalSnapshotProvider =
    Provider<AsyncValue<GlobalPatternSnapshot?>>((ref) {
      final today = DateKeys.todayKey();
      return ref.watch(layer2GlobalSnapshotProvider(today));
    });

final layer2TodayGlobalCanonicalSnapshotProvider =
    Provider<AsyncValue<GlobalBehaviorPatternSnapshot?>>((ref) {
      final today = DateKeys.todayKey();
      return ref.watch(layer2GlobalCanonicalSnapshotProvider(today));
    });

final layer2TodayRunMetadataProvider = Provider<AsyncValue<Layer2RunMetadata>>((
  ref,
) {
  final today = DateKeys.todayKey();
  return ref.watch(layer2RunMetadataProvider(today));
});
