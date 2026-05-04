import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_analytics_event.dart';
import '../../../core/local_db/isar_collections/isar_analytics_stats.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/models/analytics_event.dart';
import '../domain/models/analytics_stats_cache.dart';
import 'analytics_repository.dart';

class IsarAnalyticsRepository implements AnalyticsRepository {
  IsarAnalyticsRepository(this._remote);

  final AnalyticsRepository _remote;

  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    event.validate();
    final existingByKey = await _isar.isarAnalyticsEvents
        .filter()
        .idempotencyKeyEqualTo(event.idempotencyKey)
        .findFirst();
    if (existingByKey != null && existingByKey.updatedAtMs >= event.updatedAtMs) {
      return;
    }
    await _isar.writeTxn(() async {
      if (existingByKey != null) {
        await _isar.isarAnalyticsEvents.delete(existingByKey.id);
      }
      await _isar.isarAnalyticsEvents.putByEventId(IsarAnalyticsEvent.fromDomain(event));
    });
    final path = '${FirestorePaths.analyticsEvents}/${event.id}';
    final payload = event.toMap();
    try {
      await FirebaseFirestore.instance.doc(path).set(payload, SetOptions(merge: true));
    } catch (_) {
      await SyncService.instance.enqueueUpsert(
        entityType: 'analyticsEvent',
        documentPath: path,
        payload: payload,
      );
    }
  }

  @override
  Future<List<AnalyticsEvent>> listEvents({
    String? entityId,
    String? dateKey,
    int? fromUpdatedAtMs,
    int? toUpdatedAtMs,
  }) async {
    final rows = await _isar.isarAnalyticsEvents.where().sortByUpdatedAtMsDesc().findAll();
    var out = rows.map((e) => e.toDomain()).toList();
    if (entityId != null && entityId.trim().isNotEmpty) {
      out = out.where((e) => e.entityId == entityId.trim()).toList();
    }
    if (dateKey != null && dateKey.trim().isNotEmpty) {
      out = out.where((e) => e.dateKey == dateKey.trim()).toList();
    }
    if (fromUpdatedAtMs != null) {
      out = out.where((e) => e.updatedAtMs >= fromUpdatedAtMs).toList();
    }
    if (toUpdatedAtMs != null) {
      out = out.where((e) => e.updatedAtMs <= toUpdatedAtMs).toList();
    }
    return out;
  }

  @override
  Future<void> hydrateRemoteEvents({List<String>? entityIds}) async {
    final remote = await _remote.listEvents();
    for (final incoming in remote) {
      if (entityIds != null && entityIds.isNotEmpty && !entityIds.contains(incoming.entityId)) {
        continue;
      }
      final existingById = await _isar.isarAnalyticsEvents.filter().eventIdEqualTo(incoming.id).findFirst();
      if (existingById != null && existingById.updatedAtMs >= incoming.updatedAtMs) continue;
      final existingByKey = await _isar.isarAnalyticsEvents
          .filter()
          .idempotencyKeyEqualTo(incoming.idempotencyKey)
          .findFirst();
      if (existingByKey != null && existingByKey.updatedAtMs >= incoming.updatedAtMs) continue;
      await _isar.writeTxn(() async {
        if (existingByKey != null) {
          await _isar.isarAnalyticsEvents.delete(existingByKey.id);
        }
        await _isar.isarAnalyticsEvents.putByEventId(IsarAnalyticsEvent.fromDomain(incoming));
      });
    }
  }

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {
    stats.validate();
    await _isar.writeTxn(() async {
      await _isar.isarAnalyticsStats.putByStatsId(IsarAnalyticsStats.fromDomain(stats));
    });
    final path = '${FirestorePaths.analyticsStats}/${stats.id}';
    final payload = stats.toMap();
    try {
      await FirebaseFirestore.instance.doc(path).set(payload, SetOptions(merge: true));
    } catch (_) {
      await SyncService.instance.enqueueUpsert(
        entityType: 'analyticsStats',
        documentPath: path,
        payload: payload,
      );
    }
  }

  @override
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  }) async {
    final rows = await _isar.isarAnalyticsStats.where().sortByUpdatedAtMsDesc().findAll();
    var out = rows.map((s) => s.toDomain()).toList();
    if (scopeType != null && scopeType.trim().isNotEmpty) {
      out = out.where((s) => s.scopeType == scopeType.trim()).toList();
    }
    if (scopeId != null && scopeId.trim().isNotEmpty) {
      out = out.where((s) => s.scopeId == scopeId.trim()).toList();
    }
    if (dateKey != null && dateKey.trim().isNotEmpty) {
      out = out.where((s) => s.dateKey == dateKey.trim()).toList();
    }
    return out;
  }

  @override
  Future<void> hydrateRemoteStatsCache({List<String>? scopeIds}) async {
    final remote = await _remote.listStatsCache();
    for (final incoming in remote) {
      if (scopeIds != null && scopeIds.isNotEmpty && !scopeIds.contains(incoming.scopeId)) {
        continue;
      }
      final existing = await _isar.isarAnalyticsStats.filter().statsIdEqualTo(incoming.id).findFirst();
      if (existing != null && existing.updatedAtMs >= incoming.updatedAtMs) continue;
      await _isar.writeTxn(() async {
        await _isar.isarAnalyticsStats.putByStatsId(IsarAnalyticsStats.fromDomain(incoming));
      });
    }
  }
}
