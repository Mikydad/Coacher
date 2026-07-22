import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_keys.dart';
import '../../application/goal_period_helpers.dart';
import '../../application/goals_providers.dart';
import '../../domain/models/goal_action.dart';
import '../../domain/models/goal_check_in.dart';
import '../../domain/models/goal_enums.dart';
import '../../domain/models/user_goal.dart';
import 'goal_card.dart';
import '../goal_detail_screen.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';

/// Bottom sheet with:
///   - Action-based progress ring (doneActions / totalActions)
///   - Measurement-kind-specific counter (minutes presets / −+ for others)
///   - Inline action checklist
///   - Complete button (ticks all actions + sets value = target)
class GoalCounterSheet extends ConsumerStatefulWidget {
  const GoalCounterSheet({
    super.key,
    required this.goal,
    required this.initialProgress,
  });

  final UserGoal goal;
  final GoalTodayProgress initialProgress;

  @override
  ConsumerState<GoalCounterSheet> createState() => _GoalCounterSheetState();
}

class _GoalCounterSheetState extends ConsumerState<GoalCounterSheet> {
  /// Numeric measurement value logged **today** — the counter edits this.
  late double _value;

  /// Amount accumulated on other days of the current evaluation window
  /// (zero for daily goals). Ring shows `_otherDaysValue + _value`.
  late double _otherDaysValue;

  /// Local copies of action counts to avoid re-fetching on every toggle.
  late int _doneActions;
  late int _totalActions;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialProgress.todayValue;
    _otherDaysValue =
        widget.initialProgress.currentValue - widget.initialProgress.todayValue;
    _doneActions = widget.initialProgress.doneActions;
    _totalActions = widget.initialProgress.totalActions;
  }

  UserGoal get _goal => widget.goal;
  double get _target => _goal.targetValue;

  /// Window total accumulated so far (other days + today's edits).
  double get _windowValue => _otherDaysValue + _value;

  /// Window progress (accumulated / target) — drives the ring and card fill.
  double get _measureProgress =>
      _target > 0 ? (_windowValue / _target).clamp(0.0, 1.0) : 0.0;

  bool get _allDone => _doneActions >= _totalActions && _totalActions > 0;

  // ── Unit helpers ────────────────────────────────────────────────────────────

  String get _unitLabel {
    if (_goal.measurementKind == MeasurementKind.custom &&
        (_goal.customLabel?.isNotEmpty ?? false)) {
      return _goal.customLabel!;
    }
    return switch (_goal.measurementKind) {
      MeasurementKind.minutes => 'min',
      MeasurementKind.sessions => 'sessions',
      MeasurementKind.count => 'count',
      MeasurementKind.distance => 'km',
      MeasurementKind.custom =>
        _goal.measurementKind.displayLabel().toLowerCase(),
    };
  }

  double get _step =>
      _goal.measurementKind == MeasurementKind.distance ? 0.5 : 1.0;

  String _formatValue(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String get _horizonLabel {
    final repeat = GoalPeriodHelpers.formatRepeatSummary(_goal);
    final period = switch (_goal.horizon) {
      GoalHorizon.daily => 'Daily',
      GoalHorizon.weekly => 'This week',
      GoalHorizon.monthly => 'This month',
      GoalHorizon.entireGoal => 'Entire goal',
    };
    return repeat.isEmpty ? period : '$period · $repeat';
  }

  // Period-aware: an ended goal offers no logging controls (its check-ins
  // would no longer count in analytics — 2026-07-22 decision).
  bool get _loggableToday =>
      GoalPeriodHelpers.allowsLoggingOnDateKey(_goal, DateKeys.todayKey());

  Color get _accentColor => goalCategoryColor(_goal.categoryId);

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _saveCheckIn({bool forceComplete = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(goalsRepositoryProvider);
      final met = forceComplete || _allDone || _windowValue >= _target;
      final checkIn = GoalCheckIn(
        goalId: _goal.id,
        dateKey: DateKeys.todayKey(),
        metCommitment: met,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        value: _value,
        note: widget.initialProgress.checkIn?.note,
      );
      await repo.upsertCheckIn(checkIn);
      ref.invalidate(goalTodayProgressProvider(_goal.id));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Measurement counter actions ─────────────────────────────────────────────

  void _addValue(double amount) {
    setState(() => _value = (_value + amount).clamp(0.0, double.infinity));
    _saveCheckIn();
  }

  void _subtractValue() {
    if (_value <= 0) return;
    setState(() => _value = (_value - _step).clamp(0.0, double.infinity));
    _saveCheckIn();
  }

  // ── Action toggle ───────────────────────────────────────────────────────────

  Future<void> _toggleAction(
    GoalAction action,
    List<GoalAction> allActions,
  ) async {
    final repo = ref.read(goalsRepositoryProvider);
    final todayKey = DateKeys.todayKey();
    final nowDone = !action.isCompletedOn(todayKey);
    await repo.upsertAction(
      action.withCompletionOn(todayKey, done: nowDone),
    );

    // Recount locally.
    final newDone = allActions
        .map(
          (a) => a.id == action.id ? nowDone : a.isCompletedOn(todayKey),
        )
        .where((done) => done)
        .length;

    // Auto-compute value proportionally to action progress.
    final newValue = _totalActions > 0
        ? (newDone / _totalActions) * _target
        : _value;

    setState(() {
      _doneActions = newDone;
      _value = newValue;
    });

    ref.invalidate(goalActionsProvider(_goal.id));
    ref.invalidate(goalDetailProvider(_goal.id));
    await _saveCheckIn();
  }

  // ── Complete ────────────────────────────────────────────────────────────────

  Future<void> _complete(List<GoalAction> actions) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(goalsRepositoryProvider);
      // Tick every action due today.
      final todayKey = DateKeys.todayKey();
      for (final a in actions) {
        if (!a.isCompletedOn(todayKey)) {
          await repo.upsertAction(a.withCompletionOn(todayKey, done: true));
        }
      }
      // Bring the window total up to the target (today's log absorbs the
      // remainder); never reduce what was already logged today.
      final remainder = (_target - _otherDaysValue).clamp(0.0, double.infinity);
      final completedTodayValue = _value > remainder ? _value : remainder;
      final checkIn = GoalCheckIn(
        goalId: _goal.id,
        dateKey: DateKeys.todayKey(),
        metCommitment: true,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        value: completedTodayValue,
        note: widget.initialProgress.checkIn?.note,
      );
      await repo.upsertCheckIn(checkIn);

      ref.invalidate(goalActionsProvider(_goal.id));
      ref.invalidate(goalDetailProvider(_goal.id));
      ref.invalidate(goalTodayProgressProvider(_goal.id));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final actionsAsync = ref.watch(goalActionsProvider(_goal.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.dark151718,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: actionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => swallowedAsyncError(
              'goal_counter_sheet',
              e,
              const Center(child: Text('Error loading actions')),
            ),
            data: (actions) {
              final dueToday = actions
                  .where((a) => a.isScheduledOn(DateTime.now()))
                  .toList();
              return ListView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom + 32,
                ),
                children: [
                  _buildHandle(),
                  _buildToolbar(),
                  _buildTitle(),
                  const SizedBox(height: 20),
                  _buildRing(),
                  const SizedBox(height: 6),
                  _buildRingSubtitle(),
                  const SizedBox(height: 24),
                  if (_loggableToday) ...[
                    _buildMeasurementCounter(),
                    const SizedBox(height: 20),
                    _buildCompleteButton(dueToday),
                    _buildActionsSection(dueToday),
                  ] else
                    _buildRestDayCard(),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ── Section builders ────────────────────────────────────────────────────────

  Widget _buildHandle() => Padding(
    padding: const EdgeInsets.only(top: 12, bottom: 4),
    child: Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: AppColors.fg24,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    ),
  );

  Widget _buildToolbar() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 8),
    child: Row(
      children: [
        IconButton(
          icon: Icon(Icons.close, color: AppColors.fg54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'View full detail',
          icon: Icon(Icons.trending_up_outlined, color: AppColors.fg54),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.pushNamed(
              context,
              GoalDetailScreen.routeName,
              arguments: _goal.id,
            );
          },
        ),
      ],
    ),
  );

  Widget _buildTitle() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      children: [
        Text(
          _goal.title,
          style: TextStyle(
            color: AppColors.fg,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _horizonLabel,
          style: TextStyle(color: AppColors.fg54, fontSize: 13),
        ),
      ],
    ),
  );

  /// Measurement-based ring: fills by value / targetValue.
  Widget _buildRing() => Center(
    child: Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CircularProgressIndicator(
            value: _measureProgress,
            strokeWidth: 10,
            backgroundColor: _accentColor.withValues(alpha: 0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
          ),
        ),
        Text(
          '${(_measureProgress * 100).round()}%',
          style: TextStyle(
            color: AppColors.fg,
            fontWeight: FontWeight.w800,
            fontSize: 40,
          ),
        ),
      ],
    ),
  );

  Widget _buildRingSubtitle() {
    final valueStr = _formatValue(_windowValue);
    final targetStr = _formatValue(_target);
    final todayNote = _otherDaysValue > 0
        ? '  ·  today: ${_formatValue(_value)}'
        : '';
    return Center(
      child: Text(
        '$valueStr / $targetStr $_unitLabel$todayNote',
        style: TextStyle(color: _accentColor, fontSize: 13),
      ),
    );
  }

  /// Per-measurement-kind counter section (buttons only; value shown in ring subtitle).
  Widget _buildMeasurementCounter() {
    return _goal.measurementKind == MeasurementKind.minutes
        ? _buildMinutePresets()
        : _buildPlusMinus();
  }

  /// +5 / +15 / +30 minute preset buttons.
  Widget _buildMinutePresets() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      for (final mins in [5, 15, 30])
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: _PresetButton(
            label: '+$mins min',
            onTap: () => _addValue(mins.toDouble()),
          ),
        ),
      const SizedBox(width: 4),
      _RoundButton(
        icon: Icons.remove,
        enabled: _value > 0,
        onTap: _subtractValue,
        small: true,
      ),
    ],
  );

  /// Standard − / + row for sessions, count, distance, custom.
  Widget _buildPlusMinus() => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      _RoundButton(
        icon: Icons.remove,
        enabled: _value > 0,
        onTap: _subtractValue,
      ),
      const SizedBox(width: 64),
      _RoundButton(
        icon: Icons.add,
        enabled: true,
        onTap: () => _addValue(_step),
      ),
    ],
  );

  Widget _buildCompleteButton(List<GoalAction> actions) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _saving ? null : () => _complete(actions),
        style: ElevatedButton.styleFrom(
          backgroundColor: _allDone
              ? _accentColor
              : _accentColor.withValues(alpha: 0.85),
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black54,
                ),
              )
            : Text(
                _allDone ? 'Completed ✓' : 'Mark all done',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
      ),
    ),
  );

  /// Shown instead of counter + checklist on days the goal isn't scheduled.
  Widget _buildRestDayCard() {
    final days = GoalPeriodHelpers.formatRepeatSummary(_goal).toLowerCase();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.dark2A2D32,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.self_improvement, color: AppColors.fg54, size: 30),
            const SizedBox(height: 10),
            Text(
              'Rest day',
              style: TextStyle(
                color: AppColors.fg,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'This goal repeats $days — nothing to log today.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.fg54, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsSection(List<GoalAction> actions) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final done = _doneActions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(color: AppColors.fg12),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Text(
                'Setup steps',
                style: TextStyle(
                  color: AppColors.fg,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              Text(
                '$done / ${actions.length}',
                style: TextStyle(color: AppColors.fg38, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final fraction = actions.isEmpty
                  ? 0.0
                  : (done / actions.length).clamp(0.0, 1.0);
              return Stack(
                children: [
                  Container(
                    width: constraints.maxWidth,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppColors.fg10,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                    width: constraints.maxWidth * fraction,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      borderRadius: BorderRadius.circular(7),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        for (final action in actions)
          _ActionTile(
            action: action,
            completed: action.isCompletedOn(DateKeys.todayKey()),
            accentColor: _accentColor,
            onToggle: () => _toggleAction(action, actions),
          ),
      ],
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _PresetButton extends StatelessWidget {
  const _PresetButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.dark2A2D32,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: AppColors.fg,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.completed,
    required this.accentColor,
    required this.onToggle,
  });

  final GoalAction action;

  /// Today's completion state — per-day for repeating actions.
  final bool completed;
  final Color accentColor;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onToggle,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: completed ? accentColor : Colors.transparent,
                border: Border.all(
                  color: completed ? accentColor : Colors.white30,
                  width: 1.5,
                ),
              ),
              child: completed
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.title,
                    style: TextStyle(
                      color: completed ? AppColors.fg38 : AppColors.fg,
                      fontSize: 14,
                      decoration: completed
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: AppColors.fg38,
                    ),
                  ),
                  if (action.isRepeating)
                    Text(
                      GoalPeriodHelpers.formatWeekdays(action.repeatWeekdays!),
                      style: TextStyle(
                        color: accentColor.withValues(alpha: 0.8),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
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

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
    this.small = false,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final size = small ? 40.0 : 56.0;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? AppColors.dark2A2D32 : AppColors.surfaceMuted,
        ),
        child: Icon(
          icon,
          size: small ? 18 : 24,
          color: enabled ? AppColors.fg : AppColors.fg24,
        ),
      ),
    );
  }
}
