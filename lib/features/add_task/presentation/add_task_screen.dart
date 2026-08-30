import 'dart:async';
import 'dart:io';

import '../../../core/presentation/page_headers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../../core/utils/date_keys.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/application/form_draft_autosave.dart';
import '../../planning/application/form_draft_providers.dart';
import '../../planning/domain/add_task_duration.dart';
import '../../reminders/application/reminder_classifier.dart';
import '../../reminders/domain/models/reminder_occurrence_enums.dart';
import '../../planning/domain/models/add_task_form_draft.dart';
import '../../planning/domain/models/task_item.dart';
import '../../planning/domain/sleep_task.dart';
import '../application/add_task_conflict_flow.dart';
import '../application/add_task_draft_restore.dart';
import '../application/add_task_duration_labels.dart';
import '../application/add_task_edit_loader.dart';
import '../application/add_task_mode_resolution.dart';
import '../application/add_task_reminder_persistence.dart';
import '../application/add_task_save_target.dart';
import '../application/add_task_sleep_side_effects.dart';
import '../application/add_task_tier_gates.dart';
import 'add_task_accountability_picker_sheet.dart';
import 'add_task_args.dart';
import 'custom_duration_dialog.dart';
import '../../education/application/getting_started_controller.dart';
import '../../education/presentation/help_dot.dart';
import '../../education/presentation/tour_targets.dart';
import 'add_task_ui.dart';
import 'sections/add_task_accountability_deep_work_row.dart';
import 'sections/add_task_accountability_row.dart';
import 'sections/add_task_advanced_section.dart';
import 'sections/add_task_category_section.dart';
import 'sections/add_task_classification_section.dart';
import 'sections/add_task_duration_section.dart';
import 'sections/add_task_reminder_section.dart';
import 'sections/add_task_sleep_extras_section.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/keyboard_dismiss.dart';

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

  /// Taxonomy the USER picked, if they picked one (FR-R-21). Null means the
  /// heuristic's answer stands and is what the chip displays.
  ReminderTaxonomy? _userTaxonomy;

  /// Criticality 3 — the one thing that pierces the boundary, the Focus
  /// Shield and the sleep window. Only ever set here, never by the heuristic.
  bool _userCritical = false;
  DateTime _reminderTime = DateTime.now().add(const Duration(minutes: 10));
  bool _saving = false;
  bool _loaded = false;

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
    });
    _suppressDraftDirty = false;
    _draftAutosave?.dirty = false;
  }

  Future<void> _offerDraftRestoreIfNeeded() async {
    if (_draftRestoreOffered || !mounted) return;
    _draftRestoreOffered = true;
    await offerAddTaskDraftRestoreIfNeeded(
      context,
      ref,
      draftKey: _draftKey,
      isEdit: _isEdit,
      captureCurrent: _captureDraft,
      applyDraft: (draft) {
        _applyDraft(draft);
        // Cancel the pending autosave debounce so it can't re-persist the
        // content that was just restored-and-deleted.
        _draftAutosave?.cancel();
      },
    );
  }

  String _planDateKey() => addTaskPlanDateKey(
    reminderEnabled: _reminder,
    reminderTime: _reminderTime,
    // Respect a preset plan day (e.g. from Plan Tomorrow slot) when no reminder is set.
    presetDateKey: widget.slotArgs?.dateKey ?? widget.editArgs?.dateKey,
  );

  /// Inherit the slot routine's mode (create-from-slot only). Never overrides
  /// a user choice: guarded before the fetch and re-guarded before applying.
  Future<void> _seedModeFromRoutineSlot() async {
    if (_isEdit || widget.slotArgs == null || _modeUserCustomized || !mounted) {
      return;
    }
    final seed = await resolveRoutineSlotModeSeed(
      ref,
      slotDateKey: widget.slotArgs!.dateKey,
      slotRoutineId: widget.slotArgs!.routineId,
    );
    if (seed == null || !mounted || _modeUserCustomized) return;
    setState(() {
      _modeRefId = seed.modeRefId;
      _modeInheritSource = seed.inheritSource;
    });
  }

  /// Seeds the mode from the profile-level Discipline Mode, scaled by the
  /// target block's urgency when the slot is known. Never overrides a user
  /// choice.
  Future<void> _seedModeFromProfileDefault() async {
    if (_isEdit || _modeUserCustomized || !mounted) return;
    final seed = await resolveProfileDefaultModeSeed(
      ref,
      slotRoutineId: widget.slotArgs?.routineId,
      slotBlockId: widget.slotArgs?.blockId,
    );
    if (!mounted || _modeUserCustomized) return;
    setState(() {
      _modeRefId = seed.modeRefId;
      _modeInheritSource = seed.inheritSource;
    });
  }

  Future<void> _loadEdit() async {
    final args = widget.editArgs!;
    try {
      final load = await loadAddTaskForEdit(
        ref,
        taskId: args.taskId,
        routineId: args.routineId,
        blockId: args.blockId,
      );
      if (load == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Task not found.')));
          Navigator.pop(context);
        }
        return;
      }

      if (!mounted) return;
      final loaded = load.task;
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
        if (load.reminderId != null) {
          _existingReminderId = load.reminderId;
          _reminderCreatedAtMs = load.reminderCreatedAtMs;
        }
        // Only a USER classification is restored. If the heuristic decided
        // last time, let it decide again from the current title/duration —
        // a stale guess is worse than a fresh one.
        final stored = load.classification;
        if (stored != null) {
          _userTaxonomy = stored.taxonomy;
          _userCritical = stored.criticality >= 3;
        }
        _modeRefId = loaded.modeRefId?.trim().isNotEmpty == true
            ? loaded.modeRefId!
            : 'flexible';
        _strictModeRequired = loaded.strictModeRequired;
        _isHabitAnchor = loaded.isHabitAnchor;
        // Phase A: _isRigid defaults to false; no field on PlannedTask yet.
        _modeUserCustomized = false;
        _advancedExpanded = _isHabitAnchor || _strictModeRequired || _isRigid;
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

  /// Applies a schedule adjustment coming back from the conflict flow (live
  /// mid-sheet or via the resolution outcome) and scrolls the reminder card
  /// into view. Field writes stay inside setState so draft-dirtiness fires.
  void _applyAdjustedSchedule(DateTime? start, int? durationMinutes) {
    if (start != null) {
      setState(() {
        _reminder = true;
        _reminderTime = start;
      });
    }
    if (durationMinutes != null) {
      setState(() {
        _duration = durationLabelFromMinutes(
          durationMinutes,
          category: _category,
        );
      });
    }
    _scrollToScheduleSection();
  }

  Future<void> _onSave() async {
    if (_saving || (_isEdit && !_loaded)) return;
    // Belt to the button's braces: nothing saves without a name.
    final title = _controller.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    final planning = ref.read(planningRepositoryProvider);
    final planKey = _planDateKey();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Free-tier creation gates (no-ops while enforcement is off / on Pro).
    final gatesPass = await checkAddTaskTierGates(
      context,
      ref,
      isEdit: _isEdit,
      planDateKey: planKey,
      addingHabitAnchor:
          _isHabitAnchor &&
          (!_isEdit || !(_loadedTask?.isHabitAnchor ?? false)),
      onBlocked: () => setState(() => _saving = false),
    );
    if (!gatesPass) return;

    try {
      final target = await resolveAddTaskSaveTarget(
        ref,
        planDateKey: planKey,
        nowMs: nowMs,
        loadedTask: _isEdit ? _loadedTask : null,
        editRoutineId: widget.editArgs?.routineId,
        editBlockId: widget.editArgs?.blockId,
        editDateKey: widget.editArgs?.dateKey,
        slotRoutineId: widget.slotArgs?.routineId,
        slotBlockId: widget.slotArgs?.blockId,
      );
      final routineId = target.routineId;
      final blockId = target.blockId;
      final orderIndex = target.orderIndex;
      final taskId = target.taskId;
      final createdAtMs = target.createdAtMs;

      final modeRefId = await resolveEffectiveModeRefIdForSave(
        ref,
        routineId: routineId,
        blockId: blockId,
        planDateKey: planKey,
        explicitModeRefId: (!_isEdit && !_modeUserCustomized)
            ? null
            : _modeRefId,
        fallbackPriority: _loadedTask?.priority ?? 3,
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
      if (!mounted) return;
      final proceed = await confirmAddTaskHabitOverlap(
        context,
        ref,
        task: task,
        planDateKey: planKey,
        isEdit: _isEdit,
      );
      if (!proceed || !mounted) return;

      // Phase A — time block conflict check.
      final tbProceed = await checkAddTaskTimeBlockConflicts(
        context,
        ref,
        task: task,
        isRigid: _isRigid,
        isEdit: _isEdit,
        onAdjustSchedule: _applyAdjustedSchedule,
      );
      if (!tbProceed) return;

      await planning.upsertTask(task);

      // Phase A — sync time block after successful save.
      await syncAddTaskTimeBlock(ref, task: task, isRigid: _isRigid);

      // The task is saved; these must run even if the sheet was dismissed
      // mid-save. Both callees guard every context use with context.mounted.
      await applyAddTaskSleepSideEffects(
        // ignore: use_build_context_synchronously
        context,
        ref,
        task: task,
        syncSleepWindowAndQuietMode: _syncSleepWindowAndQuietMode,
        inAppQuietMode: _inAppQuietMode,
      );

      final reminderId = await persistAddTaskReminder(
        // ignore: use_build_context_synchronously
        context,
        ref,
        taskId: taskId,
        taskTitle: title,
        routineId: routineId,
        blockId: blockId,
        modeRefId: modeRefId,
        reminderEnabled: _reminder,
        reminderTime: _reminderTime,
        existingReminderId: _existingReminderId,
        reminderCreatedAtMs: _reminderCreatedAtMs,
        durationMinutes: _resolvedDurationMinutes,
        category: _category,
        isHabitAnchor: _isHabitAnchor,
        userTaxonomy: _userTaxonomy,
        userCriticality: _userTaxonomy == null
            ? null
            : (_userCritical ? 3 : _heuristicClassification.criticality),
      );
      if (reminderId != null) _existingReminderId ??= reminderId;
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

  int get _resolvedDurationMinutes => resolvedAddTaskDurationMinutes(
    category: _category,
    durationEnabled: _durationEnabled,
    duration: _duration,
    customMinutes: _customDurationMinutes,
  );

  int get _effectiveDurationMinutes => _resolvedDurationMinutes;

  /// What the classification chip shows: the user's choice when they have
  /// made one, otherwise the heuristic's live answer for the current title,
  /// duration, category and habit toggle. Recomputed as they type, so the
  /// chip is never stale and never a required decision.
  ReminderClassification get _heuristicClassification =>
      ReminderClassifier.classify(
        title: _controller.text.trim(),
        hasReminderTime: _reminder,
        durationMinutes: _resolvedDurationMinutes,
        category: _category,
        isHabitAnchor: _isHabitAnchor,
      );

  ReminderTaxonomy get _effectiveTaxonomy =>
      _userTaxonomy ?? _heuristicClassification.taxonomy;

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

  int get _selectedModeIndex {
    final i = kAddTaskModeChoiceIds.indexOf(_modeRefId);
    return i >= 0 ? i : 0;
  }

  /// Expand/collapse Advanced; on expand, scroll the revealed toggles into
  /// view (the section sits at the bottom of the list, below the fold).
  void _toggleAdvancedExpanded() {
    setState(() => _advancedExpanded = !_advancedExpanded);
    if (!_advancedExpanded) return;
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
  }

  String _accountabilitySubtitle(int index) {
    final label = kAddTaskModeLabels[index].toUpperCase();
    // Until the user picks a mode themselves, the value is inherited from
    // the routine or the profile Discipline Mode — show which one.
    if (!_isEdit && !_modeUserCustomized) {
      return '$label · FROM ${_modeInheritSource.toUpperCase()}';
    }
    return label;
  }

  /// Sets the category inline ([category] null clears it — no category is a
  /// valid choice). Selecting Sleep applies its defaults; leaving Sleep reverts
  /// the sleep-only duration back to the standard default.
  void _selectCategory(String? category) {
    setState(() {
      final wasSleep = isSleepCategory(_category);
      _category = category;
      if (category != null && isSleepCategory(category)) {
        _applySleepCategoryDefaults(category);
      } else if (wasSleep && sleepDurationChipKeys.contains(_duration)) {
        _duration = '25 MIN';
      }
    });
  }

  Future<void> _showAccountabilityPicker() async {
    final picked = await showAccountabilityPickerSheet(
      context,
      selectedModeId: _modeRefId,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _modeUserCustomized = true;
      _modeRefId = picked;
    });
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
        // Presented as a bottom sheet: close is an X (slide-down), not a
        // page-back arrow.
        leading: const CloseButton(),
        title: PageTitle(_isEdit ? 'Edit task' : 'Add task'),
        actions: const [HelpAppBarButton('tasks')],
      ),
      // A soft fade+slide swaps the loading spinner for the form so the
      // first paint doesn't snap in.
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
                            autofocus: !_isEdit && !isSleepCategory(_category),
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
                          // Category picker sits right under Notes: pick after
                          // jotting the task down. Optional — none is fine.
                          const AddTaskSectionLabel(title: 'Category'),
                          const SizedBox(height: 12),
                          AddTaskCategorySection(
                            category: _category,
                            onCategorySelected: _selectCategory,
                          ),
                          const SizedBox(height: 20),
                          // Reminder sits directly under the name so it can be set
                          // without scrolling — the most common add-task intent.
                          AddTaskReminderSection(
                            sectionKey: _scheduleSectionKey,
                            reminderEnabled: _reminder,
                            reminderTime: _reminderTime,
                            category: _category,
                            effectiveDurationMinutes: _effectiveDurationMinutes,
                            planDateKey: _planDateKey(),
                            onReminderToggled: (value) {
                              setState(() => _reminder = value);
                              if (!value) return;
                              ensureReminderPermissionWithNotice(context, ref);
                            },
                            onReminderTimeChanged: (time) =>
                                setState(() => _reminderTime = time),
                          ),
                          // Classification only matters when a reminder
                          // exists — it selects the ladder's shape, not
                          // whether one is armed (FR-R-23).
                          if (_reminder) ...[
                            const SizedBox(height: 12),
                            AddTaskClassificationSection(
                              taxonomy: _effectiveTaxonomy,
                              isCritical: _userCritical,
                              onTaxonomyChanged: (t) => setState(() {
                                _userTaxonomy = t;
                                // Critical is meaningless off the expiring
                                // class; drop it rather than keep it hidden
                                // and armed.
                                if (t != ReminderTaxonomy.timeSensitive) {
                                  _userCritical = false;
                                }
                              }),
                              onCriticalChanged: (v) => setState(() {
                                _userCritical = v;
                                // Ticking Critical IS choosing the class.
                                _userTaxonomy ??= _effectiveTaxonomy;
                              }),
                            ),
                          ],
                          const SizedBox(height: 12),
                          AddTaskDurationSection(
                            category: _category,
                            duration: _duration,
                            customDurationMinutes: _customDurationMinutes,
                            durationEnabled: _durationEnabled,
                            onDurationEnabledChanged: (value) =>
                                setState(() => _durationEnabled = value),
                            onPresetSelected: (key) => setState(() {
                              _durationEnabled = true;
                              _duration = key;
                            }),
                            onCustomTap: _editCustomDuration,
                          ),
                          const SizedBox(height: 20),
                          if (isSleepCategory(_category)) ...[
                            AddTaskAccountabilityRow(
                              subtitle: _accountabilitySubtitle(
                                _selectedModeIndex,
                              ),
                              onChangeTap: _showAccountabilityPicker,
                            ),
                            const SizedBox(height: 12),
                            AddTaskSleepExtrasSection(
                              category: _category,
                              syncSleepWindowAndQuietMode:
                                  _syncSleepWindowAndQuietMode,
                              inAppQuietMode: _inAppQuietMode,
                              onSyncChanged: (v) => setState(
                                () => _syncSleepWindowAndQuietMode = v,
                              ),
                              onQuietModeChanged: (mode) =>
                                  setState(() => _inAppQuietMode = mode),
                            ),
                          ] else ...[
                            AddTaskAccountabilityDeepWorkRow(
                              accountabilityLabel:
                                  kAddTaskModeLabels[_selectedModeIndex]
                                      .toUpperCase(),
                              focusSession: _focusSession,
                              onAccountabilityTap: _showAccountabilityPicker,
                              onFocusSessionChanged: (v) =>
                                  setState(() => _focusSession = v),
                            ),
                            const SizedBox(height: 20),
                            AddTaskAdvancedSection(
                              sectionKey: _advancedSectionKey,
                              expanded: _advancedExpanded,
                              isHabitAnchor: _isHabitAnchor,
                              strictModeRequired: _strictModeRequired,
                              isRigid: _isRigid,
                              onToggleExpanded: _toggleAdvancedExpanded,
                              onHabitAnchorChanged: (v) =>
                                  setState(() => _isHabitAnchor = v),
                              onStrictChanged: (v) =>
                                  setState(() => _strictModeRequired = v),
                              onRigidChanged: (v) =>
                                  setState(() => _isRigid = v),
                            ),
                          ],
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
                      // A task must have a name (2026-08-25) — blank titles
                      // used to save silently as "Untitled Task". The button
                      // disables and says why, live with every keystroke.
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: _controller,
                        builder: (context, titleValue, _) {
                          final titleBlank = titleValue.text.trim().isEmpty;
                          return FilledButton(
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
                            onPressed: _saving || titleBlank ? null : _onSave,
                            child: Text(
                              (_saving
                                      ? 'Saving…'
                                      : titleBlank
                                      ? 'Name the task first'
                                      : (_isEdit ? 'Save changes' : 'Add task'))
                                  .toUpperCase(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
