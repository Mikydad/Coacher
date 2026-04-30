import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../execution/application/execution_day_loader.dart';
import '../../execution/domain/models/timer_session.dart';
import '../../execution/domain/task_timer_engine.dart';
import '../../planning/application/planned_task_providers.dart';
import '../application/focus_quick_task.dart';
import '../../timer/presentation/timer_session_screen.dart';

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
          ref.read(activeExecutionTaskLabelProvider.notifier).state = args.taskLabel;
          ref.read(executionControllerProvider.notifier).setTask(
            id: args.taskId,
            label: args.taskLabel,
            durationMinutes: args.taskDurationMinutes,
          );
        }
        if (args.autoOpenTimer && mounted) {
          await Navigator.pushNamed(
            context,
            TimerSessionScreen.routeName,
            arguments: TimerLaunchArgs(autoStartDelaySeconds: args.autoStartDelaySeconds),
          );
        }
        return;
      }

      final exec = ref.read(executionControllerProvider);
      final hasRunningTask = exec.targetType == TimerSessionTargetType.task &&
          exec.taskId.isNotEmpty &&
          (exec.phase == ExecutionPhase.inProgress || exec.phase == ExecutionPhase.paused);
      if (!hasRunningTask) return;
      _didHandleLaunchArgs = true;
      ref.read(activeExecutionTaskIdProvider.notifier).state = exec.taskId;
      ref.read(activeExecutionTaskLabelProvider.notifier).state = exec.taskLabel;
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
      invalidateTaskListProviders(ref);
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

  @override
  Widget build(BuildContext context) {
    final selectedTask = ref.watch(activeExecutionTaskLabelProvider);
    final taskList = ref.watch(executionDayTasksProvider);
    final execState = ref.watch(executionControllerProvider);
    final hasRunningTask = execState.targetType == TimerSessionTargetType.task &&
        execState.taskId.isNotEmpty &&
        (execState.phase == ExecutionPhase.inProgress || execState.phase == ExecutionPhase.paused);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quittr'),
        actions: [
          IconButton(
            tooltip: 'Refresh list',
            onPressed: () => ref.invalidate(executionDayTasksProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'SELECTION MODE',
            style: TextStyle(letterSpacing: 3, color: Color(0xFF00E6FF)),
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
          const SizedBox(height: 12),
          const Text(
            "Lists today's plan with open tasks only — same as Home. "
            'Completed tasks stay on Home; add or reopen tasks there if this list is empty.',
            style: TextStyle(color: Colors.white54, fontSize: 14, height: 1.35),
          ),
          const SizedBox(height: 20),
          ...taskList.when(
            data: (tasks) {
              if (tasks.isEmpty) {
                return [
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No open tasks for today. Add one below, from Home, or uncomplete a task on Home if you finished it by mistake.',
                      style: TextStyle(color: Colors.white38, fontSize: 15),
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
                        subtitle: '${task.durationMinutes}m target',
                        selected: selectedTask == task.title,
                        onTap: () {
                          if (hasRunningTask && execState.taskId != task.id) {
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
                          ref
                                  .read(activeExecutionTaskIdProvider.notifier)
                                  .state =
                              task.id;
                          ref
                              .read(activeExecutionTaskLabelProvider.notifier)
                              .state = task
                              .title;
                          ref
                              .read(executionControllerProvider.notifier)
                              .setTask(
                                id: task.id,
                                label: task.title,
                                durationMinutes: task.durationMinutes,
                              );
                        },
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
                  ? const Color(0xFF2B2D31)
                  : const Color(0xFFB7FF00),
              foregroundColor: hasRunningTask ? Colors.white : Colors.black,
            ),
            onPressed: () => Navigator.pushNamed(context, TimerSessionScreen.routeName),
            child: Text(
              hasRunningTask ? 'Running Focus' : 'Start Focus',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Ink(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111317),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected ? const Color(0xFFB7FF00) : Colors.white12,
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
              style: const TextStyle(fontSize: 26, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
