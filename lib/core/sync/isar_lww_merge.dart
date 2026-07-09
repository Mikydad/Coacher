import 'package:isar_community/isar.dart';

import '../../features/planning/domain/models/task_item.dart';
import '../local_db/isar_collections/isar_task.dart';
import 'lww_updated_at.dart';

/// LWW merge of a [PlannedTask] into Isar (same rules as [RemoteIsarMerge]).
///
/// Returns true when the incoming row was applied (local row was older or
/// absent), false when the merge was a no-op.
Future<bool> mergePlannedTaskLwwIntoIsar(
  Isar isar,
  PlannedTask incoming,
) async {
  final existing = await isar.isarTasks
      .filter()
      .taskIdEqualTo(incoming.id)
      .findFirst();
  if (!shouldApplyRemoteUpdatedAt(
    localUpdatedAtMs: existing?.updatedAtMs,
    remoteUpdatedAtMs: incoming.updatedAtMs,
  )) {
    return false;
  }
  await isar.writeTxn(() async {
    await isar.isarTasks.putByTaskId(IsarTask.fromDomain(incoming));
  });
  return true;
}
