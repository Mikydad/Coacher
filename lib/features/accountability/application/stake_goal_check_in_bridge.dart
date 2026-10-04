import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_keys.dart';
import '../../goals/application/goal_period_helpers.dart';
import '../../goals/application/goals_providers.dart';
import '../../goals/domain/models/goal_check_in.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../domain/models/stake_challenge.dart';

/// Keeps the goal's book in step with the stake's (2026-09-15).
///
/// A staked goal's card opens the challenge page instead of the check-in
/// sheet, so proof (timer / camera / practice record) is the only way to
/// log it. The goal's own progress ring, streaks and coaching still read
/// goal check-ins — so every evidence write also lands today's check-in
/// with the same amount, exactly as the card's quick-add would have. One
/// action, both books. Direction matters: evidence → check-in, never the
/// reverse (a bare check-in is the bypass the stake exists to prevent).
///
/// Local-first: the check-in goes through the goals repository (Isar +
/// outbox). Best-effort: a missing/paused goal or an off-day is a no-op.
class StakeGoalCheckInBridge {
  const StakeGoalCheckInBridge(this._ref);

  final Ref _ref;

  Future<void> mirrorEvidence({
    required StakeChallenge challenge,
    required int amount,
  }) async {
    final goalId = challenge.frozenGoal.linkedGoalId?.trim();
    if (goalId == null || goalId.isEmpty || amount <= 0) return;
    final repo = _ref.read(goalsRepositoryProvider);
    final goal = await repo.getGoal(goalId);
    if (goal == null || goal.status != GoalStatus.active) return;
    final dateKey = DateKeys.todayKey();
    if (!GoalPeriodHelpers.allowsLoggingOnDateKey(goal, dateKey)) return;

    // Same math as the card's quick-add: today's amount is stored on the
    // check-in; "met" is judged against the evaluation window's total.
    final window = GoalPeriodHelpers.evaluationWindow(goal, DateTime.now());
    final inWindow = await repo.getCheckInsForGoal(
      goalId,
      startDateKey: DateKeys.yyyymmdd(window.start),
      endDateKey: DateKeys.yyyymmdd(window.end),
    );
    GoalCheckIn? today;
    var windowValue = 0.0;
    for (final c in inWindow) {
      windowValue += c.value ?? 0;
      if (c.dateKey == dateKey) today = c;
    }
    final newTodayValue = (today?.value ?? 0) + amount;
    final met = windowValue + amount >= goal.targetValue;
    await repo.upsertCheckIn(
      GoalCheckIn(
        goalId: goalId,
        dateKey: dateKey,
        metCommitment: met,
        updatedAtMs: DateTime.now().millisecondsSinceEpoch,
        value: newTodayValue,
        note: today?.note,
      ),
    );
    _ref.invalidate(goalTodayProgressProvider(goalId));
  }
}

final stakeGoalCheckInBridgeProvider = Provider<StakeGoalCheckInBridge>(
  (ref) => StakeGoalCheckInBridge(ref),
);
