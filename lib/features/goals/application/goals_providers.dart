import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../features/time_blocks/application/time_block_providers.dart';
import 'goal_block_sync_service.dart';
import 'goal_period_helpers.dart';
import '../data/goals_repository.dart';
import '../data/isar_goals_repository.dart';
import '../domain/models/goal_action.dart';
import '../domain/models/goal_check_in.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/goal_milestone.dart';
import '../domain/models/user_goal.dart';

final goalsRepositoryProvider = Provider<GoalsRepository>(
  // watch (not read): rebuilds on uid change so the repository never holds a
  // FirestoreClient pinned to a previous account after a switch.
  (ref) => IsarGoalsRepository(
    FirestoreGoalsRepository(ref.watch(firestoreClientProvider)),
  ),
);

/// Raw stream of all goals for the signed-in user (ordered by `updatedAtMs` desc).
final goalsStreamProvider = StreamProvider<List<UserGoal>>((ref) {
  return ref.watch(goalsRepositoryProvider).watchGoals();
});

final selectedGoalCategoryFilterProvider = StateProvider<String?>(
  (ref) => null,
);

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

/// Active goals for which **today** is a planned action day. Passive goals
/// (repeat off) and repeating goals on an off-day stay out — this list is
/// "what's planned today", not "every active goal" (that's the Goals hub).
final todaysActiveGoalsProvider = Provider<AsyncValue<List<UserGoal>>>((ref) {
  final async = ref.watch(goalsStreamProvider);
  return async.when(
    data: (list) {
      final todayKey = DateKeys.todayKey();
      final todayGoals =
          list
              .where(
                (g) =>
                    g.status == GoalStatus.active &&
                    GoalPeriodHelpers.isGoalActiveOnDateKey(g, todayKey),
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
      final archived =
          list
              .where(
                (g) =>
                    g.status == GoalStatus.paused ||
                    g.status == GoalStatus.completed,
              )
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

final goalDetailProvider = FutureProvider.family<GoalDetailBundle?, String>((
  ref,
  goalId,
) async {
  // watch: re-runs when the repository re-scopes on account switch.
  final repo = ref.watch(goalsRepositoryProvider);
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

/// Lightweight fetch of actions for a single goal — used by the counter sheet
/// to show the action checklist without loading milestones or check-in history.
final goalActionsProvider = FutureProvider.family<List<GoalAction>, String>((
  ref,
  goalId,
) async {
  final repo = ref.watch(goalsRepositoryProvider);
  return repo.getActions(goalId);
});

/// Provides [GoalBlockSyncService] for writing/removing goal time blocks.
final goalBlockSyncServiceProvider = Provider<GoalBlockSyncService>((ref) {
  return GoalBlockSyncService(
    timeBlockSyncService: ref.read(timeBlockSyncServiceProvider),
  );
});

/// Maps goal id → title for all known goals.
///
/// Used by the conflict detection UI so that overlapping goal blocks are
/// shown with a human-readable name instead of a raw UUID.
final goalTitleMapProvider = Provider<Map<String, String>>((ref) {
  final async = ref.watch(goalsStreamProvider);
  return async.whenOrNull(
        data: (list) => {for (final g in list) g.id: g.title},
      ) ??
      const {};
});

void invalidateGoals(WidgetRef ref, {String? goalId}) {
  ref.invalidate(goalsStreamProvider);
  if (goalId != null) {
    ref.invalidate(goalDetailProvider(goalId));
    ref.invalidate(goalTodayProgressProvider(goalId));
    ref.invalidate(goalActionsProvider(goalId));
  }
}

/// Progress snapshot for a single goal combining action completion and
/// the measurement value accumulated over the current evaluation window.
class GoalTodayProgress {
  const GoalTodayProgress({
    required this.currentValue,
    required this.todayValue,
    required this.targetValue,
    required this.progress,
    required this.metCommitment,
    required this.doneActions,
    required this.totalActions,
    this.checkIn,
  });

  /// Amount accumulated in the goal's **current evaluation window** (today /
  /// this week / this month / whole period, per [UserGoal.horizon]).
  final double currentValue;

  /// Amount logged **today** only — the value counter buttons edit this.
  final double todayValue;

  /// The goal's measurement target for the evaluation window.
  final double targetValue;

  /// Fill fraction: [currentValue] / [targetValue], clamped 0.0–1.0.
  /// Drives the card fill bar and the ring in the counter sheet.
  final double progress;

  /// True when the user has explicitly marked today as met.
  final bool metCommitment;

  /// True when the evaluation window's target has been reached.
  bool get periodTargetMet => targetValue > 0 && currentValue >= targetValue;

  /// How many of the goal's actions are completed.
  final int doneActions;

  /// Total number of actions on this goal.
  final int totalActions;

  /// Raw check-in for today, or null if none exists yet.
  final GoalCheckIn? checkIn;
}

/// Fetches progress for a single goal.
///
/// [GoalTodayProgress.currentValue] accumulates check-in values over the
/// goal's current evaluation window (per horizon: day / week / month /
/// entire goal); [GoalTodayProgress.todayValue] is today's log alone.
final goalTodayProgressProvider = FutureProvider.family<GoalTodayProgress, String>((
  ref,
  goalId,
) async {
  final repo = ref.watch(goalsRepositoryProvider);
  final goalAsync = ref.watch(goalsStreamProvider);

  UserGoal? goal;
  goalAsync.whenData((list) {
    try {
      goal = list.firstWhere((g) => g.id == goalId);
    } catch (_) {
      goal = null;
    }
  });

  final target = goal?.targetValue ?? 1.0;
  final dateKey = DateKeys.todayKey();

  // Fetch actions and today's check-in concurrently.
  final results = await Future.wait([
    repo.getActions(goalId),
    repo.getTodayCheckIn(goalId, dateKey),
  ]);

  final actions = results[0] as List<GoalAction>;
  final checkIn = results[1] as GoalCheckIn?;

  // Only actions due today count: one-time steps always, repeating steps on
  // their scheduled weekdays (completion is per-day for those).
  final today = DateKeys.parseLocalDateKey(dateKey);
  final dueToday = actions.where((a) => a.isScheduledOn(today)).toList();
  final totalActions = dueToday.length;
  final doneActions = dueToday.where((a) => a.isCompletedOn(dateKey)).length;
  final todayValue = checkIn?.value ?? 0.0;

  // Accumulate over the evaluation window (one repeat cycle, or the whole
  // period for one-time goals). Single-day windows are today-only, so the
  // extra fetch is skipped.
  var currentValue = todayValue;
  final g = goal;
  if (g != null) {
    final window = GoalPeriodHelpers.evaluationWindow(g, DateTime.now());
    if (window.start != window.end) {
      final windowCheckIns = await repo.getCheckInsForGoal(
        goalId,
        startDateKey: DateKeys.yyyymmdd(window.start),
        endDateKey: DateKeys.yyyymmdd(window.end),
      );
      currentValue = windowCheckIns.fold(
        0.0,
        (sum, c) => sum + (c.value ?? 0),
      );
    }
  }

  final progress = target > 0 ? (currentValue / target).clamp(0.0, 1.0) : 0.0;

  return GoalTodayProgress(
    currentValue: currentValue,
    todayValue: todayValue,
    targetValue: target,
    progress: progress,
    metCommitment: checkIn?.metCommitment ?? false,
    doneActions: doneActions,
    totalActions: totalActions,
    checkIn: checkIn,
  );
});
