import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/application/planned_task_providers.dart';
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

  final _controller = TextEditingController();
  final _notesController = TextEditingController();
  String _duration = '25 MIN';
  String? _category;
  bool _reminder = false;
  bool _focusSession = true;
  DateTime _reminderTime = DateTime.now().add(const Duration(minutes: 10));
  bool _saving = false;
  bool _loaded = false;

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
        _loaded = true;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load task: $e')));
        Navigator.pop(context);
      }
    }
  }

  Future<void> _persistReminder(String taskId) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final createdAt = _reminderCreatedAtMs ?? now;
    final reminder = ReminderConfig(
      id: _existingReminderId ?? StableId.generate('reminder'),
      taskId: taskId,
      enabled: _reminder,
      scheduledAtIso: _reminder ? _reminderTime.toIso8601String() : null,
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

      final task = _buildPlannedTask(
        id: taskId,
        routineId: routineId,
        blockId: blockId,
        title: title,
        orderIndex: orderIndex,
        createdAtMs: createdAtMs,
        planDateKey: planKey,
      );

      await planning.upsertTask(task);
      await _persistReminder(taskId);
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
