import 'package:isar_community/isar.dart';

import '../../../features/goals/domain/models/goal_milestone.dart';

part 'isar_goal_milestone.g.dart';

/// Local mirror of `users/{uid}/goals/{goalId}/milestones/{milestoneId}` —
/// see [IsarGoalAction] for the replication model.
@collection
class IsarGoalMilestone {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String milestoneId;

  @Index()
  late String goalId;

  late String title;
  late bool completed;
  late int orderIndex;

  @Index()
  late int updatedAtMs;

  static IsarGoalMilestone fromDomain(GoalMilestone m) {
    return IsarGoalMilestone()
      ..milestoneId = m.id
      ..goalId = m.goalId
      ..title = m.title
      ..completed = m.completed
      ..orderIndex = m.orderIndex
      ..updatedAtMs = m.updatedAtMs;
  }

  GoalMilestone toDomain() {
    return GoalMilestone(
      id: milestoneId,
      goalId: goalId,
      title: title,
      completed: completed,
      orderIndex: orderIndex,
      updatedAtMs: updatedAtMs,
    );
  }
}
