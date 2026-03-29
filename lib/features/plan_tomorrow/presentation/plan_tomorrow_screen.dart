import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../add_task/presentation/add_task_screen.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../planning/domain/models/block.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/routine_mode.dart';
import '../../planning/domain/models/task_item.dart';
import '../application/plan_tomorrow_providers.dart';

// ─── Helpers ─────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const fullDays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  return '${fullDays[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
}

String _formatTime(String isoString) {
  final dt = DateTime.tryParse(isoString)?.toLocal();
  if (dt == null) return isoString;
  final h = dt.hour;
  final m = dt.minute.toString().padLeft(2, '0');
  final period = h >= 12 ? 'PM' : 'AM';
  final hour = h == 0 ? 12 : (h > 12 ? h - 12 : h);
  return '$hour:$m $period';
}

String _priorityLabel(int priority) {
  if (priority <= 2) return 'High';
  if (priority == 3) return 'Medium';
  return 'Low';
}

Color _priorityColor(int priority) {
  if (priority <= 2) return Colors.redAccent;
  if (priority == 3) return const Color(0xFFB7FF00);
  return Colors.white38;
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class PlanTomorrowScreen extends ConsumerStatefulWidget {
  const PlanTomorrowScreen({super.key});

  static const routeName = '/plan-tomorrow';

  @override
  ConsumerState<PlanTomorrowScreen> createState() => _PlanTomorrowScreenState();
}

class _PlanTomorrowScreenState extends ConsumerState<PlanTomorrowScreen> {
  final Set<String> _expandedSlots = {};
  bool _carryForwardExpanded = true;
  bool _initialized = false;

  void _initExpansion(List<Routine> slots) {
    if (_initialized) return;
    _initialized = true;
    setState(() => _expandedSlots.addAll(slots.map((s) => s.id)));
  }

  Future<void> _onReorderSlots(List<Routine> slots, int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex--;
    final copy = List<Routine>.from(slots);
    final item = copy.removeAt(oldIndex);
    copy.insert(newIndex, item);
    final repo = ref.read(planningRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < copy.length; i++) {
      final r = copy[i];
      if (r.orderIndex == i) continue;
      await repo.upsertRoutine(
        Routine(
          id: r.id,
          title: r.title,
          dateKey: r.dateKey,
          orderIndex: i,
          modeId: r.modeId,
          mode: r.mode,
          createdAtMs: r.createdAtMs,
          updatedAtMs: now,
        ),
      );
    }
    ref.invalidate(tomorrowRoutineSlotsProvider);
  }

  Future<void> _addSlot() async {
    String slotName = '';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New slot'),
        content: TextFormField(
          autofocus: true,
          initialValue: '',
          decoration: const InputDecoration(hintText: 'Slot name'),
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => slotName = v,
          onFieldSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed != true || slotName.trim().isEmpty || !mounted) return;
    final name = slotName.trim();

    final slots = await ref.read(tomorrowRoutineSlotsProvider.future);
    final nextIndex = slots.isEmpty ? 0 : slots.map((s) => s.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
    final repo = ref.read(planningRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final routineId = StableId.generate('routine');
    await repo.upsertRoutine(
      Routine(
        id: routineId,
        title: name,
        dateKey: DateKeys.tomorrowKey(),
        orderIndex: nextIndex,
        modeId: 'flexible',
        mode: RoutineMode.flexible,
        createdAtMs: now,
        updatedAtMs: now,
      ),
    );
    await repo.upsertBlock(
      TaskBlock(
        id: StableId.generate('block'),
        routineId: routineId,
        title: 'Main',
        orderIndex: 0,
        createdAtMs: now,
        updatedAtMs: now,
      ),
    );
    if (mounted) setState(() => _expandedSlots.add(routineId));
    invalidateTomorrowProviders(ref);
  }

  Future<void> _moveToTomorrow(BuildContext context, PlannedTaskRow row) async {
    final slots = await ref.read(tomorrowRoutineSlotsProvider.future);
    if (!context.mounted) return;

    final chosen = await showModalBottomSheet<Routine>(
      context: context,
      builder: (ctx) => _SlotPickerSheet(slots: slots),
    );
    if (chosen == null || !context.mounted) return;

    final repo = ref.read(planningRepositoryProvider);
    final blocks = await repo.getBlocks(chosen.id);
    if (blocks.isEmpty || !context.mounted) return;
    final blockId = blocks.first.id;
    final existing = await repo.getTasks(routineId: chosen.id, blockId: blockId);
    final orderIndex = existing.isEmpty
        ? 0
        : existing.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b) + 1;

    final t = row.task;
    final now = DateTime.now().millisecondsSinceEpoch;
    await repo.deleteTask(
      routineId: row.routineId,
      blockId: row.blockId,
      taskId: t.id,
    );
    await repo.upsertTask(
      PlannedTask(
        id: t.id,
        routineId: chosen.id,
        blockId: blockId,
        title: t.title,
        durationMinutes: t.durationMinutes,
        priority: t.priority,
        orderIndex: orderIndex,
        reminderEnabled: t.reminderEnabled,
        reminderTimeIso: t.reminderTimeIso,
        status: TaskStatus.notStarted,
        createdAtMs: t.createdAtMs,
        updatedAtMs: now,
        category: t.category,
        planDateKey: DateKeys.tomorrowKey(),
        notes: t.notes,
        sequenceIndex: t.sequenceIndex,
        strictModeRequired: t.strictModeRequired,
        modeRefId: t.modeRefId,
      ),
    );
    invalidateTaskListProviders(ref);
    invalidateTomorrowProviders(ref);
  }

  Future<void> _showPlanSummary() async {
    final slots = await ref.read(tomorrowRoutineSlotsProvider.future);
    final Map<String, List<PlannedTaskRow>> slotTasks = {};
    for (final slot in slots) {
      final tasks = await ref.read(tomorrowTasksForRoutineProvider(slot.id).future);
      slotTasks[slot.id] = tasks;
    }
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF111317),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _PlanSummarySheet(
        slots: slots,
        slotTasks: slotTasks,
      ),
    );
    if (!mounted) return;
    Navigator.popUntil(context, ModalRoute.withName('/'));
  }

  @override
  Widget build(BuildContext context) {
    final slotsAsync = ref.watch(tomorrowRoutineSlotsProvider);
    final todayAsync = ref.watch(todayAllTasksRowsProvider);
    final tomorrow = DateTime.now().add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(title: const Text('Plan Tomorrow')),
      body: Column(
        children: [
          Expanded(
            child: slotsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Could not load slots: $e',
                    style: TextStyle(color: Colors.red.shade200),
                  ),
                ),
              ),
              data: (slots) {
                _initExpansion(slots);
                return ReorderableListView(
                  buildDefaultDragHandles: false,
                  onReorder: (o, n) => _onReorderSlots(slots, o, n),
                  header: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PLAN TOMORROW',
                          style: TextStyle(
                            letterSpacing: 3,
                            color: Color(0xFF00E6FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Design your tomorrow.',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(tomorrow),
                          style: const TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  footer: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _addSlot,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Slot'),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white24),
                            foregroundColor: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _CarryForwardSection(
                          todayAsync: todayAsync,
                          expanded: _carryForwardExpanded,
                          onToggle: () => setState(() => _carryForwardExpanded = !_carryForwardExpanded),
                          onMove: (row) => _moveToTomorrow(context, row),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                  children: [
                    for (var i = 0; i < slots.length; i++)
                      _SlotSection(
                        key: ValueKey(slots[i].id),
                        index: i,
                        routine: slots[i],
                        isExpanded: _expandedSlots.contains(slots[i].id),
                        isLastSlot: slots.length == 1,
                        onToggle: () => setState(() {
                          if (_expandedSlots.contains(slots[i].id)) {
                            _expandedSlots.remove(slots[i].id);
                          } else {
                            _expandedSlots.add(slots[i].id);
                          }
                        }),
                      ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(60),
                  backgroundColor: const Color(0xFFB7FF00),
                  foregroundColor: Colors.black,
                ),
                onPressed: _showPlanSummary,
                child: const Text(
                  'Done — See Summary',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Slot Section ────────────────────────────────────────────────────────────

class _SlotSection extends ConsumerStatefulWidget {
  const _SlotSection({
    super.key,
    required this.index,
    required this.routine,
    required this.isExpanded,
    required this.isLastSlot,
    required this.onToggle,
  });

  final int index;
  final Routine routine;
  final bool isExpanded;
  final bool isLastSlot;
  final VoidCallback onToggle;

  @override
  ConsumerState<_SlotSection> createState() => _SlotSectionState();
}

class _SlotSectionState extends ConsumerState<_SlotSection> {
  Future<void> _rename() async {
    String newTitle = widget.routine.title;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename slot'),
        content: TextFormField(
          autofocus: true,
          initialValue: widget.routine.title,
          textCapitalization: TextCapitalization.words,
          onChanged: (v) => newTitle = v,
          onFieldSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
    if (confirmed != true || newTitle.trim().isEmpty || !mounted) return;
    newTitle = newTitle.trim();
    final repo = ref.read(planningRepositoryProvider);
    final r = widget.routine;
    await repo.upsertRoutine(
      Routine(
        id: r.id,
        title: newTitle,
        dateKey: r.dateKey,
        orderIndex: r.orderIndex,
        modeId: r.modeId,
        mode: r.mode,
        createdAtMs: r.createdAtMs,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    ref.invalidate(tomorrowRoutineSlotsProvider);
  }

  Future<void> _setMode(RoutineMode mode) async {
    final repo = ref.read(planningRepositoryProvider);
    final r = widget.routine;
    await repo.upsertRoutine(
      Routine(
        id: r.id,
        title: r.title,
        dateKey: r.dateKey,
        orderIndex: r.orderIndex,
        modeId: mode.name,
        mode: mode,
        createdAtMs: r.createdAtMs,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
    ref.invalidate(tomorrowRoutineSlotsProvider);
  }

  Future<void> _delete(List<PlannedTaskRow> tasks) async {
    if (widget.isLastSlot) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Can't delete the last slot.")),
      );
      return;
    }
    final taskCount = tasks.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${widget.routine.title}"?'),
        content: taskCount > 0
            ? Text('This will also delete $taskCount task${taskCount == 1 ? '' : 's'}.')
            : const Text('This slot has no tasks.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final repo = ref.read(planningRepositoryProvider);
    for (final row in tasks) {
      await repo.deleteTask(
        routineId: row.routineId,
        blockId: row.blockId,
        taskId: row.task.id,
      );
    }
    final blocks = await repo.getBlocks(widget.routine.id);
    for (final block in blocks) {
      await repo.deleteBlock(routineId: widget.routine.id, blockId: block.id);
    }
    await repo.deleteRoutine(widget.routine.id);
    invalidateTomorrowProviders(ref);
  }

  Future<void> _addTask() async {
    final repo = ref.read(planningRepositoryProvider);
    final blocks = await repo.getBlocks(widget.routine.id);
    if (blocks.isEmpty || !mounted) return;
    await Navigator.pushNamed(
      context,
      AddTaskScreen.routeName,
      arguments: AddTaskSlotArgs(
        routineId: widget.routine.id,
        blockId: blocks.first.id,
        dateKey: DateKeys.tomorrowKey(),
      ),
    );
    if (mounted) ref.invalidate(tomorrowTasksForRoutineProvider(widget.routine.id));
  }

  Future<void> _editTask(PlannedTaskRow row) async {
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
    if (mounted) ref.invalidate(tomorrowTasksForRoutineProvider(widget.routine.id));
  }

  Future<void> _deleteTask(PlannedTaskRow row) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Remove "${row.task.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await ref.read(planningRepositoryProvider).deleteTask(
          routineId: row.routineId,
          blockId: row.blockId,
          taskId: row.task.id,
        );
    ref.invalidate(tomorrowTasksForRoutineProvider(widget.routine.id));
  }

  Future<void> _reorderTasks(
    List<PlannedTaskRow> rows,
    int oldIndex,
    int newIndex,
  ) async {
    if (newIndex > oldIndex) newIndex--;
    final copy = List<PlannedTaskRow>.from(rows);
    final item = copy.removeAt(oldIndex);
    copy.insert(newIndex, item);
    final repo = ref.read(planningRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < copy.length; i++) {
      final t = copy[i].task;
      if (t.orderIndex == i) continue;
      await repo.upsertTask(
        PlannedTask(
          id: t.id,
          routineId: t.routineId,
          blockId: t.blockId,
          title: t.title,
          durationMinutes: t.durationMinutes,
          priority: t.priority,
          orderIndex: i,
          reminderEnabled: t.reminderEnabled,
          reminderTimeIso: t.reminderTimeIso,
          status: t.status,
          createdAtMs: t.createdAtMs,
          updatedAtMs: now,
          category: t.category,
          planDateKey: t.planDateKey,
          notes: t.notes,
          sequenceIndex: t.sequenceIndex,
          strictModeRequired: t.strictModeRequired,
          modeRefId: t.modeRefId,
        ),
      );
    }
    ref.invalidate(tomorrowTasksForRoutineProvider(widget.routine.id));
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tomorrowTasksForRoutineProvider(widget.routine.id));

    return tasksAsync.when(
      loading: () => _buildShell(
        taskCount: 0,
        body: const Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: LinearProgressIndicator(),
        ),
      ),
      error: (e, _) => _buildShell(
        taskCount: 0,
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $e', style: TextStyle(color: Colors.red.shade200)),
        ),
      ),
      data: (rows) => _buildShell(
        taskCount: rows.length,
        body: widget.isExpanded
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (rows.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        'No tasks yet.',
                        style: TextStyle(color: Colors.white38, fontSize: 13),
                      ),
                    )
                  else
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      onReorder: (o, n) => _reorderTasks(rows, o, n),
                      children: [
                        for (var i = 0; i < rows.length; i++)
                          _TomorrowTaskTile(
                            key: ValueKey(rows[i].task.id),
                            index: i,
                            row: rows[i],
                            onEdit: () => _editTask(rows[i]),
                            onDelete: () => _deleteTask(rows[i]),
                          ),
                      ],
                    ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                    child: TextButton.icon(
                      onPressed: _addTask,
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add Task'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFB7FF00),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildShell({required int taskCount, required Widget body}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF111317),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            onTap: widget.onToggle,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: widget.index,
                    child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.drag_handle, color: Colors.white24, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '${widget.routine.title} (${widget.routine.mode.name})',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                    ),
                  ),
                  if (taskCount > 0)
                    Text(
                      '$taskCount task${taskCount == 1 ? '' : 's'}',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: widget.isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more, color: Colors.white54),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20, color: Colors.white54),
                    onSelected: (v) async {
                      final rows = await ref.read(
                        tomorrowTasksForRoutineProvider(widget.routine.id).future,
                      );
                      if (!mounted) return;
                      if (v == 'rename') _rename();
                      if (v == 'delete') _delete(rows);
                      if (v == 'mode_flexible') _setMode(RoutineMode.flexible);
                      if (v == 'mode_disciplined') _setMode(RoutineMode.disciplined);
                      if (v == 'mode_extreme') _setMode(RoutineMode.extreme);
                    },
                    itemBuilder: (_) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuDivider(),
                      PopupMenuItem(value: 'mode_flexible', child: Text('Mode: Flexible')),
                      PopupMenuItem(value: 'mode_disciplined', child: Text('Mode: Disciplined')),
                      PopupMenuItem(value: 'mode_extreme', child: Text('Mode: Extreme')),
                      PopupMenuDivider(),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          body,
        ],
      ),
    );
  }
}

// ─── Task Tile ────────────────────────────────────────────────────────────────

class _TomorrowTaskTile extends StatelessWidget {
  const _TomorrowTaskTile({
    super.key,
    required this.index,
    required this.row,
    required this.onEdit,
    required this.onDelete,
  });

  final int index;
  final PlannedTaskRow row;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final t = row.task;
    final priorityLabel = _priorityLabel(t.priority);
    final priorityColor = _priorityColor(t.priority);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Card(
        color: const Color(0xFF1A1C20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.drag_handle, size: 18, color: Colors.white24),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 5),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        _Chip('${t.durationMinutes} min', Colors.white24),
                        _Chip(priorityLabel, priorityColor.withValues(alpha: 0.15),
                            textColor: priorityColor),
                        if (t.category != null) _Chip(t.category!, Colors.white10),
                        if (t.reminderEnabled)
                          const Icon(Icons.notifications_active_outlined,
                              size: 14, color: Color(0xFF00E6FF)),
                      ],
                    ),
                    if (t.notes != null && t.notes!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          t.notes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: Colors.white38),
                onSelected: (v) {
                  if (v == 'edit') onEdit();
                  if (v == 'delete') onDelete();
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Colors.redAccent)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, this.background, {this.textColor = Colors.white70});
  final String label;
  final Color background;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: textColor, fontSize: 11)),
    );
  }
}

// ─── Carry-Forward Section ───────────────────────────────────────────────────

class _CarryForwardSection extends StatelessWidget {
  const _CarryForwardSection({
    required this.todayAsync,
    required this.expanded,
    required this.onToggle,
    required this.onMove,
  });

  final AsyncValue<List<PlannedTaskRow>> todayAsync;
  final bool expanded;
  final VoidCallback onToggle;
  final Future<void> Function(PlannedTaskRow) onMove;

  @override
  Widget build(BuildContext context) {
    return todayAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, s) => const SizedBox.shrink(),
      data: (rows) {
        final open = rows
            .where((r) =>
                r.task.status == TaskStatus.notStarted ||
                r.task.status == TaskStatus.inProgress ||
                r.task.status == TaskStatus.partial)
            .toList();
        if (open.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Unfinished from Today  (${open.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(Icons.expand_more, color: Colors.white38),
                    ),
                  ],
                ),
              ),
            ),
            if (expanded)
              for (final row in open)
                _CarryForwardTile(row: row, onMove: () => onMove(row)),
          ],
        );
      },
    );
  }
}

class _CarryForwardTile extends StatelessWidget {
  const _CarryForwardTile({required this.row, required this.onMove});
  final PlannedTaskRow row;
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final t = row.task;
    final statusLabel = t.status == TaskStatus.inProgress
        ? 'In Progress'
        : t.status == TaskStatus.partial
            ? 'Partial'
            : 'Not Started';

    return Card(
      color: const Color(0xFF111317),
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.white10),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: onMove,
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF00E6FF)),
              child: const Text('Move to Tomorrow →', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Slot Picker Sheet ───────────────────────────────────────────────────────

class _SlotPickerSheet extends StatelessWidget {
  const _SlotPickerSheet({required this.slots});
  final List<Routine> slots;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              'Move to which slot?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          for (final slot in slots)
            ListTile(
              title: Text(slot.title),
              trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white38),
              onTap: () => Navigator.pop(context, slot),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─── Plan Summary Sheet ──────────────────────────────────────────────────────

class _PlanSummarySheet extends StatelessWidget {
  const _PlanSummarySheet({required this.slots, required this.slotTasks});
  final List<Routine> slots;
  final Map<String, List<PlannedTaskRow>> slotTasks;

  @override
  Widget build(BuildContext context) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final allReminders = <PlannedTask>[];
    int totalTasks = 0;

    for (final slot in slots) {
      final tasks = slotTasks[slot.id] ?? [];
      totalTasks += tasks.length;
      for (final row in tasks) {
        if (row.task.reminderEnabled && row.task.reminderTimeIso != null) {
          allReminders.add(row.task);
        }
      }
    }

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'PLAN SUMMARY',
              style: TextStyle(
                letterSpacing: 3,
                color: Color(0xFF00E6FF),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _formatDate(tomorrow),
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
            ),
            Text(
              '$totalTasks task${totalTasks == 1 ? '' : 's'} planned',
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                controller: controller,
                children: [
                  for (final slot in slots) ...[
                    _buildSlotSummary(slot),
                    const SizedBox(height: 10),
                  ],
                  if (allReminders.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'REMINDERS SET',
                      style: TextStyle(
                        letterSpacing: 2,
                        color: Color(0xFF00E6FF),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final task in allReminders)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.notifications_active_outlined,
                              size: 16,
                              color: Color(0xFF00E6FF),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(task.title, style: const TextStyle(fontSize: 14)),
                            ),
                            Text(
                              _formatTime(task.reminderTimeIso!),
                              style: const TextStyle(color: Colors.white54, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: const Color(0xFFB7FF00),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
                    child: const Text(
                      'Close',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlotSummary(Routine slot) {
    final tasks = slotTasks[slot.id] ?? [];
    final totalMin = tasks.fold<int>(0, (sum, r) => sum + r.task.durationMinutes);
    final h = totalMin ~/ 60;
    final m = totalMin % 60;
    final durationStr = h > 0 ? '${h}h ${m}m' : '${m}m';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1C20),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              slot.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
            style: const TextStyle(color: Colors.white54, fontSize: 13),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(durationStr, style: const TextStyle(fontSize: 12, color: Colors.white70)),
          ),
        ],
      ),
    );
  }
}
