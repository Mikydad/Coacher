import '../../../core/tier/tier_gate.dart';
import '../../../core/tier/tier_usage.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../reminders/data/reminder_repository.dart';

/// Tier gating for AI-created entities, so the chat path can't sidestep
/// the free-tier caps the manual creation screens enforce. Throws
/// [TierLimitException]; the executor's per-action catch surfaces the
/// message in the "Could not complete" list.
class AiTierGuard {
  AiTierGuard({
    required TierGate Function() gate,
    required GoalsRepository goalsRepository,
    required ReminderRepository reminderRepository,
  }) : _gate = gate,
       _goalsRepository = goalsRepository,
       _reminderRepository = reminderRepository;

  final TierGate Function() _gate;
  final GoalsRepository _goalsRepository;
  final ReminderRepository _reminderRepository;

  Future<void> ensureCanCreateTask(String dateKey) async {
    final gate = _gate();
    if (gate.isBypassed) return;
    final count = await TierUsage.tasksPlannedForDay(dateKey);
    if (!gate.canCreateTaskForDay(count)) {
      throw TierLimitException(
        'the free plan allows ${gate.limits.freeTasksPerDay} tasks per day '
        '— SidePal Pro removes the limit',
      );
    }
  }

  Future<void> ensureCanCreateGoal() async {
    final gate = _gate();
    if (gate.isBypassed) return;
    final goals = await _goalsRepository.fetchGoalsOnce();
    final active = goals.where((g) => g.status == GoalStatus.active).length;
    if (!gate.canCreateGoal(active)) {
      throw TierLimitException(
        'the free plan allows ${gate.limits.freeGoals} active goals '
        '— SidePal Pro removes the limit',
      );
    }
  }

  Future<void> ensureCanAddReminder() async {
    final gate = _gate();
    if (gate.isBypassed) return;
    final reminders = await _reminderRepository.listAllReminders();
    final active = reminders.where((r) => r.enabled).length;
    if (!gate.canCreateReminder(active)) {
      throw TierLimitException(
        'the free plan allows ${gate.limits.freeReminders} active reminders '
        '— SidePal Pro removes the limit',
      );
    }
  }
}
