import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_keys.dart';
import '../../application/goals_providers.dart';
import '../../domain/models/goal_action.dart';
import '../../domain/models/goal_check_in.dart';
import '../../domain/models/goal_enums.dart';
import '../../domain/models/user_goal.dart';
import 'goal_card.dart';
import '../goal_detail_screen.dart';

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
  /// Numeric measurement value logged today (e.g. 30 minutes, 3 sessions).
  late double _value;

  /// Local copies of action counts to avoid re-fetching on every toggle.
  late int _doneActions;
  late int _totalActions;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _value = widget.initialProgress.currentValue;
    _doneActions = widget.initialProgress.doneActions;
    _totalActions = widget.initialProgress.totalActions;
  }

  UserGoal get _goal => widget.goal;
  double get _target => _goal.targetValue;
  /// Measurement-based progress (value / target) — drives the ring and card fill.
  double get _measureProgress =>
      _target > 0 ? (_value / _target).clamp(0.0, 1.0) : 0.0;

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

  double get _step => _goal.measurementKind == MeasurementKind.distance
      ? 0.5
      : 1.0;

  String _formatValue(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String get _horizonLabel => switch (_goal.horizon) {
    GoalHorizon.daily => 'Every day',
    GoalHorizon.weekly => 'Every week',
    GoalHorizon.monthly => 'Every month',
  };

  Color get _accentColor => goalCategoryColor(_goal.categoryId);

  // ── Persistence ─────────────────────────────────────────────────────────────

  Future<void> _saveCheckIn({bool forceComplete = false}) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final repo = ref.read(goalsRepositoryProvider);
      final met = forceComplete || _allDone || _value >= _target;
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

  Future<void> _toggleAction(GoalAction action, List<GoalAction> allActions) async {
    final repo = ref.read(goalsRepositoryProvider);
    final nowDone = !action.completed;
    await repo.upsertAction(action.copyWith(completed: nowDone));

    // Recount locally.
    final newDone = allActions
        .map((a) => a.id == action.id ? nowDone : a.completed)
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
      // Tick every action.
      for (final a in actions) {
        if (!a.completed) {
          await repo.upsertAction(a.copyWith(completed: true));
        }
      }
      // Set value to target.
      final checkIn = GoalCheckIn(
        goalId: _goal.id,
        dateKey: DateKeys.todayKey(),
        metCommitment: true,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        value: _target,
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
          decoration: const BoxDecoration(
            color: Color(0xFF151718),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: actionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Center(child: Text('Error loading actions')),
            data: (actions) => ListView(
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
                _buildMeasurementCounter(),
                const SizedBox(height: 20),
                _buildCompleteButton(actions),
                _buildActionsSection(actions),
              ],
            ),
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
          color: Colors.white24,
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
          icon: const Icon(Icons.close, color: Colors.white54),
          onPressed: () => Navigator.of(context).pop(),
        ),
        const Spacer(),
        IconButton(
          tooltip: 'View full detail',
          icon: const Icon(Icons.trending_up_outlined, color: Colors.white54),
          onPressed: () {
            Navigator.of(context).pop();
            Navigator.pushNamed(context, GoalDetailScreen.routeName,
                arguments: _goal.id);
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 22,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          _horizonLabel,
          style: const TextStyle(color: Colors.white54, fontSize: 13),
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
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 40,
          ),
        ),
      ],
    ),
  );

  Widget _buildRingSubtitle() {
    final valueStr = _formatValue(_value);
    final targetStr = _formatValue(_target);
    return Center(
      child: Text(
        '$valueStr / $targetStr $_unitLabel',
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
          backgroundColor:
              _allDone ? _accentColor : _accentColor.withValues(alpha: 0.85),
          foregroundColor: Colors.black,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: _saving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.black54),
              )
            : Text(
                _allDone ? 'Completed ✓' : 'Mark all done',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16),
              ),
      ),
    ),
  );

  Widget _buildActionsSection(List<GoalAction> actions) {
    if (actions.isEmpty) return const SizedBox.shrink();
    final done = _doneActions;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Divider(color: Colors.white12),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Text(
                'Setup steps',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15),
              ),
              const Spacer(),
              Text(
                '$done / ${actions.length}',
                style:
                    const TextStyle(color: Colors.white38, fontSize: 13),
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
                      color: Colors.white10,
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
          color: const Color(0xFF2A2D32),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.action,
    required this.accentColor,
    required this.onToggle,
  });

  final GoalAction action;
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
                color: action.completed ? accentColor : Colors.transparent,
                border: Border.all(
                  color: action.completed ? accentColor : Colors.white30,
                  width: 1.5,
                ),
              ),
              child: action.completed
                  ? const Icon(Icons.check, size: 14, color: Colors.black)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                action.title,
                style: TextStyle(
                  color: action.completed ? Colors.white38 : Colors.white,
                  fontSize: 14,
                  decoration: action.completed
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  decorationColor: Colors.white38,
                ),
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
          color: enabled
              ? const Color(0xFF2A2D32)
              : const Color(0xFF1A1C1F),
        ),
        child: Icon(
          icon,
          size: small ? 18 : 24,
          color: enabled ? Colors.white : Colors.white24,
        ),
      ),
    );
  }
}
