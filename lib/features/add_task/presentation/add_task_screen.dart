import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import '../../../core/presentation/bento_category_card.dart';
import '../../../core/presentation/page_headers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../coaching/application/default_mode_resolver.dart';
import '../../planning/application/effective_task_mode.dart';
import '../../planning/application/habit_anchor_aggregator.dart';
import '../../profile/application/profile_providers.dart';
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
import '../../education/application/getting_started_controller.dart';
import '../../education/presentation/help_dot.dart';
import '../../education/presentation/tour_targets.dart';
import 'add_task_ui.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/keyboard_dismiss.dart';

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

class _AddTaskScreenState extends ConsumerState<AddTaskScreen>
    with WidgetsBindingObserver {
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
  final _advancedSectionKey = GlobalKey();
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

  /// Category-first flow: the form is shown only after the user picks a
  /// category (or skips). Edits and restored drafts go straight to the form.
  bool _categoryChosen = false;

  /// Execution mode id: `flexible` | `disciplined` | `extreme`.
  String _modeRefId = 'flexible';
  bool _strictModeRequired = false;

  /// When false, new-task save may inherit [Routine.modeId] for the target routine.
  bool _modeUserCustomized = false;

  /// Where the inherited (non-customized) mode came from: `profile` | `routine`.
  String _modeInheritSource = 'profile';

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

  String get _draftKey => _isEdit
      ? addTaskEditDraftKey(widget.editArgs!.taskId)
      : addTaskCreateDraftKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Guided-tour hook: typing a title advances "name it" → "now save it".
    _controller.addListener(
      () => ref
          .read(gettingStartedControllerProvider.notifier)
          .onTaskTitleChanged(_controller.text),
    );
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
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Profile-scaled default first, then the parent routine's mode wins
        // over it when the slot's routine has one. User customization wins
        // over both (guarded inside each seed).
        await _seedModeFromProfileDefault();
        if (widget.slotArgs != null) await _seedModeFromRoutineSlot();
        if (mounted) _offerDraftRestoreIfNeeded();
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
        isMeaningful: () => _captureDraft().hasMeaningfulContent,
      );
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
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
      // A draft with real content resumes in the form, not the category step.
      _categoryChosen =
          draft.category != null ||
          draft.title.trim().isNotEmpty ||
          draft.notes.trim().isNotEmpty;
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
    final rd = DateTime(
      _reminderTime.year,
      _reminderTime.month,
      _reminderTime.day,
    );
    return DateKeys.yyyymmdd(rd);
  }

  Future<void> _seedModeFromRoutineSlot() async {
    if (_isEdit || widget.slotArgs == null || _modeUserCustomized || !mounted) {
      return;
    }
    try {
      final planning = ref.read(planningRepositoryProvider);
      final routines = await planning.getRoutinesForDate(
        widget.slotArgs!.dateKey,
      );
      for (final r in routines) {
        if (r.id == widget.slotArgs!.routineId) {
          if (!mounted || _modeUserCustomized) return;
          final id = r.modeId.trim().toLowerCase();
          // Only inherit a known routine mode; otherwise keep the
          // profile-scaled seed from _seedModeFromProfileDefault.
          if (_modeChoiceIds.contains(id)) {
            setState(() {
              _modeRefId = id;
              _modeInheritSource = 'routine';
            });
          }
          return;
        }
      }
    } catch (e) {
      debugPrint('add_task_screen: swallowed error: $e');
    }
  }

  /// Seeds the mode from the profile-level Discipline Mode, scaled by the
  /// target block's urgency when the slot is known ("how strict is the app
  /// overall" — see [DefaultModeResolver]). Never overrides a user choice.
  Future<void> _seedModeFromProfileDefault() async {
    if (_isEdit || _modeUserCustomized || !mounted) return;
    final profileDefault = ref.read(defaultEnforcementModeProvider);
    final urgency = await _blockUrgencyForSlot();
    if (!mounted || _modeUserCustomized) return;
    setState(() {
      _modeRefId = DefaultModeResolver.resolveModeRefId(
        profileDefault: profileDefault,
        blockUrgencyScore: urgency,
      );
      _modeInheritSource = 'profile';
    });
  }

  Future<int?> _blockUrgencyForSlot() async {
    final slot = widget.slotArgs;
    if (slot == null) return null;
    try {
      final planning = ref.read(planningRepositoryProvider);
      final blocks = await planning.getBlocks(slot.routineId);
      for (final b in blocks) {
        if (b.id == slot.blockId) return b.urgencyScore;
      }
    } catch (e) {
      debugPrint('add_task_screen: swallowed error: $e');
    }
    return null;
  }

  Future<String> _effectiveModeRefIdForSave({
    required PlanningRepository planning,
    required String routineId,
    required String planDateKey,
    required String blockId,
  }) async {
    Routine? routine;
    var blockUrgency = 50;
    try {
      final routines = await planning.getRoutinesForDate(planDateKey);
      for (final r in routines) {
        if (r.id == routineId) {
          routine = r;
          break;
        }
      }
      final blocks = await planning.getBlocks(routineId);
      for (final b in blocks) {
        if (b.id == blockId) {
          blockUrgency = b.urgencyScore;
          break;
        }
      }
    } catch (e) {
      debugPrint('add_task_screen: swallowed error: $e');
    }

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
    final fallback = DefaultModeResolver.resolveModeRefId(
      profileDefault: ref.read(defaultEnforcementModeProvider),
      priority: _loadedTask?.priority ?? 3,
      blockUrgencyScore: blockUrgency,
    );
    return EffectiveTaskMode.effectiveModeRefId(
      task: task,
      routine: routine,
      fallbackModeRefId: fallback,
    );
  }

  Future<void> _loadEdit() async {
    final args = widget.editArgs!;
    final planning = ref.read(planningRepositoryProvider);
    try {
      final tasks = await planning.getTasks(
        routineId: args.routineId,
        blockId: args.blockId,
      );
      PlannedTask? task;
      for (final t in tasks) {
        if (t.id == args.taskId) {
          task = t;
          break;
        }
      }
      if (task == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Task not found.')));
          Navigator.pop(context);
        }
        return;
      }

      final reminders = await ref
          .read(reminderRepositoryProvider)
          .getRemindersForTasks([task.id]);

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
        _modeRefId = loaded.modeRefId?.trim().isNotEmpty == true
            ? loaded.modeRefId!
            : 'flexible';
        _strictModeRequired = loaded.strictModeRequired;
        _isHabitAnchor = loaded.isHabitAnchor;
        // Phase A: _isRigid defaults to false; no field on PlannedTask yet.
        _modeUserCustomized = false;
        _advancedExpanded = _isHabitAnchor || _strictModeRequired || _isRigid;
        _categoryChosen = true;
        _loaded = true;
      });
      _suppressDraftDirty = false;
    } catch (e) {
      _suppressDraftDirty = false;
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not load task: $e')));
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
    } catch (e) {
      debugPrint('add_task_screen: swallowed error: $e');
    }

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
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      sequenceIndex: _loadedTask?.sequenceIndex,
      isHabitAnchor: _isHabitAnchor,
      strictModeRequired: _strictModeRequired,
      modeRefId: modeRefId,
    );
  }

  Future<bool> _confirmOverlapIfNeeded(
    PlannedTask task,
    String planDateKey,
  ) async {
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
                style: TextStyle(fontSize: 12, color: AppColors.fg70),
              ),
            if (conflicts.length > 3)
              Text(
                '• +${conflicts.length - 3} more',
                style: TextStyle(fontSize: 12, color: AppColors.fg54),
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

    final result = await service.checkConflicts(
      proposed,
      entityTitles: entityTitles,
    );
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
      onEntityMoved: () => ScheduleMutationCoordinator.instance.run(
        // migrated to coordinator
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
      onOverlapResolvedInline:
          ({
            required movedEntity,
            required suggestionIndex,
            conflictingEntityId,
          }) => _logOverlapResolvedInline(
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
      await ref
          .read(timeBlockSyncServiceProvider)
          .removeBlockForEntity(task.id);
      return;
    }
    final reminderIso = task.reminderTimeIso;
    if (reminderIso == null) {
      await ref
          .read(timeBlockSyncServiceProvider)
          .removeBlockForEntity(task.id);
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
      idempotencyKey:
          'overlap_created_${task.id}_${DateTime.now().millisecondsSinceEpoch}',
      modeRefId: task.modeRefId,
      reason: overridden ? 'override' : 'detected',
    );
  }

  Future<void> _onSave() async {
    if (_saving || (_isEdit && !_loaded)) return;
    setState(() => _saving = true);

    final title = _controller.text.trim().isEmpty
        ? 'Untitled Task'
        : _controller.text.trim();
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
          final existing = await planning.getTasks(
            routineId: routineId,
            blockId: blockId,
          );
          orderIndex = existing.isEmpty
              ? 0
              : existing
                        .map((t) => t.orderIndex)
                        .reduce((a, b) => a > b ? a : b) +
                    1;
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
          final existing = await planning.getTasks(
            routineId: routineId,
            blockId: blockId,
          );
          orderIndex = existing.isEmpty
              ? 0
              : existing
                        .map((t) => t.orderIndex)
                        .reduce((a, b) => a > b ? a : b) +
                    1;
        } else {
          final day = await planning.ensureDefaultDayPlan(planKey);
          routineId = day.routineId;
          blockId = day.blockId;
          final existing = await planning.getTasks(
            routineId: routineId,
            blockId: blockId,
          );
          orderIndex = existing.isEmpty
              ? 0
              : existing
                        .map((t) => t.orderIndex)
                        .reduce((a, b) => a > b ? a : b) +
                    1;
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
        commitOverride:
            () async {}, // write already done above (upsertTask + syncTimeBlock + persistReminder)
      );

      _draftClearedOnSuccessfulSave = true;
      _suppressDraftDirty = true;
      _draftAutosave?.cancel();
      await ref.read(formDraftRepositoryProvider).delete(_draftKey);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save task: $e')));
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
        ...sleepDurationChipLabels.sublist(
          0,
          sleepDurationChipLabels.length - 1,
        ),
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
    if (_isHabitAnchor) parts.add('Habit anchor');
    if (_strictModeRequired) parts.add('Strict');
    if (_isRigid) parts.add('Fixed time');
    if (parts.isEmpty) return 'Habit, strict rules, fixed time';
    return parts.join(' · ');
  }

  String _accountabilitySubtitle(int index) {
    final label = _modeLabels[index].toUpperCase();
    // Until the user picks a mode themselves, the value is inherited from
    // the routine or the profile Discipline Mode — show which one.
    if (!_isEdit && !_modeUserCustomized) {
      return '$label · FROM ${_modeInheritSource.toUpperCase()}';
    }
    return label;
  }

  /// Card matching the reminder section: a single toggle row when off, the
  /// duration chips revealed beneath it when on. Sleep always has a length,
  /// so it gets a static header instead of a switch.
  Widget _buildDurationSection() {
    final sleep = isSleepCategory(_category);
    final showChips = sleep || _durationEnabled;

    return Material(
      color: AddTaskColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sleep)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AddTaskColors.accentDim.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.hourglass_bottom_rounded,
                        size: 18,
                        color: AddTaskColors.accentDim,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sleep length',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AddTaskColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pick a preset or tap Custom',
                            style: TextStyle(
                              fontSize: 12,
                              color: AddTaskColors.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )
            else
              AddTaskToggleRow(
                icon: Icons.timer_outlined,
                iconColor: AddTaskColors.accentDim,
                title: 'Duration',
                subtitle: _durationEnabled
                    ? 'Define your focus sprint'
                    : 'Reminder only — no time block',
                value: _durationEnabled,
                onChanged: (value) => setState(() => _durationEnabled = value),
              ),
            if (showChips) ...[
              const SizedBox(height: 2),
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
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  /// Selects [category] (null = skipped) and advances to the details form.
  void _selectCategory(String? category) {
    setState(() {
      final wasSleep = isSleepCategory(_category);
      _category = category;
      if (category != null && isSleepCategory(category)) {
        _applySleepCategoryDefaults(category);
      } else if (wasSleep && sleepDurationChipKeys.contains(_duration)) {
        _duration = '25 MIN';
      }
      _categoryChosen = true;
    });
  }

  Future<void> _promptCustomCategory() async {
    final name = await showDialog<String?>(
      context: context,
      builder: (_) => const _CustomCategoryDialog(),
    );
    if (name == null || name.trim().isEmpty || !mounted) return;
    _selectCategory(name.trim());
  }

  /// Ink-drawn glyphs for the bento cards — the reference design uses clean
  /// line icons, not emoji.
  static IconData _categoryIcon(String label) => switch (label) {
    'Study' => CupertinoIcons.book_fill,
    'Fitness' => CupertinoIcons.flame_fill,
    'Work' => CupertinoIcons.briefcase_fill,
    'Personal' => CupertinoIcons.heart_fill,
    'Planning' => CupertinoIcons.calendar,
    kSleepTaskCategory => CupertinoIcons.moon_fill,
    _ => CupertinoIcons.tag_fill,
  };

  static String _categorySubtitle(String label) => switch (label) {
    'Study' => 'Learn & review',
    'Fitness' => 'Move your body',
    'Work' => 'Get things done',
    'Personal' => 'Life & self-care',
    'Planning' => 'Organize your day',
    kSleepTaskCategory => 'Rest & recover',
    _ => 'Your own category',
  };

  /// Step 1 of the category-first flow: a fixed bento mosaic of six colored
  /// category cards that fills the viewport (no scrolling), with the Custom
  /// action as a dark pill button and Skip as a floating square beside it.
  Widget _buildCategoryStep() {
    BentoCategoryCard card(String label, Color color, {bool hero = false}) =>
        BentoCategoryCard(
          color: color,
          icon: _categoryIcon(label),
          label: label,
          subtitle: _categorySubtitle(label),
          selected: _category == label,
          hero: hero,
          onTap: () => _selectCategory(label),
        );

    // A custom category (from editing or "Change") lights up the pill.
    final customActive =
        _category != null && !_categoryOptions.contains(_category);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What kind of task?',
            style: TextStyle(
              color: AddTaskColors.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick a category — you can change anything on the next screen.',
            style: TextStyle(color: AddTaskColors.muted, height: 1.3),
          ),
          const SizedBox(height: 16),
          // The mosaic (matches the bento reference): Study hero on top,
          // Work | Planning pair, then tall Fitness with Personal over
          // Sleep splitting the right column.
          Expanded(
            child: Column(
              children: [
                Expanded(
                  flex: 7,
                  child: card('Study', BentoPalette.yellow, hero: true),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 5,
                  child: Row(
                    children: [
                      Expanded(child: card('Work', BentoPalette.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: card('Planning', BentoPalette.green)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  flex: 8,
                  child: Row(
                    children: [
                      Expanded(child: card('Fitness', BentoPalette.purple)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: card('Personal', BentoPalette.blue),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: card(
                                kSleepTaskCategory,
                                BentoPalette.teal,
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
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: BentoPillButton(
                  label: customActive ? _category! : 'Custom',
                  onTap: _promptCustomCategory,
                  color: AddTaskColors.card,
                  textColor: AddTaskColors.onSurface,
                  ringColor: AddTaskColors.accentDim,
                  active: customActive,
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: AddTaskColors.card,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  onTap: () => _selectCategory(null),
                  borderRadius: BorderRadius.circular(18),
                  child: Tooltip(
                    message: 'Skip — no category',
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        size: 22,
                        color: AddTaskColors.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Compact replacement for the old in-form category grid: shows the chosen
  /// category and jumps back to the category step to change it.
  Widget _buildCategoryChipRow() {
    final label = _category ?? 'No category';
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AddTaskColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AddTaskColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  _category == null
                      ? Icons.label_off_outlined
                      : addTaskCategoryIcon(_category!),
                  size: 18,
                  color: AddTaskColors.accentDim,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AddTaskColors.onSurface,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _categoryChosen = false),
                  child: Text(
                    'Change',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AddTaskColors.accent,
                    ),
                  ),
                ),
              ],
            ),
          ),
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
                    color: AppColors.fg.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Accountability',
                style: TextStyle(
                  fontSize: 5,
                  fontWeight: FontWeight.w700,
                  color: AddTaskColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
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

  /// Accountability and Deep Work share one row of half-width cards.
  /// IntrinsicHeight bounds the stretch: inside the ListView height is
  /// unbounded, and stretching into it crashes layout.
  Widget _buildAccountabilityAndDeepWorkRow() {
    final selectedIndex = _selectedModeIndex;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: AddTaskSplitSettingCard(
              icon: Icons.verified_user_outlined,
              title: 'Accountability',
              // Short label only — the picker sheet explains the rest.
              // No HelpDot here: 'Accountability' barely fits the half-width
              // card, and a dot on one card but not its twin looks lopsided.
              subtitle: _modeLabels[selectedIndex].toUpperCase(),
              onTap: _showAccountabilityPicker,
              trailing: Text(
                'CHANGE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AddTaskColors.accentDim,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AddTaskSplitSettingCard(
              icon: Icons.bolt_rounded,
              title: 'Deep Work',
              subtitle: 'BLOCKS ALERTS',
              onTap: () => setState(() => _focusSession = !_focusSession),
              trailing: Switch.adaptive(
                value: _focusSession,
                onChanged: (v) => setState(() => _focusSession = v),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                activeTrackColor: AddTaskColors.accentDim.withValues(
                  alpha: 0.55,
                ),
                activeThumbColor: AddTaskColors.accentContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReminderSection() {
    final timeLabel = TimeOfDay.fromDateTime(_reminderTime).format(context);
    final dateLabel = MaterialLocalizations.of(
      context,
    ).formatMediumDate(_reminderTime);
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
                  final ok = await ref
                      .read(reminderSyncServiceProvider)
                      .ensurePermissions();
                  if (!ok && mounted) {
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
                  child: Builder(
                    builder: (context) {
                      final sleep = isSleepCategory(_category);
                      final datePicker = AddTaskPickerRow(
                        icon: Icons.calendar_today_outlined,
                        label: 'Date',
                        value: dateLabel,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _reminderTime,
                            firstDate: DateTime.now().subtract(
                              const Duration(days: 365),
                            ),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
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
                      );
                      final timePicker = AddTaskPickerRow(
                        icon: Icons.schedule_rounded,
                        label: sleep ? 'Sleep start' : 'Time',
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
                      );

                      return Column(
                        children: [
                          // Sleep pairs its start/end times; everything else
                          // pairs date + time — one row either way.
                          if (sleep) ...[
                            datePicker,
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(child: timePicker),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: AddTaskPickerRow(
                                    icon: Icons.bedtime_rounded,
                                    label: 'Sleep end',
                                    value: formatTaskTimeOfDay(
                                      _reminderTime.add(
                                        Duration(
                                          minutes: _effectiveDurationMinutes,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else
                            Row(
                              children: [
                                Expanded(child: datePicker),
                                const SizedBox(width: 8),
                                Expanded(child: timePicker),
                              ],
                            ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.event_available_outlined,
                                  size: 13,
                                  color: AddTaskColors.faint,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Plan day · $planLabel',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AddTaskColors.faint,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Collapsed power-user toggles. Sleep hides this — its schedule is
  /// already rigid by default and its extras live in their own card.
  Widget _buildAdvancedSection() {
    return AddTaskCollapsibleSection(
      key: _advancedSectionKey,
      title: 'Advanced settings',
      subtitle: _advancedSubtitle,
      expanded: _advancedExpanded,
      onToggle: () {
        setState(() => _advancedExpanded = !_advancedExpanded);
        if (!_advancedExpanded) return;
        // The section sits at the bottom of the list, so the toggles it
        // reveals land below the fold — scroll them into view.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = _advancedSectionKey.currentContext;
          if (ctx == null || !mounted) return;
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.05,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
          );
        });
      },
      children: [
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

  /// Sleep-only card: sync the daily sleep window / quiet mode.
  Widget _buildSleepExtrasSection() {
    if (!isSleepCategory(_category)) return const SizedBox.shrink();

    return Material(
      color: AddTaskColors.card,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
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
              onChanged: (v) =>
                  setState(() => _syncSleepWindowAndQuietMode = v),
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
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomSafe = MediaQuery.paddingOf(context).bottom;

    // A new task starts on the category grid; from the details form, back
    // (app-bar arrow and system gesture both go through maybePop) returns to
    // that grid instead of leaving the screen. Editing has no category step.
    // Saving closes via imperative Navigator.pop, which skips this scope.
    final backReturnsToCategoryStep = !_isEdit && _loaded && _categoryChosen;

    return PopScope(
      canPop: !backReturnsToCategoryStep,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _categoryChosen = false);
      },
      child: Scaffold(
        backgroundColor: AddTaskColors.surface,
        appBar: AppBar(
          backgroundColor: AddTaskColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          foregroundColor: AddTaskColors.accent,
          centerTitle: true,
          title: PageTitle(_isEdit ? 'Edit task' : 'Add task'),
          actions: const [HelpAppBarButton('tasks')],
        ),
        // The category grid and the details form are steps inside one route,
        // so route transitions never fire between them — a soft fade+slide
        // keeps the step change from snapping (forward and back).
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.02),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: !_loaded
              ? Center(
                  key: const ValueKey('add_task_loading'),
                  child: CircularProgressIndicator(color: AddTaskColors.accent),
                )
              : !_categoryChosen
              ? KeyedSubtree(
                  key: const ValueKey('add_task_category_step'),
                  child: _buildCategoryStep(),
                )
              : KeyboardDismissOnTap(
                  key: const ValueKey('add_task_form_step'),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          children: [
                            _buildCategoryChipRow(),
                            const SizedBox(height: 16),
                            const AddTaskHeroSectionLabel(
                              title: 'What do you want to do?',
                              subtitle: 'Give it a clear, actionable name',
                            ),
                            const SizedBox(height: 16),
                            AddTaskField(
                              // Guided-tour target: "give it a name".
                              key: TourTargets.addTaskTitleField,
                              controller: _controller,
                              hint: 'Read 10 pages',
                              // New task: start typing immediately. Editing keeps
                              // the keyboard down, and Sleep arrives pre-filled.
                              autofocus:
                                  !_isEdit && !isSleepCategory(_category),
                            ),
                            const SizedBox(height: 12),
                            AddTaskField(
                              controller: _notesController,
                              hint: 'Notes (optional)',
                              // One line that grows while typing.
                              minLines: 1,
                              maxLines: 3,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AddTaskColors.muted,
                              ),
                            ),
                            const SizedBox(height: 20),
                            // Reminder sits directly under the name so it can be set
                            // without scrolling — the most common add-task intent.
                            _buildReminderSection(),
                            const SizedBox(height: 12),
                            _buildDurationSection(),
                            const SizedBox(height: 20),
                            if (isSleepCategory(_category)) ...[
                              _buildAccountabilityRow(),
                              const SizedBox(height: 12),
                              _buildSleepExtrasSection(),
                            ] else ...[
                              _buildAccountabilityAndDeepWorkRow(),
                              const SizedBox(height: 20),
                              _buildAdvancedSection(),
                            ],
                          ],
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(
                          24,
                          16,
                          24,
                          16 + bottomSafe,
                        ),
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
                          // Guided-tour target: "now save it".
                          key: TourTargets.addTaskSaveButton,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(56),
                            backgroundColor: AddTaskColors.accentContainer,
                            foregroundColor: AppColors.accentDeep,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          onPressed: _saving ? null : _onSave,
                          child: Text(
                            _saving
                                ? 'Saving…'
                                : (_isEdit ? 'Save changes' : 'Add task')
                                      .toUpperCase(),
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
                ),
        ),
      ),
    );
  }
}

/// Owns its [TextEditingController] so it is disposed only after the dialog
/// route finishes (same pattern as the goal milestone dialog).
class _CustomCategoryDialog extends StatefulWidget {
  const _CustomCategoryDialog();

  @override
  State<_CustomCategoryDialog> createState() => _CustomCategoryDialogState();
}

class _CustomCategoryDialogState extends State<_CustomCategoryDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) return;
    Navigator.pop<String?>(context, name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom category'),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'e.g. Music'),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop<String?>(context, null),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _submit, child: const Text('Use')),
      ],
    );
  }
}
