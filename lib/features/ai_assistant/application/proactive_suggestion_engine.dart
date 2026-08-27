import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../goals/application/goal_period_helpers.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../../time_blocks/data/time_block_repository.dart';
import '../data/dismissed_suggestion_repository.dart';
import '../domain/models/proactive_suggestion.dart';
import 'proactive_chat_conversion_tracker.dart';
import '../domain/models/proactive_suggestion_analytics_summary.dart';
import 'entity_normaliser.dart';
import 'proactive_suggestion_display.dart';
import 'proactive_suggestion_source.dart';
import 'schedule_optimisation_service.dart';

/// Last computed weekly summary (in-memory, for internal tuning).
ProactiveSuggestionAnalyticsSummary? lastProactiveSuggestionAnalyticsSummary;

/// Generates proactive suggestion cards for today based on user history,
/// schedule gaps, and goal pace.
///
/// All suggestions are advisory — they only pre-fill Coach AI input.
/// Nothing is executed without explicit user confirmation.
class ProactiveSuggestionEngine implements ProactiveSuggestionSource {
  const ProactiveSuggestionEngine({
    required this.planningRepository,
    required this.goalsRepository,
    required this.timeBlockRepository,
    required this.dismissedRepo,
    required this.normaliser,
    required this.optimisationService,
  });

  final PlanningRepository planningRepository;
  final GoalsRepository goalsRepository;
  final TimeBlockRepository timeBlockRepository;
  final DismissedSuggestionRepository dismissedRepo;
  final EntityNormaliser normaliser;
  final ScheduleOptimisationService optimisationService;

  static const int _maxSuggestions = kCoachProactiveSuggestionLimit;
  static const int _recurringThresholdDays = 4;
  static const int _lookbackDays = 7;
  static const int _scheduleGapMinutes = 90;
  static const double _goalBehindPaceThreshold = 0.20;

  /// Generates up to 3 proactive suggestions for today and
  /// updates the weekly effectiveness summary in memory.
  Future<List<ProactiveSuggestion>> generateForToday() async {
    // One "Not now" hides the type for the rest of the day; 3 dismissals
    // in 7 days suppresses it for the week (2026-08-23 — previously only
    // the weekly rule existed, so the same card came back until the user
    // had tapped "Not now" three times).
    final suppressed = {
      ...await dismissedRepo.suppressedTypes(),
      ...await dismissedRepo.typesDismissedToday(),
    };
    final suggestions = <ProactiveSuggestion>[];

    // Run rules in parallel where possible
    final results = await Future.wait([
      _ruleRecurringTaskMissing(suppressed),
      _ruleScheduleGap(suppressed),
      _ruleGoalBehindPace(suppressed),
      _ruleOptimiseOrder(suppressed),
      _ruleScheduleOptimisation(suppressed),
    ]);

    for (final list in results) {
      suggestions.addAll(list);
    }

    // Two rules can emit the same advice (e.g. priority inversion fires
    // both the legacy rule and optimisation rule A) — keep the first of
    // each (type, title) pair so identical cards never stack.
    final seen = <String>{};
    final deduped = suggestions
        .where((s) => seen.add('${s.type.name}|${s.title}'))
        .toList();

    // Sort by confidence descending, cap at 3
    deduped.sort((a, b) => b.confidence.compareTo(a.confidence));
    final top = deduped.take(_maxSuggestions).toList();

    _updateAnalyticsSummary(top);
    return top;
  }

  void _updateAnalyticsSummary(List<ProactiveSuggestion> shown) {
    final byType = <String, int>{};
    for (final s in shown) {
      byType[s.type.name] = (byType[s.type.name] ?? 0) + 1;
    }
    final now = DateTime.now();
    final weekStart = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: now.weekday - 1));
    lastProactiveSuggestionAnalyticsSummary =
        ProactiveSuggestionAnalyticsSummary(
          weekStartKey: DateKeys.todayKey(weekStart),
          totalGenerated: shown.length,
          byType: byType,
          chatConversionsByType: ProactiveChatConversionTracker.snapshot(),
        );
  }

  // ─── Rule 1: Recurring task missing ────────────────────────────────────────

  Future<List<ProactiveSuggestion>> _ruleRecurringTaskMissing(
    Set<ProactiveSuggestionType> suppressed,
  ) async {
    if (suppressed.contains(ProactiveSuggestionType.recurringTaskMissing)) {
      return [];
    }
    try {
      final today = DateTime.now();
      final todayKey = DateKeys.todayKey();

      // Count how many days each category appeared in the last 7 days
      final categoryDayCount = <String, int>{};
      final categoryLastTitle = <String, String>{};
      final categoryLastTime = <String, String>{};

      for (var daysBack = 1; daysBack <= _lookbackDays; daysBack++) {
        final day = today.subtract(Duration(days: daysBack));
        final dateKey = DateKeys.todayKey(day);
        try {
          final rows = await collectTasksForDateKey(
            planningRepository,
            dateKey,
          );
          final seenCategories = <String>{};
          for (final row in rows) {
            final category = normaliser.normalise(row.task.title);
            if (!seenCategories.contains(category)) {
              seenCategories.add(category);
              categoryDayCount[category] =
                  (categoryDayCount[category] ?? 0) + 1;
              categoryLastTitle[category] = row.task.title;
              if (row.task.reminderTimeIso != null) {
                final dt = DateTime.tryParse(
                  row.task.reminderTimeIso!,
                )?.toLocal();
                if (dt != null) {
                  categoryLastTime[category] =
                      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                }
              }
            }
          }
        } catch (_) {
          continue;
        }
      }

      // Get today's tasks to check what's already scheduled
      final todayTasks = await collectTasksForDateKey(
        planningRepository,
        todayKey,
      );
      final todayCategories = todayTasks
          .map((r) => normaliser.normalise(r.task.title))
          .toSet();

      final suggestions = <ProactiveSuggestion>[];
      for (final entry in categoryDayCount.entries) {
        if (entry.value >= _recurringThresholdDays &&
            !todayCategories.contains(entry.key)) {
          final category = entry.key;
          final lastTitle = categoryLastTitle[category] ?? category;
          final lastTime = categoryLastTime[category];
          final preDrafted = lastTime != null
              ? 'Schedule $lastTitle at $lastTime'
              : 'Schedule $lastTitle today';

          suggestions.add(
            ProactiveSuggestion(
              id: StableId.generate('ps'),
              type: ProactiveSuggestionType.recurringTaskMissing,
              title: 'You usually schedule a $category session',
              description:
                  'It appeared on ${entry.value} of the last $_lookbackDays days but isn\'t on today\'s plan yet.',
              preDraftedInput: preDrafted,
              confidence: 0.85,
              generatedAt: DateTime.now(),
            ),
          );
        }
      }
      return suggestions;
    } catch (_) {
      return [];
    }
  }

  // ─── Rule 2: Schedule gap ───────────────────────────────────────────────────

  Future<List<ProactiveSuggestion>> _ruleScheduleGap(
    Set<ProactiveSuggestionType> suppressed,
  ) async {
    if (suppressed.contains(ProactiveSuggestionType.scheduleGap)) return [];
    try {
      final now = DateTime.now();
      final dayStart = DateTime(now.year, now.month, now.day, 6, 0);
      final dayEnd = DateTime(now.year, now.month, now.day, 22, 0);

      final blocks = await timeBlockRepository.listBlocksForDateRange(
        dayStart,
        dayEnd,
      );
      blocks.sort((a, b) => a.startAt.compareTo(b.startAt));

      final allGoals = await goalsRepository.fetchGoalsOnce();
      final goals = allGoals
          .where((g) => g.status == GoalStatus.active)
          .toList();
      if (goals.isEmpty) return [];

      // Find gaps > 90 min during the active day window
      final gaps = <(DateTime start, DateTime end)>[];
      var cursor = dayStart;
      for (final block in blocks) {
        if (block.startAt.isAfter(cursor)) {
          final gapMinutes = block.startAt.difference(cursor).inMinutes;
          if (gapMinutes >= _scheduleGapMinutes) {
            gaps.add((cursor, block.startAt));
          }
        }
        final blockEnd = block.startAt.add(
          Duration(minutes: block.expectedDurationMinutes),
        );
        if (blockEnd.isAfter(cursor)) cursor = blockEnd;
      }
      // Gap after last block
      if (cursor.isBefore(dayEnd)) {
        final remaining = dayEnd.difference(cursor).inMinutes;
        if (remaining >= _scheduleGapMinutes) gaps.add((cursor, dayEnd));
      }

      if (gaps.isEmpty) return [];

      final (gapStart, _) = gaps.first;
      final gapTimeStr =
          '${gapStart.hour.toString().padLeft(2, '0')}:${gapStart.minute.toString().padLeft(2, '0')}';
      final goal = goals.first;

      return [
        ProactiveSuggestion(
          id: StableId.generate('ps'),
          type: ProactiveSuggestionType.scheduleGap,
          title: 'You have a free slot at $gapTimeStr',
          description:
              'A ${_scheduleGapMinutes}+ min gap is available — '
              'great time to work on "${goal.title}".',
          preDraftedInput: 'Add ${goal.title} at $gapTimeStr for 60 minutes',
          confidence: 0.75,
          generatedAt: DateTime.now(),
        ),
      ];
    } catch (_) {
      return [];
    }
  }

  // ─── Rule 3: Goal behind pace ───────────────────────────────────────────────

  Future<List<ProactiveSuggestion>> _ruleGoalBehindPace(
    Set<ProactiveSuggestionType> suppressed,
  ) async {
    if (suppressed.contains(ProactiveSuggestionType.goalBehindPace)) return [];
    try {
      final allGoals = await goalsRepository.fetchGoalsOnce();
      final goals = allGoals
          .where((g) => g.status == GoalStatus.active)
          .toList();
      final suggestions = <ProactiveSuggestion>[];

      final now = DateTime.now();
      for (final goal in goals) {
        if (goal.status != GoalStatus.active) continue;

        // Pace is measured inside the goal's current evaluation window
        // (one repeat cycle, or the whole period for one-time goals) —
        // the same semantics the Goals surfaces use, so this card can
        // never contradict them (fix-wave Phase 0, §8 H7: progress used
        // to be hardcoded 0, accusing every on-track goal of being
        // "~elapsed% behind").
        final window = GoalPeriodHelpers.evaluationWindow(goal, now);
        final totalMs =
            window.end.millisecondsSinceEpoch -
            window.start.millisecondsSinceEpoch;
        if (totalMs <= 0) continue;

        final elapsedMs = now.millisecondsSinceEpoch -
            window.start.millisecondsSinceEpoch;
        final elapsedRatio = elapsedMs / totalMs;
        if (elapsedRatio <= 0 || elapsedRatio > 1.0) continue;

        final currentProgress = await _actualGoalProgress(goal, window);
        // No readable progress (target 0 / read failure) → say nothing
        // rather than fabricate a number.
        if (currentProgress == null) continue;
        final expectedProgress = elapsedRatio;
        final gap = expectedProgress - currentProgress;

        if (gap >= _goalBehindPaceThreshold) {
          final behindPct = (gap * 100).round();
          suggestions.add(
            ProactiveSuggestion(
              id: StableId.generate('ps'),
              type: ProactiveSuggestionType.goalBehindPace,
              title: '"${goal.title}" is behind schedule',
              description:
                  'You\'re ~$behindPct% behind the expected pace. '
                  'A short session today can help catch up.',
              preDraftedInput:
                  'Schedule ${goal.title} session today for 45 minutes',
              confidence: 0.80,
              generatedAt: DateTime.now(),
            ),
          );
        }
      }
      return suggestions;
    } catch (_) {
      return [];
    }
  }

  // ─── Rule 4: Optimise task order ────────────────────────────────────────────

  Future<List<ProactiveSuggestion>> _ruleOptimiseOrder(
    Set<ProactiveSuggestionType> suppressed,
  ) async {
    if (suppressed.contains(ProactiveSuggestionType.optimiseOrder)) return [];
    try {
      final todayKey = DateKeys.todayKey();
      final rows = await collectTasksForDateKey(planningRepository, todayKey);

      if (rows.length < 5) return [];

      // Check for priority inversion: high-priority task after a low-priority one
      // Priority is 1 (highest) to 5 (lowest); higher number = lower priority
      bool hasInversion = false;
      int? highestPrioritySeenSoFar;
      for (final row in rows) {
        final p = row.task.priority;
        if (highestPrioritySeenSoFar == null) {
          highestPrioritySeenSoFar = p;
          continue;
        }
        // If current is higher priority (lower number) than the highest seen
        if (p < highestPrioritySeenSoFar) {
          hasInversion = true;
          break;
        }
        if (p < highestPrioritySeenSoFar) highestPrioritySeenSoFar = p;
      }

      if (!hasInversion) return [];

      return [
        ProactiveSuggestion(
          id: StableId.generate('ps'),
          type: ProactiveSuggestionType.optimiseOrder,
          title: 'Some high-priority tasks are scheduled late',
          description:
              'Reordering could help you tackle the most important '
              'items while your energy is highest.',
          preDraftedInput: 'Move my most important tasks to the morning',
          confidence: 0.70,
          generatedAt: DateTime.now(),
        ),
      ];
    } catch (_) {
      return [];
    }
  }

  // ─── Rule 5: Schedule optimisation (Rules A/B/C) ─────────────────────────

  Future<List<ProactiveSuggestion>> _ruleScheduleOptimisation(
    Set<ProactiveSuggestionType> suppressed,
  ) async {
    if (suppressed.contains(ProactiveSuggestionType.optimiseOrder) &&
        suppressed.contains(ProactiveSuggestionType.lowEnergySlot)) {
      return [];
    }
    try {
      final todayKey = DateKeys.todayKey();
      final recommendations = await optimisationService.analyse(todayKey);

      return recommendations
          .map((rec) {
            final type = rec.ruleCode == 'A'
                ? ProactiveSuggestionType.optimiseOrder
                : ProactiveSuggestionType.lowEnergySlot;

            if (suppressed.contains(type)) return null;

            return ProactiveSuggestion(
              id: StableId.generate('ps'),
              type: type,
              title: _optimisationTitle(rec.ruleCode),
              description: rec.description,
              preDraftedInput: rec.preDraftedInput,
              confidence: rec.ruleCode == 'A' ? 0.72 : 0.68,
              generatedAt: DateTime.now(),
              optimisationRuleCode: rec.ruleCode,
            );
          })
          .whereType<ProactiveSuggestion>()
          .toList();
      // Note: scheduleOptimisationSuggested analytics is logged by
      // ProactiveSuggestionCard when the card renders.
    } catch (_) {
      return [];
    }
  }

  String _optimisationTitle(String ruleCode) {
    switch (ruleCode) {
      case 'A':
        return 'Some high-priority tasks are scheduled late';
      case 'B':
        return 'Several intense tasks are stacked back-to-back';
      case 'C':
        return 'Reminder notifications are clustered together';
      default:
        return 'Schedule optimisation available';
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  /// Real goal progress as a 0–1 ratio inside the current evaluation
  /// window: sum of check-in values over the window ÷ targetValue — the
  /// same accumulation `goalTodayProgressProvider` renders on the Goals
  /// surfaces. Returns null when no honest number exists (target 0,
  /// unreadable check-ins) so the caller stays silent instead of guessing.
  Future<double?> _actualGoalProgress(
    UserGoal goal,
    ({DateTime start, DateTime end}) window,
  ) async {
    final target = goal.targetValue;
    if (target <= 0) return null;
    try {
      final startKey = DateKeys.yyyymmdd(window.start);
      final endKey = DateKeys.yyyymmdd(window.end);
      final checkIns = await goalsRepository.getCheckInsForGoal(
        goal.id,
        startDateKey: startKey,
        endDateKey: endKey,
      );
      final currentValue = checkIns.fold<double>(
        0.0,
        (sum, c) => sum + (c.value ?? 0),
      );
      return (currentValue / target).clamp(0.0, 1.0);
    } catch (_) {
      return null;
    }
  }
}
