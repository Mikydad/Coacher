import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import 'goal_period_helpers.dart';
import '../data/goals_repository.dart';
import '../data/isar_goals_repository.dart';
import '../domain/models/goal_action.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/goal_milestone.dart';
import '../domain/models/user_goal.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>(
  (ref) => IsarGoalsRepository(FirestoreGoalsRepository(ref.read(firestoreClientProvider))),
);

/// Raw stream of all goals for the signed-in user (ordered by `updatedAtMs` desc).
final goalsStreamProvider = StreamProvider<List<UserGoal>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchGoals();
});

final selectedGoalCategoryFilterProvider = StateProvider<String?>((ref) => null);

final activeGoalsProvider = Provider<AsyncValue<List<UserGoal>>>((ref) {
  final async = ref.watch(goalsStreamProvider);
  return async.when(
    data: (list) {
      final active = list.where((g) => g.status == GoalStatus.active).toList()
        ..sort((a, b) {
          final c = b.intensity.compareTo(a.intensity);
          if (c != 0) return c;
          return b.updatedAtMs.compareTo(a.updatedAtMs);
        });
      final filter = ref.watch(selectedGoalCategoryFilterProvider);
      final filtered = filter == null
          ? active
          : active.where((g) => g.categoryId == filter).toList();
      return AsyncValue.data(filtered);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

/// Active goals whose period includes **today** (local calendar).
final todaysActiveGoalsProvider = Provider<AsyncValue<List<UserGoal>>>((ref) {
  final async = ref.watch(goalsStreamProvider);
  return async.when(
    data: (list) {
      final todayKey = DateKeys.todayKey();
      final todayGoals = list
          .where(
            (g) => g.status == GoalStatus.active && GoalPeriodHelpers.isDateKeyInPeriod(g, todayKey),
          )
          .toList()
        ..sort((a, b) {
          final c = b.intensity.compareTo(a.intensity);
          if (c != 0) return c;
          return b.updatedAtMs.compareTo(a.updatedAtMs);
        });
      return AsyncValue.data(todayGoals);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

final archivedGoalsProvider = Provider<AsyncValue<List<UserGoal>>>((ref) {
  final async = ref.watch(goalsStreamProvider);
  return async.when(
    data: (list) {
      final archived = list
          .where((g) => g.status == GoalStatus.paused || g.status == GoalStatus.completed)
          .toList()
        ..sort((a, b) => b.updatedAtMs.compareTo(a.updatedAtMs));
      return AsyncValue.data(archived);
    },
    loading: () => const AsyncValue.loading(),
    error: AsyncValue.error,
  );
});

class GoalDetailBundle {
  const GoalDetailBundle({
    required this.goal,
    required this.actions,
    required this.milestones,
    required this.checkIns,
  });

  final UserGoal goal;
  final List<GoalAction> actions;
  final List<GoalMilestone> milestones;
  final List<GoalCheckIn> checkIns;
}

final goalDetailProvider = FutureProvider.family<GoalDetailBundle?, String>((ref, goalId) async {
  final repo = ref.read(goalsRepositoryProvider);
  final goal = await repo.getGoal(goalId);
  if (goal == null) return null;
  final actions = await repo.getActions(goalId);
  final milestones = await repo.getMilestones(goalId);
  final checkIns = await repo.getCheckInsForGoal(goalId);
  return GoalDetailBundle(
    goal: goal,
    actions: actions,
    milestones: milestones,
    checkIns: checkIns,
  );
});

void invalidateGoals(WidgetRef ref, {String? goalId}) {
  ref.invalidate(goalsStreamProvider);
  if (goalId != null) {
    ref.invalidate(goalDetailProvider(goalId));
  }
}
