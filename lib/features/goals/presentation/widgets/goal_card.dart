import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_keys.dart';
import '../../../accountability/application/stakes_providers.dart';
import '../../application/goal_period_helpers.dart';
import '../../application/goals_providers.dart';
import '../../domain/models/goal_categories.dart';
import '../../domain/models/goal_check_in.dart';
import '../../domain/models/goal_enums.dart';
import '../../domain/models/user_goal.dart';
import 'goal_counter_sheet.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';

/// Color per category, used as the card fill color.
Color goalCategoryColor(String categoryId) {
  return switch (categoryId) {
    GoalCategories.study => AppColors.categoryBlue,
    GoalCategories.fitness => AppColors.categoryBurntOrange,
    GoalCategories.productivity => AppColors.limeOlive,
    GoalCategories.focus => AppColors.categoryPurple,
    GoalCategories.habits => AppColors.categoryBrown,
    GoalCategories.mentalClarity => AppColors.categoryTeal,
    _ => AppColors.textDim,
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
      } catch (e) {
        debugPrint('goal_card: swallowed error: $e');
      }
    }
    return goalCategoryColor(goal.categoryId);
  }

  /// Repeat summary when the goal has one ("Every week on Mon · Wed"),
  /// otherwise the evaluation period ("This month", "Entire goal").
  /// An ended period overrides both — the card must say so, because
  /// analytics stopped counting this goal the day its period lapsed and
  /// a live-looking card was silently misleading (2026-07-22 decision).
  String get _horizonLabel {
    if (_periodEnded) return 'Ended';
    final repeat = GoalPeriodHelpers.formatRepeatSummary(goal);
    if (repeat.isNotEmpty) return repeat;
    return switch (goal.horizon) {
      GoalHorizon.daily => 'Daily',
      GoalHorizon.weekly => 'This week',
      GoalHorizon.monthly => 'This month',
      GoalHorizon.entireGoal => 'Entire goal',
    };
  }

  bool get _periodEnded {
    final now = DateTime.now();
    final end = DateTime.fromMillisecondsSinceEpoch(goal.periodEndMs);
    return DateTime(now.year, now.month, now.day)
        .isAfter(DateTime(end.year, end.month, end.day));
  }

  /// Period-aware (unlike the model's [UserGoal.allowsLoggingOn]): a goal
  /// whose period has ended stops offering quick-add — logging it would
  /// no longer count anywhere.
  bool get _loggableToday =>
      GoalPeriodHelpers.allowsLoggingOnDateKey(goal, DateKeys.todayKey());

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
      MeasurementKind.custom =>
        goal.measurementKind.displayLabel().toLowerCase(),
    };
  }

  String _formatValue(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

  String _targetLabel(double currentValue) {
    final current = _formatValue(currentValue);
    final target = _formatValue(goal.targetValue);
    return '$current / $target $_unitLabel';
  }

  Future<void> _quickIncrement(
    BuildContext context,
    WidgetRef ref,
    GoalTodayProgress progress,
  ) async {
    final repo = ref.read(goalsRepositoryProvider);
    final dateKey = DateKeys.todayKey();
    // The check-in stores today's amount; "met" is judged against the
    // evaluation window's accumulated total.
    final newTodayValue = progress.todayValue + 1;
    final met = progress.currentValue + 1 >= goal.targetValue;

    final checkIn = GoalCheckIn(
      goalId: goal.id,
      dateKey: dateKey,
      metCommitment: met,
      updatedAtMs: DateTime.now().millisecondsSinceEpoch,
      value: newTodayValue,
      note: progress.checkIn?.note,
    );
    await repo.upsertCheckIn(checkIn);
    ref.invalidate(goalTodayProgressProvider(goal.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(goalTodayProgressProvider(goal.id));
    // CC-6 — a live challenge holds this goal hostage; say so.
    final staked = ref.watch(stakedGoalIdsProvider).contains(goal.id);

    return progressAsync.when(
      loading: () => _CardShell(
        baseColor: _baseColor,
        progress: 0,
        goal: goal,
        horizonLabel: _horizonLabel,
        measurementLabel: _targetLabel(0),
        metCommitment: false,
        staked: staked,
        onTap: () {},
        onQuickAdd: null,
      ),
      error: (e, _) => swallowedAsyncError(
        'goal_card',
        e,
        _CardShell(
          baseColor: _baseColor,
          progress: 0,
          goal: goal,
          horizonLabel: _horizonLabel,
          measurementLabel: _targetLabel(0),
          metCommitment: false,
          onTap: () {},
          onQuickAdd: null,
        ),
      ),
      data: (p) => _CardShell(
        baseColor: _baseColor,
        progress: p.progress,
        goal: goal,
        horizonLabel: _horizonLabel,
        measurementLabel: _targetLabel(p.currentValue),
        // Done styling: today explicitly met, or the window target reached.
        metCommitment: p.metCommitment || p.periodTargetMet,
        staked: staked,
        onTap: () => showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => GoalCounterSheet(goal: goal, initialProgress: p),
        ).then((_) => ref.invalidate(goalTodayProgressProvider(goal.id))),
        // Repeating goals are dormant on off-days — nothing to log.
        onQuickAdd: p.metCommitment || p.periodTargetMet || !_loggableToday
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
    this.staked = false,
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

  /// A live challenge has this goal on the line (CC-6 staked badge).
  final bool staked;

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
                    color: fillColor.withValues(
                      alpha: metCommitment ? 1.0 : 0.55,
                    ),
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
                            color: metCommitment ? Colors.black : AppColors.fg,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (staked) ...[
                              Icon(
                                Icons.handshake_rounded,
                                size: 12,
                                color: metCommitment
                                    ? Colors.black54
                                    : AppColors.accent,
                              ),
                              const SizedBox(width: 3),
                            ],
                            Flexible(
                              child: Text(
                                '${staked ? 'Staked · ' : ''}'
                                '$horizonLabel · $measurementLabel',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: metCommitment
                                      ? Colors.black54
                                      : AppColors.fg70,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Right: streak + action button
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (goal.intensity >= 4) ...[
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 16,
                        ),
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
                      _ActionButton(done: metCommitment, onTap: onQuickAdd),
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
              ? AppColors.fg.withValues(alpha: 0.25)
              : AppColors.fg.withValues(alpha: 0.15),
          border: Border.all(
            color: AppColors.fg.withValues(alpha: done ? 0.6 : 0.4),
            width: 1.5,
          ),
        ),
        child: Icon(
          done ? Icons.check : Icons.add,
          size: 18,
          color: done ? AppColors.fg : AppColors.fg70,
        ),
      ),
    );
  }
}
