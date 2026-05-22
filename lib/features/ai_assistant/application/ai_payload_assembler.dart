import '../../../core/utils/date_keys.dart';
import '../../coaching/data/coaching_style_repository.dart';
import '../../context_override/data/context_override_repository.dart';
import '../../goals/data/goals_repository.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_operating_layer_payload.dart';

/// Assembles the [AiOperatingLayerPayload] from live app data.
///
/// Design rules:
/// - All values are human-readable; no raw IDs or internal references.
/// - Reading is best-effort: errors in one source never crash the whole assembly.
class AiPayloadAssembler {
  const AiPayloadAssembler({
    required this.planningRepository,
    required this.goalsRepository,
    required this.contextOverrideRepository,
    required this.coachingStyleRepository,
    required this.historyRepository,
  });

  final PlanningRepository planningRepository;
  final GoalsRepository goalsRepository;
  final ContextOverrideRepository contextOverrideRepository;
  final CoachingStyleRepository coachingStyleRepository;
  final AiInteractionHistoryRepository historyRepository;

  Future<AiOperatingLayerPayload> assemble(
    String userInput,
    String sessionId,
  ) async {
    final results = await Future.wait([
      _buildActiveTasks(),
      _buildGoals(),
      _buildTodaySchedule(),
      _buildFocusState(),
      _buildContextOverride(),
      _buildBehaviorPreferences(),
      _buildSessionHistory(sessionId),
    ]);

    return AiOperatingLayerPayload(
      userInput: userInput,
      activeTasks: results[0] as List<Map<String, dynamic>>,
      goals: results[1] as List<Map<String, dynamic>>,
      todaySchedule: results[2] as List<Map<String, dynamic>>,
      focusState: results[3] as Map<String, dynamic>,
      contextOverride: results[4] as Map<String, dynamic>?,
      behaviorPreferences: results[5] as Map<String, dynamic>,
      sessionHistory: results[6] as List<Map<String, dynamic>>,
    );
  }

  // ─── Private builders ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _buildActiveTasks() async {
    try {
      final rows = await collectTodayPlannedRows(planningRepository);
      return rows.map((row) {
        final t = row.task;
        String? timeStr;
        if (t.reminderTimeIso != null && t.reminderTimeIso!.isNotEmpty) {
          final dt = DateTime.tryParse(t.reminderTimeIso!)?.toLocal();
          if (dt != null) {
            timeStr =
                '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
          }
        }
        return {
          'title': t.title,
          'time': timeStr ?? 'no time set',
          'duration': '${t.durationMinutes} min',
          'status': t.status.name,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _buildGoals() async {
    try {
      final goals = await goalsRepository.fetchGoalsOnce();
      return goals
          .where((g) => g.status.name == 'active')
          .take(5)
          .map((g) {
            final deadline = DateTime.fromMillisecondsSinceEpoch(g.periodEndMs)
                .toLocal();
            final deadlineStr =
                '${deadline.year}-${deadline.month.toString().padLeft(2, '0')}-${deadline.day.toString().padLeft(2, '0')}';
            return {
              'title': g.title,
              'target': '${g.targetValue.toStringAsFixed(0)} ${g.customLabel ?? g.measurementKind.name}',
              'deadline': deadlineStr,
              'category': g.categoryId,
            };
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _buildTodaySchedule() async {
    // Today's time blocks come from active tasks with a set time — already in
    // _buildActiveTasks; return a filtered view of scheduled items only.
    try {
      final rows = await collectTodayPlannedRows(planningRepository);
      final scheduled = rows.where((r) {
        final iso = r.task.reminderTimeIso;
        return iso != null && iso.isNotEmpty;
      }).toList();

      return scheduled.map((row) {
        final t = row.task;
        final dt = DateTime.tryParse(t.reminderTimeIso!)?.toLocal();
        final startStr = dt != null
            ? '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}'
            : '?';
        final endDt = dt?.add(Duration(minutes: t.durationMinutes));
        final endStr = endDt != null
            ? '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}'
            : '?';
        return {
          'title': t.title,
          'startTime': startStr,
          'endTime': endStr,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _buildFocusState() async {
    // Focus state will be enriched in Phase 3; return minimal data for now.
    return {'date': DateKeys.todayKey()};
  }

  Future<Map<String, dynamic>?> _buildContextOverride() async {
    try {
      final state = await contextOverrideRepository.getAttentionState();
      if (state == null) return null;
      final override = state.activeOverride;
      if (override.name == 'none') return null;
      return {
        'type': override.name,
        'expiresAt': state.overrideExpiresAt?.toIso8601String(),
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _buildBehaviorPreferences() async {
    try {
      final profile = await coachingStyleRepository.getProfile();
      return {
        'coachingStyle': profile?.coachingStyle.name ?? 'balanced',
      };
    } catch (_) {
      return {'coachingStyle': 'balanced'};
    }
  }

  Future<List<Map<String, dynamic>>> _buildSessionHistory(
    String sessionId,
  ) async {
    try {
      final entries =
          await historyRepository.getRecentForSession(sessionId, limit: 10);
      // Build alternating user / assistant pairs for context
      final history = <Map<String, dynamic>>[];
      for (final e in entries.reversed) {
        history.add({'role': 'user', 'content': e.userInput});
        // We don't store the AI response text directly; skip assistant turns
        // until Phase 3 introduces full turn storage.
      }
      return history;
    } catch (_) {
      return [];
    }
  }
}
