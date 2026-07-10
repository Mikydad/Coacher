import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

import '../../../core/local_db/isar_collections/isar_task.dart';
import '../../../core/offline/offline_store.dart';
import '../../analytics/application/analytics_period_bundle_notifier.dart';
import '../../analytics/application/discipline_score.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';
import 'education_prefs.dart';

enum GettingStartedPhase { loading, hidden, active, celebrating }

class GettingStartedState {
  const GettingStartedState({
    required this.phase,
    this.step1TaskCreated = false,
    this.step2TaskCompleted = false,
    this.step3ProgressSeen = false,
  });

  const GettingStartedState.loading()
    : this(phase: GettingStartedPhase.loading);

  final GettingStartedPhase phase;
  final bool step1TaskCreated;
  final bool step2TaskCompleted;
  final bool step3ProgressSeen;

  GettingStartedState copyWith({
    GettingStartedPhase? phase,
    bool? step1TaskCreated,
    bool? step2TaskCompleted,
    bool? step3ProgressSeen,
  }) => GettingStartedState(
    phase: phase ?? this.phase,
    step1TaskCreated: step1TaskCreated ?? this.step1TaskCreated,
    step2TaskCompleted: step2TaskCompleted ?? this.step2TaskCompleted,
    step3ProgressSeen: step3ProgressSeen ?? this.step3ProgressSeen,
  );
}

/// Learn-by-doing onboarding for NEW users: create a task → complete it →
/// see progress react. Steps are DERIVED from real app state (fed by the
/// provider below — never toggled by UI code) and latched, so deleting the
/// task later can't un-check them.
///
/// Lifecycle pref is tri-state ('active'/'done'/absent): the new-vs-existing
/// judgement is made exactly once, so creating your first task doesn't make
/// you look like an existing user on the next launch.
class GettingStartedController extends StateNotifier<GettingStartedState> {
  GettingStartedController(
    this._prefs, {
    Future<bool> Function()? hasExistingDataProbe,
    int Function()? streakReader,
    Duration celebrateFor = const Duration(milliseconds: 2500),
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

  // Latest signals, buffered even before init resolves so nothing emitted
  // during the (fast) prefs read is lost.
  bool _seenTaskCreated = false;
  bool _seenTaskCompleted = false;
  bool _seenProgress = false;

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
      state = state.copyWith(phase: GettingStartedPhase.hidden);
      return;
    }

    if (stored != 'active') {
      // Never evaluated for this account: probe once.
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
        if (mounted) state = state.copyWith(phase: GettingStartedPhase.hidden);
        return;
      }
      await _prefs.setOnboardingState('active');
      if (!mounted) return;
    }

    state = state.copyWith(phase: GettingStartedPhase.active);
    _applySignals();
  }

  /// Fed by the provider's ref.listen on [todayAllTasksRowsProvider].
  void onTaskRows({required bool anyTask, required bool anyCompleted}) {
    _seenTaskCreated = _seenTaskCreated || anyTask;
    _seenTaskCompleted = _seenTaskCompleted || anyCompleted;
    _applySignals();
  }

  /// Fed by the provider's ref.listen on [analyticsPeriodBundleProvider].
  void onProgressSignal({required bool progressed}) {
    _seenProgress = _seenProgress || progressed;
    _applySignals();
  }

  void _applySignals() {
    if (!mounted || state.phase != GettingStartedPhase.active) return;
    final step1 = state.step1TaskCreated || _seenTaskCreated;
    final step2 = state.step2TaskCompleted || _seenTaskCompleted;
    final step3 = state.step3ProgressSeen || (step2 && _seenProgress);
    state = state.copyWith(
      step1TaskCreated: step1,
      step2TaskCompleted: step2,
      step3ProgressSeen: step3,
    );
    if (step3) _celebrate();
  }

  void _celebrate() {
    if (state.phase != GettingStartedPhase.active) return;
    state = state.copyWith(phase: GettingStartedPhase.celebrating);
    _celebrateTimer = Timer(_celebrateFor, () async {
      await _prefs.setOnboardingState('done');
      if (mounted) state = state.copyWith(phase: GettingStartedPhase.hidden);
    });
  }

  /// ✕ button — dismiss forever.
  Future<void> skip() async {
    _celebrateTimer?.cancel();
    await _prefs.setOnboardingState('done');
    if (mounted) state = state.copyWith(phase: GettingStartedPhase.hidden);
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

      return controller;
    });
