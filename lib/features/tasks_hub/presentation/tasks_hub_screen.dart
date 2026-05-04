import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/stable_id.dart';
import '../../add_task/presentation/add_task_screen.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../planning/application/auto_next_task_flow.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/accountability_log.dart';
import '../../planning/domain/models/flow_transition_event.dart';
import '../../planning/domain/models/task_item.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../timer/presentation/timer_session_screen.dart';

PlannedTask _hubTaskWithOrderIndex(PlannedTaskRow row, int orderIndex) {
  final t = row.task;
  return PlannedTask(
    id: t.id,
    routineId: t.routineId,
    blockId: t.blockId,
    title: t.title,
    durationMinutes: t.durationMinutes,
    priority: t.priority,
    orderIndex: orderIndex,
    reminderEnabled: t.reminderEnabled,
    reminderTimeIso: t.reminderTimeIso,
    status: t.status,
    createdAtMs: t.createdAtMs,
    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    category: t.category,
    planDateKey: t.planDateKey ?? row.dateKey,
    notes: t.notes,
    sequenceIndex: orderIndex,
    isHabitAnchor: t.isHabitAnchor,
    strictModeRequired: t.strictModeRequired,
    modeRefId: t.modeRefId,
  );
}

enum _HubReorderLayer { habitAnchor, overdueScheduled, upcomingScheduled, flexible }

_HubReorderLayer _layerForHubRow(PlannedTaskRow row, DateTime now) {
  if (row.task.isHabitAnchor) {
    return _HubReorderLayer.habitAnchor;
  }
  final iso = row.task.reminderTimeIso;
  if (iso == null || iso.trim().isEmpty) {
    return _HubReorderLayer.flexible;
  }
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null ||
      parsed.year != now.year ||
      parsed.month != now.month ||
      parsed.day != now.day) {
    return _HubReorderLayer.flexible;
  }
  return parsed.isBefore(now)
      ? _HubReorderLayer.overdueScheduled
      : _HubReorderLayer.upcomingScheduled;
}

class TasksHubScreen extends ConsumerWidget {
  const TasksHubScreen({super.key});

  static const routeName = '/tasks';

  Future<void> _openAddTask(BuildContext context, WidgetRef ref) async {
    await Navigator.pushNamed(context, AddTaskScreen.routeName);
    invalidateTaskListProviders(ref);
  }

  Future<void> _openEditTask(BuildContext context, WidgetRef ref, PlannedTaskRow row) async {
    await Navigator.pushNamed(
      context,
      AddTaskScreen.routeName,
      arguments: AddTaskEditArgs(
        taskId: row.task.id,
        routineId: row.routineId,
        blockId: row.blockId,
        dateKey: row.dateKey,
      ),
    );
    invalidateTaskListProviders(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAllTasksRowsProvider);
    final otherAsync = ref.watch(openTasksOutsideTodayProvider);
    final scores = ref.watch(scoredTaskStatusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
        actions: [
          IconButton(
            tooltip: 'What next',
            icon: const Icon(Icons.play_circle_outline),
            onPressed: () async {
              final prioritized = await readFreshTodayPrioritizedRows(ref);
              if (!context.mounted) return;
              if (prioritized.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No open tasks available.')),
                );
                return;
              }
              final next = prioritized.first.row;
              ref.read(activeExecutionTaskIdProvider.notifier).state = next.task.id;
              ref.read(activeExecutionTaskLabelProvider.notifier).state = next.task.title;
              await Navigator.pushNamed(
                context,
                TimerSessionScreen.routeName,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Next suggestion: ${next.task.title}')),
                );
              }
            },
          ),
          IconButton(
            tooltip: 'Add task',
            icon: const Icon(Icons.add),
            onPressed: () => _openAddTask(context, ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateTaskListProviders(ref);
          await readFreshTodayPlannedRows(ref);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Today', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              todayAsync.when(
                data: (rows) {
                  if (rows.isEmpty) {
                    return const Text(
                      'No tasks today.',
                      style: TextStyle(color: Colors.white54),
                    );
                  }
                  return ReorderableListView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    buildDefaultDragHandles: true,
                    onReorder: (oldIndex, newIndex) async {
                      if (newIndex > oldIndex) newIndex--;
                      final now = DateTime.now();
                      final moved = rows[oldIndex];
                      final movedLayer = _layerForHubRow(moved, now);
                      final base = List<PlannedTaskRow>.from(rows)..removeAt(oldIndex);
                      if (base.isNotEmpty) {
                        final anchorIndex = newIndex.clamp(0, base.length - 1);
                        final anchor = base[anchorIndex];
                        final anchorLayer = _layerForHubRow(anchor, now);
                        if (movedLayer != anchorLayer) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Reorder is allowed only within the same section (Habit Anchors, Overdue, Upcoming, or Flexible).',
                              ),
                            ),
                          );
                          return;
                        }
                      }
                      final copy = List<PlannedTaskRow>.from(rows);
                      final item = copy.removeAt(oldIndex);
                      copy.insert(newIndex, item);
                      final planning = ref.read(planningRepositoryProvider);
                      for (var i = 0; i < copy.length; i++) {
                        final row = copy[i];
                        if (row.task.orderIndex == i) continue;
                        await planning.upsertTask(_hubTaskWithOrderIndex(row, i));
                      }
                      invalidateTaskListProviders(ref);
                    },
                    children: [
                      for (final row in rows)
                        _HubTaskTile(
                          key: ValueKey(row.task.id),
                          row: row,
                          scorePercent: scores[row.task.id],
                          onEdit: () {
                            _openEditTask(context, ref, row);
                          },
                          onCompleteNow: () => _completeFromHub(context, ref, row),
                          onPlansChanged: () => _plansChangedFromHub(context, ref, row),
                          onDelete: () => confirmDeletePlannedTask(context, ref, row),
                        ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Could not load: $e', style: TextStyle(color: Colors.red.shade200)),
              ),
              const SizedBox(height: 28),
              const Text('Open on other days', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              otherAsync.when(
                data: (rows) {
                  if (rows.isEmpty) {
                    return const Text(
                      'No open tasks on other days.',
                      style: TextStyle(color: Colors.white54),
                    );
                  }
                  return Column(
                    children: [
                      for (final row in rows)
                        _HubTaskTile(
                          key: ValueKey('other_${row.task.id}_${row.dateKey}'),
                          row: row,
                          scorePercent: scores[row.task.id],
                          showDateKey: true,
                          onEdit: () {
                            _openEditTask(context, ref, row);
                          },
                          onCompleteNow: () => _completeFromHub(context, ref, row),
                          onPlansChanged: () => _plansChangedFromHub(context, ref, row),
                          onDelete: () => confirmDeletePlannedTask(context, ref, row),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) => Text('$e', style: TextStyle(color: Colors.red.shade200)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _completeFromHub(BuildContext context, WidgetRef ref, PlannedTaskRow row) async {
  final t = row.task;
  if (t.status == TaskStatus.completed) return;
  final planning = ref.read(planningRepositoryProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
  await planning.upsertTask(
    PlannedTask(
      id: t.id,
      routineId: t.routineId,
      blockId: t.blockId,
      title: t.title,
      durationMinutes: t.durationMinutes,
      priority: t.priority,
      orderIndex: t.orderIndex,
      reminderEnabled: t.reminderEnabled,
      reminderTimeIso: t.reminderTimeIso,
      status: TaskStatus.completed,
      createdAtMs: t.createdAtMs,
      updatedAtMs: now,
      category: t.category,
      planDateKey: t.planDateKey,
      notes: t.notes,
      sequenceIndex: t.sequenceIndex,
      isHabitAnchor: t.isHabitAnchor,
      strictModeRequired: t.strictModeRequired,
      modeRefId: t.modeRefId,
    ),
  );
  fireAndForgetAnalyticsEvent(
    ref,
    type: AnalyticsEventType.taskCompleted,
    entityId: t.id,
    entityKind: 'task',
    sourceSurface: 'tasks_hub',
    idempotencyKey: 'task_completed_hub_${t.id}_${DateTime.now().millisecondsSinceEpoch}',
    modeRefId: t.modeRefId,
  );
  await ref.read(reminderSyncServiceProvider).markTaskStarted(t.id);
  invalidateTaskListProviders(ref);
  if (!context.mounted) return;
  await runAutoNextTaskFlow(
    context,
    ref,
    completedTaskId: t.id,
    completionPercent: 100,
  );
}

Future<void> _plansChangedFromHub(BuildContext context, WidgetRef ref, PlannedTaskRow row) async {
  final reason = await showDialog<OverrideReasonCategory>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Plans changed?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final option in OverrideReasonCategory.values)
            ListTile(
              title: Text(option.label),
              onTap: () => Navigator.pop(ctx, option),
            ),
        ],
      ),
    ),
  );
  if (reason == null || !context.mounted) return;
  final noteCtrl = TextEditingController();
  final note = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Short logical reason'),
      content: TextField(
        controller: noteCtrl,
        maxLines: 2,
        decoration: const InputDecoration(hintText: '1-2 sentences'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, noteCtrl.text.trim()),
          child: const Text('Save'),
        ),
      ],
    ),
  );
  noteCtrl.dispose();
  if (note == null || note.trim().isEmpty) return;
  final planning = ref.read(planningRepositoryProvider);
  await planning.logFlowTransitionEvent(
    FlowTransitionEvent(
      id: StableId.generate('flowev'),
      taskId: row.task.id,
      type: FlowTransitionType.moveWithReason,
      planChangeIntent: PlanChangeIntent.logical,
      reasonCategory: reason,
      reasonNote: note,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );
  await planning.logAccountability(
    AccountabilityLog(
      id: StableId.generate('acct'),
      taskId: row.task.id,
      action: AccountabilityAction.defer,
      reasonCategory: reason,
      reasonNote: note,
      modeRefId: row.task.modeRefId,
      taskPriority: row.task.priority,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );
  await ref.read(reminderSyncServiceProvider).markLogicalReasonProvided(row.task.id);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plans change logged.')),
    );
  }
}

Future<void> confirmDeletePlannedTask(BuildContext context, WidgetRef ref, PlannedTaskRow row) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Delete task?'),
      content: Text('Remove "${row.task.title}"?'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  await ref.read(planningRepositoryProvider).deleteTask(
        routineId: row.routineId,
        blockId: row.blockId,
        taskId: row.task.id,
      );
  invalidateTaskListProviders(ref);
}

class _HubTaskTile extends StatelessWidget {
  const _HubTaskTile({
    super.key,
    required this.row,
    required this.onEdit,
    required this.onCompleteNow,
    required this.onPlansChanged,
    required this.onDelete,
    this.scorePercent,
    this.showDateKey = false,
  });

  final PlannedTaskRow row;
  final VoidCallback onEdit;
  final VoidCallback onCompleteNow;
  final VoidCallback onPlansChanged;
  final VoidCallback onDelete;
  final int? scorePercent;
  final bool showDateKey;

  @override
  Widget build(BuildContext context) {
    final t = row.task;
    final pctLabel = scorePercent != null ? '$scorePercent%' : '—';
    final subtitle = StringBuffer()
      ..write('${t.durationMinutes} min')
      ..write(t.category != null ? ' · ${t.category}' : '')
      ..write(t.reminderEnabled ? ' · Reminder on' : '')
      ..write(' · $pctLabel')
      ..write(showDateKey ? ' · ${row.dateKey}' : '')
      ..write(' · ${t.status.name}');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: const Color(0xFF111317),
      child: ListTile(
        title: Text(t.title),
        subtitle: Text(subtitle.toString(), style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) {
            if (value == 'edit') onEdit();
            if (value == 'complete') onCompleteNow();
            if (value == 'plans_changed') onPlansChanged();
            if (value == 'delete') onDelete();
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'complete', child: Text('Complete now')),
            PopupMenuItem(value: 'plans_changed', child: Text('Plans Changed?')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
