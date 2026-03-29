import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/sync/sync_service.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/application/extension_policy.dart';
import '../../planning/application/next_task_ranker.dart';
import '../../planning/application/override_rules.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/accountability_log.dart';
import '../../planning/domain/models/flow_transition_event.dart';
import '../../planning/domain/models/block.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/task_item.dart';
import '../../planning/presentation/accountability_history_screen.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../add_task/presentation/add_task_screen.dart';
import '../../tasks_hub/presentation/tasks_hub_screen.dart';
import '../../firebase_test/presentation/firebase_test_screen.dart';
import '../../focus/presentation/focus_selection_screen.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/goal_categories.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../goals/presentation/goal_detail_screen.dart';
import '../../goals/presentation/goal_editor_screen.dart';
import '../../goals/presentation/goal_selection_screen.dart';
import '../../plan_tomorrow/presentation/plan_tomorrow_screen.dart';
import '../../timer/presentation/timer_session_screen.dart';

enum _NextTaskDecision { startNow, extraTime, moveWithReason }
enum _PlansChangedAction { reshuffle, defer, skip }

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const routeName = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scores = ref.watch(scoredTaskStatusesProvider);
    final tasksAsync = ref.watch(todayAllTasksRowsProvider);
    final todaysGoalsAsync = ref.watch(todaysActiveGoalsProvider);
    final flowSnapshotAsync = ref.watch(homeFlowSnapshotProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quittr'),
        actions: [
          IconButton(
            tooltip: 'Accountability history',
            onPressed: () => Navigator.pushNamed(context, AccountabilityHistoryScreen.routeName),
            icon: const Icon(Icons.history),
          ),
          const Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.notifications_none)),
        ],
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
            child: flowSnapshotAsync.when(
              data: (flow) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Flow now',
                    style: TextStyle(color: Color(0xFF00E6FF), fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current block: ${flow.currentBlockLabel}',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Open tasks: ${flow.openTaskCount}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 10),
                  if (flow.nextTaskRow != null)
                    FilledButton.icon(
                      onPressed: () {
                        final next = flow.nextTaskRow!.task;
                        ref.read(activeExecutionTaskIdProvider.notifier).state = next.id;
                        ref.read(activeExecutionTaskLabelProvider.notifier).state = next.title;
                        Navigator.pushNamed(context, TimerSessionScreen.routeName);
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: Text('What next: ${flow.nextTaskRow!.task.title}'),
                    )
                  else
                    const Text('No next task suggestion yet.', style: TextStyle(color: Colors.white54)),
                ],
              ),
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('Could not load flow snapshot: $e'),
            ),
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
                            onPlansChanged: () => _openPlansChangedFlow(context, ref, row),
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
          const SizedBox(height: 16),
          _NeonCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => Navigator.pushNamed(context, GoalSelectionScreen.routeName),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Today's goals",
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: Colors.white54),
                        onPressed: () => Navigator.pushNamed(context, GoalSelectionScreen.routeName),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Commitments active today — tap a goal to log progress.',
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 8),
                todaysGoalsAsync.when(
                  data: (goals) {
                    if (goals.isEmpty) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'No goals in progress for today.',
                            style: TextStyle(color: Colors.white54),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () => Navigator.pushNamed(context, GoalEditorScreen.routeName),
                            icon: const Icon(Icons.add, size: 20, color: Color(0xFFB7FF00)),
                            label: const Text('Create a goal'),
                            style: TextButton.styleFrom(foregroundColor: const Color(0xFFB7FF00)),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        for (final g in goals)
                          _TodayGoalTile(
                            title: g.title,
                            subtitle: _homeGoalSubtitle(g),
                            onTap: () => Navigator.pushNamed(context, GoalDetailScreen.routeName, arguments: g.id),
                          ),
                      ],
                    );
                  },
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  error: (_, _) => Text(
                    'Could not load goals.',
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
          if (index == 1) Navigator.pushNamed(context, GoalSelectionScreen.routeName);
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

class _TodayGoalTile extends StatelessWidget {
  const _TodayGoalTile({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.track_changes_outlined, color: Color(0xFFB7FF00), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }
}

String _homeGoalSubtitle(UserGoal g) {
  final unit = g.measurementKind == MeasurementKind.custom && (g.customLabel?.isNotEmpty ?? false)
      ? g.customLabel!
      : g.measurementKind.displayLabel().toLowerCase();
  final suffix = switch ((g.periodMode, g.horizon)) {
    (GoalPeriodMode.durationDays, _) => 'per day in this run',
    (_, GoalHorizon.weekly) => 'this week',
    (_, GoalHorizon.monthly) => 'per day (in this month)',
    (_, GoalHorizon.daily) => 'per day',
  };
  final value =
      g.targetValue == g.targetValue.roundToDouble() ? g.targetValue.toInt().toString() : g.targetValue.toString();
  return '${GoalCategories.label(g.categoryId)} · $value $unit ($suffix)';
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({
    required this.title,
    this.subtitle,
    this.done = false,
    this.partial = false,
    required this.onCheckedChange,
    required this.onPlansChanged,
  });

  final String title;
  final String? subtitle;
  final bool done;
  final bool partial;
  final void Function(bool checked) onCheckedChange;
  final VoidCallback onPlansChanged;

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
      trailing: IconButton(
        tooltip: 'Plans Changed?',
        icon: const Icon(Icons.swap_horiz, color: Colors.white54),
        onPressed: onPlansChanged,
      ),
    );
  }
}

Future<void> _openPlansChangedFlow(
  BuildContext context,
  WidgetRef ref,
  PlannedTaskRow row,
) async {
  final action = await showDialog<_PlansChangedAction>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Plans Changed?'),
      content: const Text('How should we adjust this task right now?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _PlansChangedAction.reshuffle),
          child: const Text('Reshuffle'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _PlansChangedAction.defer),
          child: const Text('Defer'),
        ),
        FilledButton.tonal(
          onPressed: () => Navigator.pop(ctx, _PlansChangedAction.skip),
          child: const Text('Skip'),
        ),
      ],
    ),
  );
  if (action == null || !context.mounted) return;

  final reason = await _promptOverrideReason(context);
  if (reason == null) return;
  if (!context.mounted) return;
  final routineForPolicy = await _routineForPlannedRow(ref, row);
  if (!context.mounted) return;
  if (OverrideRules.requiresStrictOverrideConfirm(row.task, routine: routineForPolicy)) {
    final ok = await _confirmStrictOverride(context, row.task, action);
    if (ok != true) return;
  }

  final planning = ref.read(planningRepositoryProvider);
  final t = row.task;
  final now = DateTime.now().millisecondsSinceEpoch;
  var nextUrgencyDelta = 0;
  switch (action) {
    case _PlansChangedAction.reshuffle:
      final reshuffled = PlannedTask(
        id: t.id,
        routineId: t.routineId,
        blockId: t.blockId,
        title: t.title,
        durationMinutes: t.durationMinutes,
        priority: t.priority,
        orderIndex: t.orderIndex + 1,
        reminderEnabled: t.reminderEnabled,
        reminderTimeIso: t.reminderTimeIso,
        status: t.status,
        createdAtMs: t.createdAtMs,
        updatedAtMs: now,
        category: t.category,
        planDateKey: t.planDateKey ?? row.dateKey,
        notes: _appendMoveReason(
          existing: t.notes,
          reason: reason.reason,
          explanation: '[Reshuffle] ${reason.note}',
        ),
        sequenceIndex: (t.sequenceIndex ?? t.orderIndex) + 100,
        strictModeRequired: t.strictModeRequired,
        modeRefId: t.modeRefId,
      );
      await planning.upsertTask(reshuffled);
      nextUrgencyDelta = 10;
      break;
    case _PlansChangedAction.defer:
      final deferTime = DateTime.now().add(const Duration(hours: 1));
      final deferred = PlannedTask(
        id: t.id,
        routineId: t.routineId,
        blockId: t.blockId,
        title: t.title,
        durationMinutes: t.durationMinutes,
        priority: t.priority,
        orderIndex: t.orderIndex,
        reminderEnabled: t.reminderEnabled,
        reminderTimeIso: t.reminderEnabled ? deferTime.toIso8601String() : t.reminderTimeIso,
        status: TaskStatus.notStarted,
        createdAtMs: t.createdAtMs,
        updatedAtMs: now,
        category: t.category,
        planDateKey: t.planDateKey ?? row.dateKey,
        notes: _appendMoveReason(
          existing: t.notes,
          reason: reason.reason,
          explanation: '[Defer] ${reason.note}',
        ),
        sequenceIndex: (t.sequenceIndex ?? t.orderIndex) + 500,
        strictModeRequired: t.strictModeRequired,
        modeRefId: t.modeRefId,
      );
      await planning.upsertTask(deferred);
      nextUrgencyDelta = 20;
      break;
    case _PlansChangedAction.skip:
      final skipped = PlannedTask(
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
        notes: _appendMoveReason(
          existing: t.notes,
          reason: reason.reason,
          explanation: '[Skip] ${reason.note}',
        ),
        sequenceIndex: t.sequenceIndex,
        strictModeRequired: t.strictModeRequired,
        modeRefId: t.modeRefId,
      );
      await planning.upsertTask(skipped);
      nextUrgencyDelta = -20;
      break;
  }

  final blocks = await planning.getBlocks(row.routineId);
  TaskBlock? currentBlock;
  for (final b in blocks) {
    if (b.id == row.blockId) {
      currentBlock = b;
      break;
    }
  }
  if (currentBlock != null) {
    final adjusted = (currentBlock.urgencyScore + nextUrgencyDelta).clamp(0, 100);
    await planning.upsertBlock(
      TaskBlock(
        id: currentBlock.id,
        routineId: currentBlock.routineId,
        title: currentBlock.title,
        orderIndex: currentBlock.orderIndex,
        startMinutesFromMidnight: currentBlock.startMinutesFromMidnight,
        endMinutesFromMidnight: currentBlock.endMinutesFromMidnight,
        urgencyScore: adjusted,
        modeRefId: currentBlock.modeRefId,
        createdAtMs: currentBlock.createdAtMs,
        updatedAtMs: now,
      ),
    );
  }

  await planning.logFlowTransitionEvent(
    FlowTransitionEvent(
      id: StableId.generate('flowev'),
      taskId: t.id,
      type: FlowTransitionType.moveWithReason,
      reasonCategory: reason.reason,
      reasonNote: '[${action.name}] ${reason.note}',
      createdAtMs: now,
    ),
  );
  await planning.logAccountability(
    AccountabilityLog(
      id: StableId.generate('acct'),
      taskId: t.id,
      action: switch (action) {
        _PlansChangedAction.reshuffle => AccountabilityAction.reshuffle,
        _PlansChangedAction.defer => AccountabilityAction.defer,
        _PlansChangedAction.skip => AccountabilityAction.skip,
      },
      reasonCategory: reason.reason,
      reasonNote: reason.note,
      modeRefId: t.modeRefId,
      taskPriority: t.priority,
      createdAtMs: now,
    ),
  );
  await ref.read(reminderSyncServiceProvider).markLogicalReasonProvided(t.id);

  invalidateTaskListProviders(ref);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Updated "${t.title}" with ${action.name} decision.')),
  );
}

Future<bool?> _confirmStrictOverride(
  BuildContext context,
  PlannedTask task,
  _PlansChangedAction action,
) async {
  final confirmCtrl = TextEditingController();
  String? errorText;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Strict confirmation required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This is a high-importance task ("${task.title}"). '
              'You are choosing to ${action.name}.',
            ),
            const SizedBox(height: 8),
            const Text(
              'Type CONFIRM to proceed.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: confirmCtrl,
              decoration: const InputDecoration(
                labelText: 'Type CONFIRM',
              ),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              if (!OverrideRules.isStrictConfirmInputValid(confirmCtrl.text)) {
                setState(() => errorText = 'Please type CONFIRM exactly.');
                return;
              }
              Navigator.pop(ctx, true);
            },
            child: const Text('Proceed'),
          ),
        ],
      ),
    ),
  );
  confirmCtrl.dispose();
  return ok;
}

Future<({OverrideReasonCategory reason, String note})?> _promptOverrideReason(
  BuildContext context,
) async {
  final reasons = OverrideReasonCategory.values;
  OverrideReasonCategory selectedReason = reasons.first;
  final noteCtrl = TextEditingController();
  String? errorText;
  final choice = await showDialog<({OverrideReasonCategory reason, String note})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Why are plans changing?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<OverrideReasonCategory>(
              initialValue: selectedReason,
              items: [
                for (final r in reasons) DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (v) => setState(() => selectedReason = v ?? reasons.first),
              decoration: const InputDecoration(labelText: 'Reason category'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: noteCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Logical reason (1-2 sentences)',
                hintText: 'Explain clearly why this is the best move now.',
              ),
            ),
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final note = noteCtrl.text.trim();
              try {
                FlowTransitionEvent.validateReasonNote(note);
              } catch (_) {
                setState(() => errorText = 'Give a clear reason in 1-2 sentences.');
                return;
              }
              Navigator.pop(ctx, (reason: selectedReason, note: note));
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    ),
  );
  noteCtrl.dispose();
  return choice;
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

Future<Routine?> _routineForPlannedRow(WidgetRef ref, PlannedTaskRow row) async {
  final planning = ref.read(planningRepositoryProvider);
  try {
    final routines = await planning.getRoutinesForDate(row.dateKey);
    for (final r in routines) {
      if (r.id == row.routineId) return r;
    }
  } catch (_) {}
  return null;
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
  final routineForPolicy = await _routineForPlannedRow(ref, row);
  if (!context.mounted) return;
  if (OverrideRules.requiresMandatoryTimer(t, routine: routineForPolicy)) {
    final sessions = await ref.read(executionRepositoryProvider).getSessionsForTask(t.id);
    final ok = OverrideRules.hasSatisfiedMandatoryTimer(sessions);
    if (!ok) {
      if (!context.mounted) return;
      final start = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Timer required'),
          content: Text(
            'This task requires a completed timer session before marking done.\n\nTask: ${t.title}',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Start timer')),
          ],
        ),
      );
      if (start == true && context.mounted) {
        ref.read(activeExecutionTaskIdProvider.notifier).state = t.id;
        ref.read(activeExecutionTaskLabelProvider.notifier).state = t.title;
        ref.read(executionControllerProvider.notifier).setTask(id: t.id, label: t.title);
        await Navigator.pushNamed(context, TimerSessionScreen.routeName);
      }
      return;
    }
  }
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
    sequenceIndex: t.sequenceIndex,
    strictModeRequired: t.strictModeRequired,
    modeRefId: t.modeRefId,
  );
  try {
    await planning.upsertTask(updated);
    await ref.read(reminderSyncServiceProvider).markTaskStarted(t.id);
    await ref.read(scoringControllerProvider).submit(taskId: t.id, completionPercent: 100);
    final prev = ref.read(scoredTaskStatusesProvider);
    ref.read(scoredTaskStatusesProvider.notifier).state = {...prev, t.id: 100};
    invalidateTaskListProviders(ref);
    final rows = await ref.read(todayAllTasksRowsProvider.future);
    if (!context.mounted) return;
    await _promptStartNextTask(context, ref, rows, completedTaskId: t.id);
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not complete: $e')));
    }
  }
}

Future<void> _promptStartNextTask(
  BuildContext context,
  WidgetRef ref,
  List<PlannedTaskRow> rows, {
  required String completedTaskId,
}) async {
  final candidates = rows.where((r) => r.task.id != completedTaskId).toList();
  final next = NextTaskRanker.chooseNext(candidates, preferUserSequence: true);
  if (next == null) return;
  final decision = await showDialog<_NextTaskDecision>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Start next task?'),
      content: Text('Next up: ${next.task.title}'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, _NextTaskDecision.moveWithReason),
          child: const Text('Move to later'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, _NextTaskDecision.extraTime),
          child: const Text('Need extra time'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, _NextTaskDecision.startNow),
          child: const Text('Start now'),
        ),
      ],
    ),
  );
  if (!context.mounted || decision == null) return;
  switch (decision) {
    case _NextTaskDecision.startNow:
      await ref.read(planningRepositoryProvider).logFlowTransitionEvent(
        FlowTransitionEvent(
          id: StableId.generate('flowev'),
          taskId: next.task.id,
          type: FlowTransitionType.startNow,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
        ),
      );
      if (!context.mounted) return;
      ref.read(activeExecutionTaskIdProvider.notifier).state = next.task.id;
      ref.read(activeExecutionTaskLabelProvider.notifier).state = next.task.title;
      ref.read(executionControllerProvider.notifier).setTask(
        id: next.task.id,
        label: next.task.title,
      );
      await Navigator.pushNamed(context, TimerSessionScreen.routeName);
      return;
    case _NextTaskDecision.extraTime:
      await _handleExtraTime(context, ref, completedTaskId: completedTaskId, rows: rows);
      return;
    case _NextTaskDecision.moveWithReason:
      await _handleMoveWithReason(context, ref, row: next);
      return;
  }
}

Future<void> _handleExtraTime(
  BuildContext context,
  WidgetRef ref, {
  required String completedTaskId,
  required List<PlannedTaskRow> rows,
}) async {
  PlannedTaskRow? completedRow;
  for (final r in rows) {
    if (r.task.id == completedTaskId) {
      completedRow = r;
      break;
    }
  }
  if (completedRow == null) return;
  final t = completedRow.task;
  final planning = ref.read(planningRepositoryProvider);
  final blocks = await planning.getBlocks(completedRow.routineId);
  var urgency = 50;
  for (final b in blocks) {
    if (b.id == completedRow.blockId) {
      urgency = b.urgencyScore;
      break;
    }
  }
  final routineForPolicy = await _routineForPlannedRow(ref, completedRow);
  if (!context.mounted) return;
  final policy = ExtensionPolicy.forTask(
    task: t,
    resolver: ref.read(routineModePolicyResolverProvider),
    blockUrgencyScore: urgency,
    routine: routineForPolicy,
  );
  if (!context.mounted) return;
  final extension = await _promptExtensionRequest(
    context,
    allowedMaxMinutes: policy.allowedMaxMinutes,
    requireReason: policy.requiresReason,
    requireReflection: policy.requiresReflectionPrompt,
  );
  if (extension == null) return;
  final extraMinutes = extension.minutes;
  final updated = PlannedTask(
    id: t.id,
    routineId: t.routineId,
    blockId: t.blockId,
    title: t.title,
    durationMinutes: (t.durationMinutes + extraMinutes).clamp(1, 24 * 60),
    priority: t.priority,
    orderIndex: t.orderIndex,
    reminderEnabled: t.reminderEnabled,
    reminderTimeIso: t.reminderTimeIso,
    status: TaskStatus.inProgress,
    createdAtMs: t.createdAtMs,
    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    category: t.category,
    planDateKey: t.planDateKey ?? completedRow.dateKey,
    notes: _appendExtraTimeNote(
      existing: t.notes,
      extraMinutes: extraMinutes,
      reason: extension.reason,
      reflection: extension.reflection,
    ),
    sequenceIndex: t.sequenceIndex,
    strictModeRequired: t.strictModeRequired,
    modeRefId: t.modeRefId,
  );
  await planning.upsertTask(updated);
  await planning.logFlowTransitionEvent(
    FlowTransitionEvent(
      id: StableId.generate('flowev'),
      taskId: t.id,
      type: FlowTransitionType.extraTime,
      reasonNote: '[+${extraMinutes}m] ${extension.reason}${extension.reflection == null ? '' : ' | ${extension.reflection}'}',
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );
  await ref.read(reminderSyncServiceProvider).markLogicalReasonProvided(t.id);
  final prev = ref.read(scoredTaskStatusesProvider);
  final nextScores = Map<String, int>.from(prev)..remove(t.id);
  ref.read(scoredTaskStatusesProvider.notifier).state = nextScores;
  invalidateTaskListProviders(ref);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Added $extraMinutes minutes and moved task back to in progress.')),
  );
}

Future<({int minutes, String reason, String? reflection})?> _promptExtensionRequest(
  BuildContext context, {
  required int allowedMaxMinutes,
  required bool requireReason,
  required bool requireReflection,
}) async {
  final options = [15, 30, 45, 60].where((m) => m <= allowedMaxMinutes).toList();
  if (options.isEmpty) return null;
  var selectedMinutes = options.first;
  final reasonCtrl = TextEditingController();
  final reflectionCtrl = TextEditingController();
  String? errorText;
  final result = await showDialog<({int minutes, String reason, String? reflection})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: const Text('Request extra time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              initialValue: selectedMinutes,
              items: [
                for (final m in options) DropdownMenuItem(value: m, child: Text('+$m minutes')),
              ],
              onChanged: (v) => setState(() => selectedMinutes = v ?? options.first),
              decoration: InputDecoration(labelText: 'Allowed (max +$allowedMaxMinutes min)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: requireReason ? 'Reason (required)' : 'Reason',
                hintText: 'Why do you need more time?',
              ),
            ),
            if (requireReflection) ...[
              const SizedBox(height: 10),
              TextField(
                controller: reflectionCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'What did you promise yourself? (required)',
                  hintText: 'Short commitment reminder to stay aligned.',
                ),
              ),
            ],
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final reason = reasonCtrl.text.trim();
              final reflection = reflectionCtrl.text.trim();
              if (requireReason && reason.isEmpty) {
                setState(() => errorText = 'Reason is required.');
                return;
              }
              if (requireReflection && reflection.isEmpty) {
                setState(() => errorText = 'Reflection is required.');
                return;
              }
              Navigator.pop(
                ctx,
                (
                  minutes: selectedMinutes,
                  reason: reason.isEmpty ? 'No reason provided' : reason,
                  reflection: reflection.isEmpty ? null : reflection,
                ),
              );
            },
            child: const Text('Approve extension'),
          ),
        ],
      ),
    ),
  );
  reasonCtrl.dispose();
  reflectionCtrl.dispose();
  return result;
}

Future<void> _handleMoveWithReason(
  BuildContext context,
  WidgetRef ref, {
  required PlannedTaskRow row,
}) async {
  final reasons = OverrideReasonCategory.values;
  OverrideReasonCategory selectedReason = reasons.first;
  final noteCtrl = TextEditingController();
  String? errorText;
  final choice = await showDialog<({OverrideReasonCategory reason, String note})>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Move task with reason'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<OverrideReasonCategory>(
                initialValue: selectedReason,
                items: [
                  for (final r in reasons)
                    DropdownMenuItem(value: r, child: Text(r.label)),
                ],
                onChanged: (v) => setState(() => selectedReason = v ?? reasons.first),
                decoration: const InputDecoration(labelText: 'Reason category'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: noteCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Logical reason (1-2 sentences)',
                  hintText: 'Explain why this move is the best decision now.',
                ),
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(errorText!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final note = noteCtrl.text.trim();
                try {
                  FlowTransitionEvent.validateReasonNote(note);
                } catch (_) {
                  setState(() => errorText = 'Give a clear reason in 1-2 sentences.');
                  return;
                }
                Navigator.pop(ctx, (reason: selectedReason, note: note));
              },
              child: const Text('Move task'),
            ),
          ],
        );
      },
    ),
  );
  noteCtrl.dispose();
  if (choice == null) return;

  final t = row.task;
  final planning = ref.read(planningRepositoryProvider);
  final moved = PlannedTask(
    id: t.id,
    routineId: t.routineId,
    blockId: t.blockId,
    title: t.title,
    durationMinutes: t.durationMinutes,
    priority: t.priority,
    orderIndex: t.orderIndex,
    reminderEnabled: t.reminderEnabled,
    reminderTimeIso: t.reminderTimeIso,
    status: t.status,
    createdAtMs: t.createdAtMs,
    updatedAtMs: DateTime.now().millisecondsSinceEpoch,
    category: t.category,
    planDateKey: t.planDateKey ?? row.dateKey,
    notes: _appendMoveReason(
      existing: t.notes,
      reason: choice.reason,
      explanation: choice.note,
    ),
    sequenceIndex: (t.sequenceIndex ?? t.orderIndex) + 1000,
    strictModeRequired: t.strictModeRequired,
    modeRefId: t.modeRefId,
  );
  await planning.upsertTask(moved);
  await planning.logFlowTransitionEvent(
    FlowTransitionEvent(
      id: StableId.generate('flowev'),
      taskId: t.id,
      type: FlowTransitionType.moveWithReason,
      reasonCategory: choice.reason,
      reasonNote: choice.note,
      createdAtMs: DateTime.now().millisecondsSinceEpoch,
    ),
  );
  await ref.read(reminderSyncServiceProvider).markLogicalReasonProvided(t.id);
  invalidateTaskListProviders(ref);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Moved "${t.title}" to later: ${choice.reason.label}.')),
  );
}

String _appendMoveReason({
  required String? existing,
  required OverrideReasonCategory reason,
  required String explanation,
}) {
  final stamp = DateTime.now().toIso8601String();
  final entry = '[Moved $stamp] ${reason.label}: $explanation';
  if (existing == null || existing.trim().isEmpty) return entry;
  return '$existing\n$entry';
}

String _appendExtraTimeNote({
  required String? existing,
  required int extraMinutes,
  required String reason,
  required String? reflection,
}) {
  final stamp = DateTime.now().toIso8601String();
  final reflectPart = reflection == null ? '' : ' | Reflection: $reflection';
  final entry = '[ExtraTime $stamp] +${extraMinutes}m | Reason: $reason$reflectPart';
  if (existing == null || existing.trim().isEmpty) return entry;
  return '$existing\n$entry';
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
    sequenceIndex: t.sequenceIndex,
    strictModeRequired: t.strictModeRequired,
    modeRefId: t.modeRefId,
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
