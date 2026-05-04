import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/models/analytics_event.dart';
import '../domain/models/analytics_stats_cache.dart';

AnalyticsEvent analyticsEventFromFirestoreDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final map = Map<String, dynamic>.from(doc.data());
  map['id'] = map['id'] ?? doc.id;
  return AnalyticsEvent.fromMap(map);
}

AnalyticsStatsCache analyticsStatsFromFirestoreDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
  final map = Map<String, dynamic>.from(doc.data());
  map['id'] = map['id'] ?? doc.id;
  return AnalyticsStatsCache.fromMap(map);
}

abstract class AnalyticsRepository {
  Future<void> logEvent(AnalyticsEvent event);
  Future<List<AnalyticsEvent>> listEvents({
    String? entityId,
    String? dateKey,
    int? fromUpdatedAtMs,
    int? toUpdatedAtMs,
  });
  Future<void> hydrateRemoteEvents({List<String>? entityIds});

  Future<void> upsertStatsCache(AnalyticsStatsCache stats);
  Future<List<AnalyticsStatsCache>> listStatsCache({
    String? scopeType,
    String? scopeId,
    String? dateKey,
  });
  Future<void> hydrateRemoteStatsCache({List<String>? scopeIds});
}

class FirestoreAnalyticsRepository implements AnalyticsRepository {
  @override
  Future<void> logEvent(AnalyticsEvent event) async {
    event.validate();
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
    var query = FirebaseFirestore.instance
        .collection(FirestorePaths.analyticsEvents)
        .orderBy('updatedAtMs', descending: true);
    if (entityId != null && entityId.trim().isNotEmpty) {
      query = query.where('entityId', isEqualTo: entityId.trim());
    }
    if (dateKey != null && dateKey.trim().isNotEmpty) {
      query = query.where('dateKey', isEqualTo: dateKey.trim());
    }
    final snap = await query.get();
    var out = snap.docs.map(analyticsEventFromFirestoreDoc).toList();
    if (fromUpdatedAtMs != null) {
      out = out.where((e) => e.updatedAtMs >= fromUpdatedAtMs).toList();
    }
    if (toUpdatedAtMs != null) {
      out = out.where((e) => e.updatedAtMs <= toUpdatedAtMs).toList();
    }
    return out;
  }

  @override
  Future<void> hydrateRemoteEvents({List<String>? entityIds}) async {}

  @override
  Future<void> upsertStatsCache(AnalyticsStatsCache stats) async {
    stats.validate();
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
    var query = FirebaseFirestore.instance
        .collection(FirestorePaths.analyticsStats)
        .orderBy('updatedAtMs', descending: true);
    if (scopeType != null && scopeType.trim().isNotEmpty) {
      query = query.where('scopeType', isEqualTo: scopeType.trim());
    }
    if (scopeId != null && scopeId.trim().isNotEmpty) {
      query = query.where('scopeId', isEqualTo: scopeId.trim());
    }
    if (dateKey != null && dateKey.trim().isNotEmpty) {
      query = query.where('dateKey', isEqualTo: dateKey.trim());
    }
    final snap = await query.get();
    return snap.docs.map(analyticsStatsFromFirestoreDoc).toList();
  }

  @override
  Future<void> hydrateRemoteStatsCache({List<String>? scopeIds}) async {}
}
