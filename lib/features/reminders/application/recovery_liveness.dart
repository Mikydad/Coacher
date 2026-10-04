import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/domain/models/task_item.dart';
import '../domain/models/reminder_occurrence.dart';
import 'notification_route_resolver.dart';

/// Answers "does this occurrence's entity still want doing?" for the
/// Recovery Card (Miko, 2026-09-18).
///
/// Occurrences are their own rows and can outlive what they point at: a
/// goal deleted, paused or completed on this device before the cleanup
/// paths existed, a task removed by another device's tombstone, a task
/// completed on a path that never told the state machine. Each of those
/// used to keep a row on the card whose "Do now" opened "Goal not found"
/// or dumped the user in the Tasks Hub. The card now checks the entity
/// itself, so a row is shown only when tapping it can land somewhere real.
///
/// Pure over injected lookups so the rule is unit-testable without Isar.
abstract final class RecoveryLiveness {
  /// Goals that still count: active only. Paused and completed goals live
  /// on the "Paused & completed" page and must not ask for attention.
  static Set<String> activeGoalIds(Iterable<UserGoal> goals) => {
    for (final g in goals)
      if (g.status == GoalStatus.active) g.id,
  };

  /// A task counts while it exists and is not done. Every other status
  /// (not started, in progress, partial) is still owed.
  static bool taskIsLive(PlannedTask? task) =>
      task != null && task.status != TaskStatus.completed;

  /// Resolves, once per pool emission, which task ids are live — one lookup
  /// per distinct task, never per row.
  static Future<Set<String>> liveTaskIds(
    Iterable<ReminderOccurrence> pool, {
    required Future<PlannedTask?> Function(String taskId) taskById,
  }) async {
    final ids = {
      for (final o in pool)
        if (o.entityKind == ReminderEntityKinds.task) o.entityId,
    };
    final live = <String>{};
    for (final id in ids) {
      if (taskIsLive(await taskById(id))) live.add(id);
    }
    return live;
  }

  /// The predicate [RecoveryViewBuilder.build] takes. Kinds the card does
  /// not know how to check (activities, coach insights) pass through — the
  /// guard exists to drop ghosts, not to second-guess every producer.
  static bool Function(ReminderOccurrence) predicate({
    required Set<String> activeGoalIds,
    required Set<String> liveTaskIds,
  }) => (o) => switch (o.entityKind) {
    ReminderEntityKinds.goal => activeGoalIds.contains(o.entityId),
    ReminderEntityKinds.task => liveTaskIds.contains(o.entityId),
    _ => true,
  };
}
