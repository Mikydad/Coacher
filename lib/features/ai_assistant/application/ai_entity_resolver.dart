import '../../../core/utils/date_keys.dart';
import '../../../core/utils/friendly_date.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../domain/models/ai_action.dart';

/// Resolves entity-targeting actions (edit/move/delete task, modify/delete
/// goal, remove reminder) to concrete Isar ids at PREVIEW time — before the
/// user confirms anything (fix-wave Phase 1, the keystone of §8 E1/E2).
///
/// Settled semantics (Q2, decision log 2026-08-27):
/// - a unique match at ≥0.8 resolves silently; the card then shows the
///   REAL matched title, so the confirm gate covers a wrong guess;
/// - zero or multiple matches ask a LOCAL question (no model call, no
///   quota) listing the candidates;
/// - an undated reference searches today → tomorrow → the rest of this
///   week, and asks only when matches span several days.
///
/// Matching is deliberately stricter than [EntityNormaliser.similarityScore]:
/// its category tier scores "call mom" vs "Call with investors" at 0.9
/// (both 'work'), which is fine for assumption hints but disastrous for
/// picking a deletion target. Here only exact, containment, and
/// all-query-words matches count.
class AiEntityResolver {
  const AiEntityResolver({
    required this.planningRepository,
    required this.goalsRepository,
  });

  final PlanningRepository planningRepository;
  final GoalsRepository goalsRepository;

  /// Action kinds that target an existing task by title.
  static const taskTargetKinds = {
    ActionType.editTask,
    ActionType.moveTask,
    ActionType.deleteTask,
    ActionType.removeReminder,
  };

  /// Action kinds that target an existing goal by title.
  static const goalTargetKinds = {
    ActionType.modifyGoal,
    ActionType.deleteGoal,
  };

  /// Resolves every targeting action in [actions]. Returns either the
  /// resolved list (params stamped with `_resolvedTaskId`/`_resolvedGoalId`
  /// + location keys, titles rewritten to the matched entity) or a local
  /// disambiguation question.
  Future<EntityResolution> resolve(List<AiAction> actions) async {
    final resolved = <AiAction>[];
    for (final action in actions) {
      if (taskTargetKinds.contains(action.actionType)) {
        final outcome = await _resolveTask(action);
        if (outcome is _Question) return EntityResolutionQuestion(outcome.text);
        resolved.add((outcome as _Resolved).action);
      } else if (goalTargetKinds.contains(action.actionType)) {
        final outcome = await _resolveGoal(action);
        if (outcome is _Question) return EntityResolutionQuestion(outcome.text);
        resolved.add((outcome as _Resolved).action);
      } else {
        resolved.add(action);
      }
    }
    return EntityResolutionOk(resolved);
  }

  // ─── Tasks ──────────────────────────────────────────────────────────────────

  Future<_Outcome> _resolveTask(AiAction action) async {
    final ref =
        (action.parameters['taskTitle'] as String?)?.trim() ??
        (action.parameters['title'] as String?)?.trim() ??
        '';
    if (ref.isEmpty) {
      return const _Question(
        'Which task do you mean? Give me its name and I\'ll take it from '
        'there.',
      );
    }

    // Nearest day wins: the explicit date (when given) is searched first,
    // then today → tomorrow → the rest of the week. The first day with any
    // match settles the scope — an undated "delete my workout" means
    // today's workout even when tomorrow has one too; ambiguity WITHIN a
    // day still asks.
    final dateParam = action.parameters['date'] as String?;
    final candidates = <_TaskCandidate>[];
    for (final dateKey in _searchDateKeys(dateParam)) {
      final rows = await collectTasksForDateKey(planningRepository, dateKey);
      for (final row in rows) {
        final score = matchScore(ref, row.task.title);
        if (score >= 0.8) {
          candidates.add(_TaskCandidate(row, dateKey, score));
        }
      }
      if (candidates.isNotEmpty) break;
    }

    if (candidates.isEmpty) {
      return _Question(
        'I couldn\'t find a task called "$ref" on this week\'s plan. '
        'Which task did you mean?',
      );
    }

    // Prefer the best score; ties across entities need the user.
    candidates.sort((a, b) => b.score.compareTo(a.score));
    final best = candidates.first;
    final rivals = candidates
        .where((c) => c.row.task.id != best.row.task.id)
        .where((c) => (best.score - c.score) < 0.05)
        .toList();
    if (rivals.isNotEmpty) {
      final options = <_TaskCandidate>[best, ...rivals.take(3)];
      final listed = options
          .map((c) => '"${c.row.task.title}" (${_describeWhen(c)})')
          .join(' or ');
      return _Question('Which one did you mean: $listed?');
    }

    final p = Map<String, dynamic>.from(action.parameters);
    p['_resolvedTaskId'] = best.row.task.id;
    p['_resolvedRoutineId'] = best.row.routineId;
    p['_resolvedBlockId'] = best.row.blockId;
    p['_resolvedDateKey'] = best.dateKey;
    // The card must show what was actually matched, not the model's guess.
    if (action.actionType == ActionType.editTask) {
      p['title'] = best.row.task.title;
    } else {
      p['taskTitle'] = best.row.task.title;
    }
    return _Resolved(action.copyWith(parameters: p));
  }

  List<String> _searchDateKeys(String? dateParam) {
    final now = DateTime.now();
    final keys = <String>[
      if (dateParam != null && dateParam.trim().isNotEmpty)
        _dateKeyFor(dateParam),
      for (var offset = 0; offset < 7; offset++)
        DateKeys.yyyymmdd(DateTime(now.year, now.month, now.day + offset)),
    ];
    final seen = <String>{};
    return [
      for (final k in keys)
        if (seen.add(k)) k,
    ];
  }

  String _dateKeyFor(String raw) {
    if (raw == 'today') return DateKeys.todayKey();
    if (raw == 'tomorrow') return DateKeys.tomorrowKey();
    return raw;
  }

  String _describeWhen(_TaskCandidate c) {
    final time = c.row.task.reminderTimeIso;
    final day = friendlyDateKey(c.dateKey);
    if (time == null) return day;
    final dt = DateTime.tryParse(time);
    if (dt == null) return day;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$day $hh:$mm';
  }

  // ─── Goals ──────────────────────────────────────────────────────────────────

  Future<_Outcome> _resolveGoal(AiAction action) async {
    final ref = (action.parameters['goalTitle'] as String?)?.trim() ?? '';
    if (ref.isEmpty) {
      return const _Question(
        'Which goal do you mean? Give me its name and I\'ll take it from '
        'there.',
      );
    }

    final goals = (await goalsRepository.fetchGoalsOnce())
        .where((g) => g.status == GoalStatus.active)
        .toList();
    final scored = [
      for (final g in goals)
        if (matchScore(ref, g.title) >= 0.8)
          (goal: g, score: matchScore(ref, g.title)),
    ]..sort((a, b) => b.score.compareTo(a.score));

    if (scored.isEmpty) {
      return _Question(
        'I couldn\'t find an active goal called "$ref". '
        'Which goal did you mean?',
      );
    }
    final best = scored.first;
    final rivals = scored
        .where((s) => s.goal.id != best.goal.id)
        .where((s) => (best.score - s.score) < 0.05)
        .toList();
    if (rivals.isNotEmpty) {
      final listed = [best, ...rivals.take(3)]
          .map((s) => '"${s.goal.title}"')
          .join(' or ');
      return _Question('Which goal did you mean: $listed?');
    }

    final p = Map<String, dynamic>.from(action.parameters);
    p['_resolvedGoalId'] = best.goal.id;
    p['goalTitle'] = best.goal.title;
    return _Resolved(action.copyWith(parameters: p));
  }

  // ─── Matching ───────────────────────────────────────────────────────────────

  /// Targeting-grade similarity: 1.0 exact (cleaned), 0.85 whole-string
  /// containment ("gym" ↔ "Gym session"), 0.8 when every >2-char query word
  /// appears in the candidate. No category tier — see the class doc.
  static double matchScore(String query, String candidateTitle) {
    final q = _clean(query);
    final c = _clean(candidateTitle);
    if (q.isEmpty || c.isEmpty) return 0;
    if (q == c) return 1.0;
    if (c.contains(q) || q.contains(c)) return 0.85;
    final qWords = q.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    final cWords = c.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    if (qWords.isNotEmpty && cWords.containsAll(qWords)) return 0.8;
    return 0;
  }

  static String _clean(String raw) =>
      raw.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
}

// ─── Results ──────────────────────────────────────────────────────────────────

sealed class EntityResolution {
  const EntityResolution();
}

class EntityResolutionOk extends EntityResolution {
  const EntityResolutionOk(this.actions);
  final List<AiAction> actions;
}

/// A LOCAL disambiguation question — costs no model call and no quota.
class EntityResolutionQuestion extends EntityResolution {
  const EntityResolutionQuestion(this.question);
  final String question;
}

sealed class _Outcome {
  const _Outcome();
}

class _Resolved extends _Outcome {
  const _Resolved(this.action);
  final AiAction action;
}

class _Question extends _Outcome {
  const _Question(this.text);
  final String text;
}

class _TaskCandidate {
  const _TaskCandidate(this.row, this.dateKey, this.score);
  final PlannedTaskRow row;
  final String dateKey;
  final double score;
}
