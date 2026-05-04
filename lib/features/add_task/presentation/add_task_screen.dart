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
  static const _modeChoiceIds = ['flexible', 'disciplined', 'extreme'];
  static const _modeLabels = ['Flexible', 'Disciplined', 'Extreme'];

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
        _modeUserCustomized = false;
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

      await planning.upsertTask(task);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Task' : 'Add Task')),
      body: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('TASK IDENTITY', style: TextStyle(letterSpacing: 2, color: Colors.white70)),
                const SizedBox(height: 8),
                TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: 'Read 10 pages'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Notes (optional)',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                const Text('CLASSIFICATION', style: TextStyle(letterSpacing: 2, color: Colors.white70)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: _categoryOptions
                      .map(
                        (label) => ChoiceChip(
                          label: Text(label),
                          selected: _category == label,
                          onSelected: (selected) => setState(() => _category = selected ? label : null),
                        ),
                      )
                      .toList(),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Habit Anchor'),
                  subtitle: const Text(
                    'Treat this as a stable habit time with top scheduling priority.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _isHabitAnchor,
                  onChanged: (v) => setState(() => _isHabitAnchor = v),
                ),
                const SizedBox(height: 24),
                const Text('EXECUTION MODE', style: TextStyle(letterSpacing: 2, color: Colors.white70)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    for (var i = 0; i < _modeChoiceIds.length; i++)
                      ChoiceChip(
                        label: Text(_modeLabels[i]),
                        selected: _modeRefId == _modeChoiceIds[i],
                        onSelected: (_) => setState(() {
                          _modeUserCustomized = true;
                          _modeRefId = _modeChoiceIds[i];
                        }),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Overrides the slot default for this task only. Uses the slot mode for new tasks until you pick another.',
                  style: TextStyle(color: Colors.white38, fontSize: 12),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Strict for this task'),
                  subtitle: const Text(
                    'Stricter checks (e.g. timer / overrides) even if the slot is Flexible.',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  value: _strictModeRequired,
                  onChanged: (v) => setState(() => _strictModeRequired = v),
                ),
                const SizedBox(height: 24),
                const Text('TEMPORAL DEPTH', style: TextStyle(letterSpacing: 2, color: Colors.white70)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  children: ['15 MIN', '25 MIN', '45 MIN', '1 HOUR']
                      .map(
                        (it) => ChoiceChip(
                          selected: _duration == it,
                          onSelected: (_) => setState(() => _duration = it),
                          label: Text(it),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 24),
                SwitchListTile(
                  title: const Text('Reminder'),
                  subtitle: const Text('Notify me before start'),
                  value: _reminder,
                  onChanged: (value) async {
                    setState(() => _reminder = value);
                    if (!value) return;
                    final ok = await ref.read(reminderSyncServiceProvider).ensurePermissions();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Notification permission is disabled.')),
                      );
                    }
                  },
                ),
                if (_reminder) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminder date'),
                    subtitle: Text(
                      MaterialLocalizations.of(context).formatFullDate(_reminderTime),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _reminderTime,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
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
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reminder time'),
                    subtitle: Text(_reminderTime.toLocal().toString()),
                    trailing: IconButton(
                      icon: const Icon(Icons.schedule),
                      onPressed: () async {
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
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Plan day'),
                    subtitle: Text(
                      _planDateKey() == DateKeys.todayKey()
                          ? 'Today (${_planDateKey()})'
                          : _planDateKey(),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Use for Focus Session'),
                  subtitle: const Text('Activate deep focus protocol'),
                  value: _focusSession,
                  onChanged: (value) => setState(() => _focusSession = value),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    backgroundColor: const Color(0xFFB7FF00),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: _saving ? null : _onSave,
                  child: Text(_saving ? 'Saving…' : (_isEdit ? 'Save' : 'Add Task')),
                ),
              ],
            ),
    );
  }
}
