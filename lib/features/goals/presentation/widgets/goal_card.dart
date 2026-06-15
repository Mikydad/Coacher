import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_keys.dart';
import '../../../../core/utils/stable_id.dart';
import '../../application/goals_providers.dart';
import '../../domain/models/goal_categories.dart';
import '../../domain/models/goal_check_in.dart';
import '../../domain/models/goal_enums.dart';
import '../../domain/models/user_goal.dart';
import 'goal_counter_sheet.dart';

/// Color per category, used as the card fill color.
Color goalCategoryColor(String categoryId) {
  return switch (categoryId) {
    GoalCategories.study => const Color(0xFF3B6FD4),
    GoalCategories.fitness => const Color(0xFFE07B2A),
    GoalCategories.productivity => const Color(0xFF7BAF2A),
    GoalCategories.focus => const Color(0xFF7B4FBF),
    GoalCategories.habits => const Color(0xFF8B6B3D),
    GoalCategories.mentalClarity => const Color(0xFF2A9B8B),
    _ => const Color(0xFF444444),
  };
}

/// A goal card with a horizontal fill bar showing today's progress.
///
/// Tapping the card opens [GoalCounterSheet].
/// Tapping the + button increments the value by 1 directly.
class GoalCard extends ConsumerWidget {
  const GoalCard({super.key, required this.goal});

  final UserGoal goal;

  Color get _baseColor {
    if (goal.colorHex != null && goal.colorHex!.length == 6) {
      try {
        return Color(int.parse('FF${goal.colorHex}', radix: 16));
      } catch (_) {}
    }
    return goalCategoryColor(goal.categoryId);
  }

  String get _horizonLabel => switch (goal.horizon) {
    GoalHorizon.daily => 'Every day',
    GoalHorizon.weekly => 'Every week',
    GoalHorizon.monthly => 'Every month',
  };

  String get _unitLabel {
    if (goal.measurementKind == MeasurementKind.custom &&
        (goal.customLabel?.isNotEmpty ?? false)) {
      return goal.customLabel!;
    }
    return switch (goal.measurementKind) {
      MeasurementKind.minutes => 'min',
      MeasurementKind.sessions => 'sessions',
      MeasurementKind.count => 'count',
      MeasurementKind.distance => 'km',
      MeasurementKind.custom => goal.measurementKind.displayLabel().toLowerCase(),
    };
  }

  String _formatValue(double v) => v == v.roundToDouble()
      ? v.toInt().toString()
      : v.toStringAsFixed(1);

  String _targetLabel(double currentValue) {
    final current = _formatValue(currentValue);
    final target = _formatValue(goal.targetValue);
    return '$current / $target $_unitLabel';
  }

  Future<void> _quickIncrement(BuildContext context, WidgetRef ref,
      GoalTodayProgress progress) async {
    final repo = ref.read(goalsRepositoryProvider);
    final dateKey = DateKeys.todayKey();
    final newValue = progress.currentValue + 1;
    final met = newValue >= goal.targetValue;

    final checkIn = GoalCheckIn(
      goalId: goal.id,
      dateKey: dateKey,
      metCommitment: met,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      value: newValue,
      note: progress.checkIn?.note,
    );
    await repo.upsertCheckIn(checkIn);
    ref.invalidate(goalTodayProgressProvider(goal.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalTodayProgressProvider(goal.id));

    return progressAsync.when(
      loading: () => _CardShell(
        baseColor: _baseColor,
        progress: 0,
        goal: goal,
        horizonLabel: _horizonLabel,
        measurementLabel: _targetLabel(0),
        metCommitment: false,
        onTap: () {},
        onQuickAdd: null,
      ),
      error: (_, __) => _CardShell(
        baseColor: _baseColor,
        progress: 0,
        goal: goal,
        horizonLabel: _horizonLabel,
        measurementLabel: _targetLabel(0),
        metCommitment: false,
        onTap: () {},
        onQuickAdd: null,
      ),
      data: (p) => _CardShell(
        baseColor: _baseColor,
        progress: p.progress,
        goal: goal,
        horizonLabel: _horizonLabel,
        measurementLabel: _targetLabel(p.currentValue),
        metCommitment: p.metCommitment,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => GoalCounterSheet(goal: goal, initialProgress: p),
        ).then((_) => ref.invalidate(goalTodayProgressProvider(goal.id))),
        onQuickAdd: p.metCommitment
            ? null
            : () => _quickIncrement(context, ref, p),
      ),
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.baseColor,
    required this.progress,
    required this.goal,
    required this.horizonLabel,
    required this.measurementLabel,
    required this.metCommitment,
    required this.onTap,
    required this.onQuickAdd,
  });

  final Color baseColor;
  final double progress;
  final UserGoal goal;
  final String horizonLabel;

  /// e.g. "3 / 5 sessions" or "30 / 60 min"
  final String measurementLabel;
  final bool metCommitment;
  final VoidCallback onTap;
  final VoidCallback? onQuickAdd;

  @override
  Widget build(BuildContext context) {
    final fillColor = baseColor;
    final bgColor = baseColor.withValues(alpha: 0.18);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        height: 72,
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Fill bar ─────────────────────────────────────────────────
            Align(
              alignment: Alignment.centerLeft,
              child: AnimatedFractionallySizedBox(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                widthFactor: progress.clamp(0.0, 1.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: fillColor.withValues(alpha: metCommitment ? 1.0 : 0.55),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
              ),
            ),

            // ── Content overlay ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // Left: title + subtitle
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          goal.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: metCommitment ? Colors.black : Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$horizonLabel · $measurementLabel',
                          style: TextStyle(
                            color: metCommitment
                                ? Colors.black54
                                : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Right: streak + action button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (goal.intensity >= 4) ...[
                        const Icon(Icons.local_fire_department,
                            color: Colors.orange, size: 16),
                        Text(
                          '${goal.intensity}',
                          style: const TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      _ActionButton(
                        done: metCommitment,
                        onTap: onQuickAdd,
                      ),
                    ],
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.done, required this.onTap});

  final bool done;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: done
              ? Colors.white.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.15),
          border: Border.all(
            color: Colors.white.withValues(alpha: done ? 0.6 : 0.4),
            width: 1.5,
          ),
        ),
        child: Icon(
          done ? Icons.check : Icons.add,
          size: 18,
          color: done ? Colors.white : Colors.white70,
        ),
      ),
    );
  }
}
