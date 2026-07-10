import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_task.dart';
import '../../../core/offline/offline_store.dart';
import '../../analytics/application/analytics_period_bundle_notifier.dart';
import '../../analytics/application/discipline_score.dart';
import '../../feedback/application/feedback_route_tracker.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';
import 'education_prefs.dart';

/// Where the new user is in the guided first-task tour.
enum TourStep {
  /// Home — spotlight on the ADD TASK tile: "Tap here…".
  tapAddTask,

  /// Add Task screen — spotlight on the title field: "Give it a name".
  nameTask,

  /// Add Task screen — spotlight on the save button: "Now save it".
  saveTask,

  /// Back on Home — small non-blocking hint: "tap the circle when done"
  /// (real life may take hours between creating and finishing the task).
  completeTask,

  /// Celebration — spotlight on the progress card, then auto-finish.
  seeProgress,
}

enum TourStatus { loading, hidden, active }

class GettingStartedState {
  const GettingStartedState({
    required this.status,
    this.step = TourStep.tapAddTask,
  });

  const GettingStartedState.loading() : this(status: TourStatus.loading);

  final TourStatus status;
  final TourStep step;

  bool get isActive => status == TourStatus.active;

  GettingStartedState copyWith({TourStatus? status, TourStep? step}) =>
      GettingStartedState(
        status: status ?? this.status,
        step: step ?? this.step,
      );
}

/// Guided learn-by-doing tour for NEW users. The spotlight overlay renders
/// [GettingStartedState.step]; steps advance ONLY when the user performs the
/// real action (route opened, title typed, task saved/completed) — signals
/// are fed by the provider below and by small hooks in the screens.
///
/// Lifecycle pref is tri-state ('active'/'done'/absent): the new-vs-existing
/// judgement is made exactly once, so creating your first task doesn't make
/// you look like an existing user on the next launch. Invalidated on account
/// switch (user_scoped_invalidation.dart).
class GettingStartedController extends StateNotifier<GettingStartedState> {
  GettingStartedController(
    this._prefs, {
    Future<bool> Function()? hasExistingDataProbe,
    int Function()? streakReader,
    Duration celebrateFor = const Duration(milliseconds: 3500),
  }) : _hasExistingDataProbe = hasExistingDataProbe ?? _defaultProbe,
       _streakReader = streakReader,
       _celebrateFor = celebrateFor,
       super(const GettingStartedState.loading()) {
    _init();
  }

  final EducationPrefs _prefs;
  final Future<bool> Function() _hasExistingDataProbe;
  final int Function()? _streakReader;
  final Duration _celebrateFor;
  Timer? _celebrateTimer;

  // Latest signals, buffered even before init resolves.
  bool _seenTaskCreated = false;
  bool _seenTaskCompleted = false;
  bool _seenProgress = false;
  bool _titleTyped = false;
  String? _topRoute;

  /// Existing-user signal: any task ever stored locally. Safe because
  /// FirstLaunchGate blocks the UI on the remote→local seed, so an existing
  /// account has rows before home builds.
  static Future<bool> _defaultProbe() async {
    final isar = OfflineStore.instance.isar;
    if (isar == null) return false;
    return await isar.isarTasks.where().count() > 0;
  }

  Future<void> _init() async {
    final stored = await _prefs.onboardingState();
    if (!mounted) return;

    if (stored == 'done') {
      state = state.copyWith(status: TourStatus.hidden);
      return;
    }

    if (stored != 'active') {
      var existing = false;
      try {
        existing =
            await _hasExistingDataProbe() || (_streakReader?.call() ?? 0) > 0;
      } catch (_) {
        // A failed probe must not block a brand-new user's onboarding.
      }
      if (!mounted) return;
      if (existing) {
        await _prefs.setOnboardingState('done');
        if (mounted) state = state.copyWith(status: TourStatus.hidden);
        return;
      }
      await _prefs.setOnboardingState('active');
      if (!mounted) return;
    }

    // Resume mid-journey (app killed while 'active'): derive the step from
    // what already happened rather than restarting at "tap here".
    var step = TourStep.tapAddTask;
    if (_seenTaskCompleted) {
      step = TourStep.seeProgress;
    } else if (_seenTaskCreated) {
      step = TourStep.completeTask;
    }
    state = GettingStartedState(status: TourStatus.active, step: step);
    if (step == TourStep.seeProgress) _startCelebrationTimer();
  }

  // ─── Signals (fed by the provider body + screen hooks) ────────────────────

  void onRouteChanged(String? route) {
    _topRoute = route;
    if (!mounted || !state.isActive) return;
    switch (state.step) {
      case TourStep.tapAddTask:
        if (route == '/add-task') {
          state = state.copyWith(step: TourStep.nameTask);
        }
      case TourStep.nameTask:
      case TourStep.saveTask:
        // Left Add Task without saving — point at the tile again.
        if (route != '/add-task' && !_seenTaskCreated) {
          _titleTyped = false;
          state = state.copyWith(step: TourStep.tapAddTask);
        }
      case TourStep.completeTask:
      case TourStep.seeProgress:
        break;
    }
  }

  /// Hook from the Add Task screen's title field.
  void onTaskTitleChanged(String text) {
    _titleTyped = text.trim().isNotEmpty;
    if (!mounted || !state.isActive) return;
    if (state.step == TourStep.nameTask && _titleTyped) {
      state = state.copyWith(step: TourStep.saveTask);
    }
  }

  /// Fed by the provider's ref.listen on today's task rows.
  void onTaskRows({required bool anyTask, required bool anyCompleted}) {
    _seenTaskCreated = _seenTaskCreated || anyTask;
    _seenTaskCompleted = _seenTaskCompleted || anyCompleted;
    if (!mounted || !state.isActive) return;

    if (_seenTaskCompleted &&
        (state.step == TourStep.completeTask ||
            state.step == TourStep.tapAddTask ||
            state.step == TourStep.nameTask ||
            state.step == TourStep.saveTask)) {
      state = state.copyWith(step: TourStep.seeProgress);
      _startCelebrationTimer();
      return;
    }
    if (_seenTaskCreated &&
        (state.step == TourStep.tapAddTask ||
            state.step == TourStep.nameTask ||
            state.step == TourStep.saveTask)) {
      state = state.copyWith(step: TourStep.completeTask);
    }
  }

  /// Fed by the provider's ref.listen on the analytics bundle.
  void onProgressSignal({required bool progressed}) {
    _seenProgress = _seenProgress || progressed;
  }

  /// Whether the analytics number visibly moved (celebration copy hook).
  bool get progressConfirmed => _seenProgress;

  String? get topRoute => _topRoute;

  void _startCelebrationTimer() {
    _celebrateTimer?.cancel();
    _celebrateTimer = Timer(_celebrateFor, () async {
      await _prefs.setOnboardingState('done');
      if (mounted) state = state.copyWith(status: TourStatus.hidden);
    });
  }

  /// Skip button — dismiss forever.
  Future<void> skip() async {
    _celebrateTimer?.cancel();
    await _prefs.setOnboardingState('done');
    if (mounted) state = state.copyWith(status: TourStatus.hidden);
  }

  @override
  void dispose() {
    _celebrateTimer?.cancel();
    super.dispose();
  }
}

final gettingStartedControllerProvider =
    StateNotifierProvider<GettingStartedController, GettingStartedState>((
      ref,
    ) {
      final controller = GettingStartedController(
        ref.watch(educationPrefsProvider),
        streakReader: () => ref.read(homeDisplayStreakDaysProvider),
      );

      // Listeners live in the provider body (ref.listen must be synchronous
      // with provider construction); the controller latches what they feed.
      ref.listen<AsyncValue<List<PlannedTaskRow>>>(
        todayAllTasksRowsProvider,
        (_, next) {
          final rows = next.valueOrNull;
          if (rows == null) return;
          controller.onTaskRows(
            anyTask: rows.isNotEmpty,
            anyCompleted: rows.any(
              (r) =>
                  r.task.status == TaskStatus.completed ||
                  r.task.status == TaskStatus.partial,
            ),
          );
        },
        fireImmediately: true,
      );
      ref.listen(analyticsPeriodBundleProvider, (_, next) {
        final bundle = next.valueOrNull;
        if (bundle == null) return;
        controller.onProgressSignal(
          progressed:
              bundle.taskDay.weightedCompletionRate > 0 ||
              homeDisplayStreakDays(bundle) > 0,
        );
      }, fireImmediately: true);

      // Route changes advance/rewind the tour (reuses the feedback tracker).
      controller.onRouteChanged(FeedbackRouteTracker.topRouteName.value);
      void routeListener() =>
          controller.onRouteChanged(FeedbackRouteTracker.topRouteName.value);
      FeedbackRouteTracker.topRouteName.addListener(routeListener);
      ref.onDispose(
        () => FeedbackRouteTracker.topRouteName.removeListener(routeListener),
      );

      return controller;
    });
