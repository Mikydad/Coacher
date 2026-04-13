import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isar/isar.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/local_db/isar_collections/isar_goal.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/sync/sync_service.dart';
import '../domain/models/goal_action.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_milestone.dart';
import '../domain/models/user_goal.dart';
import 'goals_repository.dart';

/// Local-first goal documents in Isar; subcollections stay on Firestore via [_remote].
class IsarGoalsRepository implements GoalsRepository {
  IsarGoalsRepository(this._remote);

  final GoalsRepository _remote;

  Isar get _isar => OfflineStore.instance.isar!;

  Future<void> _enqueueUpsert({
    required String entityType,
    required String path,
    required Map<String, dynamic> payload,
  }) async {
    try {
      await FirebaseFirestore.instance.doc(path).set(payload, SetOptions(merge: true));
    } catch (_) {
      await SyncService.instance.enqueueUpsert(
        entityType: entityType,
        documentPath: path,
        payload: payload,
      );
    }
  }

  @override
  Stream<List<UserGoal>> watchGoals() {
    return _isar.isarGoals
        .where()
        .sortByUpdatedAtMsDesc()
        .watch(fireImmediately: true)
        .map((list) => list.map((e) => e.toDomain()).toList());
  }

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async {
    final rows = await _isar.isarGoals.where().sortByUpdatedAtMsDesc().findAll();
    return rows.map((e) => e.toDomain()).toList();
  }

  @override
  Future<UserGoal?> getGoal(String goalId) async {
    final row = await _isar.isarGoals.filter().goalIdEqualTo(goalId).findFirst();
    return row?.toDomain();
  }

  @override
  Future<void> upsertGoal(UserGoal goal) async {
    goal.validate();
    await _isar.writeTxn(() async {
      await _isar.isarGoals.putByGoalId(IsarGoal.fromDomain(goal));
    });
    await _enqueueUpsert(
      entityType: 'goal',
      path: FirestorePaths.goalDocument(goal.id),
      payload: goal.toMap(),
    );
  }

  @override
  Future<void> deleteGoal(String goalId) async {
    await _isar.writeTxn(() async {
      final row = await _isar.isarGoals.filter().goalIdEqualTo(goalId).findFirst();
      if (row != null) await _isar.isarGoals.delete(row.id);
    });
    await _remote.deleteGoal(goalId);
  }

  @override
  Future<List<GoalAction>> getActions(String goalId) => _remote.getActions(goalId);

  @override
  Future<void> upsertAction(GoalAction action) => _remote.upsertAction(action);

  @override
  Future<void> deleteAction({required String goalId, required String actionId}) =>
      _remote.deleteAction(goalId: goalId, actionId: actionId);

  @override
  Future<List<GoalMilestone>> getMilestones(String goalId) => _remote.getMilestones(goalId);

  @override
  Future<void> upsertMilestone(GoalMilestone milestone) => _remote.upsertMilestone(milestone);

  @override
  Future<void> deleteMilestone({required String goalId, required String milestoneId}) =>
      _remote.deleteMilestone(goalId: goalId, milestoneId: milestoneId);

  @override
  Future<void> upsertCheckIn(GoalCheckIn checkIn) => _remote.upsertCheckIn(checkIn);

  @override
  Future<List<GoalCheckIn>> getCheckInsForGoal(
    String goalId, {
    String? startDateKey,
    String? endDateKey,
  }) => _remote.getCheckInsForGoal(goalId, startDateKey: startDateKey, endDateKey: endDateKey);
}
