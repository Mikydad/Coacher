import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_action.dart';
import '../domain/models/assumption_result.dart';
import 'entity_normaliser.dart';

/// Infers pre-filled parameters for an incomplete [AiAction] by searching the
/// user's task history for a matching entity.
///
/// Pipeline (per action):
///  1. Normalise the action's entity name to a canonical category.
///  2. Search the last 30 days of tasks for the most recent match.
///  3. Score confidence; if ≥ 0.80 copy only the null fields.
///  4. Attach a human-readable reason label.
class AiAssumptionEngine {
  const AiAssumptionEngine({
    required this.planningRepository,
    required this.historyRepository,
    required this.normaliser,
  });

  final PlanningRepository planningRepository;
  final AiInteractionHistoryRepository historyRepository;
  final EntityNormaliser normaliser;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Infers parameters for a single [incompleteAction].
  Future<AssumptionResult> infer(AiAction incompleteAction) async {
    final rawTitle =
        incompleteAction.parameters['title']?.toString() ??
        incompleteAction.parameters['taskTitle']?.toString() ??
        '';

    if (rawTitle.isEmpty) return AssumptionResult.noMatch;

    final category = normaliser.normalise(rawTitle);

    // Search the last 30 days for matching tasks
    final match = await _findBestMatchingTask(rawTitle, category);
    if (match == null) return AssumptionResult.noMatch;

    final confidence = match.confidence;
    if (confidence < 0.80) {
      return AssumptionResult(
        confidence: confidence,
        suggestedParameters: const {},
        reasonLabel: '',
        source: AssumptionSource.taskHistory,
      );
    }

    // Build suggested parameters — only fill null fields
    final suggested = <String, dynamic>{};
    final params = incompleteAction.parameters;

    if (params['time'] == null && match.time != null) {
      suggested['time'] = match.time;
    }
    if (params['duration'] == null && match.durationMinutes != null) {
      suggested['duration'] = match.durationMinutes;
    }
    if (params['reminderOffset'] == null && match.reminderOffset != null) {
      suggested['reminderOffset'] = match.reminderOffset;
    }
    if (params['modeRefId'] == null && match.modeRefId != null) {
      suggested['modeRefId'] = match.modeRefId;
    }
    if (params['category'] == null) {
      suggested['category'] = category;
    }

    return AssumptionResult(
      confidence: confidence,
      suggestedParameters: suggested,
      reasonLabel: 'Based on your latest $category setup',
      source: AssumptionSource.taskHistory,
    );
  }

  /// Runs [infer] for all [actions] in parallel, preserving order.
  Future<List<AssumptionResult>> inferAll(List<AiAction> actions) {
    return Future.wait(actions.map(infer));
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<_TaskMatch?> _findBestMatchingTask(
    String rawTitle,
    String category,
  ) async {
    final today = DateTime.now();
    _TaskMatch? best;

    for (var daysBack = 0; daysBack < 30; daysBack++) {
      final day = today.subtract(Duration(days: daysBack));
      final dateKey =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

      List<PlannedTaskRow> rows;
      try {
        rows = await collectTasksForDateKey(planningRepository, dateKey);
      } catch (_) {
        continue;
      }

      for (final row in rows) {
        final task = row.task;
        final score = normaliser.similarityScore(rawTitle, task.title);

        // Boost for completed tasks
        final confidence = task.status.name == 'completed'
            ? (score >= 0.9 ? 0.95 : score >= 0.7 ? 0.80 : score)
            : (score >= 0.9 ? 0.80 : score >= 0.7 ? 0.65 : score);

        if (confidence < 0.65) continue;
        if (best == null || confidence > best.confidence) {
          String? timeStr;
          if (task.reminderTimeIso != null &&
              task.reminderTimeIso!.isNotEmpty) {
            final dt = DateTime.tryParse(task.reminderTimeIso!)?.toLocal();
            if (dt != null) {
              timeStr =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }
          }

          best = _TaskMatch(
            confidence: confidence,
            time: timeStr,
            durationMinutes: task.durationMinutes,
            modeRefId: task.modeRefId,
            reminderOffset: null, // stored on reminder model, not task
          );
        }
      }

      // Stop early if we already have a high-confidence match
      if (best != null && best.confidence >= 0.95) break;
    }

    return best;
  }
}

class _TaskMatch {
  const _TaskMatch({
    required this.confidence,
    this.time,
    this.durationMinutes,
    this.modeRefId,
    this.reminderOffset,
  });

  final double confidence;
  final String? time;
  final int? durationMinutes;
  final String? modeRefId;
  final int? reminderOffset;
}
