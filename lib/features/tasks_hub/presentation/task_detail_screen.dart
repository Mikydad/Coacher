import 'package:flutter/material.dart';

import '../../education/presentation/help_dot.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../add_task/presentation/add_task_screen.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../planning/application/effective_task_mode.dart';
import '../../planning/application/planned_task_actions.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/domain/add_task_duration.dart';
import '../../planning/domain/models/block.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/task_item.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../timer/presentation/timer_session_screen.dart';

/// Navigation arguments for [TaskDetailScreen]; mirrors [AddTaskEditArgs]
/// so any surface that can open the editor can open the detail page.
class TaskDetailArgs {
  const TaskDetailArgs({
    required this.taskId,
    required this.routineId,
    required this.blockId,
    required this.dateKey,
  });

  final String taskId;
  final String routineId;
  final String blockId;

  /// `Routine.dateKey` for this task's plan day.
  final String dateKey;

  static TaskDetailArgs fromRow(PlannedTaskRow row) => TaskDetailArgs(
    taskId: row.task.id,
    routineId: row.routineId,
    blockId: row.blockId,
    dateKey: row.dateKey,
  );

  @override
  bool operator ==(Object other) =>
      other is TaskDetailArgs &&
      other.taskId == taskId &&
      other.routineId == routineId &&
      other.blockId == blockId &&
      other.dateKey == dateKey;

  @override
  int get hashCode => Object.hash(taskId, routineId, blockId, dateKey);
}

class TaskDetailBundle {
  const TaskDetailBundle({required this.task, this.routine, this.block});

  final PlannedTask task;
  final Routine? routine;
  final TaskBlock? block;
}

/// Fresh read of the task + its routine/block context. Family key equality
/// (via [TaskDetailArgs.==]) keeps one provider instance per task page.
final taskDetailProvider = FutureProvider.autoDispose
    .family<TaskDetailBundle?, TaskDetailArgs>((ref, args) async {
      final repo = ref.watch(planningRepositoryProvider);

      final tasks = await repo.getTasks(
        routineId: args.routineId,
        blockId: args.blockId,
      );
      PlannedTask? task;
      for (final t in tasks) {
        if (t.id == args.taskId) {
          task = t;
          break;
        }
      }
      if (task == null) return null;

      Routine? routine;
      final routines = await repo.getRoutinesForDate(args.dateKey);
      for (final r in routines) {
        if (r.id == args.routineId) {
          routine = r;
          break;
        }
      }

      TaskBlock? block;
      final blocks = await repo.getBlocks(args.routineId);
      for (final b in blocks) {
        if (b.id == args.blockId) {
          block = b;
          break;
        }
      }

      return TaskDetailBundle(task: task, routine: routine, block: block);
    });

class TaskDetailScreen extends ConsumerWidget {
  const TaskDetailScreen({super.key, required this.args});

  static const routeName = '/tasks/detail';

  final TaskDetailArgs args;

  PlannedTaskRow _rowFor(PlannedTask task) => PlannedTaskRow(
    dateKey: args.dateKey,
    routineId: args.routineId,
    blockId: args.blockId,
    task: task,
  );

  Future<void> _openEdit(BuildContext context, WidgetRef ref) async {
    await showAddTaskSheet(
      context,
      editArgs: AddTaskEditArgs(
        taskId: args.taskId,
        routineId: args.routineId,
        blockId: args.blockId,
        dateKey: args.dateKey,
      ),
    );
    // Same safety-net recompute the hub does after the editor closes.
    await ScheduleMutationCoordinator.instance.run(
      TaskUpdatedMutation(
        entityId: args.taskId,
        sourceContext: 'task_detail.open_edit',
        dateStr: args.dateKey,
      ),
      commitOverride: () async {},
    );
    ref.invalidate(taskDetailProvider(args));
  }

  Future<void> _complete(
    BuildContext context,
    WidgetRef ref,
    PlannedTask task,
  ) async {
    await completePlannedTaskRow(
      context,
      ref,
      _rowFor(task),
      sourceSurface: 'task_detail',
      sourceContext: 'task_detail.complete',
      runAutoNext: false,
    );
    ref.invalidate(taskDetailProvider(args));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task completed.')));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    PlannedTask task,
  ) async {
    final deleted = await confirmDeletePlannedTask(
      context,
      ref,
      _rowFor(task),
      sourceContext: 'task_detail.delete',
    );
    if (deleted && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _startFocus(
    BuildContext context,
    WidgetRef ref,
    PlannedTask task,
  ) async {
    // Same guard as focus selection: never silently steal a running session.
    final exec = ref.read(executionControllerProvider);
    if (exec.hasActiveFocusTask && exec.taskId != task.id) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Task "${exec.taskLabel}" is already running. '
            'Finish or stop it before switching focus.',
          ),
        ),
      );
      return;
    }

    ref.read(activeExecutionTaskIdProvider.notifier).state = task.id;
    ref.read(activeExecutionTaskLabelProvider.notifier).state = task.title;
    ref
        .read(executionControllerProvider.notifier)
        .setTask(
          id: task.id,
          label: task.title,
          durationMinutes: taskHasFocusDuration(task.durationMinutes)
              ? task.durationMinutes
              : null,
        );
    fireAndForgetAnalyticsEvent(
      ref,
      type: AnalyticsEventType.taskStarted,
      entityId: task.id,
      entityKind: 'task',
      sourceSurface: 'task_detail',
      idempotencyKey:
          'task_started_detail_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
    );
    await Navigator.pushNamed(context, TimerSessionScreen.routeName);
    ref.invalidate(taskDetailProvider(args));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(taskDetailProvider(args));

    return async.when(
      loading: () => Scaffold(
        appBar: AppBar(title: const PageTitle('Task'), centerTitle: true),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const PageTitle('Task'), centerTitle: true),
        body: Center(child: Text('Could not load task: $e')),
      ),
      data: (bundle) {
        if (bundle == null) {
          return Scaffold(
            appBar: AppBar(title: const PageTitle('Task'), centerTitle: true),
            body: Center(
              child: Text(
                'Task not found. It may have been deleted.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }
        final task = bundle.task;
        final scores = ref.watch(scoredTaskStatusesProvider);
        final completed = task.status == TaskStatus.completed;

        return Scaffold(
          appBar: AppBar(
            title: const PageTitle('Task'),
            centerTitle: true,
            actions: [
              const HelpAppBarButton('tasks'),
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _openEdit(context, ref),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'plans_changed') {
                    promptPlansChangedForRow(context, ref, _rowFor(task));
                  }
                  if (value == 'delete') _delete(context, ref, task);
                },
                itemBuilder: (ctx) => const [
                  PopupMenuItem(
                    value: 'plans_changed',
                    child: Text('Plans Changed?'),
                  ),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _StatusHeader(task: task),
              const SizedBox(height: 20),
              _DetailCard(
                title: 'SCHEDULE',
                rows: [
                  _DetailRow(
                    icon: Icons.event_outlined,
                    label: 'Planned for',
                    value: _dateKeyLabel(args.dateKey),
                  ),
                  _DetailRow(
                    icon: Icons.timer_outlined,
                    label: 'Duration',
                    value: _durationLabel(task.durationMinutes),
                  ),
                  _DetailRow(
                    icon: Icons.notifications_outlined,
                    label: 'Reminder',
                    value: _reminderLabel(task),
                  ),
                  if (bundle.block != null)
                    _DetailRow(
                      icon: Icons.view_agenda_outlined,
                      label: 'Block',
                      value: _blockLabel(bundle.block!),
                    ),
                  if (bundle.routine != null)
                    _DetailRow(
                      icon: Icons.repeat_outlined,
                      label: 'Routine',
                      value: bundle.routine!.title,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _DetailCard(
                title: 'COACHING',
                rows: [
                  _DetailRow(
                    icon: Icons.shield_outlined,
                    label: 'Discipline mode',
                    value: _modeLabel(task, bundle.routine),
                    valueColor: _modeColor(task, bundle.routine),
                  ),
                  _DetailRow(
                    icon: Icons.flag_outlined,
                    label: 'Priority',
                    value: _priorityLabel(task.priority),
                  ),
                  if (task.isHabitAnchor)
                    const _DetailRow(
                      icon: Icons.anchor_outlined,
                      label: 'Habit anchor',
                      value: 'Yes — keeps its slot in reshuffles',
                    ),
                  if (task.strictModeRequired)
                    const _DetailRow(
                      icon: Icons.lock_outlined,
                      label: 'Strict mode',
                      value: 'Required',
                    ),
                ],
              ),
              if ((task.notes ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                _DetailCard(
                  title: 'NOTES',
                  child: Text(
                    task.notes!.trim(),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _DetailCard(
                title: 'ACTIVITY',
                rows: [
                  _DetailRow(
                    icon: Icons.donut_large_outlined,
                    label: 'Score',
                    value: scores[task.id] != null
                        ? '${scores[task.id]}%'
                        : 'Not scored yet',
                  ),
                  _DetailRow(
                    icon: Icons.add_circle_outline,
                    label: 'Created',
                    value: _timestampLabel(task.createdAtMs),
                  ),
                  _DetailRow(
                    icon: Icons.update_outlined,
                    label: 'Last updated',
                    value: _timestampLabel(task.updatedAtMs),
                  ),
                ],
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: completed
                        ? null
                        : () => _startFocus(context, ref, task),
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: Text(completed ? 'Completed' : 'Start focus'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.accent,
                      side: BorderSide(color: AppColors.accentDeep),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: completed
                        ? null
                        : () => _complete(context, ref, task),
                    icon: const Icon(Icons.check_rounded),
                    label: const Text('Mark done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Formatting helpers ──────────────────────────────────────────────────────

String _dateKeyLabel(String dateKey) {
  if (dateKey == DateKeys.todayKey()) return 'Today · $dateKey';
  final parsed = DateTime.tryParse(dateKey);
  if (parsed != null) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    if (parsed.year == tomorrow.year &&
        parsed.month == tomorrow.month &&
        parsed.day == tomorrow.day) {
      return 'Tomorrow · $dateKey';
    }
  }
  return dateKey;
}

String _durationLabel(int minutes) {
  if (minutes <= 0) return 'No focus duration';
  if (minutes < 60) return '$minutes min';
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return m == 0 ? '$h h' : '$h h $m min';
}

String _reminderLabel(PlannedTask task) {
  if (!task.reminderEnabled) return 'Off';
  final iso = task.reminderTimeIso;
  final parsed = iso == null ? null : DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return 'On';
  return 'On · ${_clockLabel(parsed.hour, parsed.minute)}';
}

String _blockLabel(TaskBlock block) {
  final start = block.startMinutesFromMidnight;
  final end = block.endMinutesFromMidnight;
  if (start == null || end == null) return block.title;
  return '${block.title} · ${_clockLabel(start ~/ 60, start % 60)}'
      '–${_clockLabel(end ~/ 60, end % 60)}';
}

String _clockLabel(int hour24, int minute) {
  final period = hour24 >= 12 ? 'PM' : 'AM';
  final hour = hour24 % 12 == 0 ? 12 : hour24 % 12;
  return '$hour:${minute.toString().padLeft(2, '0')} $period';
}

String _timestampLabel(int ms) {
  if (ms <= 0) return '—';
  final dt = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · '
      '${_clockLabel(dt.hour, dt.minute)}';
}

String _priorityLabel(int priority) => switch (priority) {
  1 => 'P1 · Highest',
  2 => 'P2 · High',
  3 => 'P3 · Normal',
  4 => 'P4 · Low',
  _ => 'P5 · Lowest',
};

/// Effective mode + where it came from, matching [EffectiveTaskMode]
/// precedence (task override → routine → app default).
String _modeLabel(PlannedTask task, Routine? routine) {
  final effective = EffectiveTaskMode.effectiveModeRefId(
    task: task,
    routine: routine,
  );
  final name = effective[0].toUpperCase() + effective.substring(1);
  final taskRaw = task.modeRefId?.trim().toLowerCase();
  final source = (taskRaw != null && taskRaw == effective)
      ? 'set on task'
      : routine != null
      ? 'from routine'
      : 'default';
  return '$name · $source';
}

Color _modeColor(PlannedTask task, Routine? routine) {
  final effective = EffectiveTaskMode.effectiveModeRefId(
    task: task,
    routine: routine,
  );
  return switch (effective) {
    'extreme' => AppColors.danger,
    'disciplined' => AppColors.cyan,
    _ => AppColors.textPrimary,
  };
}

// ── Widgets ─────────────────────────────────────────────────────────────────

class _StatusHeader extends StatelessWidget {
  const _StatusHeader({required this.task});

  final PlannedTask task;

  (String, Color) get _statusChip => switch (task.status) {
    TaskStatus.completed => ('COMPLETED', AppColors.accent),
    TaskStatus.inProgress => ('IN PROGRESS', AppColors.cyan),
    TaskStatus.partial => ('PARTIAL', AppColors.amber),
    TaskStatus.notStarted => ('NOT STARTED', AppColors.textMuted),
  };

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _statusChip;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _Pill(label: statusLabel, color: statusColor),
            if ((task.category ?? '').isNotEmpty)
              _Pill(
                label: task.category!.toUpperCase(),
                color: AppColors.textMuted,
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          task.title,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, this.rows, this.child});

  final String title;
  final List<_DetailRow>? rows;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ?child,
          if (rows != null)
            for (var i = 0; i < rows!.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              rows![i],
            ],
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.textMuted),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
