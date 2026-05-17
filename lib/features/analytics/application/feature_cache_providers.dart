import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/local_db/isar_collections/isar_behavior_feature_cache.dart';
import '../domain/models/behavior_feature_object.dart';

class FeatureCacheMetadata {
  const FeatureCacheMetadata({
    required this.count,
    required this.lastComputedAtMs,
    required this.schemaVersions,
  });

  final int count;
  final int lastComputedAtMs;
  final List<int> schemaVersions;
}

class FeatureCacheScopeQuery {
  const FeatureCacheScopeQuery({
    required this.kind,
    this.startDateKey,
    this.endDateKey,
  });

  final BehaviorEntityKind kind;
  final String? startDateKey;
  final String? endDateKey;

  @override
  bool operator ==(Object other) {
    return other is FeatureCacheScopeQuery &&
        other.kind == kind &&
        other.startDateKey == startDateKey &&
        other.endDateKey == endDateKey;
  }

  @override
  int get hashCode => Object.hash(kind, startDateKey, endDateKey);
}

Stream<List<BehaviorFeatureObject>> _watchFeatureList(
  Ref ref, {
  required Future<List<BehaviorFeatureObject>> Function() loader,
}) {
  final isar = ref.watch(offlineStoreProvider).isar;
  if (isar == null) {
    return Stream.value(const <BehaviorFeatureObject>[]);
  }

  final controller = StreamController<List<BehaviorFeatureObject>>.broadcast();

  Future<void> emit() async {
    try {
      final values = await loader();
      if (!controller.isClosed) controller.add(values);
    } catch (e, st) {
      if (!controller.isClosed) controller.addError(e, st);
    }
  }

  unawaited(emit());
  final sub = isar.isarBehaviorFeatureCaches
      .watchLazy(fireImmediately: false)
      .listen((_) => unawaited(emit()));

  ref.onDispose(() async {
    await sub.cancel();
    await controller.close();
  });

  return controller.stream;
}

final featureCacheByEntityProvider =
    StreamProvider.family<BehaviorFeatureObject?, String>((
      ref,
      entityId,
    ) async* {
      final key = entityId.trim();
      if (key.isEmpty) {
        yield null;
        return;
      }
      final stream = _watchFeatureList(
        ref,
        loader: () async {
          final value = await ref
              .read(featureCacheRepositoryProvider)
              .getByEntityId(key);
          return value == null ? const <BehaviorFeatureObject>[] : [value];
        },
      );
      await for (final list in stream) {
        yield list.isEmpty ? null : list.first;
      }
    });

final featureCacheByScopeProvider =
    StreamProvider.family<List<BehaviorFeatureObject>, FeatureCacheScopeQuery>((
      ref,
      query,
    ) {
      return _watchFeatureList(
        ref,
        loader: () {
          return ref
              .read(featureCacheRepositoryProvider)
              .listByKindAndDateWindow(
                kind: query.kind,
                startDateKey: query.startDateKey,
                endDateKey: query.endDateKey,
              );
        },
      );
    });

final featureCacheMetadataProvider = StreamProvider<FeatureCacheMetadata>((
  ref,
) {
  return _watchFeatureList(
    ref,
    loader: () => ref.read(featureCacheRepositoryProvider).listAll(),
  ).map((features) {
    var lastComputedAtMs = 0;
    final versions = <int>{};
    for (final feature in features) {
      if (feature.computedAtMs > lastComputedAtMs) {
        lastComputedAtMs = feature.computedAtMs;
      }
      versions.add(feature.schemaVersion);
    }
    final sortedVersions = versions.toList()..sort();
    return FeatureCacheMetadata(
      count: features.length,
      lastComputedAtMs: lastComputedAtMs,
      schemaVersions: sortedVersions,
    );
  });
});
