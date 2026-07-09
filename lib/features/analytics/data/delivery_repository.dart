import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_delivery_decision_snapshot.dart';
import '../../../core/local_db/isar_collections/isar_delivery_history_entry.dart';
import '../../../core/offline/offline_store.dart';
import '../domain/models/delivery_decision.dart';

abstract class DeliveryRepository {
  Future<void> upsertDecision({
    required String scopeId,
    required DeliverySurface surface,
    required DeliveryDecision decision,
  });

  Future<DeliveryDecision?> readDecision({
    required String scopeId,
    required DeliverySurface surface,
  });

  Future<void> logHistory(DeliveryHistoryEntry entry);

  Future<List<DeliveryHistoryEntry>> listHistoryForScope({
    required String scopeId,
    DeliverySurface? surface,
    int? fromDeliveredAtMs,
  });
}

class IsarDeliveryRepository implements DeliveryRepository {
  Isar get _isar => OfflineStore.instance.isar!;

  @override
  Future<void> upsertDecision({
    required String scopeId,
    required DeliverySurface surface,
    required DeliveryDecision decision,
  }) async {
    final key = scopeId.trim();
    if (key.isEmpty) return;
    decision.validate();
    await _isar.writeTxn(() async {
      await _isar.isarDeliveryDecisionSnapshots.putBySnapshotId(
        IsarDeliveryDecisionSnapshot.fromDomain(
          scopeId: key,
          surface: surface,
          decision: decision,
        ),
      );
    });
  }

  @override
  Future<DeliveryDecision?> readDecision({
    required String scopeId,
    required DeliverySurface surface,
  }) async {
    final key = scopeId.trim();
    if (key.isEmpty) return null;
    final snapshotId = decisionSnapshotId(scopeId: key, surface: surface);
    final row = await _isar.isarDeliveryDecisionSnapshots
        .filter()
        .snapshotIdEqualTo(snapshotId)
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<void> logHistory(DeliveryHistoryEntry entry) async {
    entry.validate();
    await _isar.writeTxn(() async {
      await _isar.isarDeliveryHistoryEntrys.putByHistoryId(
        IsarDeliveryHistoryEntry.fromDomain(entry),
      );
    });
  }

  @override
  Future<List<DeliveryHistoryEntry>> listHistoryForScope({
    required String scopeId,
    DeliverySurface? surface,
    int? fromDeliveredAtMs,
  }) async {
    final key = scopeId.trim();
    if (key.isEmpty) return const <DeliveryHistoryEntry>[];
    final rows = surface == null
        ? await _isar.isarDeliveryHistoryEntrys
              .filter()
              .scopeIdEqualTo(key)
              .sortByDeliveredAtMsDesc()
              .findAll()
        : await _isar.isarDeliveryHistoryEntrys
              .filter()
              .scopeIdEqualTo(key)
              .and()
              .surfaceEqualTo(surface.name)
              .sortByDeliveredAtMsDesc()
              .findAll();
    final fromMs = fromDeliveredAtMs;
    return rows
        .map((row) => row.toDomain())
        .where((entry) => fromMs == null || entry.deliveredAtMs >= fromMs)
        .toList(growable: false);
  }
}
