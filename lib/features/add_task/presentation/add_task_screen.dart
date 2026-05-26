import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/application/effective_task_mode.dart';
import '../../planning/application/habit_anchor_aggregator.dart';
import '../../planning/application/planned_task_providers.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/data/planning_repository.dart';
import '../../planning/domain/add_task_duration.dart';
import '../../planning/domain/models/task_item.dart';
import '../../reminders/domain/models/reminder_config.dart';
import '../../time_blocks/application/conflict_entity_title_resolver.dart';
import '../../time_blocks/application/time_block_providers.dart';
import '../../time_blocks/domain/models/time_conflict.dart';
import '../../time_blocks/presentation/conflict_bottom_sheet.dart';
import 'add_task_ui.dart';

class AddTaskEditArgs {
  const AddTaskEditArgs({
    required this.taskId,
    required this.routineId,
    required this.blockId,
    required this.dateKey,
  });

  final String taskId;
  final String routineId;
  final String blockId;
  /// `Routine.dateKey` for this task’s current plan day.
  final String dateKey;
}

/// Passed when opening Add Task from a specific routine slot (e.g. Plan Tomorrow).
/// Saves directly under [routineId]/[blockId] without calling [ensureDefaultDayPlan].
class AddTaskSlotArgs {
  const AddTaskSlotArgs({
    required this.routineId,
    required this.blockId,
    required this.dateKey,
  });

  final String routineId;
  final String blockId;
  final String dateKey;
}

class AddTaskScreen extends ConsumerStatefulWidget {
  const AddTaskScreen({super.key, this.editArgs, this.slotArgs});

  final AddTaskEditArgs? editArgs;
  final AddTaskSlotArgs? slotArgs;

  static const routeName = '/add-task';

  @override
  ConsumerState<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> {
  static const _categoryOptions = ['Study', 'Fitness', 'Work', 'Personal', 'Planning'];
  static const _durationOptions = ['15 MIN', '25 MIN', '45 MIN', '1 HOUR'];
  static const _durationLabels = ['15m', '25m', '45m', '1h'];
  static const _modeChoiceIds = ['flexible', 'disciplined', 'extreme'];
  static const _modeLabels = ['Flexible', 'Disciplined', 'Extreme'];
  static const _modeDescriptions = [
    'Reminders are gentle. Missing a day is okay.',
    'Hold me accountable. Streaks matter.',
    'No excuses. Follow up until I act.',
  ];

  final _controller = TextEditingController();
  final _notesController = TextEditingController();
  String _duration = '25 MIN';
  String? _category;
  bool _reminder = false;
  bool _focusSession = true;
  bool _isHabitAnchor = false;
  DateTime _reminderTime = DateTime.now().add(const Duration(minutes: 10));
  bool _saving = false;
  bool _loaded = false;

  /// Execution mode id: `flexible` | `disciplined` | `extreme`.
  String _modeRefId = 'flexible';
  bool _strictModeRequired = false;
  /// When false, new-task save may inherit [Routine.modeId] for the target routine.
  bool _modeUserCustomized = false;

  /// Whether this task occupies a fixed (rigid) time slot.
  bool _isRigid = false;

  bool _advancedExpanded = false;

  PlannedTask? _loadedTask;
  String? _existingReminderId;
  int? _reminderCreatedAtMs;

  bool get _isEdit => widget.editArgs != null;

  @override
  void initState() {
    super.initState();
    // Pre-set reminder time to slot's plan day at 9 AM if coming from a future slot.
    final slotDateKey = widget.slotArgs?.dateKey;
    if (slotDateKey != null && slotDateKey != DateKeys.todayKey()) {
      final parsed = DateTime.tryParse(slotDateKey);
      if (parsed != null) {
        _reminderTime = DateTime(parsed.year, parsed.month, parsed.day, 9, 0);
      }
    }
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadEdit());
    } else {
      _loaded = true;
      if (widget.slotArgs != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _seedModeFromRoutineSlot());
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _planDateKey() {
    if (!_reminder) {
      // Respect a preset plan day (e.g. from Plan Tomorrow slot) when no reminder is set.
      return widget.slotArgs?.dateKey ??
          widget.editArgs?.dateKey ??
          DateKeys.todayKey();
    }
    final rd = DateTime(_reminderTime.year, _reminderTime.month, _reminderTime.day);
    return DateKeys.yyyymmdd(rd);
  }

  Future<void> _seedModeFromRoutineSlot() async {
    if (_isEdit || widget.slotArgs == null || _modeUserCustomized || !mounted) return;
    try {
      final planning = ref.read(planningRepositoryProvider);
      final routines = await planning.getRoutinesForDate(widget.slotArgs!.dateKey);
      for (final r in routines) {
        if (r.id == widget.slotArgs!.routineId) {
          if (!mounted || _modeUserCustomized) return;
          setState(() => _modeRefId = r.modeId);
          return;
        }
      }
    } catch (_) {}
  }

  Future<String> _effectiveModeRefIdForSave({
    required PlanningRepository planning,
    required String routineId,
    required String planDateKey,
    required String blockId,
  }) async {
    Routine? routine;
    try {
      final routines = await planning.getRoutinesForDate(planDateKey);
      for (final r in routines) {
        if (r.id == routineId) {
          routine = r;
          break;
        }
      }
    } catch (_) {}

    final explicit = (!_isEdit && !_modeUserCustomized) ? null : _modeRefId;
    final task = PlannedTask(
      id: '',
      routineId: routineId,
      blockId: blockId,
      title: '',
      durationMinutes: 1,
      priority: 3,
      orderIndex: 0,
      reminderEnabled: false,
      reminderTimeIso: null,
      status: TaskStatus.notStarted,
      createdAtMs: 0,
      updatedAtMs: 0,
      modeRefId: explicit,
    );
    return EffectiveTaskMode.effectiveModeRefId(task: task, routine: routine);
  }

  Future<void> _loadEdit() async {
    final args = widget.editArgs!;
    final planning = ref.read(planningRepositoryProvider);
    try {
      final tasks = await planning.getTasks(routineId: args.routineId, blockId: args.blockId);
      PlannedTask? task;
      for (final t in tasks) {
        if (t.id == args.taskId) {
          task = t;
          break;
        }
      }
      if (task == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task not found.')));
          Navigator.pop(context);
        }
        return;
      }

      final reminders = await ref.read(reminderRepositoryProvider).getRemindersForTasks([task.id]);

      if (!mounted) return;
      final loaded = task;
      setState(() {
        _loadedTask = loaded;
        _controller.text = loaded.title;
        _notesController.text = loaded.notes ?? '';
        _duration = durationLabelFromMinutes(loaded.durationMinutes);
        _category = loaded.category;
        _reminder = loaded.reminderEnabled;
        if (loaded.reminderTimeIso != null) {
          final parsed = DateTime.tryParse(loaded.reminderTimeIso!);
          if (parsed != null) {
            _reminderTime = parsed.toLocal();
          }
        }
        if (reminders.isNotEmpty) {
          _existingReminderId = reminders.first.id;
          _reminderCreatedAtMs = reminders.first.createdAtMs;
        }
        _modeRefId = loaded.modeRefId?.trim().isNotEmpty == true ? loaded.modeRefId! : 'flexible';
        _strictModeRequired = loaded.strictModeRequired;
        _isHabitAnchor = loaded.isHabitAnchor;
        // Phase A: _isRigid defaults to false; no field on PlannedTask yet.
        _modeUserCustomized = false;
        _advancedExpanded =
            _isHabitAnchor || _strictModeRequired || _isRigid;
        _loaded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load task: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _persistReminder({
    required String taskId,
    required String taskTitle,
    required String routineId,
    required String blockId,
    required String modeRefId,
  }) async {
    var blockUrgency = 50;
    try {
      final planning = ref.read(planningRepositoryProvider);
      final blocks = await planning.getBlocks(routineId);
      for (final b in blocks) {
        if (b.id == blockId) {
          blockUrgency = b.urgencyScore;
          break;
        }
      }
    } catch (_) {}

    final now = DateTime.now().millisecondsSinceEpoch;
    final createdAt = _reminderCreatedAtMs ?? now;
    final reminder = ReminderConfig(
      id: _existingReminderId ?? StableId.generate('reminder'),
      taskId: taskId,
      taskTitle: taskTitle,
      enabled: _reminder,
      scheduledAtIso: _reminder ? _reminderTime.toIso8601String() : null,
      modeRefId: modeRefId,
      blockUrgencyScore: blockUrgency,
      createdAtMs: createdAt,
      updatedAtMs: now,
    );
    await ref.read(reminderRepositoryProvider).upsertReminder(reminder);
    _existingReminderId ??= reminder.id;
    await ref.read(reminderSyncServiceProvider).syncForTaskIds([taskId]);
  }

  PlannedTask _buildPlannedTask({
    required String id,
    required String routineId,
    required String blockId,
    required String title,
    required int orderIndex,
    required int createdAtMs,
    required String planDateKey,
    required String modeRefId,
  }) {
    return PlannedTask(
      id: id,
      routineId: routineId,
      blockId: blockId,
      title: title,
      durationMinutes: addTaskDurationMinutes(_duration),
      priority: _loadedTask?.priority ?? 3,
      orderIndex: orderIndex,
      reminderEnabled: _reminder,
      reminderTimeIso: _reminder ? _reminderTime.toIso8601String() : null,
      status: _loadedTask?.status ?? TaskStatus.notStarted,
      createdAtMs: createdAtMs,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      category: _category,
      planDateKey: planDateKey,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      sequenceIndex: _loadedTask?.sequenceIndex,
      isHabitAnchor: _isHabitAnchor,
      strictModeRequired: _strictModeRequired,
      modeRefId: modeRefId,
    );
  }

  Future<bool> _confirmOverlapIfNeeded(PlannedTask task, String planDateKey) async {
    if (!task.reminderEnabled || task.reminderTimeIso == null) return true;
    final anchors = await readHabitAnchorsForDate(ref, dateKey: planDateKey);
    if (!mounted) return false;
    final conflicts = findOverlappingHabitAnchorsForTask(
      task,
      anchors,
      ignoredTaskId: _isEdit ? task.id : null,
    );
    if (conflicts.isEmpty) return true;
    final proceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Overlaps habit time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This task overlaps one or more habit anchors. Are you sure you want to continue?',
            ),
            const SizedBox(height: 10),
            for (final c in conflicts.take(3))
              Text(
                '• ${c.label} (${_timeLabel(c.startLocal)}-${_timeLabel(c.endLocal)})'
                ' ${c.source == HabitAnchorSource.goal ? '[Goal]' : '[Task Habit]'}',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            if (conflicts.length > 3)
              Text(
                '• +${conflicts.length - 3} more',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Change time'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save anyway'),
          ),
        ],
      ),
    );
    if (proceed == true) {
      fireAndForgetAnalyticsEvent(
        ref,
        type: AnalyticsEventType.overlapOverride,
        entityId: task.id,
        entityKind: 'task',
        sourceSurface: _isEdit ? 'add_task_edit' : 'add_task_create',
        idempotencyKey:
            'overlap_override_${task.id}_${task.reminderTimeIso ?? 'na'}_${conflicts.length}',
        modeRefId: task.modeRefId,
        reason: 'save_anyway_after_overlap_warning',
      );
    }
    return proceed == true;
  }

  String _timeLabel(DateTime dt) {
    final tod = TimeOfDay.fromDateTime(dt);
    return tod.format(context);
  }

  // ─── Phase A: time block helpers ──────────────────────────────────────────

  Future<bool> _checkTimeBlockConflicts(PlannedTask task) async {
    final reminderIso = task.reminderTimeIso;
    if (reminderIso == null) return true;
    final startAt = DateTime.tryParse(reminderIso);
    if (startAt == null) return true;

    final service = ref.read(timeBlockSyncServiceProvider);
    final proposed = service.deriveBlock(
      entityId: task.id,
      entityKind: 'task',
      startAt: startAt,
      durationMinutes: task.durationMinutes,
      modeRefId: task.modeRefId,
      isRigid: _isRigid,
    );
    if (proposed == null) return true;

    final repo = ref.read(timeBlockRepositoryProvider);
    final overlapping = await repo.listOverlappingBlocks(proposed);
    final entityTitles = await buildSchedulingConflictEntityTitles(
      ref,
      overlapping: overlapping,
    );

    final result = await service.checkConflicts(proposed, entityTitles: entityTitles);
    if (!result.hasConflicts) {
      // Still log overlapCreated = false (no event needed — clean save).
      return true;
    }

    if (!mounted) return false;

    // Minor conflicts: show inline banner only (no bottom sheet).
    if (result.worstSeverity == ConflictSeverity.minor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minor time overlap with ${result.conflicts.first.conflictingEntityTitle}. '
            'Saved anyway.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      _logOverlapCreated(task, overridden: true);
      return true;
    }

    // Moderate / severe: show full conflict bottom sheet.
    final action = await ConflictBottomSheet.show(
      context: context,
      conflicts: result.conflicts,
      proposedEntityTitle: task.title,
    );

    switch (action) {
      case ConflictAction.saveAnyway:
        _logOverlapCreated(task, overridden: true);
        fireAndForgetAnalyticsEvent(
          ref,
          type: AnalyticsEventType.overlapOverridden,
          entityId: task.id,
          entityKind: 'task',
          sourceSurface: _isEdit ? 'add_task_edit' : 'add_task_create',
          idempotencyKey: 'overlap_overridden_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
          modeRefId: task.modeRefId,
        );
        return true;
      case ConflictAction.adjustTime:
      case ConflictAction.shortenDuration:
      case null:
        return false;
    }
  }

  Future<void> _syncTimeBlock(PlannedTask task) async {
    final reminderIso = task.reminderTimeIso;
    if (reminderIso == null) {
      await ref.read(timeBlockSyncServiceProvider).removeBlockForEntity(task.id);
      return;
    }
    final startAt = DateTime.tryParse(reminderIso);
    if (startAt == null) return;

    final service = ref.read(timeBlockSyncServiceProvider);
    final block = service.deriveBlock(
      entityId: task.id,
      entityKind: 'task',
      startAt: startAt,
      durationMinutes: task.durationMinutes,
      modeRefId: task.modeRefId,
      isRigid: _isRigid,
    );
    if (block != null) {
      await service.syncBlock(block);
    }
  }

  void _logOverlapCreated(PlannedTask task, {required bool overridden}) {
    fireAndForgetAnalyticsEvent(
      ref,
      type: AnalyticsEventType.overlapCreated,
      entityId: task.id,
      entityKind: 'task',
      sourceSurface: _isEdit ? 'add_task_edit' : 'add_task_create',
      idempotencyKey: 'overlap_created_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
      modeRefId: task.modeRefId,
      reason: overridden ? 'override' : 'detected',
    );
  }

  Future<void> _onSave() async {
    if (_saving || (_isEdit && !_loaded)) return;
    setState(() => _saving = true);

    final title = _controller.text.trim().isEmpty ? 'Untitled Task' : _controller.text.trim();
    final planning = ref.read(planningRepositoryProvider);
    final planKey = _planDateKey();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    try {
      late final String routineId;
      late final String blockId;
      late final int orderIndex;
      late final String taskId;
      late final int createdAtMs;

      if (_isEdit) {
        final args = widget.editArgs!;
        taskId = _loadedTask!.id;
        createdAtMs = _loadedTask!.createdAtMs;

        if (planKey != args.dateKey) {
          await planning.deleteTask(
            routineId: args.routineId,
            blockId: args.blockId,
            taskId: taskId,
          );
          final day = await planning.ensureDefaultDayPlan(planKey);
          routineId = day.routineId;
          blockId = day.blockId;
          final existing = await planning.getTasks(routineId: routineId, blockId: blockId);
          orderIndex = existing.isEmpty
              ? 0
              : existing.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
        } else {
          routineId = args.routineId;
          blockId = args.blockId;
          orderIndex = _loadedTask!.orderIndex;
        }
      } else {
        taskId = StableId.generate('task');
        createdAtMs = nowMs;
        if (widget.slotArgs != null) {
          // Save directly into the preset slot — no ensureDefaultDayPlan needed.
          routineId = widget.slotArgs!.routineId;
          blockId = widget.slotArgs!.blockId;
          final existing = await planning.getTasks(routineId: routineId, blockId: blockId);
          orderIndex = existing.isEmpty
              ? 0
              : existing.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
        } else {
          final day = await planning.ensureDefaultDayPlan(planKey);
          routineId = day.routineId;
          blockId = day.blockId;
          final existing = await planning.getTasks(routineId: routineId, blockId: blockId);
          orderIndex = existing.isEmpty
              ? 0
              : existing.map((t) => t.orderIndex).reduce((a, b) => a > b ? a : b) + 1;
        }
      }

      final modeRefId = await _effectiveModeRefIdForSave(
        planning: planning,
        routineId: routineId,
        planDateKey: planKey,
        blockId: blockId,
      );

      final task = _buildPlannedTask(
        id: taskId,
        routineId: routineId,
        blockId: blockId,
        title: title,
        orderIndex: orderIndex,
        createdAtMs: createdAtMs,
        planDateKey: planKey,
        modeRefId: modeRefId,
      );
      final proceed = await _confirmOverlapIfNeeded(task, planKey);
      if (!proceed) return;

      // Phase A — time block conflict check.
      final tbProceed = await _checkTimeBlockConflicts(task);
      if (!tbProceed) return;

      await planning.upsertTask(task);

      // Phase A — sync time block after successful save.
      await _syncTimeBlock(task);

      await _persistReminder(
        taskId: taskId,
        taskTitle: title,
        routineId: routineId,
        blockId: blockId,
        modeRefId: modeRefId,
      );
      invalidateTaskListProviders(ref);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save task: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  int get _selectedModeIndex {
    final i = _modeChoiceIds.indexOf(_modeRefId);
    return i >= 0 ? i : 0;
  }

  String get _durationDisplayLabel {
    final i = _durationOptions.indexOf(_duration);
    return i >= 0 ? _durationLabels[i] : _durationLabels[1];
  }

  String get _advancedSubtitle {
    final parts = <String>[];
    if (_isHabitAnchor) parts.add('Habit anchor');
    if (_strictModeRequired) parts.add('Strict');
    if (_isRigid) parts.add('Fixed time');
    if (parts.isEmpty) return 'Habit, strict rules, fixed time';
    return parts.join(' · ');
  }

  Widget _buildCategoryCard() {
    return AddTaskCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AddTaskSectionLabel(
            title: 'Category',
            subtitle: 'Optional — tap to select or clear',
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              const spacing = 8.0;
              const columns = 3;
              final tileWidth =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final label in _categoryOptions)
                    SizedBox(
                      width: tileWidth,
                      child: AddTaskCategoryTile(
                        label: label,
                        icon: addTaskCategoryIcon(label),
                        selected: _category == label,
                        onTap: () => setState(
                          () => _category = _category == label ? null : label,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showAccountabilityPicker() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AddTaskColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final bottom = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Accountability',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AddTaskColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'How we remind you and follow up on this task',
                style: TextStyle(fontSize: 12, color: AddTaskColors.muted),
              ),
              const SizedBox(height: 16),
              for (var i = 0; i < _modeChoiceIds.length; i++) ...[
                if (i > 0) const SizedBox(height: 8),
                AddTaskEnforcementTile(
                  modeId: _modeChoiceIds[i],
                  label: _modeLabels[i],
                  description: _modeDescriptions[i],
                  isSelected: _modeRefId == _modeChoiceIds[i],
                  onTap: () => Navigator.pop(ctx, _modeChoiceIds[i]),
                ),
              ],
            ],
          ),
        );
      },
    );

    if (picked == null || !mounted) return;
    setState(() {
      _modeUserCustomized = true;
      _modeRefId = picked;
    });
  }

  Widget _buildAccountabilityCard() {
    final selectedIndex = _selectedModeIndex;
    final modeId = _modeChoiceIds[selectedIndex];

    return AddTaskCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: AddTaskSectionLabel(
                  title: 'Accountability',
                  subtitle: 'Reminders and follow-up style',
                ),
              ),
              TextButton(
                onPressed: _showAccountabilityPicker,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AddTaskColors.accent,
                ),
                child: const Text(
                  'Change',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Material(
            color: AddTaskColors.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _showAccountabilityPicker,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AddTaskColors.accent.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        AddTaskEnforcementTile.iconFor(modeId),
                        size: 17,
                        color: AddTaskColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _modeLabels[selectedIndex],
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AddTaskColors.accent,
                            ),
                          ),
                          Text(
                            _modeDescriptions[selectedIndex],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              height: 1.25,
                              color: AddTaskColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '+2',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AddTaskColors.accent.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: AddTaskColors.accent.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleCard() {
    final timeLabel = TimeOfDay.fromDateTime(_reminderTime).format(context);
    final dateLabel =
        MaterialLocalizations.of(context).formatMediumDate(_reminderTime);
    final planLabel = _planDateKey() == DateKeys.todayKey()
        ? 'Today'
        : _planDateKey();

    return AddTaskCard(
      child: Column(
        children: [
          AddTaskToggleRow(
            icon: Icons.notifications_active_outlined,
            iconColor: AddTaskColors.cyan,
            title: 'Reminder',
            subtitle: 'Get notified before this task starts',
            value: _reminder,
            onChanged: (value) async {
              setState(() => _reminder = value);
              if (!value) return;
              final ok =
                  await ref.read(reminderSyncServiceProvider).ensurePermissions();
              if (!ok && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notification permission is disabled.'),
                  ),
                );
              }
            },
          ),
          if (_reminder) ...[
            const Divider(height: 24, color: AddTaskColors.border),
            AddTaskInsetPanel(
              child: Column(
                children: [
                  AddTaskPickerRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Date',
                    value: dateLabel,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _reminderTime,
                        firstDate:
                            DateTime.now().subtract(const Duration(days: 365)),
                        lastDate:
                            DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked == null || !mounted) return;
                      setState(() {
                        _reminderTime = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          _reminderTime.hour,
                          _reminderTime.minute,
                        );
                      });
                    },
                  ),
                  const Divider(height: 1, color: AddTaskColors.border),
                  AddTaskPickerRow(
                    icon: Icons.schedule_rounded,
                    label: 'Time',
                    value: timeLabel,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(_reminderTime),
                      );
                      if (picked == null) return;
                      setState(() {
                        _reminderTime = DateTime(
                          _reminderTime.year,
                          _reminderTime.month,
                          _reminderTime.day,
                          picked.hour,
                          picked.minute,
                        );
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.event_available_outlined,
                          size: 18,
                          color: AddTaskColors.muted,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Plan day',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AddTaskColors.faint,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                planLabel,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AddTaskColors.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const Divider(height: 24, color: AddTaskColors.border),
          AddTaskToggleRow(
            icon: Icons.center_focus_strong_rounded,
            title: 'Focus session',
            subtitle: 'Start in deep-focus mode when you begin',
            value: _focusSession,
            onChanged: (v) => setState(() => _focusSession = v),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedCard() {
    return AddTaskExpandableCard(
      title: 'Advanced',
      subtitle: _advancedSubtitle,
      leadingIcon: Icons.tune_rounded,
      expanded: _advancedExpanded,
      onToggle: () => setState(() => _advancedExpanded = !_advancedExpanded),
      children: [
        AddTaskToggleRow(
          icon: Icons.anchor_rounded,
          iconColor: AddTaskColors.accentDim,
          title: 'Habit anchor',
          subtitle: 'Priority scheduling for a stable habit slot',
          value: _isHabitAnchor,
          onChanged: (v) => setState(() => _isHabitAnchor = v),
        ),
        const Divider(height: 8, color: AddTaskColors.border),
        AddTaskToggleRow(
          icon: Icons.gavel_rounded,
          iconColor: AddTaskColors.cyan,
          title: 'Strict for this task',
          subtitle: 'Extra checks even when the slot is Flexible',
          value: _strictModeRequired,
          onChanged: (v) => setState(() => _strictModeRequired = v),
        ),
        const Divider(height: 8, color: AddTaskColors.border),
        AddTaskToggleRow(
          icon: Icons.lock_clock_rounded,
          title: 'Fixed time slot',
          subtitle: 'Treat as a hard block for conflict detection',
          value: _isRigid,
          onChanged: (v) => setState(() => _isRigid = v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AddTaskColors.surface,
      appBar: AppBar(
        backgroundColor: AddTaskColors.surface,
        elevation: 0,
        foregroundColor: AddTaskColors.onSurface,
        title: Text(
          _isEdit ? 'Edit task' : 'Add task',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: !_loaded
          ? const Center(
              child: CircularProgressIndicator(color: AddTaskColors.accent),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      AddTaskCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AddTaskSectionLabel(
                              title: 'What are you doing?',
                              subtitle: 'Give it a clear, actionable name',
                            ),
                            const SizedBox(height: 14),
                            AddTaskField(
                              controller: _controller,
                              hint: 'Read 10 pages',
                            ),
                            const SizedBox(height: 12),
                            AddTaskField(
                              controller: _notesController,
                              hint: 'Notes (optional)',
                              maxLines: 3,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AddTaskColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      AddTaskCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const AddTaskSectionLabel(title: 'Duration'),
                            const SizedBox(height: 12),
                            AddTaskDurationSegment(
                              options: _durationLabels,
                              selected: _durationDisplayLabel,
                              onSelected: (label) {
                                final i = _durationLabels.indexOf(label);
                                if (i >= 0) {
                                  setState(() => _duration = _durationOptions[i]);
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildCategoryCard(),
                      const SizedBox(height: 12),
                      _buildAccountabilityCard(),
                      const SizedBox(height: 12),
                      _buildScheduleCard(),
                      const SizedBox(height: 12),
                      _buildAdvancedCard(),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomSafe),
                  decoration: const BoxDecoration(
                    color: AddTaskColors.surface,
                    border: Border(top: BorderSide(color: AddTaskColors.border)),
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      backgroundColor: AddTaskColors.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: _saving ? null : _onSave,
                    child: Text(
                      _saving ? 'Saving…' : (_isEdit ? 'Save changes' : 'Add task'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
