import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_behavior_feature_cache.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/behavior_feature_object.dart';

abstract class FeatureCacheRepository {
  Future<void> upsertFeature(BehaviorFeatureObject feature);
  Future<void> upsertFeatures(List<BehaviorFeatureObject> features);
  Future<void> deleteByEntityId(String entityId);
  Future<BehaviorFeatureObject?> getByEntityId(String entityId);
  Future<List<BehaviorFeatureObject>> listByEntityKind(BehaviorEntityKind kind);
  Future<List<BehaviorFeatureObject>> listByKindAndDateWindow({
    required BehaviorEntityKind kind,
    String? startDateKey,
    String? endDateKey,
  });
  Future<List<BehaviorFeatureObject>> listAll();
}

class IsarFeatureCacheRepository implements FeatureCacheRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<void> upsertFeature(BehaviorFeatureObject feature) async {
    feature.validate();
    await _isar.writeTxn(() async {
      await _isar.isarBehaviorFeatureCaches.putByEntityId(
        IsarBehaviorFeatureCache.fromDomain(feature),
      );
    });
  }

  @override
  Future<void> upsertFeatures(List<BehaviorFeatureObject> features) async {
    if (features.isEmpty) return;
    for (final feature in features) {
      feature.validate();
    }
    await _isar.writeTxn(() async {
      final rows = features.map(IsarBehaviorFeatureCache.fromDomain).toList();
      await _isar.isarBehaviorFeatureCaches.putAllByEntityId(rows);
    });
  }

  @override
  Future<void> deleteByEntityId(String entityId) async {
    final key = entityId.trim();
    if (key.isEmpty) return;
    await _isar.writeTxn(() async {
      await _isar.isarBehaviorFeatureCaches.deleteAllByEntityId([key]);
    });
  }

  @override
  Future<BehaviorFeatureObject?> getByEntityId(String entityId) async {
    final key = entityId.trim();
    if (key.isEmpty) return null;
    final row = await _isar.isarBehaviorFeatureCaches
        .filter()
        .entityIdEqualTo(key)
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<List<BehaviorFeatureObject>> listByEntityKind(
    BehaviorEntityKind kind,
  ) async {
    final rows = await _isar.isarBehaviorFeatureCaches
        .filter()
        .entityKindEqualTo(kind.name)
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows.map((row) => row.toDomain()).toList();
  }

  @override
  Future<List<BehaviorFeatureObject>> listByKindAndDateWindow({
    required BehaviorEntityKind kind,
    String? startDateKey,
    String? endDateKey,
  }) async {
    final rows = await _isar.isarBehaviorFeatureCaches
        .filter()
        .entityKindEqualTo(kind.name)
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows.map((row) => row.toDomain()).where((feature) {
      final start = startDateKey?.trim();
      final end = endDateKey?.trim();
      if (start != null &&
          start.isNotEmpty &&
          (feature.windowEndDateKey == null ||
              feature.windowEndDateKey!.compareTo(start) < 0)) {
        return false;
      }
      if (end != null &&
          end.isNotEmpty &&
          (feature.windowStartDateKey == null ||
              feature.windowStartDateKey!.compareTo(end) > 0)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Future<List<BehaviorFeatureObject>> listAll() async {
    final rows = await _isar.isarBehaviorFeatureCaches
        .where()
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows.map((row) => row.toDomain()).toList();
  }
}
