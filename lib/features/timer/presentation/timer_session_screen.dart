import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../reminders/presentation/recovery_navigation.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../execution/application/execution_controller.dart';
import '../../execution/domain/task_timer_engine.dart';
import '../../execution/domain/models/timer_session.dart';
import '../../planning/application/auto_next_task_flow.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../scoring/presentation/score_task_dialog.dart';
import '../../education/presentation/help_dot.dart';
import '../../planning/application/planned_task_actions.dart';
import '../../time_blocks/application/time_block_providers.dart';

import 'focus_stage.dart';

class TimerLaunchArgs {
  const TimerLaunchArgs({this.autoStartDelaySeconds});

  final int? autoStartDelaySeconds;
}

class TimerSessionScreen extends ConsumerStatefulWidget {
  const TimerSessionScreen({super.key, this.launchArgs});

  static const routeName = '/timer';

  final TimerLaunchArgs? launchArgs;

  @override
  ConsumerState<TimerSessionScreen> createState() => _TimerSessionScreenState();
}

class _TimerSessionScreenState extends ConsumerState<TimerSessionScreen> {
  Timer? _autoStartTicker;
  int? _remainingAutoStartSeconds;
  bool _autoStartCancelled = false;
  bool _isHandlingStopFlow = false;
  bool _autoStopQueued = false;

  /// The "task done" celebration (2026-09-27). Set when a session ends at
  /// 100%; stays on screen (under any next-task dialog) until the route
  /// goes. [_celebrationDone] completes on Continue / Back.
  ({String label, int minutes})? _celebration;
  Completer<void>? _celebrationDone;

  @override
  void initState() {
    super.initState();
    final secs = widget.launchArgs?.autoStartDelaySeconds;
    if (secs != null && secs > 0) {
      _remainingAutoStartSeconds = secs;
      _autoStartTicker = Timer.periodic(const Duration(seconds: 1), (t) {
        final execState = ref.read(executionControllerProvider);
        if (_autoStartCancelled ||
            execState.phase != ExecutionPhase.notStarted) {
          t.cancel();
          return;
        }
        final next = (_remainingAutoStartSeconds ?? 0) - 1;
        if (next <= 0) {
          t.cancel();
          _startSession(ref.read(executionControllerProvider));
          return;
        }
        if (mounted) {
          setState(() => _remainingAutoStartSeconds = next);
        }
      });
    }
  }

  @override
  void dispose() {
    _autoStartTicker?.cancel();
    super.dispose();
  }

  void _startSession(ExecutionState execState) {
    final ctrl = ref.read(executionControllerProvider.notifier);
    if (execState.phase != ExecutionPhase.notStarted) return;
    ctrl.start();
    if (execState.targetType == TimerSessionTargetType.task &&
        execState.taskId.isNotEmpty) {
      unawaited(
        ref
            .read(reminderSyncServiceProvider)
            .markTaskStarted(
              execState.taskId,
              // The dynamic Focus Shield (FR-R-32): other entities' armed
              // slots inside this session are silenced for its duration.
              sessionLength: (execState.targetDurationMinutes ?? 0) > 0
                  ? Duration(minutes: execState.targetDurationMinutes!)
                  : null,
            ),
      );
    }
    if (mounted) {
      setState(() {
        _remainingAutoStartSeconds = null;
      });
    }
  }

  /// End pressed by hand. Under a minute in, ask first (Miko, 2026-09-27):
  /// an accidental End at 0:25 stopped the timer and opened the rating
  /// card. Auto-stop at the planned duration never asks.
  Future<void> _confirmThenStop({required String activeLabel}) async {
    final latest = ref.read(executionControllerProvider);
    final elapsed = latest.elapsed;
    if (latest.phase != ExecutionPhase.finished &&
        elapsed < const Duration(minutes: 1)) {
      final seconds = elapsed.inSeconds;
      final end = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('End session?'),
          content: Text(
            "You've focused for $seconds "
            '${seconds == 1 ? 'second' : 'seconds'}.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('End'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep going'),
            ),
          ],
        ),
      );
      if (end != true || !mounted) return;
    }
    await _handleStopFlow(
      execState: ref.read(executionControllerProvider),
      activeLabel: activeLabel,
    );
  }

  /// Shows the celebration and returns a future that completes when the
  /// user taps Continue (or Back).
  Future<void> _showCelebration(String label, Duration focused) {
    final done = Completer<void>();
    setState(() {
      _celebration = (label: label, minutes: focused.inMinutes);
      _celebrationDone = done;
    });
    return done.future;
  }

  void _finishCelebration() {
    final done = _celebrationDone;
    if (done == null || done.isCompleted) return;
    setState(() => done.complete());
  }

  Future<void> _handleStopFlow({
    required ExecutionState execState,
    required String activeLabel,
  }) async {
    final ctrl = ref.read(executionControllerProvider.notifier);
    if (_isHandlingStopFlow || execState.phase == ExecutionPhase.notStarted) {
      return;
    }
    if (mounted) {
      setState(() => _isHandlingStopFlow = true);
    } else {
      _isHandlingStopFlow = true;
    }
    try {
      // Already-finished sessions were persisted by the first stop — never
      // write a duplicate TimerSession row for a second press.
      if (execState.phase != ExecutionPhase.finished) {
        await ctrl.stopAndPersist();
      }
      if (!mounted) return;
      if (execState.targetType == TimerSessionTargetType.block) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Block timer session saved.')),
        );
        return;
      }
      // The completion rate is computed, not asked (2026-08-25): worked
      // elapsed vs the planned duration. Working the full planned time IS
      // completion — no rating card, no reason, in every mode.
      final targetMinutes = execState.targetDurationMinutes;
      final int? computedPercent = (targetMinutes != null && targetMinutes > 0)
          ? ((execState.elapsed.inSeconds / (targetMinutes * 60)) * 100)
                .clamp(0.0, 100.0)
                .round()
          : null;
      // Discipline-mode contract for the post-session rating:
      // flexible → dismissible; dismissing keeps the worked time, records
      //   no score, and returns to the Focus page;
      // disciplined → a score to record one (reason below its 90% bar);
      // extreme → a score AND a reason at any percentage.
      // Strict modes can still leave after a "Leave without rating?" check
      // (2026-09-27) — same outcome as flexible's dismiss.
      final mode = await effectiveModeRefIdForTaskId(ref, execState.taskId);
      if (!mounted) return;
      final ScoreTaskDialogResult? result;
      if (computedPercent != null && computedPercent >= 100) {
        result = const ScoreTaskDialogResult(
          completionPercent: 100,
          reason: null,
        );
      } else {
        result = await ScoreTaskDialog.show(
          context,
          taskTitle: activeLabel,
          requireSubmit: mode == 'disciplined' || mode == 'extreme',
          requireReasonAlways: mode == 'extreme',
          initialPercent: computedPercent ?? 100,
          reasonThresholdPercent: ScoreTaskDialog.reasonThresholdForMode(mode),
          leaveMessage:
              "Your focus time is saved. The task stays open — it isn't "
              'marked done. Start it again to pick up where you left off.',
        );
      }
      if (!mounted) return;
      if (result == null) {
        // Cancel: the worked time is already saved; no score is recorded,
        // and the user lands back where tasks are chosen — never stranded
        // on a dead timer.
        await returnToFocusList(context, ref);
        return;
      }
      // Celebrate at once (the saves below run under it); the rest of the
      // flow waits for Continue.
      final celebrated = result.completionPercent >= 100
          ? _showCelebration(activeLabel, execState.elapsed)
          : null;
      await ref
          .read(scoringControllerProvider)
          .submit(
            taskId: execState.taskId,
            completionPercent: result.completionPercent,
            reason: result.reason,
          );
      fireAndForgetAnalyticsEvent(
        ref,
        type: result.completionPercent >= 100
            ? AnalyticsEventType.taskCompleted
            : AnalyticsEventType.taskDeferred,
        entityId: execState.taskId,
        entityKind: 'task',
        sourceSurface: 'timer_session',
        idempotencyKey:
            '${result.completionPercent >= 100 ? 'task_completed' : 'task_deferred'}_${execState.taskId}_${DateTime.now().millisecondsSinceEpoch}',
        reason: result.reason,
      );
      await _syncTaskStatusFromScore(
        taskId: execState.taskId,
        completionPercent: result.completionPercent,
      );
      invalidateTaskListProviders(ref);

      // Phase A — check for reclaimed time on full completion.
      if (result.completionPercent >= 100) {
        await ref
            .read(executionControllerProvider.notifier)
            .clearResumePoint(execState.taskId);
        await _checkReclaimedTime(execState.taskId);
      }
      final prev = ref.read(scoredTaskStatusesProvider);
      ref.read(scoredTaskStatusesProvider.notifier).state = {
        ...prev,
        execState.taskId: result.completionPercent,
      };
      if (celebrated != null) {
        await celebrated;
      } else if (mounted) {
        final minutes = execState.elapsed.inMinutes;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              minutes >= 1
                  ? 'Saved: ${result.completionPercent}% done · '
                        '$minutes min of focus.'
                  : 'Saved: ${result.completionPercent}% done.',
            ),
          ),
        );
      }
      if (!mounted) return;
      // The strongest recovery moment (§3.6): a session just ended, so the
      // user is between things. Shows only when something is genuinely open,
      // and before the auto-next flow so it cannot interrupt it midway.
      try {
        await showRecoveryPromptIfNeeded(context, ref);
      } catch (e) {
        debugPrint('[TimerSession] recovery prompt failed: $e');
      }
      if (!mounted) return;
      if (result.completionPercent >= 100) {
        // A throw in the next-task lookup must never strand the user on
        // the dead timer — the terminal navigation below still runs.
        try {
          await runAutoNextTaskFlow(
            context,
            ref,
            completedTaskId: execState.taskId,
            completionPercent: result.completionPercent,
          );
        } catch (e) {
          debugPrint('[TimerSession] auto-next failed: $e');
        }
      } else {
        await returnToFocusList(context, ref);
      }
      // The rating is saved at this point — ending a session ALWAYS lands
      // on the Focus list where tasks are chosen (2026-08-25), no matter
      // where the timer was launched from. Most paths above already
      // navigated (returnToFocusList, or "Start now" pushing the next
      // task's timer on top); this catches the rest — no next task
      // available, a next-task sub-dialog cancelled, or auto-next threw.
      // Guarded on isCurrent so a route pushed on top is never yanked.
      _autoReturnToFocusIfStillCurrent();
    } finally {
      if (mounted) {
        setState(() => _isHandlingStopFlow = false);
      } else {
        _isHandlingStopFlow = false;
      }
    }
  }

  /// Routes to the Focus list once the post-session rating flow has fully
  /// settled, but only if nothing else already navigated away.
  /// `route.isCurrent` is false when another screen (e.g. Focus, or a
  /// freshly-pushed timer for the auto-next task) is now on top, so this
  /// is a no-op in that case. A plain pop used to land wherever the timer
  /// was launched from (Home, task detail) — ending a session should
  /// always return to where tasks are chosen (2026-08-25).
  void _autoReturnToFocusIfStillCurrent() {
    if (!mounted) return;
    final route = ModalRoute.of(context);
    if (route == null || !route.isCurrent) return;
    unawaited(returnToFocusList(context, ref));
  }

  Future<void> _checkReclaimedTime(String taskId) async {
    try {
      final service = ref.read(reclaimedTimeServiceProvider);
      final window = await service.checkEarlyCompletion(entityId: taskId);
      if (window == null || !mounted) return;

      // Log analytics event for any reclaimed time ≥ 1 min.
      fireAndForgetAnalyticsEvent(
        ref,
        type: AnalyticsEventType.reclaimedTimeGenerated,
        entityId: taskId,
        entityKind: 'task',
        sourceSurface: 'timer_session',
        idempotencyKey: 'reclaimed_${taskId}_${window.createdAtMs}',
        reason: '${window.durationMinutes}min_reclaimed',
      );

      // Show suggestion snackbar only when ≥ 10 minutes freed.
      if (window.durationMinutes >= 10 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You freed up ${window.durationMinutes} minutes. '
              'Want to tackle something from your list?',
            ),
            duration: const Duration(seconds: 6),
            action: SnackBarAction(
              label: 'View tasks',
              onPressed: () {
                fireAndForgetAnalyticsEvent(
                  ref,
                  type: AnalyticsEventType.reclaimedTimeUsed,
                  entityId: taskId,
                  entityKind: 'task',
                  sourceSurface: 'timer_session_snackbar',
                  idempotencyKey:
                      'reclaimed_used_${taskId}_${window.createdAtMs}',
                );
                if (mounted) Navigator.popUntil(context, (r) => r.isFirst);
              },
            ),
          ),
        );
      }
    } catch (_) {
      // Non-fatal — reclaimed time is a passive suggestion.
    }
  }

  Future<void> _syncTaskStatusFromScore({
    required String taskId,
    required int completionPercent,
  }) async {
    final rows = await readFreshTodayPlannedRows(ref);
    PlannedTaskRow? row;
    for (final item in rows) {
      if (item.task.id == taskId) {
        row = item;
        break;
      }
    }
    if (row == null) return;
    final t = row.task;
    final nextStatus = completionPercent >= 100
        ? TaskStatus.completed
        : TaskStatus.partial;
    if (t.status == nextStatus) return;
    final updated = PlannedTask(
      id: t.id,
      routineId: t.routineId,
      blockId: t.blockId,
      title: t.title,
      durationMinutes: t.durationMinutes,
      priority: t.priority,
      orderIndex: t.orderIndex,
      reminderEnabled: t.reminderEnabled,
      reminderTimeIso: t.reminderTimeIso,
      status: nextStatus,
      createdAtMs: t.createdAtMs,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      category: t.category,
      planDateKey: t.planDateKey ?? row.dateKey,
      notes: t.notes,
      sequenceIndex: t.sequenceIndex,
      isHabitAnchor: t.isHabitAnchor,
      strictModeRequired: t.strictModeRequired,
      modeRefId: t.modeRefId,
    );
    await ref.read(planningRepositoryProvider).upsertTask(updated);
    // migrated to coordinator
    await ScheduleMutationCoordinator.instance.run(
      nextStatus == TaskStatus.completed
          ? TaskCompletedMutation(
              entityId: t.id,
              sourceContext: 'timer_session_screen',
              dateStr: t.planDateKey ?? row.dateKey,
            )
          : TaskUpdatedMutation(
              entityId: t.id,
              sourceContext: 'timer_session_screen',
              dateStr: t.planDateKey ?? row.dateKey,
            ),
      commitOverride: () async {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final execState = ref.watch(executionControllerProvider);
    final ctrl = ref.read(executionControllerProvider.notifier);
    final running = execState.phase == ExecutionPhase.inProgress;
    final paused = execState.phase == ExecutionPhase.paused;
    final elapsed = execState.elapsed;
    final activeLabel = execState.targetType == TimerSessionTargetType.task
        ? execState.taskLabel
        : execState.blockLabel;
    final mins = elapsed.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = elapsed.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hrs = elapsed.inHours;
    final timerText = hrs > 0
        ? '${hrs.toString().padLeft(2, '0')}:$mins:$secs'
        : '$mins:$secs';

    final showAutoStart =
        execState.phase == ExecutionPhase.notStarted &&
        !_autoStartCancelled &&
        (_remainingAutoStartSeconds ?? 0) > 0;
    // No target (or a 0 one, e.g. from an older runtime cache) = open-ended:
    // never auto-stop at 0:00.
    final targetDuration =
        execState.targetType == TimerSessionTargetType.task &&
            (execState.targetDurationMinutes ?? 0) > 0
        ? Duration(minutes: execState.targetDurationMinutes!)
        : null;
    final shouldAutoStop =
        running &&
        targetDuration != null &&
        elapsed >= targetDuration &&
        !_isHandlingStopFlow;
    if (shouldAutoStop && !_autoStopQueued) {
      _autoStopQueued = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _autoStopQueued = false;
        if (!mounted) return;
        final latest = ref.read(executionControllerProvider);
        if (latest.phase != ExecutionPhase.inProgress) return;
        await _handleStopFlow(execState: latest, activeLabel: activeLabel);
      });
    }

    final notStarted = execState.phase == ExecutionPhase.notStarted;
    final canEnd = !notStarted && !_isHandlingStopFlow;
    // After End (saving, rating) the session is over: say so instead of
    // "Ready", and Start stays off until the flow moves on.
    final ended =
        _isHandlingStopFlow || execState.phase == ExecutionPhase.finished;
    final celebration = _celebration;

    if (celebration != null) {
      final waiting = _celebrationDone?.isCompleted == false;
      return PopScope(
        canPop: !waiting,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _finishCelebration();
        },
        child: FocusStageScaffold(
          title: 'Focus session',
          body: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Center(
                  child: FocusCelebration(
                    ringSize: focusRingSize(constraints) * 0.9,
                    taskLabel: celebration.label,
                    focusedMinutes: celebration.minutes,
                    onContinue: waiting ? _finishCelebration : null,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return FocusStageScaffold(
      title: 'Focus session',
      actions: const [HelpAppBarButton('focus')],
      body: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SizedBox(height: 8),
                FocusRing(
                  size: focusRingSize(constraints),
                  progress: targetDuration == null
                      ? null
                      : elapsed.inMilliseconds / targetDuration.inMilliseconds,
                  timeText: timerText,
                  statusLabel: ended
                      ? 'Session ended'
                      : running
                      ? 'Focus'
                      : paused
                      ? 'Paused'
                      : 'Ready',
                  statusIcon: ended
                      ? Icons.stop_circle_outlined
                      : paused
                      ? Icons.pause_rounded
                      : Icons.track_changes_rounded,
                  chipLabel: targetDuration == null
                      ? 'No time limit'
                      : 'of ${targetDuration.inMinutes} min',
                  dimmed: paused,
                ),
                Column(
                  children: [
                    const SizedBox(height: 28),
                    if (showAutoStart) ...[
                      FocusNotice(
                        text: 'Auto-starting in ${_remainingAutoStartSeconds}s',
                        action: TextButton(
                          onPressed: () {
                            _autoStartTicker?.cancel();
                            setState(() {
                              _autoStartCancelled = true;
                              _remainingAutoStartSeconds = null;
                            });
                          },
                          child: Text(
                            'Cancel',
                            style: TextStyle(color: FocusColors.accent),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                    FocusControls(
                      primary: FocusRoundButton(
                        primary: true,
                        icon: running
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        label: running
                            ? 'Pause'
                            : paused
                            ? 'Resume'
                            : 'Start',
                        onPressed: ended
                            ? null
                            : () {
                                if (running) {
                                  ctrl.pause();
                                } else if (paused) {
                                  ctrl.resume();
                                } else {
                                  _autoStartTicker?.cancel();
                                  _remainingAutoStartSeconds = null;
                                  _startSession(execState);
                                }
                              },
                      ),
                      secondary: FocusRoundButton(
                        icon: Icons.stop_rounded,
                        label: _isHandlingStopFlow ? 'Saving...' : 'End',
                        busy: _isHandlingStopFlow,
                        onPressed: canEnd
                            ? () => _confirmThenStop(activeLabel: activeLabel)
                            : null,
                      ),
                    ),
                    if (execState.readyToScore) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Task is now marked as ready for scoring.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: FocusColors.textSecondary),
                      ),
                    ],
                    const SizedBox(height: 28),
                  ],
                ),
                FocusWorkingOnCard(title: activeLabel),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
