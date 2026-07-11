import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/keyboard_dismiss.dart';
import '../../../core/runtime/mutation_request.dart';
import '../../../core/runtime/schedule_mutation_coordinator.dart';
import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../planning/application/form_draft_autosave.dart';
import '../../planning/application/form_draft_providers.dart';
import '../../../core/utils/stable_id.dart';
import '../../time_blocks/application/conflict_entity_title_resolver.dart';
import '../../time_blocks/application/scheduling_conflict_analytics.dart';
import '../../time_blocks/application/time_block_providers.dart';
import '../../time_blocks/domain/models/time_conflict.dart';
import '../../time_blocks/domain/models/conflict_resolution_outcome.dart';
import '../../time_blocks/presentation/scheduling_conflict_sheet.dart';
import '../application/goal_period_helpers.dart';
import '../application/goals_providers.dart';
import '../domain/models/goal_action.dart';
import '../domain/models/goal_categories.dart';
import '../domain/models/goal_enums.dart';
import '../domain/models/goal_editor_form_draft.dart';
import '../domain/models/goal_template.dart';
import '../domain/models/user_goal.dart';
import 'widgets/goal_editor_widgets.dart';
import '../../../core/presentation/app_colors.dart';

class GoalEditorArgs {
  const GoalEditorArgs({this.goalId, this.template});

  final String? goalId;
  final GoalTemplate? template;
}

class GoalEditorScreen extends ConsumerStatefulWidget {
  const GoalEditorScreen({super.key, this.goalId, this.template});

  final String? goalId;
  final GoalTemplate? template;

  static const routeName = '/goals/edit';

  @override
  ConsumerState<GoalEditorScreen> createState() => _GoalEditorScreenState();
}

class _GoalEditorScreenState extends ConsumerState<GoalEditorScreen>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _target = TextEditingController();
  final _customLabel = TextEditingController();
  final _durationDays = TextEditingController(text: '30');
  final _actionDrafts = <_ActionDraft>[_ActionDraft()];
  final _reminderSectionKey = GlobalKey();

  /// A template's suggested title, shown as a placeholder (not prefilled text)
  /// so it never looks like a label the user must work around. Used as the
  /// title when the user saves without typing their own.
  String? _suggestedTitle;

  /// Template target value, shown as a placeholder like [_suggestedTitle];
  /// applied on save when the field is left blank.
  String? _suggestedTarget;

  /// Template setup steps rendered as a greyed example card — never saved
  /// unless the user taps "Use these steps".
  final List<String> _exampleSteps = [];
  bool _exampleStepsDismissed = false;

  String _categoryId = GoalCategories.study;
  GoalPeriodMode _periodMode = GoalPeriodMode.calendar;

  /// The single scheduling control. Off = one-time goal (target accumulates
  /// start→end); Daily/Weekly/Monthly repeat also defines the target window.
  GoalRepeatCadence _repeatCadence = GoalRepeatCadence.off;

  /// "Every X" for the repeat cadence, set by the wheel picker.
  int _repeatInterval = 1;

  /// Weekdays (1=Mon…7=Sun) acted on when repeat is weekly.
  final Set<int> _scheduledWeekdays = <int>{};

  /// Days of month (1–31) acted on when repeat is monthly.
  final Set<int> _repeatDaysOfMonth = <int>{};
  MeasurementKind _measurement = MeasurementKind.minutes;
  double _intensity = 3;
  DateTime _rangeStart = DateTime.now();
  DateTime _rangeEnd = DateTime.now().add(const Duration(days: 6));
  DateTime _durationStart = DateTime.now();
  bool _reminderEnabled = false;
  int _reminderMinutesFromMidnight = 9 * 60;
  bool _seeded = false;
  bool _saving = false;
  bool _advancedExpanded = false;

  FormDraftAutosave? _draftAutosave;
  bool _draftInitialized = false;
  bool _draftRestoreOffered = false;
  bool _draftRestoreScheduled = false;
  bool _suppressDraftDirty = false;
  bool _draftClearedOnSuccessfulSave = false;

  String get _draftKey => widget.goalId == null
      ? goalCreateDraftKey()
      : goalEditDraftKey(widget.goalId!);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.goalId == null &&
        widget.template != null &&
        !widget.template!.isBlank) {
      _applyTemplate(widget.template!);
    }
    if (widget.goalId == null) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _offerDraftRestoreIfNeeded(),
      );
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
    _title.dispose();
    _target.dispose();
    _customLabel.dispose();
    _durationDays.dispose();
    for (final d in _actionDrafts) {
      d.controller.dispose();
    }
    super.dispose();
  }

  GoalEditorFormDraft _captureDraft() {
    return GoalEditorFormDraft(
      savedAtMs: DateTime.now().millisecondsSinceEpoch,
      title: _title.text,
      target: _target.text,
      customLabel: _customLabel.text,
      durationDays: _durationDays.text,
      categoryId: _categoryId,
      periodMode: _periodMode.name,
      measurement: _measurement.name,
      intensity: _intensity,
      rangeStartMs: _rangeStart.millisecondsSinceEpoch,
      rangeEndMs: _rangeEnd.millisecondsSinceEpoch,
      durationStartMs: _durationStart.millisecondsSinceEpoch,
      repeatCadence: _repeatCadence.name,
      repeatInterval: '$_repeatInterval',
      scheduledWeekdays: _scheduledWeekdays.toList()..sort(),
      repeatDaysOfMonth: _repeatDaysOfMonth.toList()..sort(),
      reminderEnabled: _reminderEnabled,
      reminderMinutesFromMidnight: _reminderMinutesFromMidnight,
      actions: _actionDrafts
          .map(
            (d) => GoalEditorActionDraftRow(
              id: d.id,
              title: d.controller.text,
              completed: d.completed,
              repeatWeekdays: d.repeatWeekdays.toList()..sort(),
            ),
          )
          .toList(),
    );
  }

  Map<String, dynamic> _captureDraftJson() => _captureDraft().toJson();

  void _applyDraft(GoalEditorFormDraft draft) {
    _suppressDraftDirty = true;
    for (final d in _actionDrafts) {
      d.controller.dispose();
    }
    _actionDrafts.clear();
    if (draft.actions.isEmpty) {
      _actionDrafts.add(_ActionDraft());
    } else {
      for (final row in draft.actions) {
        _actionDrafts.add(
          _ActionDraft(
            id: row.id,
            controller: TextEditingController(text: row.title),
            completed: row.completed,
            repeatWeekdays: row.repeatWeekdays.toSet(),
          ),
        );
      }
    }
    setState(() {
      // A restored draft is the user's own work-in-progress — don't show the
      // template example card on top of their real steps.
      _exampleStepsDismissed = _actionDrafts.any(
        (d) => d.controller.text.trim().isNotEmpty,
      );
      _title.text = draft.title;
      _target.text = draft.target;
      _customLabel.text = draft.customLabel;
      _durationDays.text = draft.durationDays;
      _categoryId = draft.categoryId;
      _periodMode = GoalPeriodModeStorage.fromStorage(draft.periodMode);
      _measurement = MeasurementKind.values.firstWhere(
        (e) => e.name == draft.measurement,
        orElse: () => MeasurementKind.minutes,
      );
      _intensity = draft.intensity;
      _rangeStart = DateTime.fromMillisecondsSinceEpoch(draft.rangeStartMs);
      _rangeEnd = DateTime.fromMillisecondsSinceEpoch(draft.rangeEndMs);
      _durationStart = DateTime.fromMillisecondsSinceEpoch(
        draft.durationStartMs,
      );
      _repeatCadence = GoalRepeatCadenceStorage.fromStorage(
        draft.repeatCadence,
      );
      _repeatInterval = int.tryParse(draft.repeatInterval) ?? 1;
      _scheduledWeekdays
        ..clear()
        ..addAll(draft.scheduledWeekdays);
      _repeatDaysOfMonth
        ..clear()
        ..addAll(draft.repeatDaysOfMonth);
      _reminderEnabled = draft.reminderEnabled;
      _reminderMinutesFromMidnight = draft.reminderMinutesFromMidnight;
    });
    _suppressDraftDirty = false;
    _draftAutosave?.dirty = false;
  }

  void _applyTemplate(GoalTemplate template) {
    _suppressDraftDirty = true;
    for (final d in _actionDrafts) {
      d.controller.dispose();
    }
    _actionDrafts.clear();
    // Template steps are shown as a greyed example card, not prefilled rows —
    // the user starts from one empty row and the example fades away once they
    // write their own (or is copied in via "Use these steps").
    _actionDrafts.add(_ActionDraft());
    _exampleSteps
      ..clear()
      ..addAll(template.setupSteps);
    _exampleStepsDismissed = false;
    setState(() {
      if (template.suggestedTitle.isNotEmpty) {
        // Show as a placeholder rather than prefilled text; applied on save if
        // the user leaves the field blank.
        _suggestedTitle = template.suggestedTitle;
      }
      if (template.categoryId != null) _categoryId = template.categoryId!;
      if (template.repeatCadence != null) {
        _repeatCadence = template.repeatCadence!;
      }
      if (template.periodMode != null) _periodMode = template.periodMode!;
      if (template.measurement != null) _measurement = template.measurement!;
      if (template.targetValue != null) {
        final t = template.targetValue!;
        // Placeholder, not prefilled — applied on save when left blank.
        _suggestedTarget = t == t.roundToDouble() ? '${t.toInt()}' : '$t';
      }
      if (template.intensity != null) {
        _intensity = template.intensity!.toDouble();
      }
      if (template.reminderEnabled != null) {
        _reminderEnabled = template.reminderEnabled!;
        // Reminders need a repeat schedule; templates predate the split and
        // meant "remind me every day".
        if (template.reminderEnabled! &&
            _repeatCadence == GoalRepeatCadence.off) {
          _repeatCadence = GoalRepeatCadence.daily;
        }
      }
      if (template.reminderMinutesFromMidnight != null) {
        _reminderMinutesFromMidnight = template.reminderMinutesFromMidnight!;
      }
      if (template.customLabel != null) {
        _customLabel.text = template.customLabel!;
      }
    });
    _suppressDraftDirty = false;
  }

  /// Copies the example steps into real editable rows (explicit opt-in from
  /// the example card) and collapses the card.
  void _useExampleSteps() {
    setState(() {
      // Drop untouched empty rows so the copied steps don't leave a stray
      // blank row above them; keep anything the user already typed.
      _actionDrafts.removeWhere((d) {
        if (d.controller.text.trim().isNotEmpty) return false;
        d.controller.dispose();
        return true;
      });
      for (final step in _exampleSteps) {
        _actionDrafts.add(
          _ActionDraft(controller: TextEditingController(text: step)),
        );
      }
      _exampleStepsDismissed = true;
    });
  }

  Future<void> _offerDraftRestoreIfNeeded() async {
    if (_draftRestoreOffered || !mounted) return;
    _draftRestoreOffered = true;

    final repo = ref.read(formDraftRepositoryProvider);
    final raw = await repo.load(_draftKey);
    if (!mounted || raw == null) return;

    final draft = GoalEditorFormDraft.fromJson(raw);
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
        sourceSurface: widget.goalId == null ? 'goal_create' : 'goal_edit',
        idempotencyKey: 'form_draft_restored_$_draftKey',
      );
    } else {
      await repo.delete(_draftKey);
      fireAndForgetAnalyticsEvent(
        ref,
        type: AnalyticsEventType.formDraftDiscarded,
        entityId: _draftKey,
        entityKind: 'form_draft',
        sourceSurface: widget.goalId == null ? 'goal_create' : 'goal_edit',
        idempotencyKey: 'form_draft_discarded_$_draftKey',
      );
    }
  }

  void _logGoalOverlapResolvedInline({
    required String goalId,
    required String movedEntity,
    required Object suggestionIndex,
    String? conflictingEntityId,
  }) {
    fireAndForgetAnalyticsEvent(
      ref,
      type: AnalyticsEventType.overlapResolvedInline,
      entityId: goalId,
      entityKind: 'goal',
      sourceSurface: widget.goalId == null ? 'goal_create' : 'goal_edit',
      idempotencyKey:
          'overlap_resolved_inline_${goalId}_${DateTime.now().millisecondsSinceEpoch}',
      reason: inlineConflictResolutionReason(
        movedEntity: movedEntity,
        suggestionIndex: suggestionIndex,
        conflictingEntityId: conflictingEntityId,
      ),
    );
  }

  /// Start and end picked together on one calendar, like booking a flight.
  Future<void> _pickRange() async {
    final start = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
    final end = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day);
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: start,
        end: end.isBefore(start) ? start : end,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Goal duration',
      saveText: 'Set duration',
    );
    if (picked != null) {
      setState(() {
        _rangeStart = picked.start;
        _rangeEnd = picked.end;
      });
    }
  }

  static const _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  String _formatRangeDay(DateTime d) =>
      '${_shortMonths[d.month - 1]} ${d.day}, ${d.year}';

  String _formatReminderTime(BuildContext context) {
    final t = TimeOfDay(
      hour: _reminderMinutesFromMidnight ~/ 60,
      minute: _reminderMinutesFromMidnight % 60,
    );
    return t.format(context);
  }

  Future<void> _pickReminderTime() async {
    final initial = TimeOfDay(
      hour: _reminderMinutesFromMidnight ~/ 60,
      minute: _reminderMinutesFromMidnight % 60,
    );
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(
        () => _reminderMinutesFromMidnight = picked.hour * 60 + picked.minute,
      );
    }
  }

  Future<void> _pickDurationStart() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _durationStart,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _durationStart = picked);
  }

  ({int startMs, int endMs}) _periodBounds({required int? durationDayCount}) {
    if (_periodMode == GoalPeriodMode.durationDays) {
      final n =
          durationDayCount ?? int.tryParse(_durationDays.text.trim()) ?? 1;
      return GoalPeriodHelpers.localDurationDayCount(_durationStart, n);
    }
    return GoalPeriodHelpers.localDayRangeBounds(_rangeStart, _rangeEnd);
  }

  // ─── Time block helpers ──────────────────────────────────────────────────

  /// Runs a conflict check against the proposed goal time block.
  ///
  /// Returns true if the save can proceed; false if the user cancelled.
  Future<bool> _checkGoalTimeBlockConflicts(UserGoal goal) async {
    final blockSvc = ref.read(goalBlockSyncServiceProvider);
    final today = DateTime.now();
    final proposed = blockSvc.deriveBlockForGoal(goal, today);
    if (proposed == null) return true;

    final repo = ref.read(timeBlockRepositoryProvider);
    final overlapping = await repo.listOverlappingBlocks(proposed);
    final entityTitles = await buildSchedulingConflictEntityTitles(
      ref,
      overlapping: overlapping,
    );

    final tbSvc = ref.read(timeBlockSyncServiceProvider);
    final checkResult = await tbSvc.checkConflicts(
      proposed,
      entityTitles: entityTitles,
    );

    if (!checkResult.hasConflicts) return true;
    if (!mounted) return false;

    if (checkResult.worstSeverity == ConflictSeverity.minor) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Minor time overlap with '
            '${checkResult.conflicts.first.conflictingEntityTitle}. '
            'Saved anyway.',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return true;
    }

    final planDay = DateTime(today.year, today.month, today.day);
    final outcome = await SchedulingConflictSheet.show(
      context: context,
      proposedTitle: goal.title,
      proposedKind: 'goal',
      proposedBlock: proposed,
      conflicts: checkResult.conflicts,
      resolutionPort: ref.read(conflictResolutionServiceProvider),
      loadEntityTitles: () =>
          buildSchedulingConflictEntityTitles(ref, overlapping: overlapping),
      planDay: planDay,
      ignoreEntityIds: {goal.id},
      onEntityMoved: () {
        invalidateGoals(ref, goalId: goal.id);
        // migrated to coordinator
        ScheduleMutationCoordinator.instance.run(
          GoalChangedMutation(
            entityId: goal.id,
            sourceContext: 'goal_editor_screen.conflict_resolution',
            changeKind: 'updated',
          ),
          commitOverride: () async {},
        );
      },
      onAdjustProposedSchedule: (start, _) {
        setState(() {
          _reminderEnabled = true;
          _reminderMinutesFromMidnight = start.hour * 60 + start.minute;
        });
        _scrollToReminderSection();
      },
      onOverlapResolvedInline:
          ({
            required movedEntity,
            required suggestionIndex,
            conflictingEntityId,
          }) => _logGoalOverlapResolvedInline(
            goalId: goal.id,
            movedEntity: movedEntity,
            suggestionIndex: suggestionIndex,
            conflictingEntityId: conflictingEntityId,
          ),
    );

    return _handleGoalConflictOutcome(outcome);
  }

  void _scrollToReminderSection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _reminderSectionKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  bool _handleGoalConflictOutcome(ConflictResolutionOutcome? outcome) {
    if (outcome == null) return false;
    switch (outcome.kind) {
      case ConflictResolutionKind.proceedToSave:
        return true;
      case ConflictResolutionKind.stayOnForm:
        return false;
      case ConflictResolutionKind.proposedScheduleAdjusted:
        if (outcome.adjustedStart != null) {
          final start = outcome.adjustedStart!;
          setState(() {
            _reminderEnabled = true;
            _reminderMinutesFromMidnight = start.hour * 60 + start.minute;
          });
        }
        _scrollToReminderSection();
        return false;
    }
  }

  Future<void> _syncGoalBlock(UserGoal goal) async {
    final today = DateTime.now();
    await ref.read(goalBlockSyncServiceProvider).syncBlockForGoal(goal, today);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    int? durationDayCount;
    if (_periodMode == GoalPeriodMode.durationDays) {
      durationDayCount = int.tryParse(_durationDays.text.trim());
      if (durationDayCount == null ||
          durationDayCount < 1 ||
          durationDayCount > 3650) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter number of days (1–3650)')),
        );
        return;
      }
    } else {
      final rs = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
      final re = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day);
      if (re.isBefore(rs)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('End date must be on or after start date'),
          ),
        );
        return;
      }
    }
    final targetText = _target.text.trim().isNotEmpty
        ? _target.text.trim()
        : (_suggestedTarget ?? '');
    final target = double.tryParse(targetText);
    if (target == null || target < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid target number')),
      );
      return;
    }
    if (_repeatCadence == GoalRepeatCadence.weekly &&
        _scheduledWeekdays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one weekday to repeat on')),
      );
      return;
    }
    if (_repeatCadence == GoalRepeatCadence.monthly &&
        _repeatDaysOfMonth.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pick at least one day of the month to repeat on'),
        ),
      );
      return;
    }
    final repeatInterval = _repeatCadence == GoalRepeatCadence.off
        ? 1
        : _repeatInterval.clamp(1, 999);
    setState(() => _saving = true);
    final repo = ref.read(goalsRepositoryProvider);
    final now = DateTime.now().millisecondsSinceEpoch;
    final bounds = _periodBounds(durationDayCount: durationDayCount);
    final goalId = widget.goalId ?? StableId.generate('goal');

    try {
      final existing = widget.goalId != null
          ? await repo.getGoal(goalId)
          : null;
      final typedTitle = _title.text.trim();
      final goal = UserGoal(
        id: goalId,
        title: typedTitle.isNotEmpty
            ? typedTitle
            : (_suggestedTitle?.trim() ?? ''),
        categoryId: _categoryId,
        status: existing?.status ?? GoalStatus.active,
        measurementKind: _measurement,
        targetValue: target,
        customLabel: _measurement == MeasurementKind.custom
            ? _customLabel.text.trim().isEmpty
                  ? null
                  : _customLabel.text.trim()
            : null,
        intensity: _intensity.round().clamp(1, 5),
        periodStartMs: bounds.startMs,
        periodEndMs: bounds.endMs,
        periodMode: _periodMode,
        durationDays: _periodMode == GoalPeriodMode.durationDays
            ? durationDayCount
            : null,
        repeatCadence: _repeatCadence,
        repeatInterval: repeatInterval,
        scheduledWeekdays: _repeatCadence == GoalRepeatCadence.weekly
            ? (_scheduledWeekdays.toList()..sort())
            : null,
        repeatDaysOfMonth: _repeatCadence == GoalRepeatCadence.monthly
            ? (_repeatDaysOfMonth.toList()..sort())
            : null,
        // Reminders are gated on the repeat schedule.
        reminderEnabled:
            _reminderEnabled && _repeatCadence != GoalRepeatCadence.off,
        reminderMinutesFromMidnight:
            _reminderEnabled && _repeatCadence != GoalRepeatCadence.off
            ? _reminderMinutesFromMidnight
            : null,
        reminderStyle: existing?.reminderStyle ?? GoalReminderStyle.dailyOnce,
        createdAtMs: existing?.createdAtMs ?? now,
        updatedAtMs: now,
        colorHex: existing?.colorHex,
      );

      // Time block conflict check — must happen before persisting so the user
      // can cancel without any state being committed.
      final canProceed = await _checkGoalTimeBlockConflicts(goal);
      if (!canProceed) {
        if (mounted) setState(() => _saving = false);
        return;
      }

      await repo.upsertGoal(goal);

      // Existing rows keep their per-day completion history on re-save.
      final oldActions = widget.goalId != null
          ? await repo.getActions(goalId)
          : const <GoalAction>[];
      final oldActionsById = {for (final a in oldActions) a.id: a};

      final keptActionIds = <String>{};
      var actionIndex = 0;
      for (final draft in _actionDrafts) {
        final title = draft.controller.text.trim();
        if (title.isEmpty) continue;
        final actionId = draft.id ?? StableId.generate('gaction');
        keptActionIds.add(actionId);
        await repo.upsertAction(
          GoalAction(
            id: actionId,
            goalId: goalId,
            title: title,
            orderIndex: actionIndex++,
            completed: draft.completed,
            repeatWeekdays: draft.repeatWeekdays.isEmpty
                ? null
                : (draft.repeatWeekdays.toList()..sort()),
            completedDateKeys:
                oldActionsById[actionId]?.completedDateKeys ?? const [],
          ),
        );
      }
      for (final a in oldActions) {
        if (!keptActionIds.contains(a.id)) {
          await repo.deleteAction(goalId: goalId, actionId: a.id);
        }
      }

      if (!mounted) return;
      invalidateGoals(ref, goalId: goalId);
      await ref.read(goalReminderSyncServiceProvider).applyForGoal(goal);

      // Sync goal time block after all data is committed.
      if (mounted) await _syncGoalBlock(goal);
      if (!mounted) return;

      _draftClearedOnSuccessfulSave = true;
      _suppressDraftDirty = true;
      _draftAutosave?.cancel();
      await ref.read(formDraftRepositoryProvider).delete(_draftKey);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) {
        if (_draftClearedOnSuccessfulSave) _suppressDraftDirty = true;
        setState(() => _saving = false);
      }
    }
  }

  void _seedFromBundle(GoalDetailBundle bundle) {
    if (_seeded) return;
    _seeded = true;
    _suppressDraftDirty = true;
    final g = bundle.goal;
    _title.text = g.title;
    _categoryId = g.categoryId;
    _measurement = g.measurementKind;
    _target.text = g.targetValue == g.targetValue.roundToDouble()
        ? '${g.targetValue.toInt()}'
        : '${g.targetValue}';
    if (g.customLabel != null) _customLabel.text = g.customLabel!;
    _intensity = g.intensity.toDouble();
    _periodMode = g.periodMode;
    _rangeStart = DateTime.fromMillisecondsSinceEpoch(g.periodStartMs);
    _rangeEnd = DateTime.fromMillisecondsSinceEpoch(g.periodEndMs);
    _durationStart = DateTime.fromMillisecondsSinceEpoch(g.periodStartMs);
    _durationDays.text =
        '${g.durationDays ?? GoalPeriodHelpers.totalCalendarDaysInPeriod(g)}';
    _repeatCadence = g.repeatCadence;
    _repeatInterval = g.repeatInterval;
    _scheduledWeekdays
      ..clear()
      ..addAll(g.scheduledWeekdays ?? const []);
    _repeatDaysOfMonth
      ..clear()
      ..addAll(g.repeatDaysOfMonth ?? const []);
    _reminderEnabled = g.reminderEnabled;
    _reminderMinutesFromMidnight = g.reminderMinutesFromMidnight ?? 9 * 60;
    for (final d in _actionDrafts) {
      d.controller.dispose();
    }
    _actionDrafts.clear();
    if (bundle.actions.isEmpty) {
      _actionDrafts.add(_ActionDraft());
    } else {
      for (final a in bundle.actions) {
        _actionDrafts.add(
          _ActionDraft(
            id: a.id,
            controller: TextEditingController(text: a.title),
            completed: a.completed,
            repeatWeekdays: a.repeatWeekdays?.toSet(),
          ),
        );
      }
    }
    setState(() {});
    _suppressDraftDirty = false;
    if (widget.goalId != null) {
      _advancedExpanded = true;
    }
    if (!_draftRestoreScheduled) {
      _draftRestoreScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _offerDraftRestoreIfNeeded();
      });
    }
  }

  /// Target framing follows the repeat cycle: Off accumulates over the whole
  /// goal, a repeating goal measures per cycle.
  String _targetLabelText() {
    final n = _repeatInterval;
    return switch (_repeatCadence) {
      GoalRepeatCadence.off => 'Target (entire goal)',
      GoalRepeatCadence.daily =>
        n <= 1 ? 'Target (per day)' : 'Target (per $n days)',
      GoalRepeatCadence.weekly =>
        n <= 1 ? 'Target (per week)' : 'Target (per $n weeks)',
      GoalRepeatCadence.monthly =>
        n <= 1 ? 'Target (per month)' : 'Target (per $n months)',
    };
  }

  /// Start/end dates — how long the goal lives.
  Widget _buildDurationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const GoalEditorSectionLabel('Duration'),
        if (_periodMode == GoalPeriodMode.calendar)
          GoalEditorDateCard(
            title:
                '${_formatRangeDay(_rangeStart)}  →  ${_formatRangeDay(_rangeEnd)}',
            subtitle: 'First day → last day · tap to change',
            onTap: _pickRange,
          )
        else
          Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'Day count mode — set start date and duration in Advanced settings.',
              style: TextStyle(color: AppColors.fg38, fontSize: 12),
            ),
          ),
      ],
    );
  }

  /// The single scheduling section: Off / Daily / Weekly / Monthly. Defines
  /// both when the user acts (reminders, time blocks, Today's goals) and the
  /// window the target is measured over.
  Widget _buildRepeatSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GoalEditorSectionLabel(
          'Schedule',
          trailing: Text(
            _repeatCadence == GoalRepeatCadence.off ? 'ONE-TIME' : 'REPEATS',
            style: TextStyle(
              color: _repeatCadence == GoalRepeatCadence.off
                  ? AppColors.fg38
                  : GoalEditorColors.lime,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
            ),
          ),
        ),
        GoalEditorRepeatToggle(
          selected: _repeatCadence,
          onChanged: (c) => setState(() => _repeatCadence = c),
        ),
        const SizedBox(height: 8),
        if (_repeatCadence == GoalRepeatCadence.off)
          Text(
            'One-time goal — progress accumulates from start to end date. '
            'Log whenever you like; no reminders or routine days.',
            style: TextStyle(color: AppColors.fg38, fontSize: 12),
          )
        else ...[
          if (_repeatCadence == GoalRepeatCadence.weekly) ...[
            const SizedBox(height: 8),
            GoalEditorWeekdayPicker(
              selected: _scheduledWeekdays,
              onDayToggled: (day) => setState(() {
                if (!_scheduledWeekdays.remove(day)) {
                  _scheduledWeekdays.add(day);
                }
              }),
            ),
            const SizedBox(height: 12),
          ],
          if (_repeatCadence == GoalRepeatCadence.monthly) ...[
            const SizedBox(height: 8),
            GoalEditorMonthDayPicker(
              selected: _repeatDaysOfMonth,
              onChanged: (days) => setState(() {
                _repeatDaysOfMonth
                  ..clear()
                  ..addAll(days);
              }),
            ),
            const SizedBox(height: 12),
          ],
          // "Every X days" wheel and the reminder control share one row.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GoalEditorIntervalWheel(
                value: _repeatInterval,
                maxValue: _repeatCadence == GoalRepeatCadence.daily ? 30 : 12,
                onChanged: (v) => setState(() => _repeatInterval = v),
                unitSingular: switch (_repeatCadence) {
                  GoalRepeatCadence.daily => 'day',
                  GoalRepeatCadence.weekly => 'week',
                  GoalRepeatCadence.monthly => 'month',
                  GoalRepeatCadence.off => '',
                },
                unitPlural: switch (_repeatCadence) {
                  GoalRepeatCadence.daily => 'days',
                  GoalRepeatCadence.weekly => 'weeks',
                  GoalRepeatCadence.monthly => 'months',
                  GoalRepeatCadence.off => '',
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KeyedSubtree(
                  key: _reminderSectionKey,
                  child: GoalEditorReminderCard(
                    compact: true,
                    enabled: _reminderEnabled,
                    timeLabel: _formatReminderTime(context),
                    onToggle: (v) async {
                      if (v) {
                        final ok = await ref
                            .read(localNotificationsServiceProvider)
                            .requestPermissionsIfNeeded();
                        if (!context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Allow notifications to get goal reminders.',
                              ),
                            ),
                          );
                        }
                      }
                      if (!context.mounted) return;
                      setState(() => _reminderEnabled = v);
                    },
                    onPickTime: _pickReminderTime,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Target is measured per '
            '${_repeatInterval <= 1 ? '' : '$_repeatInterval '}'
            '${switch (_repeatCadence) {
              GoalRepeatCadence.daily => _repeatInterval <= 1 ? 'day' : 'days',
              GoalRepeatCadence.weekly =>
                _repeatInterval <= 1 ? 'week' : 'weeks',
              GoalRepeatCadence.monthly =>
                _repeatInterval <= 1 ? 'month' : 'months',
              GoalRepeatCadence.off => '',
            }}.',
            style: TextStyle(color: AppColors.fg38, fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedSection(BuildContext context) {
    return GoalEditorCollapsibleSection(
      title: 'Advanced settings',
      subtitle: 'Period mode, discipline',
      expanded: _advancedExpanded,
      onToggle: () => setState(() => _advancedExpanded = !_advancedExpanded),
      children: [
        const GoalEditorSectionLabel('Period mode'),
        GoalEditorPeriodModeCards(
          selected: _periodMode,
          onChanged: (m) => setState(() => _periodMode = m),
        ),
        if (_periodMode == GoalPeriodMode.durationDays) ...[
          const SizedBox(height: 12),
          GoalEditorDateCard(
            title:
                'Starts: ${_durationStart.year}-${_durationStart.month.toString().padLeft(2, '0')}-${_durationStart.day.toString().padLeft(2, '0')}',
            subtitle: 'First day of the run',
            onTap: _pickDurationStart,
          ),
          const SizedBox(height: 8),
          GoalEditorTextField(
            controller: _durationDays,
            keyboardType: TextInputType.number,
            hintText: '30',
            helperText: 'Inclusive: day 1 through this many days',
          ),
        ],
        const SizedBox(height: 20),
        const GoalEditorSectionLabel('Discipline level'),
        GoalEditorDisciplineSection(
          intensity: _intensity,
          onChanged: (v) => setState(() => _intensity = v),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.goalId != null) {
      final async = ref.watch(goalDetailProvider(widget.goalId!));
      async.whenData((b) {
        if (b != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _seedFromBundle(b);
          });
        }
      });
    }

    final filledSteps = _actionDrafts
        .where((d) => d.controller.text.trim().isNotEmpty)
        .length;

    final bottomSafe = MediaQuery.paddingOf(context).bottom;
    final surface = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      appBar: GoalEditorHeader(
        isEditing: widget.goalId != null,
        onBack: () => Navigator.pop(context),
        onSave: _saving ? null : _save,
      ),
      body: KeyboardDismissOnTap(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    // ── 1. Title ────────────────────────────────────────────────
                    const GoalEditorSectionLabel('Title'),
                    GoalEditorTextField(
                      controller: _title,
                      // Creating a new goal (from the template/custom picker) opens the
                      // keyboard on the title so the user can type at once. Editing an
                      // existing goal (goalId != null) must not shove the keyboard open.
                      autofocus: widget.goalId == null,
                      hintText:
                          (_suggestedTitle != null &&
                              _suggestedTitle!.isNotEmpty)
                          ? _suggestedTitle!
                          : 'What is your mission?',
                      validator: (v) {
                        // A blank field is fine when a template suggestion will be used.
                        if (v != null && v.trim().isNotEmpty) return null;
                        if (_suggestedTitle != null &&
                            _suggestedTitle!.trim().isNotEmpty) {
                          return null;
                        }
                        return 'Required';
                      },
                    ),
                    const SizedBox(height: 24),

                    // ── 2. Target + unit (one row) ──────────────────────────────
                    const GoalEditorSectionLabel('Target'),
                    // IntrinsicHeight + stretch keeps the unit pill exactly
                    // as tall as the target field.
                    IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 3,
                            child: GoalEditorTextField(
                              controller: _target,
                              keyboardType: TextInputType.number,
                              hintText: _suggestedTarget ?? 'e.g. 30',
                              validator: (v) {
                                // Blank is fine when the template suggestion
                                // will be used.
                                if (v != null && v.trim().isNotEmpty) {
                                  return null;
                                }
                                if (_suggestedTarget != null) return null;
                                return 'Required';
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: GoalEditorMeasurementDropdown(
                              value: _measurement,
                              onChanged: (v) =>
                                  setState(() => _measurement = v),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _targetLabelText(),
                      style: TextStyle(color: AppColors.fg38, fontSize: 12),
                    ),
                    if (_measurement == MeasurementKind.custom) ...[
                      const SizedBox(height: 12),
                      GoalEditorTextField(
                        controller: _customLabel,
                        hintText: 'Custom unit label',
                      ),
                    ],
                    const SizedBox(height: 24),

                    // ── 4. Duration (start/end dates) ───────────────────────────
                    _buildDurationSection(),
                    const SizedBox(height: 24),

                    // ── 5. Schedule (Off / Daily / Weekly / Monthly) ────────────
                    _buildRepeatSection(context),
                    const SizedBox(height: 24),

                    // ── 6. Setup steps (optional) ───────────────────────────────
                    GoalEditorSetupStepsSection(
                      stepCount: filledSteps,
                      onAdd: () => setState(() {
                        // Writing their own steps — the example has done its job.
                        _exampleStepsDismissed = true;
                        _actionDrafts.add(_ActionDraft());
                      }),
                      children: [
                        if (_exampleSteps.isNotEmpty)
                          GoalEditorExampleStepsCard(
                            visible: !_exampleStepsDismissed,
                            steps: _exampleSteps,
                            onUseThese: _useExampleSteps,
                          ),
                        for (var i = 0; i < _actionDrafts.length; i++)
                          GoalEditorSetupStepRow(
                            index: i,
                            controller: _actionDrafts[i].controller,
                            canRemove: _actionDrafts.length > 1,
                            repeatWeekdays: _actionDrafts[i].repeatWeekdays,
                            repeatExpanded: _actionDrafts[i].repeatExpanded,
                            onToggleRepeatExpanded: () => setState(() {
                              _actionDrafts[i].repeatExpanded =
                                  !_actionDrafts[i].repeatExpanded;
                            }),
                            onRepeatDayToggled: (day) => setState(() {
                              final days = _actionDrafts[i].repeatWeekdays;
                              if (!days.remove(day)) days.add(day);
                            }),
                            onChanged: (text) {
                              if (!_exampleStepsDismissed &&
                                  text.trim().isNotEmpty) {
                                setState(() => _exampleStepsDismissed = true);
                              }
                            },
                            onRemove: () {
                              setState(() {
                                _actionDrafts[i].controller.dispose();
                                _actionDrafts.removeAt(i);
                              });
                            },
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // ── 7. Advanced settings ────────────────────────────────────
                    _buildAdvancedSection(context),
                  ],
                ),
              ),
              // Save button pinned below the scroll so it's always reachable
              // without scrolling. Scaffold's default resizeToAvoidBottomInset
              // lifts this above the keyboard when it opens.
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomSafe),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [surface.withValues(alpha: 0), surface],
                  ),
                ),
                child: GoalEditorSaveButton(
                  saving: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionDraft {
  _ActionDraft({
    this.id,
    TextEditingController? controller,
    this.completed = false,
    Set<int>? repeatWeekdays,
  }) : controller = controller ?? TextEditingController(),
       repeatWeekdays = repeatWeekdays ?? <int>{};

  final String? id;
  final TextEditingController controller;
  final bool completed;

  /// Weekdays (1=Mon…7=Sun) this step repeats on; empty = one-time step.
  final Set<int> repeatWeekdays;

  /// Whether the inline weekday chips are open in the editor.
  bool repeatExpanded = false;
}
