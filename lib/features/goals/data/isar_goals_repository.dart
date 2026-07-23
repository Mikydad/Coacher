import 'package:isar_community/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_goal.dart';
import '../../../core/local_db/isar_collections/isar_goal_action.dart';
import '../../../core/local_db/isar_collections/isar_goal_check_in.dart';
import '../../../core/local_db/isar_collections/isar_goal_milestone.dart';
import '../../../core/local_db/isar_collections/isar_scheduled_time_block.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/outbox_writer.dart';
import '../domain/models/goal_action.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_milestone.dart';
import '../domain/models/user_goal.dart';
import 'goals_repository.dart';

/// Fully local-first goals: documents AND subcollections (actions,
/// milestones, check-ins) live in Isar — the UI reads and mutates them
/// offline in milliseconds. Firestore is replicated in the background via
/// the outbox (push) and [RemoteIsarMerge] (pull).
class IsarGoalsRepository implements GoalsRepository {
  IsarGoalsRepository();

  Isar get _isar => OfflineStore.instance.isar!;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  // ─── Goals ────────────────────────────────────────────────────────────────

  @override
  Stream<List<UserGoal>> watchGoals() {
    return _isar.isarGoals
        .where()
        .sortByUpdatedAtMsDesc()
        .watch(fireImmediately: true)
        .map((list) => list.map((e) => e.toDomain()).toList());
  }

  @override
  Stream<UserGoal?> watchGoal(String goalId) {
    return _isar.isarGoals
        .filter()
        .goalIdEqualTo(goalId)
        .watch(fireImmediately: true)
        .map((rows) => rows.isEmpty ? null : rows.first.toDomain());
  }

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async {
    final rows = await _isar.isarGoals
        .where()
        .sortByUpdatedAtMsDesc()
        .findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<UserGoal?> getGoal(String goalId) async {
    final row = await _isar.isarGoals
        .filter()
        .goalIdEqualTo(goalId)
        .findFirst();
    return row?.toDomain();
  }

  @override
  Future<void> upsertGoal(UserGoal goal) async {
    goal.validate();
    await _isar.writeTxn(() async {
      await _isar.isarGoals.putByGoalId(IsarGoal.fromDomain(goal));
    });
    await outboxUpsert(
      entityType: 'goal',
      documentPath: FirestorePaths.goalDocument(goal.id),
      payload: goal.toMap(),
    );
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    // Capture subdocument ids before the purge so the cloud copies can be
    // deleted through the outbox (works offline; replays on reconnect).
    final actionIds = await _isar.isarGoalActions
        .filter()
        .goalIdEqualTo(goalId)
        .actionIdProperty()
        .findAll();
    final milestoneIds = await _isar.isarGoalMilestones
        .filter()
        .goalIdEqualTo(goalId)
        .milestoneIdProperty()
        .findAll();
    final checkInDateKeys = await _isar.isarGoalCheckIns
        .filter()
        .goalIdEqualTo(goalId)
        .dateKeyProperty()
        .findAll();
    final timeBlockIds = await _isar.isarScheduledTimeBlocks
        .filter()
        .entityIdEqualTo(goalId)
        .blockIdProperty()
        .findAll();

    await _isar.writeTxn(() async {
      final row = await _isar.isarGoals
          .filter()
          .goalIdEqualTo(goalId)
          .findFirst();
      if (row != null) await _isar.isarGoals.delete(row.id);
      await _isar.isarGoalActions.filter().goalIdEqualTo(goalId).deleteAll();
      await _isar.isarGoalMilestones.filter().goalIdEqualTo(goalId).deleteAll();
      await _isar.isarGoalCheckIns.filter().goalIdEqualTo(goalId).deleteAll();
      await _isar.isarScheduledTimeBlocks
          .filter()
          .entityIdEqualTo(goalId)
          .deleteAll();
    });

    for (final id in actionIds) {
      await outboxDelete(
        entityType: 'goalAction',
        documentPath: '${FirestorePaths.goalActions(goalId)}/$id',
      );
    }
    for (final id in milestoneIds) {
      await outboxDelete(
        entityType: 'goalMilestone',
        documentPath: '${FirestorePaths.goalMilestones(goalId)}/$id',
      );
    }
    for (final dateKey in checkInDateKeys) {
      await outboxDelete(
        entityType: 'goalCheckIn',
        documentPath: '${FirestorePaths.goalCheckIns(goalId)}/$dateKey',
      );
    }
    for (final blockId in timeBlockIds) {
      await outboxDelete(
        entityType: 'timeBlock',
        documentPath: FirestorePaths.timeBlockDocument(blockId),
      );
    }
    await outboxDelete(
      entityType: 'goal',
      documentPath: FirestorePaths.goalDocument(goalId),
    );
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  @override
  Future<List<GoalAction>> getActions(String goalId) async {
    final rows = await _isar.isarGoalActions
        .filter()
        .goalIdEqualTo(goalId)
        .findAll();
    return rows.map((e) => e.toDomain()).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  @override
  Stream<List<GoalAction>> watchActions(String goalId) {
    return _isar.isarGoalActions
        .filter()
        .goalIdEqualTo(goalId)
        .watch(fireImmediately: true)
        .map(
          (rows) =>
              rows.map((e) => e.toDomain()).toList()
                ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
        );
  }

  @override
  Future<void> upsertAction(GoalAction action) async {
    final stamped = action.copyWith(updatedAtMs: _now());
    await _isar.writeTxn(() async {
      await _isar.isarGoalActions.putByActionId(
        IsarGoalAction.fromDomain(stamped),
      );
    });
    await outboxUpsert(
      entityType: 'goalAction',
      documentPath: '${FirestorePaths.goalActions(action.goalId)}/${action.id}',
      payload: stamped.toMap(),
    );
  }

  @override
  Future<void> deleteAction({
    required String goalId,
    required String actionId,
  }) async {
    await _isar.writeTxn(() async {
      await _isar.isarGoalActions.deleteByActionId(actionId);
    });
    await outboxDelete(
      entityType: 'goalAction',
      documentPath: '${FirestorePaths.goalActions(goalId)}/$actionId',
    );
  }

  // ─── Milestones ───────────────────────────────────────────────────────────

  @override
  Future<List<GoalMilestone>> getMilestones(String goalId) async {
    final rows = await _isar.isarGoalMilestones
        .filter()
        .goalIdEqualTo(goalId)
        .findAll();
    return rows.map((e) => e.toDomain()).toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  @override
  Stream<List<GoalMilestone>> watchMilestones(String goalId) {
    return _isar.isarGoalMilestones
        .filter()
        .goalIdEqualTo(goalId)
        .watch(fireImmediately: true)
        .map(
          (rows) =>
              rows.map((e) => e.toDomain()).toList()
                ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex)),
        );
  }

  @override
  Future<void> upsertMilestone(GoalMilestone milestone) async {
    final stamped = milestone.copyWith(updatedAtMs: _now());
    await _isar.writeTxn(() async {
      await _isar.isarGoalMilestones.putByMilestoneId(
        IsarGoalMilestone.fromDomain(stamped),
      );
    });
    await outboxUpsert(
      entityType: 'goalMilestone',
      documentPath:
          '${FirestorePaths.goalMilestones(milestone.goalId)}/${milestone.id}',
      payload: stamped.toMap(),
    );
  }

  @override
  Future<void> deleteMilestone({
    required String goalId,
    required String milestoneId,
  }) async {
    await _isar.writeTxn(() async {
      await _isar.isarGoalMilestones.deleteByMilestoneId(milestoneId);
    });
    await outboxDelete(
      entityType: 'goalMilestone',
      documentPath: '${FirestorePaths.goalMilestones(goalId)}/$milestoneId',
    );
  }

  // ─── Check-ins ────────────────────────────────────────────────────────────

  @override
  Future<void> upsertCheckIn(GoalCheckIn checkIn) async {
    final stamped = checkIn.copyWith(updatedAtMs: _now());
    await _isar.writeTxn(() async {
      await _isar.isarGoalCheckIns.putByCheckInKey(
        IsarGoalCheckIn.fromDomain(stamped),
      );
    });
    await outboxUpsert(
      entityType: 'goalCheckIn',
      documentPath:
          '${FirestorePaths.goalCheckIns(checkIn.goalId)}/${checkIn.dateKey}',
      payload: stamped.toMap(),
    );
  }

  @override
  Future<GoalCheckIn?> getTodayCheckIn(String goalId, String dateKey) async {
    final row = await _isar.isarGoalCheckIns.getByCheckInKey(
      IsarGoalCheckIn.keyFor(goalId, dateKey),
    );
    return row?.toDomain();
  }

  @override
  Future<List<GoalCheckIn>> getCheckInsForGoal(
    String goalId, {
    String? startDateKey,
    String? endDateKey,
  }) async {
    final rows = await _isar.isarGoalCheckIns
        .filter()
        .goalIdEqualTo(goalId)
        .findAll();
    var list = rows.map((e) => e.toDomain()).toList()
      ..sort((a, b) => a.dateKey.compareTo(b.dateKey));
    if (startDateKey != null) {
      list = list.where((c) => c.dateKey.compareTo(startDateKey) >= 0).toList();
    }
    if (endDateKey != null) {
      list = list.where((c) => c.dateKey.compareTo(endDateKey) <= 0).toList();
    }
    return list;
  }

  @override
  Stream<List<GoalCheckIn>> watchCheckIns(String goalId) {
    return _isar.isarGoalCheckIns
        .filter()
        .goalIdEqualTo(goalId)
        .watch(fireImmediately: true)
        .map(
          (rows) =>
              rows.map((e) => e.toDomain()).toList()
                ..sort((a, b) => a.dateKey.compareTo(b.dateKey)),
        );
  }
}
