import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  // Fully local-first: reads/writes hit Isar; Firestore replication happens
  // in the background (outbox push + RemoteIsarMerge pull), so no client
  // needs to be pinned here.
  (ref) => IsarGoalsRepository(),
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

/// Live Isar watches — one stream per goal aspect. These are the single door
/// through which ALL updates reach the UI: a local tick and a background sync
/// pull both write Isar, Isar emits, screens rebuild in one frame. No
/// invalidation, no refetch.
final goalStreamProvider = StreamProvider.family<UserGoal?, String>(
  (ref, goalId) => ref.watch(goalsRepositoryProvider).watchGoal(goalId),
);

final goalActionsStreamProvider =
    StreamProvider.family<List<GoalAction>, String>(
      (ref, goalId) => ref.watch(goalsRepositoryProvider).watchActions(goalId),
    );

final goalMilestonesStreamProvider =
    StreamProvider.family<List<GoalMilestone>, String>(
      (ref, goalId) =>
          ref.watch(goalsRepositoryProvider).watchMilestones(goalId),
    );

final goalCheckInsStreamProvider =
    StreamProvider.family<List<GoalCheckIn>, String>(
      (ref, goalId) => ref.watch(goalsRepositoryProvider).watchCheckIns(goalId),
    );

/// Detail bundle assembled synchronously from the four watch streams above.
/// Same [AsyncValue] surface as the old FutureProvider, so call sites keep
/// their `.when(...)` handling — but data now arrives from local Isar in one
/// frame and stays live.
final goalDetailProvider =
    Provider.family<AsyncValue<GoalDetailBundle?>, String>((ref, goalId) {
      final goalAsync = ref.watch(goalStreamProvider(goalId));
      final actionsAsync = ref.watch(goalActionsStreamProvider(goalId));
      final milestonesAsync = ref.watch(goalMilestonesStreamProvider(goalId));
      final checkInsAsync = ref.watch(goalCheckInsStreamProvider(goalId));

      for (final async in [
        goalAsync,
        actionsAsync,
        milestonesAsync,
        checkInsAsync,
      ]) {
        final err = async.whenOrNull(error: (e, st) => (e, st));
        if (err != null) return AsyncValue.error(err.$1, err.$2);
      }
      if (goalAsync.isLoading ||
          actionsAsync.isLoading ||
          milestonesAsync.isLoading ||
          checkInsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      final goal = goalAsync.valueOrNull;
      if (goal == null) return const AsyncValue.data(null);
      return AsyncValue.data(
        GoalDetailBundle(
          goal: goal,
          actions: actionsAsync.valueOrNull ?? const [],
          milestones: milestonesAsync.valueOrNull ?? const [],
          checkIns: checkInsAsync.valueOrNull ?? const [],
        ),
      );
    });

/// Live actions for a single goal — used by the counter sheet to show the
/// checklist without loading milestones or check-in history.
final goalActionsProvider =
    Provider.family<AsyncValue<List<GoalAction>>, String>(
      (ref, goalId) => ref.watch(goalActionsStreamProvider(goalId)),
    );

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

/// Historically forced a refetch after every goal mutation. All goal
/// providers are now live Isar watches, so the mutation's own local write is
/// what updates the UI — invalidating the streams here would only re-subscribe
/// them and flash a loading state. Kept as a no-op so call sites stay valid;
/// prefer removing calls as code is touched.
void invalidateGoals(WidgetRef ref, {String? goalId}) {}

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
final goalTodayProgressProvider =
    Provider.family<AsyncValue<GoalTodayProgress>, String>((ref, goalId) {
      final goalsAsync = ref.watch(goalsStreamProvider);
      final actionsAsync = ref.watch(goalActionsStreamProvider(goalId));
      final checkInsAsync = ref.watch(goalCheckInsStreamProvider(goalId));

      for (final async in [actionsAsync, checkInsAsync]) {
        final err = async.whenOrNull(error: (e, st) => (e, st));
        if (err != null) return AsyncValue.error(err.$1, err.$2);
      }
      if (actionsAsync.isLoading || checkInsAsync.isLoading) {
        return const AsyncValue.loading();
      }

      UserGoal? goal;
      for (final g in goalsAsync.valueOrNull ?? const <UserGoal>[]) {
        if (g.id == goalId) {
          goal = g;
          break;
        }
      }

      final target = goal?.targetValue ?? 1.0;
      final dateKey = DateKeys.todayKey();
      final actions = actionsAsync.valueOrNull ?? const <GoalAction>[];
      final checkIns = checkInsAsync.valueOrNull ?? const <GoalCheckIn>[];

      GoalCheckIn? checkIn;
      for (final c in checkIns) {
        if (c.dateKey == dateKey) {
          checkIn = c;
          break;
        }
      }

      // Only actions due today count: one-time steps always, repeating steps
      // on their scheduled weekdays (completion is per-day for those).
      final today = DateKeys.parseLocalDateKey(dateKey);
      final dueToday = actions.where((a) => a.isScheduledOn(today)).toList();
      final totalActions = dueToday.length;
      final doneActions = dueToday
          .where((a) => a.isCompletedOn(dateKey))
          .length;
      final todayValue = checkIn?.value ?? 0.0;

      // Accumulate over the evaluation window (one repeat cycle, or the whole
      // period for one-time goals). All data is local — this is pure math.
      var currentValue = todayValue;
      if (goal != null) {
        final window = GoalPeriodHelpers.evaluationWindow(goal, DateTime.now());
        if (window.start != window.end) {
          final startKey = DateKeys.yyyymmdd(window.start);
          final endKey = DateKeys.yyyymmdd(window.end);
          currentValue = checkIns
              .where(
                (c) =>
                    c.dateKey.compareTo(startKey) >= 0 &&
                    c.dateKey.compareTo(endKey) <= 0,
              )
              .fold(0.0, (sum, c) => sum + (c.value ?? 0));
        }
      }

      final progress = target > 0
          ? (currentValue / target).clamp(0.0, 1.0)
          : 0.0;

      return AsyncValue.data(
        GoalTodayProgress(
          currentValue: currentValue,
          todayValue: todayValue,
          targetValue: target,
          progress: progress,
          metCommitment: checkIn?.metCommitment ?? false,
          doneActions: doneActions,
          totalActions: totalActions,
          checkIn: checkIn,
        ),
      );
    });
