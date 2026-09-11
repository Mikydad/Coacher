import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_direction_entry.dart';
import '../../../core/sync/lww_updated_at.dart';
import '../domain/models/direction_entry.dart';

/// LWW merge of a remote [DirectionEntry] into Isar — the same rule as every
/// other `RemoteIsarMerge` phase (`remote.updatedAtMs > local` to apply),
/// extracted so it is unit-testable without Firestore.
///
/// Returns true when the incoming row was applied (local absent or older).
Future<bool> mergeDirectionEntryLwwIntoIsar(
  Isar isar,
  DirectionEntry incoming,
) async {
  final existing = await isar.isarDirectionEntrys
      .filter()
      .entryIdEqualTo(incoming.id)
      .findFirst();
  if (!shouldApplyRemoteUpdatedAt(
    localUpdatedAtMs: existing?.updatedAtMs,
    remoteUpdatedAtMs: incoming.updatedAtMs,
  )) {
    return false;
  }
  await isar.writeTxn(() async {
    await isar.isarDirectionEntrys.putByEntryId(
      IsarDirectionEntry.fromDomain(incoming),
    );
  });
  return true;
}
