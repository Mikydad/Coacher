import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../add_task/presentation/add_task_args.dart';
import '../../add_task/presentation/add_task_sheet.dart';
import '../../education/presentation/help_dot.dart';
import '../../planning/application/planned_task_actions.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/task_item.dart';
import '../../planning/domain/sleep_task.dart';
import '../../scoring/application/scoring_controller.dart';
import '../../timer/presentation/timer_session_screen.dart';
import 'task_detail_screen.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/presentation/swipe_actions.dart';

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

enum _HubReorderLayer {
  habitAnchor,
  overdueScheduled,
  upcomingScheduled,
  flexible,
}

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
    await showAddTaskSheet(context);
    // AddTaskScreen calls the coordinator on save; this is a safety net
    // recompute for the case the user navigates back without saving.
    // migrated to coordinator
    await ScheduleMutationCoordinator.instance.run(
      TaskCreatedMutation(
        entityId: 'tasks_hub_post_add',
        sourceContext: 'tasks_hub.open_add',
        dateStr: DateKeys.todayKey(),
      ),
      commitOverride: () async {},
    );
  }

  Future<void> _openEditTask(
    BuildContext context,
    WidgetRef ref,
    PlannedTaskRow row,
  ) async {
    await showAddTaskSheet(
      context,
      editArgs: AddTaskEditArgs(
        taskId: row.task.id,
        routineId: row.routineId,
        blockId: row.blockId,
        dateKey: row.dateKey,
      ),
    );
    // migrated to coordinator
    await ScheduleMutationCoordinator.instance.run(
      TaskUpdatedMutation(
        entityId: row.task.id,
        sourceContext: 'tasks_hub.open_edit',
        dateStr: row.task.planDateKey ?? DateKeys.todayKey(),
      ),
      commitOverride: () async {},
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayAllTasksRowsProvider);
    final otherAsync = ref.watch(openTasksOutsideTodayProvider);
    final scores = ref.watch(scoredTaskStatusesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const PageTitle('Tasks'),
        centerTitle: true,
        actions: [
          const HelpAppBarButton('tasks'),
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
              ref.read(activeExecutionTaskIdProvider.notifier).state =
                  next.task.id;
              ref.read(activeExecutionTaskLabelProvider.notifier).state =
                  next.task.title;
              await Navigator.pushNamed(context, TimerSessionScreen.routeName);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Next suggestion: ${next.task.title}'),
                  ),
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
          // migrated to coordinator
          await ScheduleMutationCoordinator.instance.run(
            TaskUpdatedMutation(
              entityId: 'tasks_hub_pull_refresh',
              sourceContext: 'tasks_hub.pull_to_refresh',
              dateStr: DateKeys.todayKey(),
            ),
            commitOverride: () async {},
          );
          await readFreshTodayPlannedRows(ref);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _HubSectionHeader('Today'),
              const SizedBox(height: 8),
              todayAsync.when(
                data: (rows) {
                  if (rows.isEmpty) {
                    return Text(
                      'No tasks today.',
                      style: TextStyle(color: AppColors.fg54),
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
                      final base = List<PlannedTaskRow>.from(rows)
                        ..removeAt(oldIndex);
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
                        await planning.upsertTask(
                          _hubTaskWithOrderIndex(row, i),
                        );
                      }
                      // migrated to coordinator
                      await ScheduleMutationCoordinator.instance.run(
                        TaskUpdatedMutation(
                          entityId: copy.isNotEmpty
                              ? copy.first.task.id
                              : 'tasks_hub_reorder',
                          sourceContext: 'tasks_hub.drag_reorder',
                          dateStr: copy.isNotEmpty
                              ? (copy.first.task.planDateKey ??
                                    DateKeys.todayKey())
                              : DateKeys.todayKey(),
                        ),
                        commitOverride: () async {},
                      );
                    },
                    children: [
                      // Swipe right-to-left for Edit / Delete (2026-08-22);
                      // reorder stays on long-press, so the two gestures
                      // don't collide.
                      for (final row in rows)
                        SwipeActionsRow(
                          key: ValueKey(row.task.id),
                          id: row.task.id,
                          groupTag: 'hub-tasks-today',
                          onEdit: () => _openEditTask(context, ref, row),
                          onDelete: () =>
                              confirmDeletePlannedTask(context, ref, row),
                          child: _HubTaskTile(
                            row: row,
                            scorePercent: scores[row.task.id],
                            onEdit: () {
                              _openEditTask(context, ref, row);
                            },
                            onCompleteNow: () => completePlannedTaskRow(
                              context,
                              ref,
                              row,
                              sourceSurface: 'tasks_hub',
                              sourceContext: 'tasks_hub.complete',
                            ),
                            onPlansChanged: () =>
                                promptPlansChangedForRow(context, ref, row),
                            onDelete: () =>
                                confirmDeletePlannedTask(context, ref, row),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text(
                  'Could not load: $e',
                  style: TextStyle(color: Colors.red.shade200),
                ),
              ),
              const SizedBox(height: 28),
              const _HubSectionHeader('Open on other days'),
              const SizedBox(height: 8),
              otherAsync.when(
                data: (rows) {
                  if (rows.isEmpty) {
                    return Text(
                      'No open tasks on other days.',
                      style: TextStyle(color: AppColors.fg54),
                    );
                  }
                  return Column(
                    children: [
                      for (final row in rows)
                        SwipeActionsRow(
                          key: ValueKey('other_${row.task.id}_${row.dateKey}'),
                          id: '${row.task.id}_${row.dateKey}',
                          groupTag: 'hub-tasks-other',
                          onEdit: () => _openEditTask(context, ref, row),
                          onDelete: () =>
                              confirmDeletePlannedTask(context, ref, row),
                          child: _HubTaskTile(
                            row: row,
                            scorePercent: scores[row.task.id],
                            showDateKey: true,
                            onEdit: () {
                              _openEditTask(context, ref, row);
                            },
                            onCompleteNow: () => completePlannedTaskRow(
                              context,
                              ref,
                              row,
                              sourceSurface: 'tasks_hub',
                              sourceContext: 'tasks_hub.complete',
                            ),
                            onPlansChanged: () =>
                                promptPlansChangedForRow(context, ref, row),
                            onDelete: () =>
                                confirmDeletePlannedTask(context, ref, row),
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (e, _) =>
                    Text('$e', style: TextStyle(color: Colors.red.shade200)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Section heading for the hub — the shared [SectionHeader] type scale with
/// a lime calendar glyph in front, so "Today" and "Open on other days" read
/// as dated buckets rather than plain labels.
class _HubSectionHeader extends StatelessWidget {
  const _HubSectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.accent),
        const SizedBox(width: 8),
        Text(title, style: SectionHeader.style),
      ],
    );
  }
}

/// Stripe + checkbox color for one row.
///
/// The six built-in categories hold a fixed hue so the list reads by kind.
/// A custom category derives a stable hue from its own name; an
/// uncategorized task derives one from its title and wears it desaturated —
/// enough to give the list rhythm without pretending to mean something a
/// categorized row's color does.
Color _taskAccent(PlannedTask t) {
  final category = t.category?.trim();
  if (category == null || category.isEmpty) {
    return _derivedAccent(t.title, saturation: 0.20, lightness: 0.52);
  }
  return switch (category) {
    'Study' => AppColors.categoryBlue,
    'Fitness' => AppColors.coral,
    'Work' => AppColors.orange,
    'Personal' => AppColors.violetSoft,
    'Plan' || 'Planning' => AppColors.success,
    kSleepTaskCategory => AppColors.periwinkle,
    _ => _derivedAccent(category, saturation: 0.45, lightness: 0.60),
  };
}

/// Same text → same hue, every launch: [String.hashCode] is stable within a
/// run and the value only ever drives decoration.
Color _derivedAccent(
  String seed, {
  required double saturation,
  required double lightness,
}) {
  final hue = (seed.hashCode.abs() % 360).toDouble();
  return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
}

class _HubTaskTile extends ConsumerWidget {
  const _HubTaskTile({
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

  void _openDetails(BuildContext context) {
    Navigator.pushNamed(
      context,
      TaskDetailScreen.routeName,
      arguments: TaskDetailArgs.fromRow(row),
    );
  }

  /// Status only when it says something the row doesn't already show — the
  /// empty checkbox is what "notStarted" means, so spelling it out was noise.
  String? get _statusLabel => switch (row.task.status) {
    TaskStatus.notStarted => null,
    TaskStatus.inProgress => 'In progress',
    TaskStatus.completed => 'Done',
    TaskStatus.partial => 'Partial',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = row.task;
    final isOverdue = ref.watch(overdueEntityIdsProvider).contains(t.id);
    final accent = _taskAccent(t);
    final done = t.status == TaskStatus.completed;

    // Meta chunks, each rendered as its own span so the reminder can carry
    // a bell in the accent color mid-line.
    final chunks = <(String, bool)>[
      // Overdue leads and takes the accent flag: it is the one thing on this
      // row that is asking for something (FR-R-50's task-list badge). Uses
      // the row's existing meta-span mechanism rather than a bolted-on chip.
      if (isOverdue) ('Overdue', true),
      if (t.durationMinutes > 0) ('${t.durationMinutes} min', false),
      if (t.category != null && t.category!.trim().isNotEmpty)
        (t.category!, false),
      if (t.reminderEnabled) ('Reminder on', true),
      if (showDateKey) (row.dateKey, false),
      if (scorePercent != null) ('$scorePercent%', false),
      if (_statusLabel != null) (_statusLabel!, false),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      // Floor, not a fixed height: a row whose meta chunks all filtered out
      // (0 min, no category, no reminder) would otherwise collapse to its
      // title and break the list's rhythm; wrapped titles still grow past it.
      constraints: const BoxConstraints(minHeight: 76),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: AppColors.surfacePanel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openDetails(context),
          // IntrinsicHeight gives the stretch a bounded height — the list
          // items are shrink-wrapped, so without it the stripe (and every
          // stretched child) has no height to lay out against.
          child: IntrinsicHeight(
            child: Row(
              // Stretch so the stripe runs the full height of a wrapped title.
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(width: 4, color: accent),
                _CompleteCircle(
                  accent: accent,
                  done: done,
                  onTap: done ? null : onCompleteNow,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: done ? AppColors.fg54 : AppColors.fg,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.fg54,
                          ),
                        ),
                        if (chunks.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          _MetaLine(chunks: chunks, accent: accent),
                        ],
                      ],
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: AppColors.fg54),
                  onSelected: (value) {
                    if (value == 'details') _openDetails(context);
                    if (value == 'edit') onEdit();
                    if (value == 'complete') onCompleteNow();
                    if (value == 'plans_changed') onPlansChanged();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (ctx) => const [
                    PopupMenuItem(value: 'details', child: Text('Details')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(
                      value: 'complete',
                      child: Text('Complete now'),
                    ),
                    PopupMenuItem(
                      value: 'plans_changed',
                      child: Text('Plans Changed?'),
                    ),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one-line meta under the title. Chunks join with " · "; the reminder
/// chunk gets a bell and the row's accent so "Reminder on" is spottable
/// without reading the line.
class _MetaLine extends StatelessWidget {
  const _MetaLine({required this.chunks, required this.accent});

  final List<(String, bool)> chunks;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final spans = <InlineSpan>[];
    for (var i = 0; i < chunks.length; i++) {
      if (i > 0) spans.add(const TextSpan(text: ' · '));
      final (text, isReminder) = chunks[i];
      if (isReminder) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                Icons.notifications_active_rounded,
                size: 13,
                color: accent,
              ),
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: text,
          style: isReminder ? TextStyle(color: accent) : null,
        ),
      );
    }
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(color: AppColors.fg54, fontSize: 12),
    );
  }
}

/// Tap-to-complete circle — the row's primary action now (it was buried in
/// the kebab menu). Completing fills the ring with the row's accent; an
/// already-done row's circle is inert, since nothing here un-completes.
class _CompleteCircle extends StatelessWidget {
  const _CompleteCircle({
    required this.accent,
    required this.done,
    required this.onTap,
  });

  final Color accent;
  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 26,
      child: SizedBox(
        width: 52,
        child: Center(
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? accent : Colors.transparent,
              border: Border.all(color: accent, width: 2),
            ),
            child: done
                ? Icon(Icons.check_rounded, size: 16, color: AppColors.scaffold)
                : null,
          ),
        ),
      ),
    );
  }
}
