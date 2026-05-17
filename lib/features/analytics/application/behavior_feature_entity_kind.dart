import '../../goals/domain/models/goal_categories.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/domain/models/task_item.dart';
import '../domain/models/behavior_feature_object.dart';

BehaviorEntityKind behaviorEntityKindForTask(PlannedTask task) {
  if (task.isHabitAnchor) return BehaviorEntityKind.habit;
  return BehaviorEntityKind.task;
}

BehaviorEntityKind behaviorEntityKindForGoal(UserGoal goal) {
  if (goal.categoryId == GoalCategories.habits) return BehaviorEntityKind.habit;
  return BehaviorEntityKind.goal;
}
