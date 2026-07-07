import 'package:flutter/material.dart';

import '../application/conflict_resolution_port.dart';
import '../application/scheduling_slot_suggestions.dart';
import '../application/time_block_sync_service.dart';
import '../domain/models/conflict_resolution_outcome.dart';
import '../domain/models/scheduled_time_block.dart';
import '../domain/models/time_conflict.dart';
import 'conflict_bottom_sheet.dart';
import 'conflict_move_panel.dart';
import '../../../core/presentation/app_colors.dart';

enum _SheetMode { chooseAction, moveOther }

/// Fired when the user resolves a conflict inline (move existing / proposed).
typedef OnOverlapResolvedInline =
    void Function({
      required String movedEntity,
      required Object suggestionIndex,
      String? conflictingEntityId,
    });

/// Inline resolver for moderate/severe scheduling conflicts.
class SchedulingConflictSheet extends StatefulWidget {
  const SchedulingConflictSheet._({
    required this.proposedTitle,
    required this.proposedKind,
    required this.proposedBlock,
    required this.initialConflicts,
    required this.resolutionPort,
    required this.loadEntityTitles,
    required this.planDay,
    required this.ignoreEntityIds,
    this.onAdjustProposedSchedule,
    this.onEntityMoved,
    this.onOverlapResolvedInline,
  });

  final String proposedTitle;
  final String proposedKind;
  final ScheduledTimeBlock proposedBlock;
  final List<TimeConflict> initialConflicts;
  final ConflictResolutionPort resolutionPort;
  final Future<Map<String, String>> Function() loadEntityTitles;
  final DateTime planDay;
  final Set<String> ignoreEntityIds;
  final void Function(DateTime start, int durationMinutes)?
  onAdjustProposedSchedule;
  final VoidCallback? onEntityMoved;
  final OnOverlapResolvedInline? onOverlapResolvedInline;

  static Future<ConflictResolutionOutcome?> show({
    required BuildContext context,
    required String proposedTitle,
    required String proposedKind,
    required ScheduledTimeBlock proposedBlock,
    required List<TimeConflict> conflicts,
    required ConflictResolutionPort resolutionPort,
    required Future<Map<String, String>> Function() loadEntityTitles,
    required DateTime planDay,
    Set<String> ignoreEntityIds = const {},
    void Function(DateTime start, int durationMinutes)?
    onAdjustProposedSchedule,
    VoidCallback? onEntityMoved,
    OnOverlapResolvedInline? onOverlapResolvedInline,
  }) {
    return showModalBottomSheet<ConflictResolutionOutcome>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SchedulingConflictSheet._(
        proposedTitle: proposedTitle,
        proposedKind: proposedKind,
        proposedBlock: proposedBlock,
        initialConflicts: conflicts,
        resolutionPort: resolutionPort,
        loadEntityTitles: loadEntityTitles,
        planDay: planDay,
        ignoreEntityIds: ignoreEntityIds,
        onAdjustProposedSchedule: onAdjustProposedSchedule,
        onEntityMoved: onEntityMoved,
        onOverlapResolvedInline: onOverlapResolvedInline,
      ),
    );
  }

  @override
  State<SchedulingConflictSheet> createState() =>
      _SchedulingConflictSheetState();
}

class _SchedulingConflictSheetState extends State<SchedulingConflictSheet> {
  _SheetMode _mode = _SheetMode.chooseAction;
  late List<TimeConflict> _conflicts;
  final List<String> _appliedConfirmations = [];
  bool _busy = false;
  bool _canProceed = false;
  bool _conflictsExpanded = false;
  TimeConflict? _selectedConflict;
  TimeConflict? _activeConflict;
  List<TimeSlotSuggestion> _suggestions = const [];
  String? _otherCurrentRange;
  final _continueSaveKey = GlobalKey();
  bool _promptContinueSave = false;

  static const _collapsedConflictLimit = 3;

  @override
  void initState() {
    super.initState();
    _conflicts = List.of(widget.initialConflicts);
    if (_conflicts.isNotEmpty) {
      _selectedConflict = _conflicts.first;
    }
    _recheck(initial: true);
  }

  TimeConflict get _targetConflict =>
      _activeConflict ?? _selectedConflict ?? _conflicts.first;

  int get _moveDurationMinutes {
    if (widget.proposedKind == 'goal') {
      return kGoalBlockDefaultDurationMinutes;
    }
    return widget.proposedBlock.expectedDurationMinutes;
  }

  List<TimeConflict> get _visibleConflicts {
    if (_conflictsExpanded || _conflicts.length <= _collapsedConflictLimit) {
      return _conflicts;
    }
    return _conflicts.take(_collapsedConflictLimit).toList();
  }

  int get _hiddenConflictCount {
    if (_conflictsExpanded || _conflicts.length <= _collapsedConflictLimit) {
      return 0;
    }
    return _conflicts.length - _collapsedConflictLimit;
  }

  Future<void> _recheck({bool initial = false}) async {
    final titles = await widget.loadEntityTitles();
    if (!mounted) return;
    final result = await widget.resolutionPort.recheckProposedBlock(
      widget.proposedBlock,
      entityTitles: titles,
    );
    if (!mounted) return;

    setState(() {
      if (result.hasConflicts) {
        _conflicts = result.conflicts;
        final stillSelected =
            _selectedConflict != null &&
            _conflicts.any(
              (c) =>
                  c.conflictingEntityId ==
                  _selectedConflict!.conflictingEntityId,
            );
        if (!stillSelected && _conflicts.isNotEmpty) {
          _selectedConflict = _conflicts.first;
        }
      } else {
        _conflicts = const [];
        _selectedConflict = null;
      }
      _canProceed = _allowsProceed(result);
      if (!initial && _canProceed && _mode == _SheetMode.moveOther) {
        _mode = _SheetMode.chooseAction;
        _activeConflict = null;
      }
    });
  }

  bool _allowsProceed(ConflictCheckResult result) {
    if (!result.hasConflicts) return true;
    final worst = result.worstSeverity;
    if (worst == null) return true;
    return worst == ConflictSeverity.minor;
  }

  Future<void> _openMoveOther([TimeConflict? conflict]) async {
    final target = conflict ?? _targetConflict;
    final block = await widget.resolutionPort.blockForEntity(
      target.conflictingEntityId,
    );
    if (!mounted) return;

    final blocks = await widget.resolutionPort.blocksForPlanDay(widget.planDay);
    if (!mounted) return;

    final afterTime =
        block?.computedEndAt ??
        widget.proposedBlock.startAt.add(
          Duration(minutes: target.overlapMinutes),
        );

    final duration = block?.expectedDurationMinutes ?? _moveDurationMinutes;
    final suggestions = suggestAlternativeSlots(
      planDay: widget.planDay,
      durationMinutes: duration,
      blocksOnDay: blocks,
      afterTime: afterTime,
      ignoreEntityIds: widget.ignoreEntityIds,
      direction: SlotSearchDirection.forwardFrom,
    );

    setState(() {
      _mode = _SheetMode.moveOther;
      _activeConflict = target;
      _selectedConflict = target;
      _suggestions = suggestions;
      _otherCurrentRange = block != null
          ? formatSchedulingTimeRange(block.startAt, block.computedEndAt)
          : 'Unknown';
    });
  }

  Future<void> _applyMove(
    DateTime newStart, {
    int? durationMinutes,
    required Object suggestionIndex,
  }) async {
    final conflict = _activeConflict ?? _targetConflict;
    setState(() => _busy = true);
    try {
      final label = await widget.resolutionPort.moveConflictingEntity(
        conflict: conflict,
        newStart: newStart,
        planDay: widget.planDay,
        durationMinutes: durationMinutes,
      );
      widget.onEntityMoved?.call();
      widget.onOverlapResolvedInline?.call(
        movedEntity: 'existing',
        suggestionIndex: suggestionIndex,
        conflictingEntityId: conflict.conflictingEntityId,
      );
      if (!mounted) return;
      setState(() {
        _appliedConfirmations.add('$label ✓');
        _busy = false;
        _activeConflict = null;
        _mode = _SheetMode.chooseAction;
      });
      await _recheck();
      if (!mounted) return;
      if (_canProceed) {
        setState(() => _promptContinueSave = true);
        _scrollToContinueSave();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Schedule looks clear. Review below, then tap Continue & save.',
            ),
            duration: Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _conflicts.isEmpty
                  ? 'Schedule updated.'
                  : 'Moved. Resolve any remaining overlaps, then tap Continue & save.',
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not move: $e')));
    }
  }

  Future<void> _pickCustomTime() async {
    final conflict = _activeConflict ?? _targetConflict;
    final block = await widget.resolutionPort.blockForEntity(
      conflict.conflictingEntityId,
    );
    final duration = block?.expectedDurationMinutes ?? _moveDurationMinutes;
    final initial = TimeOfDay.fromDateTime(
      roundDateTimeToFiveMinutes(
        block?.computedEndAt ?? widget.proposedBlock.startAt,
      ),
    );

    if (!mounted) return;
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked == null || !mounted) return;

    final newStart = roundDateTimeToFiveMinutes(
      DateTime(
        widget.planDay.year,
        widget.planDay.month,
        widget.planDay.day,
        picked.hour,
        picked.minute,
      ),
    );
    await _applyMove(
      newStart,
      durationMinutes: duration,
      suggestionIndex: SchedulingSlotSuggestionIndex.custom,
    );
  }

  Future<void> _moveProposed() async {
    final blocks = await widget.resolutionPort.blocksForPlanDay(widget.planDay);
    final primary = _conflicts.isNotEmpty ? _targetConflict : null;
    final forwardAfter = primary != null
        ? widget.proposedBlock.startAt.add(
            Duration(minutes: primary.overlapMinutes),
          )
        : widget.proposedBlock.startAt;

    final suggestions = suggestAlternativeSlots(
      planDay: widget.planDay,
      durationMinutes: widget.proposedBlock.expectedDurationMinutes,
      blocksOnDay: blocks,
      afterTime: forwardAfter,
      ignoreEntityIds: widget.ignoreEntityIds,
      direction: SlotSearchDirection.preferBeforeAnchor,
      anchorTime: widget.proposedBlock.startAt,
    );

    if (!mounted) return;

    DateTime start = widget.proposedBlock.startAt;
    var duration = widget.proposedBlock.expectedDurationMinutes;
    Object suggestionIndex = SchedulingSlotSuggestionIndex.custom;

    if (suggestions.isNotEmpty) {
      start = suggestions.first.startAt;
      duration = suggestions.first.durationMinutes;
      suggestionIndex = suggestions.first.suggestionIndex;
    }

    widget.onOverlapResolvedInline?.call(
      movedEntity: 'proposed',
      suggestionIndex: suggestionIndex,
      conflictingEntityId: primary?.conflictingEntityId,
    );

    Navigator.pop(context, ConflictResolutionOutcome.stayOnForm);

    if (!mounted) return;

    widget.onAdjustProposedSchedule?.call(start, duration);

    final message = suggestions.isNotEmpty
        ? 'Earlier slot suggested (${formatSchedulingTimeRange(start, start.add(Duration(minutes: duration)))}). Tweak below if needed.'
        : 'Adjust the time on your form below, then save again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 4)),
    );
  }

  void _allowOverlap() {
    Navigator.pop(
      context,
      ConflictResolutionOutcome.proceed(overlapOverridden: true),
    );
  }

  void _scrollToContinueSave() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _continueSaveKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          alignment: 0.9,
        );
      }
    });
  }

  void _continueSave() {
    Navigator.pop(context, ConflictResolutionOutcome.proceed());
  }

  @override
  Widget build(BuildContext context) {
    final target = _conflicts.isNotEmpty ? _targetConflict : null;
    final worst = _conflicts
        .map((c) => c.severityLabel)
        .fold<ConflictSeverity?>(null, (prev, s) {
          if (prev == null) return s;
          return s.index > prev.index ? s : prev;
        });

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 16,
          bottom: 24 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.fg24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: _severityColor(worst),
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scheduling conflict',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                ConflictBottomSheet.overlapSummary(
                  proposedTitle: widget.proposedTitle,
                  conflictCount: _conflicts.isEmpty
                      ? widget.initialConflicts.length
                      : _conflicts.length,
                ),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.fg60),
              ),
              if (_conflicts.length > 1 &&
                  _mode == _SheetMode.chooseAction) ...[
                const SizedBox(height: 12),
                Text(
                  'Resolve one at a time',
                  style: Theme.of(
                    context,
                  ).textTheme.labelMedium?.copyWith(color: AppColors.fg54),
                ),
                const SizedBox(height: 6),
                for (final c in _visibleConflicts)
                  _ConflictPickRow(
                    conflict: c,
                    selected:
                        _selectedConflict?.conflictingEntityId ==
                        c.conflictingEntityId,
                    onTap: _busy
                        ? null
                        : () => setState(() => _selectedConflict = c),
                  ),
                if (_hiddenConflictCount > 0)
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _conflictsExpanded = true),
                    child: Text('+$_hiddenConflictCount more'),
                  ),
              ] else if (target != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Overlaps ${target.conflictingEntityTitle} '
                  '(${target.overlapMinutes}m)',
                  style: TextStyle(fontSize: 13, color: AppColors.fg70),
                ),
              ],
              for (final chip in _appliedConfirmations) ...[
                const SizedBox(height: 8),
                Chip(
                  avatar: const Icon(
                    Icons.check,
                    size: 16,
                    color: Colors.greenAccent,
                  ),
                  label: Text(chip, style: const TextStyle(fontSize: 12)),
                  backgroundColor: Colors.green.withAlpha(30),
                ),
              ],
              const SizedBox(height: 16),
              if (_mode == _SheetMode.chooseAction) ...[
                Text(
                  'Choose an action',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(color: AppColors.fg70),
                ),
                const SizedBox(height: 10),
                if (target != null)
                  _ActionTile(
                    label: 'Move ${target.conflictingEntityTitle}',
                    subtitle: _conflicts.length > 1
                        ? 'Reschedule the selected item'
                        : 'Reschedule the existing item',
                    icon: Icons.swap_horiz,
                    onTap: _busy ? null : () => _openMoveOther(target),
                  ),
                const SizedBox(height: 8),
                _ActionTile(
                  label: 'Move ${widget.proposedTitle}',
                  subtitle: 'Use an earlier slot or edit time below',
                  icon: Icons.edit_calendar,
                  onTap: _busy ? null : _moveProposed,
                ),
                const SizedBox(height: 8),
                _ActionTile(
                  label: 'Allow overlap',
                  subtitle: 'Save with overlapping schedule',
                  icon: Icons.layers,
                  color: Colors.orangeAccent,
                  onTap: _busy ? null : _allowOverlap,
                ),
              ] else if (target != null && _otherCurrentRange != null) ...[
                ConflictMovePanel(
                  entityTitle: target.conflictingEntityTitle,
                  currentRangeLabel: _otherCurrentRange!,
                  suggestions: _suggestions,
                  durationMinutes: _moveDurationMinutes,
                  busy: _busy,
                  onApplySuggestion: (s) =>
                      _applyMove(s.startAt, suggestionIndex: s.suggestionIndex),
                  onCustomTime: _pickCustomTime,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() {
                          _mode = _SheetMode.chooseAction;
                          _activeConflict = null;
                        }),
                  child: const Text('Back'),
                ),
              ],
              const SizedBox(height: 16),
              if (_promptContinueSave && _canProceed) ...[
                Text(
                  'Ready to save',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              KeyedSubtree(
                key: _continueSaveKey,
                child: FilledButton(
                  onPressed: _canProceed && !_busy ? _continueSave : null,
                  style: _promptContinueSave && _canProceed
                      ? FilledButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                        )
                      : null,
                  child: const Text('Continue & save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _severityColor(ConflictSeverity? severity) {
    switch (severity) {
      case ConflictSeverity.minor:
        return Colors.yellow;
      case ConflictSeverity.moderate:
        return Colors.orange;
      case ConflictSeverity.severe:
        return Colors.red;
      case null:
        return Colors.greenAccent;
    }
  }
}

class _ConflictPickRow extends StatelessWidget {
  const _ConflictPickRow({
    required this.conflict,
    required this.selected,
    this.onTap,
  });

  final TimeConflict conflict;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? AppColors.fg.withAlpha(18)
            : AppColors.fg.withAlpha(6),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  size: 18,
                  color: selected ? Colors.blueAccent : AppColors.fg38,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    conflict.conflictingEntityTitle,
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${conflict.overlapMinutes}m · ${conflict.severityLabel.name}',
                  style: TextStyle(fontSize: 11, color: AppColors.fg54),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    this.onTap,
    this.color,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? Colors.blueAccent;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.fg.withAlpha(10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.fg12),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: accent,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: AppColors.fg54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
