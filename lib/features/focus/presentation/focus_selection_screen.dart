import '../../education/presentation/first_time_feature_card.dart';
import '../../education/presentation/help_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/keyboard_dismiss.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../execution/application/execution_day_loader.dart';
import '../../planning/domain/models/task_item.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../planning/domain/add_task_duration.dart';
import '../application/focus_quick_task.dart';
import '../application/focus_task_resume.dart';
import '../../timer/presentation/timer_session_screen.dart';
import '../../home/presentation/pathpal_app_bar_title.dart';
import 'focus_session_duration_picker.dart';

import '../../../core/presentation/app_colors.dart';

class FocusLaunchArgs {
  const FocusLaunchArgs({
    required this.taskId,
    required this.taskLabel,
    this.taskDurationMinutes,
    this.autoOpenTimer = false,
    this.autoStartDelaySeconds = 10,
  });

  final String taskId;
  final String taskLabel;
  final int? taskDurationMinutes;
  final bool autoOpenTimer;
  final int autoStartDelaySeconds;
}

class FocusSelectionScreen extends ConsumerStatefulWidget {
  const FocusSelectionScreen({super.key, this.launchArgs});

  static const routeName = '/focus';
  final FocusLaunchArgs? launchArgs;

  @override
  ConsumerState<FocusSelectionScreen> createState() =>
      _FocusSelectionScreenState();
}

class _FocusSelectionScreenState extends ConsumerState<FocusSelectionScreen> {
  final _quickController = TextEditingController();
  bool _quickBusy = false;
  bool _didHandleLaunchArgs = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _didHandleLaunchArgs) return;
      final args = widget.launchArgs;
      if (args != null) {
        _didHandleLaunchArgs = true;
        if (args.taskId.isNotEmpty) {
          ref.read(activeExecutionTaskIdProvider.notifier).state = args.taskId;
          ref.read(activeExecutionTaskLabelProvider.notifier).state =
              args.taskLabel;
          ref
              .read(executionControllerProvider.notifier)
              .setTask(
                id: args.taskId,
                label: args.taskLabel,
                durationMinutes: args.taskDurationMinutes,
              );
        }
        if (args.autoOpenTimer && mounted) {
          await Navigator.pushNamed(
            context,
            TimerSessionScreen.routeName,
            arguments: TimerLaunchArgs(
              autoStartDelaySeconds: args.autoStartDelaySeconds,
            ),
          );
        }
        return;
      }

      final exec = ref.read(executionControllerProvider);
      if (!exec.hasActiveFocusTask) return;
      _didHandleLaunchArgs = true;
      ref.read(activeExecutionTaskIdProvider.notifier).state = exec.taskId;
      ref.read(activeExecutionTaskLabelProvider.notifier).state =
          exec.taskLabel;
      if (mounted) {
        await Navigator.pushNamed(context, TimerSessionScreen.routeName);
      }
    });
  }

  @override
  void dispose() {
    _quickController.dispose();
    super.dispose();
  }

  Future<void> _onQuickAdd() async {
    if (_quickBusy) return;
    final text = _quickController.text;
    if (text.trim().isEmpty) return;
    setState(() => _quickBusy = true);
    try {
      await persistQuickPlannedTaskForToday(
        ref.read(planningRepositoryProvider),
        text,
      );
      if (!mounted) return;
      _quickController.clear();
      // migrated to coordinator
      await ScheduleMutationCoordinator.instance.run(
        TaskCreatedMutation(
          entityId: 'focus_quick_add',
          sourceContext: 'focus_selection_screen',
          dateStr: DateKeys.todayKey(),
        ),
        commitOverride: () async {},
      );
      if (!mounted) return;
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not create task: $e')));
      }
    } finally {
      if (mounted) setState(() => _quickBusy = false);
    }
  }

  Future<int?> _resolveFocusDurationMinutes(ExecutionTaskItem task) async {
    if (taskHasFocusDuration(task.durationMinutes)) {
      return task.durationMinutes;
    }
    return showFocusSessionDurationPicker(context, taskTitle: task.title);
  }

  Future<void> _selectTask(ExecutionTaskItem task) async {
    final execState = ref.read(executionControllerProvider);
    if (execState.hasActiveFocusTask && execState.taskId != task.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task "${execState.taskLabel}" is already running. '
            'Finish or stop it before switching focus.',
          ),
        ),
      );
      return;
    }

    ref.read(activeExecutionTaskIdProvider.notifier).state = task.id;
    ref.read(activeExecutionTaskLabelProvider.notifier).state = task.title;

    final focusMinutes = taskHasFocusDuration(task.durationMinutes)
        ? task.durationMinutes
        : null;
    ref
        .read(executionControllerProvider.notifier)
        .setTask(id: task.id, label: task.title, durationMinutes: focusMinutes);

    fireAndForgetAnalyticsEvent(
      ref,
      type: AnalyticsEventType.taskStarted,
      entityId: task.id,
      entityKind: 'task',
      sourceSurface: 'focus_selection',
      idempotencyKey:
          'task_started_focus_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  Future<void> _openTimerForSelectedTask(List<ExecutionTaskItem> tasks) async {
    final selectedId = ref.read(activeExecutionTaskIdProvider);
    ExecutionTaskItem? selected;
    for (final task in tasks) {
      if (task.id == selectedId) {
        selected = task;
        break;
      }
    }
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a task to start focus.')),
      );
      return;
    }

    final minutes = await _resolveFocusDurationMinutes(selected);
    if (!mounted || minutes == null) return;

    var resumeElapsed = Duration.zero;
    var targetMinutes = minutes;
    if (selected.status == TaskStatus.partial) {
      resumeElapsed = await readPriorFocusElapsedForTask(ref, selected.id);
      // Extend the auto-stop target past what was already done so the timer
      // keeps running instead of stopping the instant Start is pressed.
      if (resumeElapsed > Duration.zero) {
        targetMinutes = minutes + resumeElapsed.inMinutes;
      }
    }

    ref
        .read(executionControllerProvider.notifier)
        .setTask(
          id: selected.id,
          label: selected.title,
          durationMinutes: targetMinutes,
          resumeElapsed: resumeElapsed,
        );

    if (!mounted) return;
    if (resumeElapsed > Duration.zero) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Continuing from ${formatFocusElapsed(resumeElapsed)}'),
        ),
      );
    }
    await Navigator.pushNamed(context, TimerSessionScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final selectedTask = ref.watch(activeExecutionTaskLabelProvider);
    final taskList = ref.watch(executionDayTasksProvider);
    final scores = ref.watch(scoredTaskStatusesProvider);
    // Scoped watch: avoids rebuilding this screen on every 1-second
    // `elapsed` tick while a session runs.
    final hasRunningTask = ref.watch(
      executionControllerProvider.select((s) => s.hasActiveFocusTask),
    );

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      // Swipe right anywhere to go back Home — augments the iOS edge-swipe so a
      // full-width rightward drag pops back to the previous (Home) route.
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity;
        if (velocity != null &&
            velocity > 250 &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const PathPalAppBarTitle(),
          actions: [
            const HelpAppBarButton('focus'),
            IconButton(
              tooltip: 'Refresh list',
              onPressed: () => ref.invalidate(executionDayTasksProvider),
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: KeyboardDismissOnTap(
          child: ListView(
          padding: const EdgeInsets.all(16),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          children: [
            const FirstTimeFeatureCard(guideId: 'focus'),
            Text(
              'SELECTION MODE',
              style: TextStyle(letterSpacing: 3, color: AppColors.cyan),
            ),
            const SizedBox(height: 12),
            const Text(
              'What task do you want\nto focus on?',
              style: TextStyle(
                fontSize: 48,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ...taskList.when(
              data: (tasks) {
                if (tasks.isEmpty) {
                  return [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No tasks today.',
                        style: TextStyle(color: AppColors.fg38, fontSize: 15),
                      ),
                    ),
                  ];
                }
                return tasks
                    .map(
                      (task) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TaskCard(
                          title: task.title,
                          subtitle: focusTaskListSubtitle(
                            task: task,
                            scores: scores,
                          ),
                          isPartial: task.status == TaskStatus.partial,
                          selected: selectedTask == task.title,
                          onTap: () => _selectTask(task),
                        ),
                      ),
                    )
                    .toList();
              },
              loading: () => const [
                Padding(
                  padding: EdgeInsets.all(18),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Text(
                    'Could not load tasks. Check your connection and try leaving this screen and opening Focus again.\n\n$e',
                    style: TextStyle(color: Colors.red.shade200),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            TextField(
              controller: _quickController,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onQuickAdd(),
              decoration: InputDecoration(
                hintText: 'Create Quick Task…',
                suffixIcon: IconButton(
                  onPressed: _quickBusy ? null : _onQuickAdd,
                  icon: _quickBusy
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.add_circle),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
                backgroundColor: hasRunningTask
                    ? AppColors.dark2B2D31
                    : AppColors.accent,
                foregroundColor: hasRunningTask
                    ? AppColors.fg
                    : AppColors.onAccent,
              ),
              onPressed: hasRunningTask
                  ? () => Navigator.pushNamed(
                      context,
                      TimerSessionScreen.routeName,
                    )
                  : taskList.maybeWhen(
                      data: (tasks) =>
                          () => _openTimerForSelectedTask(tasks),
                      orElse: () => null,
                    ),
              child: Text(
                hasRunningTask ? 'Running Focus' : 'Start Focus',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
          ),
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    this.isPartial = false,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final bool isPartial;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfacePanel,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? AppColors.accent
                : isPartial
                ? AppColors.amber.withValues(alpha: 0.55)
                : AppColors.fg12,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 26,
                color: isPartial ? AppColors.amber : AppColors.fg60,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
