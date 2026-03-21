import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/sync/sync_service.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../add_task/presentation/add_task_screen.dart';
import '../../tasks_hub/presentation/tasks_hub_screen.dart';
import '../../firebase_test/presentation/firebase_test_screen.dart';
import '../../focus/presentation/focus_selection_screen.dart';
import '../../plan_tomorrow/presentation/plan_tomorrow_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(scoredTaskStatusesProvider);
    final tasksAsync = ref.watch(todayAllTasksRowsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quittr'),
        actions: const [Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.notifications_none))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _NeonCard(
            child: Column(
              children: [
                const SizedBox(height: 8),
                const Text('7', style: TextStyle(fontSize: 52, fontWeight: FontWeight.bold)),
                const Text('DAY STREAK', style: TextStyle(letterSpacing: 2, color: Colors.white70)),
                const SizedBox(height: 12),
                const Text("Today's Progress", style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                tasksAsync.when(
                  data: (rows) {
                    final completed = _completedForRows(rows, scores);
                    final partial = _partialForRows(rows, scores);
                    final doneCount = completed + partial;
                    return Text(
                      '$doneCount / ${rows.length} Tasks',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                    );
                  },
                  loading: () => const Text('…', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  error: (Object? error, StackTrace? stackTrace) =>
                      const Text('—', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCircle(
                  icon: Icons.bolt,
                  label: 'START FOCUS',
                  onTap: () => Navigator.pushNamed(context, FocusSelectionScreen.routeName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCircle(
                  icon: Icons.add,
                  label: 'ADD TASK',
                  onTap: () => Navigator.pushNamed(context, AddTaskScreen.routeName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCircle(
                  icon: Icons.calendar_today,
                  label: 'PLAN\nTOMORROW',
                  onTap: () => Navigator.pushNamed(context, PlanTomorrowScreen.routeName),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('DAILY DISCIPLINE', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(value: 0.6, minHeight: 8),
          ),
          const SizedBox(height: 24),
          _NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('COACH INSIGHTS', style: TextStyle(color: Color(0xFF00E6FF), fontWeight: FontWeight.w700)),
                SizedBox(height: 8),
                Text(
                  "\"You've stayed focused for 4 hours today. That's 20% higher than your average.\"",
                  style: TextStyle(fontSize: 20, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.pushNamed(context, TasksHubScreen.routeName),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text("Today's Tasks", style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white54),
                        onPressed: () => Navigator.pushNamed(context, TasksHubScreen.routeName),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                tasksAsync.when(
                  data: (rows) {
                    if (rows.isEmpty) {
                      return const Text(
                        'No tasks yet. Tap ADD TASK to create one.',
                        style: TextStyle(color: Colors.white54),
                      );
                    }
                    return Column(
                      children: [
                        for (final row in rows)
                          _TaskItem(
                            title: row.task.title,
                            subtitle: _homeTaskSubtitle(row, scores),
                            done: row.task.status == TaskStatus.completed || scores[row.task.id] == 100,
                            partial: row.task.status != TaskStatus.completed &&
                                scores[row.task.id] != null &&
                                scores[row.task.id]! < 100,
                            onCheckedChange: (checked) {
                              if (checked) {
                                _completeTaskFromHome(context, ref, row);
                              } else {
                                _uncompleteTaskFromHome(context, ref, row);
                              }
                            },
                          ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => Text(
                    'Could not load tasks.',
                    style: TextStyle(color: Colors.red.shade200),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          tasksAsync.when(
            data: (rows) {
              final completed = _completedForRows(rows, scores);
              final partial = _partialForRows(rows, scores);
              return Text(
                'Completed: $completed • Partial: $partial',
                style: const TextStyle(color: Colors.white70),
              );
            },
            loading: () => const Text(
              'Completed: … • Partial: …',
              style: TextStyle(color: Colors.white70),
            ),
            error: (Object? error, StackTrace? stackTrace) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 4),
          ValueListenableBuilder<int>(
            valueListenable: SyncService.instance.pendingCount,
            builder: (context, pending, _) => Text(
              pending > 0 ? 'Pending sync operations: $pending' : 'All changes synced',
              style: const TextStyle(color: Colors.white54),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF301615),
              foregroundColor: const Color(0xFFFF6D4E),
              minimumSize: const Size.fromHeight(56),
            ),
            onPressed: () {},
            child: const Text("I'M DISTRACTED", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, FirebaseTestScreen.routeName),
            child: const Text('Open Firebase Test Screen'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) Navigator.pushNamed(context, PlanTomorrowScreen.routeName);
          if (index == 2) Navigator.pushNamed(context, FocusSelectionScreen.routeName);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.track_changes), label: 'Goals'),
          BottomNavigationBarItem(icon: Icon(Icons.trending_up), label: 'Progress'),
          BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Community'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ActionCircle extends StatelessWidget {
  const _ActionCircle({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Ink(
        height: 108,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1C1F),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFFB7FF00)),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.title,
    this.subtitle,
    this.done = false,
    this.partial = false,
    required this.onCheckedChange,
  });

  final String title;
  final String? subtitle;
  final bool done;
  final bool partial;
  final void Function(bool checked) onCheckedChange;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: done,
        onChanged: (value) {
          if (value == null) return;
          onCheckedChange(value);
        },
        activeColor: const Color(0xFFB7FF00),
      ),
      title: Text(
        title,
        style: TextStyle(
          decoration: done ? TextDecoration.lineThrough : null,
          fontStyle: partial ? FontStyle.italic : FontStyle.normal,
          color: Colors.white70,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(subtitle!, style: const TextStyle(color: Colors.white38, fontSize: 12)),
    );
  }
}

class _NeonCard extends StatelessWidget {
  const _NeonCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111317),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white12),
      ),
      child: child,
    );
  }
}

String? _homeTaskSubtitle(PlannedTaskRow row, Map<String, int> scores) {
  final id = row.task.id;
  final p = scores[id];
  if (p != null && p < 100) return '$p% complete';
  return null;
}

int _completedForRows(List<PlannedTaskRow> rows, Map<String, int> scores) {
  var n = 0;
  for (final row in rows) {
    if (row.task.status == TaskStatus.completed || scores[row.task.id] == 100) n++;
  }
  return n;
}

int _partialForRows(List<PlannedTaskRow> rows, Map<String, int> scores) {
  var n = 0;
  for (final row in rows) {
    if (row.task.status == TaskStatus.completed) continue;
    final v = scores[row.task.id];
    if (v != null && v < 100) n++;
  }
  return n;
}

Future<void> _completeTaskFromHome(BuildContext context, WidgetRef ref, PlannedTaskRow row) async {
  final t = row.task;
  final planning = ref.read(planningRepositoryProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
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
    status: TaskStatus.completed,
    createdAtMs: t.createdAtMs,
    updatedAtMs: now,
    category: t.category,
    planDateKey: t.planDateKey ?? row.dateKey,
    notes: t.notes,
  );
  try {
    await planning.upsertTask(updated);
    await ref.read(scoringControllerProvider).submit(taskId: t.id, completionPercent: 100);
    final prev = ref.read(scoredTaskStatusesProvider);
    ref.read(scoredTaskStatusesProvider.notifier).state = {...prev, t.id: 100};
    invalidateTaskListProviders(ref);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not complete: $e')));
    }
  }
}

Future<void> _uncompleteTaskFromHome(BuildContext context, WidgetRef ref, PlannedTaskRow row) async {
  final t = row.task;
  final scoreMap = ref.read(scoredTaskStatusesProvider);
  final isDone = t.status == TaskStatus.completed || scoreMap[t.id] == 100;
  if (!isDone) return;

  final planning = ref.read(planningRepositoryProvider);
  final now = DateTime.now().millisecondsSinceEpoch;
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
    status: TaskStatus.notStarted,
    createdAtMs: t.createdAtMs,
    updatedAtMs: now,
    category: t.category,
    planDateKey: t.planDateKey ?? row.dateKey,
    notes: t.notes,
  );
  try {
    await planning.upsertTask(updated);
    final prev = ref.read(scoredTaskStatusesProvider);
    final next = Map<String, int>.from(prev)..remove(t.id);
    ref.read(scoredTaskStatusesProvider.notifier).state = next;
    invalidateTaskListProviders(ref);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not update task: $e')));
    }
  }
}
