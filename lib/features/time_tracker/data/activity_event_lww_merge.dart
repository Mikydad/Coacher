import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_activity_event.dart';
import '../../../core/sync/lww_updated_at.dart';
import '../domain/models/activity_event.dart';

/// LWW merge of a remote [ActivityEvent] into Isar — the same rule as every
/// other `RemoteIsarMerge` phase (`remote.updatedAtMs > local` to apply),
/// extracted so it is unit-testable without Firestore. Tombstones merge
/// like any other write, so a delete on one device wins over a stale edit.
///
/// Returns true when the incoming row was applied.
Future<bool> mergeActivityEventLwwIntoIsar(
  Isar isar,
  ActivityEvent incoming,
) async {
  final existing = await isar.isarActivityEvents
      .filter()
      .eventIdEqualTo(incoming.id)
      .findFirst();
  if (!shouldApplyRemoteUpdatedAt(
    localUpdatedAtMs: existing?.updatedAtMs,
    remoteUpdatedAtMs: incoming.updatedAtMs,
  )) {
    return false;
  }
  await isar.writeTxn(() async {
    await isar.isarActivityEvents.putByEventId(
      IsarActivityEvent.fromDomain(incoming),
    );
  });
  return true;
}
