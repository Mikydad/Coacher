import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../add_task/presentation/add_task_screen.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';
import '../../scoring/application/scoring_controller.dart';

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
  );
}

class TasksHubScreen extends ConsumerWidget {
  const TasksHubScreen({super.key});

  static const routeName = '/tasks';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAllTasksRowsProvider);
    final otherAsync = ref.watch(openTasksOutsideTodayProvider);
    final scores = ref.watch(scoredTaskStatusesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Tasks')),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateTaskListProviders(ref);
          await ref.read(todayAllTasksRowsProvider.future);
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
                            Navigator.pushNamed(
                              context,
                              AddTaskScreen.routeName,
                              arguments: AddTaskEditArgs(
                                taskId: row.task.id,
                                routineId: row.routineId,
                                blockId: row.blockId,
                                dateKey: row.dateKey,
                              ),
                            );
                          },
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
                            Navigator.pushNamed(
                              context,
                              AddTaskScreen.routeName,
                              arguments: AddTaskEditArgs(
                                taskId: row.task.id,
                                routineId: row.routineId,
                                blockId: row.blockId,
                                dateKey: row.dateKey,
                              ),
                            );
                          },
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
    required this.onDelete,
    this.scorePercent,
    this.showDateKey = false,
  });

  final PlannedTaskRow row;
  final VoidCallback onEdit;
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
            if (value == 'delete') onDelete();
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}
