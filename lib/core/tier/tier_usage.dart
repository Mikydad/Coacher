import 'package:isar_community/isar.dart';

import '../local_db/isar_collections/isar_task.dart';
import '../offline/offline_store.dart';

/// Count queries the tier gates need that no repository exposes.
/// Read-only Isar access, same layer as core/sync.
class TierUsage {
  TierUsage._();

  static Isar? get _isar => OfflineStore.instance.isar;

  /// Tasks planned for [dateKey] (the add-task screen's plan date).
  static Future<int> tasksPlannedForDay(String dateKey) async {
    final isar = _isar;
    if (isar == null) return 0;
    return isar.isarTasks.filter().planDateKeyEqualTo(dateKey).count();
  }

  /// Habit Anchor tasks on [dateKey] — the app's "active habits" for a day.
  static Future<int> habitAnchorsForDay(String dateKey) async {
    final isar = _isar;
    if (isar == null) return 0;
    return isar.isarTasks
        .filter()
        .planDateKeyEqualTo(dateKey)
        .isHabitAnchorEqualTo(true)
        .count();
  }
}
