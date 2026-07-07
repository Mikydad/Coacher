import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../../reminders/data/reminder_repository.dart';

// ─── Model ────────────────────────────────────────────────────────────────────

/// A single schedule optimisation recommendation.
class OptimisationRecommendation {
  const OptimisationRecommendation({
    required this.ruleCode,
    required this.description,
    required this.preDraftedInput,
  });

  /// Short code identifying the rule that generated this recommendation.
  ///
  ///   - `A`: priority inversion
  ///   - `B`: fatigue stacking
  ///   - `C`: reminder noise
  final String ruleCode;

  /// Human-readable explanation (one sentence).
  final String description;

  /// Text to pre-fill in the Coach AI input if the user wants to act.
  final String preDraftedInput;

  @override
  String toString() =>
      'OptimisationRecommendation(rule: $ruleCode, $description)';
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Analyses today's schedule for common inefficiency patterns.
///
/// Returns a list of [OptimisationRecommendation]s — never mutates any data.
class ScheduleOptimisationService {
  const ScheduleOptimisationService({
    required this.planningRepository,
    required this.reminderRepository,
  });

  final PlanningRepository planningRepository;
  final ReminderRepository reminderRepository;

  static const int _fatigueStackThreshold = 3;
  static const int _reminderNoiseWindowMinutes = 30;
  static const int _reminderNoiseThreshold = 4;

  /// Analyses the schedule for [dateKey] and returns applicable recommendations.
  Future<List<OptimisationRecommendation>> analyse(String dateKey) async {
    final recommendations = <OptimisationRecommendation>[];

    try {
      final rows = await collectTasksForDateKey(planningRepository, dateKey);
      if (rows.isEmpty) return [];

      // Rule A — Priority inversion
      final ruleA = _checkPriorityInversion(rows);
      if (ruleA != null) recommendations.add(ruleA);

      // Rule B — Fatigue stacking (strict-mode tasks back-to-back)
      final ruleB = _checkFatigueStacking(rows);
      if (ruleB != null) recommendations.add(ruleB);

      // Rule C — Reminder noise (≥4 reminders in any 30-min window)
      final ruleC = await _checkReminderNoise(rows);
      if (ruleC != null) recommendations.add(ruleC);
    } catch (_) {
      // Best-effort; never block the rest of the UI
    }

    return recommendations;
  }

  // ─── Rule A: Priority inversion ───────────────────────────────────────────

  /// High-priority task (lower priority number) appears after a low-priority
  /// task in today's ordering.
  OptimisationRecommendation? _checkPriorityInversion(
    List<PlannedTaskRow> rows,
  ) {
    // We need rows sorted by their reminderTime or orderIndex to check order
    final sortedByTime = List<PlannedTaskRow>.from(rows)
      ..sort((a, b) {
        final aTime = a.task.reminderTimeIso;
        final bTime = b.task.reminderTimeIso;
        if (aTime == null && bTime == null) {
          return a.task.orderIndex.compareTo(b.task.orderIndex);
        }
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return aTime.compareTo(bTime);
      });

    int? lowestPrioritySeen; // highest number = lowest priority
    for (final row in sortedByTime) {
      final p = row.task.priority;
      if (lowestPrioritySeen == null) {
        lowestPrioritySeen = p;
        continue;
      }
      // If this task has a higher priority (lower number) than the lowest seen,
      // it means a high-priority task comes AFTER a low-priority one.
      if (p < lowestPrioritySeen) {
        return const OptimisationRecommendation(
          ruleCode: 'A',
          description:
              'Some high-priority tasks are scheduled after lower-priority ones.',
          preDraftedInput: 'Move my most important tasks to the morning',
        );
      }
      if (p > lowestPrioritySeen) lowestPrioritySeen = p;
    }
    return null;
  }

  // ─── Rule B: Fatigue stacking ─────────────────────────────────────────────

  /// ≥3 high-enforcement (strict / extreme) tasks scheduled back-to-back.
  OptimisationRecommendation? _checkFatigueStacking(List<PlannedTaskRow> rows) {
    // Consider tasks with strictModeRequired OR with disciplined/extreme modeRefId
    final strictTasks = rows.where((r) {
      final mode = r.task.modeRefId ?? '';
      return r.task.strictModeRequired ||
          mode == 'disciplined' ||
          mode == 'extreme';
    }).toList();

    if (strictTasks.length < _fatigueStackThreshold) return null;

    // Sort by reminder time to check consecutive runs
    final sorted = List<PlannedTaskRow>.from(strictTasks)
      ..sort((a, b) {
        final aT = a.task.reminderTimeIso;
        final bT = b.task.reminderTimeIso;
        if (aT == null) return 1;
        if (bT == null) return -1;
        return aT.compareTo(bT);
      });

    int consecutiveRun = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prevEnd = _taskEndMs(sorted[i - 1].task);
      final currStart = _taskStartMs(sorted[i].task);

      if (prevEnd == null || currStart == null) {
        consecutiveRun = 1;
        continue;
      }

      // "Back-to-back" = gap ≤ 5 minutes
      final gapMinutes = (currStart - prevEnd) ~/ 60000;
      if (gapMinutes <= 5) {
        consecutiveRun++;
        if (consecutiveRun >= _fatigueStackThreshold) {
          return const OptimisationRecommendation(
            ruleCode: 'B',
            description:
                '3+ high-enforcement tasks are scheduled back-to-back with no break.',
            preDraftedInput: 'Add a 15-minute break between my intense tasks',
          );
        }
      } else {
        consecutiveRun = 1;
      }
    }
    return null;
  }

  // ─── Rule C: Reminder noise ───────────────────────────────────────────────

  /// ≥4 reminders firing within any 30-minute window.
  Future<OptimisationRecommendation?> _checkReminderNoise(
    List<PlannedTaskRow> rows,
  ) async {
    try {
      final taskIds = rows.map((r) => r.task.id).toList();
      if (taskIds.isEmpty) return null;

      final reminders = await reminderRepository.getRemindersForTasks(taskIds);

      // Build a list of reminder fire times in minutes-from-midnight
      final times = <int>[];
      for (final r in reminders) {
        if (!r.enabled) continue;
        if (r.scheduledAtIso == null) continue;
        final dt = DateTime.tryParse(r.scheduledAtIso!)?.toLocal();
        if (dt == null) continue;
        times.add(dt.hour * 60 + dt.minute);
      }

      if (times.length < _reminderNoiseThreshold) return null;
      times.sort();

      // Sliding window check
      for (var i = 0; i <= times.length - _reminderNoiseThreshold; i++) {
        final window = times[i + _reminderNoiseThreshold - 1] - times[i];
        if (window <= _reminderNoiseWindowMinutes) {
          return const OptimisationRecommendation(
            ruleCode: 'C',
            description:
                '4+ reminders fire within a 30-minute window — spreading them could reduce notification overload.',
            preDraftedInput:
                'Spread out my reminders to avoid notification overload',
          );
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  int? _taskStartMs(dynamic task) {
    final iso = task.reminderTimeIso as String?;
    if (iso == null) return null;
    return DateTime.tryParse(iso)?.millisecondsSinceEpoch;
  }

  int? _taskEndMs(dynamic task) {
    final startMs = _taskStartMs(task);
    if (startMs == null) return null;
    final duration = (task.durationMinutes as int?) ?? 30;
    return startMs + duration * 60000;
  }
}
