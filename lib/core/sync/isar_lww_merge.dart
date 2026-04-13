import 'package:isar/isar.dart';

import '../../features/planning/domain/models/task_item.dart';
import '../local_db/isar_collections/isar_task.dart';
import 'lww_updated_at.dart';

/// LWW merge of a [PlannedTask] into Isar (same rules as [RemoteIsarMerge]).
Future<void> mergePlannedTaskLwwIntoIsar(Isar isar, PlannedTask incoming) async {
  final existing = await isar.isarTasks.filter().taskIdEqualTo(incoming.id).findFirst();
  if (!shouldApplyRemoteUpdatedAt(
    localUpdatedAtMs: existing?.updatedAtMs,
    remoteUpdatedAtMs: incoming.updatedAtMs,
  )) {
    return;
  }
  await isar.writeTxn(() async {
    await isar.isarTasks.putByTaskId(IsarTask.fromDomain(incoming));
  });
}
