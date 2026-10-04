import 'package:isar_community/isar.dart';

import '../local_db/isar_collections/isar_intention.dart';
import '../local_db/isar_collections/isar_task.dart';
import '../offline/offline_store.dart';

/// Count queries the tier gates need that no repository exposes.
/// Read-only Isar access, same layer as core/sync.
class TierUsage {
  TierUsage._();

  static Isar? get _isar => OfflineStore.instance.isar;

  /// Non-habit tasks planned for [dateKey] (the add-task screen's plan
  /// date). Habit Anchors have their own cap (decision 2026-09-27: 4 tasks
  /// and 4 habits a day, counted separately).
  static Future<int> tasksPlannedForDay(String dateKey) async {
    final isar = _isar;
    if (isar == null) return 0;
    return isar.isarTasks
        .filter()
        .planDateKeyEqualTo(dateKey)
        .isHabitAnchorEqualTo(false)
        .count();
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

  /// Monday 00:00 local of [now]'s week — the promise quota's reset line
  /// (decision 2026-09-27: Mon–Sun, independent of the week-start setting).
  static DateTime promiseWeekStart(DateTime now) =>
      DateTime(now.year, now.month, now.day - (now.weekday - DateTime.monday));

  /// Promises created this Mon–Sun week that still exist. Dormant "on your
  /// radar" items are excluded — the AI noticed those on its own, so they
  /// never spend the user's allowance.
  static Future<int> promisesCreatedThisWeek(DateTime now) async {
    final isar = _isar;
    if (isar == null) return 0;
    final startMs = promiseWeekStart(now).millisecondsSinceEpoch;
    return isar.isarIntentions
        .filter()
        .activeEqualTo(true)
        .createdAtMsGreaterThan(startMs, include: true)
        .not()
        .statusStorageEqualTo('dormant')
        .count();
  }
}
