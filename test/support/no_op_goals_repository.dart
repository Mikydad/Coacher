import 'package:coach_for_life/features/goals/data/goals_repository.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_action.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_check_in.dart';
import 'package:coach_for_life/features/goals/domain/models/goal_milestone.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';

/// Stub remote used with [IsarGoalsRepository] in tests (no Firestore).
class NoOpGoalsRepository implements GoalsRepository {
  @override
  Future<void> deleteAction({required String goalId, required String actionId}) async {}

  @override
  Future<void> deleteGoal(String goalId) async {}

  @override
  Future<void> deleteMilestone({required String goalId, required String milestoneId}) async {}

  @override
  Future<List<GoalAction>> getActions(String goalId) async => const [];

  @override
  Future<List<GoalCheckIn>> getCheckInsForGoal(
    String goalId, {
    String? startDateKey,
    String? endDateKey,
  }) async =>
      const [];

  @override
  Future<UserGoal?> getGoal(String goalId) async => null;

  @override
  Future<List<GoalMilestone>> getMilestones(String goalId) async => const [];

  @override
  Future<List<UserGoal>> fetchGoalsOnce() async => const [];

  @override
  Stream<List<UserGoal>> watchGoals() => Stream.value(const []);

  @override
  Future<void> upsertAction(GoalAction action) async {}

  @override
  Future<void> upsertCheckIn(GoalCheckIn checkIn) async {}

  @override
  Future<void> upsertGoal(UserGoal goal) async {}

  @override
  Future<void> upsertMilestone(GoalMilestone milestone) async {}
}
