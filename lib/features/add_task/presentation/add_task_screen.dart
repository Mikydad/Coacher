import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../planning/application/effective_task_mode.dart';
import '../../planning/application/habit_anchor_aggregator.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/data/planning_repository.dart';
import '../../context_override/application/context_override_providers.dart';
import '../../context_override/domain/models/context_override.dart';
import '../../planning/application/task_schedule_display.dart';
import '../../planning/application/form_draft_autosave.dart';
import '../../planning/application/form_draft_providers.dart';
import '../../planning/domain/add_task_duration.dart';
import '../../planning/domain/models/add_task_form_draft.dart';
import '../../planning/domain/models/task_item.dart';
import '../../planning/domain/sleep_task.dart';
import '../../planning/presentation/sleep_task_ios_guidance.dart';
import 'custom_duration_dialog.dart';
import '../../reminders/domain/models/reminder_config.dart';
import '../../time_blocks/application/conflict_entity_title_resolver.dart';
import '../../time_blocks/application/scheduling_conflict_analytics.dart';
import '../../time_blocks/application/time_block_providers.dart';
import '../../time_blocks/domain/models/time_conflict.dart';
import '../../time_blocks/domain/models/conflict_resolution_outcome.dart';
import '../../time_blocks/presentation/scheduling_conflict_sheet.dart';
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

class _AddTaskScreenState extends ConsumerState<AddTaskScreen> with WidgetsBindingObserver {
  static const _categoryOptions = [
    'Study',
    'Fitness',
    'Work',
    'Personal',
    'Planning',
    kSleepTaskCategory,
  ];
  static const _modeChoiceIds = ['flexible', 'disciplined', 'extreme'];
  static const _modeLabels = ['Flexible', 'Disciplined', 'Extreme'];
  static const _modeDescriptions = [
    'Reminders are gentle. Missing a day is okay.',
    'Hold me accountable. Streaks matter.',
    'No excuses. Follow up until I act.',
  ];

  final _controller = TextEditingController();
  final _notesController = TextEditingController();
  final _scheduleSectionKey = GlobalKey();
  String _duration = '25 MIN';
  int _customDurationMinutes = kAddTaskDefaultCustomMinutes;
  bool _durationEnabled = false;
  String? _category;
  bool _reminder = false;
  bool _focusSession = false;
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

  /// When [category] is Sleep: sync daily sleep window + optional in-app quiet mode.
  bool _syncSleepWindowAndQuietMode = true;

  /// `sleep` or `dnd` for in-app override when [_syncSleepWindowAndQuietMode].
  String _inAppQuietMode = 'sleep';

  PlannedTask? _loadedTask;
  String? _existingReminderId;
  int? _reminderCreatedAtMs;

  FormDraftAutosave? _draftAutosave;
  bool _draftInitialized = false;
  bool _draftRestoreOffered = false;
  bool _suppressDraftDirty = false;
  bool _draftClearedOnSuccessfulSave = false;

  bool get _isEdit => widget.editArgs != null;

  String get _draftKey =>
      _isEdit ? addTaskEditDraftKey(widget.editArgs!.taskId) : addTaskCreateDraftKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Pre-set reminder time to slot's plan day at 9 AM if coming from a future slot.
    final slotDateKey = widget.slotArgs?.dateKey;
    if (slotDateKey != null && slotDateKey != DateKeys.todayKey()) {
      final parsed = DateTime.tryParse(slotDateKey);
      if (parsed != null) {
        _reminderTime = DateTime(parsed.year, parsed.month, parsed.day, 9, 0);
      }
    }
    if (_isEdit) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadEdit().then((_) {
          if (mounted) _offerDraftRestoreIfNeeded();
        });
      });
    } else {
      _loaded = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.slotArgs != null) _seedModeFromRoutineSlot();
        _offerDraftRestoreIfNeeded();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_draftInitialized) {
      _draftInitialized = true;
      _draftAutosave = FormDraftAutosave(
        repository: ref.read(formDraftRepositoryProvider),
        key: _draftKey,
        capture: _captureDraftJson,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      unawaited(_draftAutosave?.persistIfDirty());
    }
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    if (_draftInitialized && !_suppressDraftDirty) {
      _draftAutosave?.markDirty();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_draftClearedOnSuccessfulSave) {
      unawaited(_draftAutosave?.persistIfDirty());
    }
    _draftAutosave?.dispose();
    _controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  AddTaskFormDraft _captureDraft() {
    final slot = widget.slotArgs;
    return AddTaskFormDraft(
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
      title: _controller.text,
      notes: _notesController.text,
      duration: _duration,
      durationEnabled: _durationEnabled,
      customDurationMinutes: _customDurationMinutes,
      category: _category,
      reminder: _reminder,
      focusSession: _focusSession,
      isHabitAnchor: _isHabitAnchor,
      reminderTimeMs: _reminderTime.millisecondsSinceEpoch,
      modeRefId: _modeRefId,
      strictModeRequired: _strictModeRequired,
      modeUserCustomized: _modeUserCustomized,
      isRigid: _isRigid,
      advancedExpanded: _advancedExpanded,
      syncSleepWindowAndQuietMode: _syncSleepWindowAndQuietMode,
      inAppQuietMode: _inAppQuietMode,
      slotRoutineId: slot?.routineId,
      slotBlockId: slot?.blockId,
      slotDateKey: slot?.dateKey,
    );
  }

  Map<String, dynamic> _captureDraftJson() => _captureDraft().toJson();

  void _applyDraft(AddTaskFormDraft draft) {
    _suppressDraftDirty = true;
    setState(() {
      _controller.text = draft.title;
      _notesController.text = draft.notes;
      _duration = draft.duration;
      _durationEnabled = draft.durationEnabled;
      _customDurationMinutes = draft.customDurationMinutes;
      _category = draft.category;
      _reminder = draft.reminder;
      _focusSession = draft.focusSession;
      _isHabitAnchor = draft.isHabitAnchor;
      _reminderTime = DateTime.fromMillisecondsSinceEpoch(draft.reminderTimeMs);
      _modeRefId = draft.modeRefId;
      _strictModeRequired = draft.strictModeRequired;
      _modeUserCustomized = draft.modeUserCustomized;
      _isRigid = draft.isRigid;
      _advancedExpanded = draft.advancedExpanded;
      _syncSleepWindowAndQuietMode = draft.syncSleepWindowAndQuietMode;
      _inAppQuietMode = draft.inAppQuietMode;
    });
    _suppressDraftDirty = false;
    _draftAutosave?.dirty = false;
  }

  Future<void> _offerDraftRestoreIfNeeded() async {
    if (_draftRestoreOffered || !mounted) return;
    _draftRestoreOffered = true;

    final repo = ref.read(formDraftRepositoryProvider);
    final raw = await repo.load(_draftKey);
    if (!mounted || raw == null) return;

    final draft = AddTaskFormDraft.fromJson(raw);
    if (repo.isExpired(draft.savedAtMs)) {
      await repo.delete(_draftKey);
      return;
    }
    if (!draft.hasMeaningfulContent) {
      await repo.delete(_draftKey);
      return;
    }

    final current = _captureDraft();
    if (current.contentEquals(draft)) {
      await repo.delete(_draftKey);
      return;
    }

    final restore = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore draft?'),
        content: const Text(
          'You have unsaved changes from earlier. Restore them or start fresh?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Start fresh'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (restore == true) {
      _applyDraft(draft);
      await repo.delete(_draftKey);
      _draftAutosave?.cancel();
      fireAndForgetAnalyticsEvent(
        ref,
        type: AnalyticsEventType.formDraftRestored,
        entityId: _draftKey,
        entityKind: 'form_draft',
        sourceSurface: _isEdit ? 'add_task_edit' : 'add_task_create',
        idempotencyKey: 'form_draft_restored_$_draftKey',
      );
    } else {
      await repo.delete(_draftKey);
      fireAndForgetAnalyticsEvent(
        ref,
        type: AnalyticsEventType.formDraftDiscarded,
        entityId: _draftKey,
        entityKind: 'form_draft',
        sourceSurface: _isEdit ? 'add_task_edit' : 'add_task_create',
        idempotencyKey: 'form_draft_discarded_$_draftKey',
      );
    }
  }

  void _logOverlapResolvedInline({
    required String taskId,
    required String movedEntity,
    required Object suggestionIndex,
    String? conflictingEntityId,
  }) {
    fireAndForgetAnalyticsEvent(
      ref,
      type: AnalyticsEventType.overlapResolvedInline,
      entityId: taskId,
      entityKind: 'task',
      sourceSurface: _isEdit ? 'add_task_edit' : 'add_task_create',
      idempotencyKey:
          'overlap_resolved_inline_${taskId}_${DateTime.now().millisecondsSinceEpoch}',
      reason: inlineConflictResolutionReason(
        movedEntity: movedEntity,
        suggestionIndex: suggestionIndex,
        conflictingEntityId: conflictingEntityId,
      ),
    );
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
      _suppressDraftDirty = true;
      setState(() {
        _loadedTask = loaded;
        _controller.text = loaded.title;
        _notesController.text = loaded.notes ?? '';
        _durationEnabled = taskHasFocusDuration(loaded.durationMinutes);
        if (_durationEnabled) {
          _duration = durationLabelFromMinutes(
            loaded.durationMinutes,
            category: loaded.category,
          );
          if (isCustomDurationKey(_duration)) {
            _customDurationMinutes = loaded.durationMinutes;
          }
        }
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
      _suppressDraftDirty = false;
    } catch (e) {
      _suppressDraftDirty = false;
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
      durationMinutes: _resolvedDurationMinutes,
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
    if (!taskHasFocusDuration(task.durationMinutes)) return true;
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

    final planDay = DateTime(
      proposed.startAt.year,
      proposed.startAt.month,
      proposed.startAt.day,
    );

    final outcome = await SchedulingConflictSheet.show(
      context: context,
      proposedTitle: task.title,
      proposedKind: 'task',
      proposedBlock: proposed,
      conflicts: result.conflicts,
      resolutionPort: ref.read(conflictResolutionServiceProvider),
      loadEntityTitles: () async {
        final overlapping = await ref
            .read(timeBlockRepositoryProvider)
            .listOverlappingBlocks(proposed);
        return buildSchedulingConflictEntityTitles(
          ref,
          overlapping: overlapping,
        );
      },
      planDay: planDay,
      ignoreEntityIds: {task.id},
      onEntityMoved: () => ScheduleMutationCoordinator.instance.run( // migrated to coordinator
        TimeBlockChangedMutation(
          entityId: task.id,
          sourceContext: 'add_task_screen.conflict_resolution',
          dateStr: DateKeys.todayKey(planDay),
        ),
        commitOverride: () async {}, // move already done by conflict resolution
      ),
      onAdjustProposedSchedule: (start, durationMinutes) {
        setState(() {
          _reminder = true;
          _reminderTime = start;
          _duration = durationLabelFromMinutes(
            durationMinutes,
            category: _category,
          );
        });
        _scrollToScheduleSection();
      },
      onOverlapResolvedInline: ({
        required movedEntity,
        required suggestionIndex,
        conflictingEntityId,
      }) =>
          _logOverlapResolvedInline(
        taskId: task.id,
        movedEntity: movedEntity,
        suggestionIndex: suggestionIndex,
        conflictingEntityId: conflictingEntityId,
      ),
    );

    return _handleConflictResolutionOutcome(task, outcome);
  }

  void _scrollToScheduleSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _scheduleSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool _handleConflictResolutionOutcome(
    PlannedTask task,
    ConflictResolutionOutcome? outcome,
  ) {
    if (outcome == null) return false;
    switch (outcome.kind) {
      case ConflictResolutionKind.proceedToSave:
        if (outcome.overlapOverridden) {
          _logOverlapCreated(task, overridden: true);
          fireAndForgetAnalyticsEvent(
            ref,
            type: AnalyticsEventType.overlapOverridden,
            entityId: task.id,
            entityKind: 'task',
            sourceSurface: _isEdit ? 'add_task_edit' : 'add_task_create',
            idempotencyKey:
                'overlap_overridden_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
            modeRefId: task.modeRefId,
          );
        }
        return true;
      case ConflictResolutionKind.stayOnForm:
        return false;
      case ConflictResolutionKind.proposedScheduleAdjusted:
        if (outcome.adjustedStart != null) {
          setState(() {
            _reminder = true;
            _reminderTime = outcome.adjustedStart!;
          });
        }
        if (outcome.adjustedDurationMinutes != null) {
          setState(() {
            _duration = durationLabelFromMinutes(
              outcome.adjustedDurationMinutes!,
              category: _category,
            );
          });
        }
        _scrollToScheduleSection();
        return false;
    }
  }

  Future<void> _syncTimeBlock(PlannedTask task) async {
    if (!taskHasFocusDuration(task.durationMinutes)) {
      await ref.read(timeBlockSyncServiceProvider).removeBlockForEntity(task.id);
      return;
    }
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

      await _applySleepSchedulingSideEffects(task);

      await _persistReminder(
        taskId: taskId,
        taskTitle: title,
        routineId: routineId,
        blockId: blockId,
        modeRefId: modeRefId,
      );
      // migrated to coordinator
      await ScheduleMutationCoordinator.instance.run(
        _isEdit
            ? TaskUpdatedMutation(
                entityId: taskId,
                sourceContext: 'add_task_screen',
                dateStr: planKey,
              )
            : TaskCreatedMutation(
                entityId: taskId,
                sourceContext: 'add_task_screen',
                dateStr: planKey,
              ),
        commitOverride: () async {}, // write already done above (upsertTask + syncTimeBlock + persistReminder)
      );

      _draftClearedOnSuccessfulSave = true;
      _suppressDraftDirty = true;
      _draftAutosave?.cancel();
      await ref.read(formDraftRepositoryProvider).delete(_draftKey);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not save task: $e')),
        );
      }
    } finally {
      if (mounted) {
        if (_draftClearedOnSuccessfulSave) _suppressDraftDirty = true;
        setState(() => _saving = false);
      }
    }
  }

  List<String> get _activeDurationOptions => isSleepCategory(_category)
      ? sleepDurationChipKeys
      : standardDurationChipKeys;

  List<String> get _activeDurationLabels {
    if (isSleepCategory(_category)) {
      return [
        ...sleepDurationChipLabels.sublist(0, sleepDurationChipLabels.length - 1),
        isCustomDurationKey(_duration)
            ? formatAddTaskDurationChipLabel(_customDurationMinutes)
            : sleepDurationChipLabels.last,
      ];
    }
    return [
      ...standardDurationChipLabels.sublist(0, 4),
      isCustomDurationKey(_duration)
          ? formatAddTaskDurationChipLabel(_customDurationMinutes)
          : 'Custom',
    ];
  }

  int get _resolvedDurationMinutes {
    if (isSleepCategory(_category) || _durationEnabled) {
      return addTaskDurationMinutes(
        _duration,
        customMinutes: _customDurationMinutes,
      );
    }
    return kReminderOnlyDurationMinutes;
  }

  int get _effectiveDurationMinutes => _resolvedDurationMinutes;

  Future<void> _editCustomDuration() async {
    final sleep = isSleepCategory(_category);
    final picked = await showCustomDurationDialog(
      context,
      initialMinutes: sleep
          ? _customDurationMinutes.clamp(
              kSleepMinCustomMinutes,
              kSleepMaxCustomMinutes,
            )
          : _customDurationMinutes,
      minMinutes: sleep ? kSleepMinCustomMinutes : null,
      maxMinutes: sleep ? kSleepMaxCustomMinutes : null,
      title: sleep ? 'Custom sleep length' : null,
      minErrorMessage: sleep ? 'Sleep length must be at least 3 hours' : null,
      maxErrorMessage: sleep ? 'Maximum sleep length is 14 hours' : null,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _duration = kAddTaskCustomDurationKey;
      _customDurationMinutes = picked;
      if (!sleep) _durationEnabled = true;
    });
  }

  void _applySleepCategoryDefaults(String label) {
    if (!isSleepCategory(label)) return;
    _durationEnabled = true;
    _duration = '8 HOURS';
    _reminder = true;
    _isRigid = true;
    _focusSession = false;
    if (_controller.text.trim().isEmpty) {
      _controller.text = kSleepTaskCategory;
    }
    if (Platform.isIOS) {
      _syncSleepWindowAndQuietMode = true;
    }
  }

  Future<void> _applySleepSchedulingSideEffects(PlannedTask task) async {
    if (!isSleepTask(task)) return;
    if (!task.reminderEnabled || task.reminderTimeIso == null) return;

    final start = DateTime.tryParse(task.reminderTimeIso!)?.toLocal();
    if (start == null) return;
    final end = start.add(Duration(minutes: task.durationMinutes));

    final overrideService = ref.read(contextOverrideServiceProvider);
    await overrideService.setSleepWindow(
      start: formatSleepWindowHHmm(start),
      end: formatSleepWindowHHmm(end),
    );

    if (!_syncSleepWindowAndQuietMode) return;

    if (Platform.isIOS && mounted) {
      await showSleepTaskIosFocusGuidance(
        context,
        onUseInAppSleep: () async {
          await overrideService.activateOverride(
            type: ContextOverride.sleep,
            expiresAt: end,
          );
        },
        onUseInAppDnd: () async {
          await overrideService.activateOverride(
            type: ContextOverride.doNotDisturb,
            expiresAt: end,
          );
        },
      );
      return;
    }

    final type = _inAppQuietMode == 'dnd'
        ? ContextOverride.doNotDisturb
        : ContextOverride.sleep;
    await overrideService.activateOverride(type: type, expiresAt: end);
  }

  int get _selectedModeIndex {
    final i = _modeChoiceIds.indexOf(_modeRefId);
    return i >= 0 ? i : 0;
  }

  String get _durationDisplayLabel {
    if (isCustomDurationKey(_duration)) {
      return formatAddTaskDurationChipLabel(_customDurationMinutes);
    }
    final i = _activeDurationOptions.indexOf(_duration);
    if (i >= 0) return _activeDurationLabels[i];
    return isSleepCategory(_category) ? sleepDurationChipLabels.last : '25m';
  }

  /// No chip highlighted until duration is enabled (sleep always has duration).
  String? get _durationSegmentSelection {
    if (isSleepCategory(_category) || _durationEnabled) {
      return _durationDisplayLabel;
    }
    return null;
  }

  String get _advancedSubtitle {
    final parts = <String>[];
    if (isSleepCategory(_category) && _syncSleepWindowAndQuietMode) {
      parts.add('Sleep window');
    }
    if (_isHabitAnchor) parts.add('Habit anchor');
    if (_strictModeRequired) parts.add('Strict');
    if (_isRigid) parts.add('Fixed time');
    if (parts.isEmpty) return 'Habit, strict rules, fixed time';
    return parts.join(' · ');
  }

  String _accountabilitySubtitle(int index) {
    switch (_modeChoiceIds[index]) {
      case 'extreme':
        return 'AGGRESSIVE REMINDERS';
      case 'disciplined':
        return 'STEADY ACCOUNTABILITY';
      default:
        return 'GENTLE REMINDERS';
    }
  }

  Widget _buildDurationSection() {
    final sleep = isSleepCategory(_category);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: AddTaskHeroSectionLabel(
                title: 'Duration',
                subtitle: sleep
                    ? 'Choose a preset or tap Custom for your sleep length'
                    : _durationEnabled
                        ? 'Define your focus sprint'
                        : 'Reminder only — no calendar time block',
              ),
            ),
            if (!sleep) ...[
              const SizedBox(width: 12),
              Column(
                children: [
                  Switch.adaptive(
                    value: _durationEnabled,
                    onChanged: (value) => setState(() => _durationEnabled = value),
                    activeTrackColor: AddTaskColors.accentDim.withValues(alpha: 0.55),
                    activeThumbColor: AddTaskColors.accentContainer,
                  ),
                  const Text(
                    'Use duration',
                    style: TextStyle(
                      color: AddTaskColors.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        AddTaskDurationSegment(
          options: _activeDurationLabels,
          selected: _durationSegmentSelection,
          onSelected: (label) async {
            final i = _activeDurationLabels.indexOf(label);
            if (i < 0) return;
            final key = _activeDurationOptions[i];
            if (isCustomDurationKey(key)) {
              await _editCustomDuration();
              return;
            }
            setState(() {
              _durationEnabled = true;
              _duration = key;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AddTaskHeroSectionLabel(
          title: 'Category',
          subtitle: 'Tap to organize your energy',
        ),
        const SizedBox(height: 16),
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
                        onTap: () => setState(() {
                          if (_category == label) {
                            _category = null;
                          } else {
                            final wasSleep = isSleepCategory(_category);
                            _category = label;
                            if (isSleepCategory(label)) {
                              _applySleepCategoryDefaults(label);
                            } else if (wasSleep &&
                                sleepDurationChipKeys.contains(_duration)) {
                              _duration = '25 MIN';
                            }
                          }
                        }),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
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

  Widget _buildAccountabilityRow() {
    final selectedIndex = _selectedModeIndex;

    return AddTaskSettingsActionRow(
      icon: Icons.verified_user_outlined,
      title: 'Accountability',
      subtitle: _accountabilitySubtitle(selectedIndex),
      actionLabel: 'CHANGE',
      onTap: _showAccountabilityPicker,
    );
  }

  Widget _buildDeepWorkRow() {
    return AddTaskSettingsToggleRow(
      icon: Icons.bolt_rounded,
      title: 'Deep Work',
      subtitle: 'NOTIFICATION BLACKOUT',
      value: _focusSession,
      onChanged: (v) => setState(() => _focusSession = v),
    );
  }

  Widget _buildReminderSection() {
    final timeLabel = TimeOfDay.fromDateTime(_reminderTime).format(context);
    final dateLabel =
        MaterialLocalizations.of(context).formatMediumDate(_reminderTime);
    final planLabel = _planDateKey() == DateKeys.todayKey()
        ? 'Today'
        : _planDateKey();

    return KeyedSubtree(
      key: _scheduleSectionKey,
      child: Material(
        color: AddTaskColors.card,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      const SizedBox(height: 8),
                      AddTaskPickerRow(
                        icon: Icons.schedule_rounded,
                        label: isSleepCategory(_category) ? 'Sleep start' : 'Time',
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
                      if (isSleepCategory(_category) && _reminder) ...[
                        const SizedBox(height: 8),
                        AddTaskPickerRow(
                          icon: Icons.bedtime_rounded,
                          label: 'Sleep end',
                          value: formatTaskTimeOfDay(
                            _reminderTime.add(
                              Duration(minutes: _effectiveDurationMinutes),
                            ),
                          ),
                        ),
                      ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSleepAdvancedExtras() {
    if (!isSleepCategory(_category)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AddTaskToggleRow(
          icon: Icons.bedtime_rounded,
          iconColor: AddTaskColors.accentDim,
          title: 'Sleep window & quiet mode',
          subtitle: Platform.isIOS
              ? 'Updates daily sleep window; offers in-app Sleep or DND'
              : 'Updates daily sleep window and in-app quiet mode',
          value: _syncSleepWindowAndQuietMode,
          onChanged: (v) => setState(() => _syncSleepWindowAndQuietMode = v),
        ),
        if (_syncSleepWindowAndQuietMode && !Platform.isIOS) ...[
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'sleep', label: Text('Sleep')),
              ButtonSegment(value: 'dnd', label: Text('DND')),
            ],
            selected: {_inAppQuietMode},
            onSelectionChanged: (s) {
              if (s.isEmpty) return;
              setState(() => _inAppQuietMode = s.first);
            },
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedSection() {
    return AddTaskCollapsibleSection(
      title: 'Advanced settings',
      subtitle: _advancedSubtitle,
      expanded: _advancedExpanded,
      onToggle: () => setState(() => _advancedExpanded = !_advancedExpanded),
      children: [
        if (isSleepCategory(_category)) ...[
          _buildSleepAdvancedExtras(),
          const SizedBox(height: 12),
        ],
        AddTaskToggleRow(
          icon: Icons.anchor_rounded,
          iconColor: AddTaskColors.accentDim,
          title: 'Habit anchor',
          subtitle: 'Priority scheduling for a stable habit slot',
          value: _isHabitAnchor,
          onChanged: (v) => setState(() => _isHabitAnchor = v),
        ),
        const SizedBox(height: 8),
        AddTaskToggleRow(
          icon: Icons.gavel_rounded,
          iconColor: AddTaskColors.cyan,
          title: 'Strict for this task',
          subtitle: 'Extra checks even when the slot is Flexible',
          value: _strictModeRequired,
          onChanged: (v) => setState(() => _strictModeRequired = v),
        ),
        const SizedBox(height: 8),
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
        scrolledUnderElevation: 0,
        foregroundColor: AddTaskColors.accent,
        centerTitle: true,
        title: Text(
          (_isEdit ? 'Edit task' : 'Add task').toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            letterSpacing: 2,
            color: AddTaskColors.onSurface,
          ),
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
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      const AddTaskHeroSectionLabel(
                        title: 'What are you doing?',
                        subtitle: 'Give it a clear, actionable name',
                      ),
                      const SizedBox(height: 16),
                      AddTaskField(
                        controller: _controller,
                        hint: 'Read 10 pages',
                      ),
                      const SizedBox(height: 12),
                      AddTaskField(
                        controller: _notesController,
                        hint: 'Notes (optional)',
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: AddTaskColors.muted,
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildDurationSection(),
                      const SizedBox(height: 32),
                      _buildCategorySection(),
                      const SizedBox(height: 24),
                      _buildAccountabilityRow(),
                      if (!isSleepCategory(_category)) ...[
                        const SizedBox(height: 12),
                        _buildDeepWorkRow(),
                      ],
                      const SizedBox(height: 12),
                      _buildReminderSection(),
                      const SizedBox(height: 24),
                      _buildAdvancedSection(),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.fromLTRB(24, 16, 24, 16 + bottomSafe),
                  decoration: BoxDecoration(
                    color: AddTaskColors.surface,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AddTaskColors.surface.withValues(alpha: 0),
                        AddTaskColors.surface,
                      ],
                    ),
                  ),
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: AddTaskColors.accentContainer,
                      foregroundColor: const Color(0xFF445D00),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: _saving ? null : _onSave,
                    child: Text(
                      _saving
                          ? 'Saving…'
                          : (_isEdit ? 'Save changes' : 'Add task').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
