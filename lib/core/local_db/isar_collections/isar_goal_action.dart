import 'package:isar_community/isar.dart';

import '../../../features/goals/domain/models/goal_action.dart';

part 'isar_goal_action.g.dart';

/// Local mirror of `users/{uid}/goals/{goalId}/actions/{actionId}` so goal
/// detail renders and mutates offline; Firestore is replicated via the
/// outbox (push) and [RemoteIsarMerge] (pull).
@collection
class IsarGoalAction {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String actionId;

  @Index()
  late String goalId;

  late String title;
  late int orderIndex;
  late bool completed;
  List<int>? repeatWeekdays;
  List<String>? completedDateKeys;

  @Index()
  late int updatedAtMs;

  static IsarGoalAction fromDomain(GoalAction a) {
    return IsarGoalAction()
      ..actionId = a.id
      ..goalId = a.goalId
      ..title = a.title
      ..orderIndex = a.orderIndex
      ..completed = a.completed
      ..repeatWeekdays = a.repeatWeekdays
      ..completedDateKeys = a.completedDateKeys.isEmpty
          ? null
          : a.completedDateKeys
      ..updatedAtMs = a.updatedAtMs;
  }

  GoalAction toDomain() {
    return GoalAction(
      id: actionId,
      goalId: goalId,
      title: title,
      orderIndex: orderIndex,
      completed: completed,
      repeatWeekdays: repeatWeekdays,
      completedDateKeys: completedDateKeys ?? const [],
      updatedAtMs: updatedAtMs,
    );
  }
}
