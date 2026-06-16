import '../../../core/utils/date_keys.dart';
import '../../coaching/data/coaching_style_repository.dart';
import '../../context_override/data/context_override_repository.dart';
import '../../goals/application/goal_period_helpers.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_check_in.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../../profile/application/profile_preference_service.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_intent_kind.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import 'ai_capability_registry.dart';
import 'entity_normaliser.dart';

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
    this.profilePreferenceService,
    EntityNormaliser? normaliser,
  }) : _normaliser = normaliser ?? const EntityNormaliser();

  final PlanningRepository planningRepository;
  final GoalsRepository goalsRepository;
  final ContextOverrideRepository contextOverrideRepository;
  final CoachingStyleRepository coachingStyleRepository;
  final AiInteractionHistoryRepository historyRepository;
  final ProfilePreferenceService? profilePreferenceService;
  final EntityNormaliser _normaliser;

  Future<AiOperatingLayerPayload> assemble(
    String userInput,
    String sessionId, {
    String? previousPlanSummary,
    AiIntentRoute? intentRoute,
    Map<String, dynamic>? proactiveContext,
  }) async {
    final results = await Future.wait([
      _buildActiveTasks(),
      _buildGoals(),
      _buildGoalProgress(),
      _buildTodaySchedule(),
      _buildTomorrowTasks(),
      _buildTomorrowSchedule(),
      _buildWeekOverview(),
      _buildFocusState(),
      _buildContextOverride(),
      _buildBehaviorPreferences(),
      _buildSessionHistory(sessionId),
      _buildRecentPatterns(),
      buildConversationHistory(sessionId),
      _buildCompletedInSession(sessionId),
    ]);

    return AiOperatingLayerPayload(
      userInput: userInput,
      activeTasks: results[0] as List<Map<String, dynamic>>,
      goals: results[1] as List<Map<String, dynamic>>,
      goalProgress: results[2] as List<Map<String, dynamic>>,
      todaySchedule: results[3] as List<Map<String, dynamic>>,
      tomorrowTasks: results[4] as List<Map<String, dynamic>>,
      tomorrowSchedule: results[5] as List<Map<String, dynamic>>,
      weekOverview: results[6] as List<Map<String, dynamic>>,
      focusState: results[7] as Map<String, dynamic>,
      contextOverride: results[8] as Map<String, dynamic>?,
      behaviorPreferences: results[9] as Map<String, dynamic>,
      sessionHistory: results[10] as List<Map<String, dynamic>>,
      recentPatterns: results[11] as List<Map<String, dynamic>>,
      conversationHistory: results[12] as List<Map<String, dynamic>>,
      completedInSession: results[13] as List<String>,
      capabilities: AiCapabilityRegistry.buildPayloadSection(),
      intentHint: intentRoute?.toPromptHint(),
      proactiveContext: proactiveContext,
      previousPlan: previousPlanSummary,
    );
  }

  // ─── Private builders ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _buildActiveTasks() async {
    try {
      final rows = await collectTodayPlannedRows(planningRepository);
      return _taskMapsFromRows(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _buildTomorrowTasks() async {
    try {
      final rows = await collectTasksForDateKey(
        planningRepository,
        DateKeys.tomorrowKey(),
      );
      return _taskMapsFromRows(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _buildTodaySchedule() async {
    try {
      final rows = await collectTodayPlannedRows(planningRepository);
      return _scheduleMapsFromRows(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _buildTomorrowSchedule() async {
    try {
      final rows = await collectTasksForDateKey(
        planningRepository,
        DateKeys.tomorrowKey(),
      );
      return _scheduleMapsFromRows(rows);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _buildWeekOverview() async {
    try {
      final today = DateTime.now();
      final dayFutures = <Future<Map<String, dynamic>>>[];
      for (var offset = 0; offset < 7; offset++) {
        final day = today.add(Duration(days: offset));
        dayFutures.add(_buildDayOverview(day, offset));
      }
      return await Future.wait(dayFutures);
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _buildDayOverview(
    DateTime day,
    int offsetFromToday,
  ) async {
    final dateKey = DateKeys.yyyymmdd(day);
    try {
      final rows = await collectTasksForDateKey(planningRepository, dateKey);
      var scheduledCount = 0;
      for (final row in rows) {
        final time = row.task.reminderTimeIso;
        if (time != null && time.isNotEmpty) scheduledCount++;
      }
      return {
        'date': dateKey,
        'label': _weekDayLabel(offsetFromToday, day),
        'taskCount': rows.length,
        'scheduledCount': scheduledCount,
      };
    } catch (_) {
      return {
        'date': dateKey,
        'label': _weekDayLabel(offsetFromToday, day),
        'taskCount': 0,
        'scheduledCount': 0,
      };
    }
  }

  static String _weekDayLabel(int offsetFromToday, DateTime day) {
    if (offsetFromToday == 0) return 'today';
    if (offsetFromToday == 1) return 'tomorrow';
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[day.weekday - 1];
  }

  List<Map<String, dynamic>> _taskMapsFromRows(List<PlannedTaskRow> rows) {
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
      final durationLabel = t.durationMinutes >= 1
          ? '${t.durationMinutes} min'
          : 'reminder only';
      return {
        'title': t.title,
        'time': timeStr ?? 'no time set',
        'duration': durationLabel,
        'status': t.status.name,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _scheduleMapsFromRows(List<PlannedTaskRow> rows) {
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
      final endDt = dt != null && t.durationMinutes >= 1
          ? dt.add(Duration(minutes: t.durationMinutes))
          : null;
      final endStr = endDt != null
          ? '${endDt.hour.toString().padLeft(2, '0')}:${endDt.minute.toString().padLeft(2, '0')}'
          : '?';
      return {
        'title': t.title,
        'startTime': startStr,
        'endTime': endStr,
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _buildGoals() async {
    try {
      final goals = await goalsRepository.fetchGoalsOnce();
      return goals
          .where((g) => g.status == GoalStatus.active)
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

  Future<List<Map<String, dynamic>>> _buildGoalProgress() async {
    try {
      final goals = await goalsRepository.fetchGoalsOnce();
      final active = goals.where((g) => g.status == GoalStatus.active).take(5);
      final now = DateTime.now();
      final progress = <Map<String, dynamic>>[];

      for (final g in active) {
        final periodStart = DateTime.fromMillisecondsSinceEpoch(g.periodStartMs)
            .toLocal();
        final periodEnd = DateTime.fromMillisecondsSinceEpoch(g.periodEndMs)
            .toLocal();

        List<GoalCheckIn> checkIns;
        try {
          checkIns = await goalsRepository.getCheckInsForGoal(
            g.id,
            startDateKey: DateKeys.yyyymmdd(periodStart),
            endDateKey: DateKeys.yyyymmdd(periodEnd),
          );
        } catch (_) {
          checkIns = const [];
        }

        progress.add({
          'title': g.title,
          'target':
              '${g.targetValue.toStringAsFixed(0)} ${g.customLabel ?? g.measurementKind.name}',
          'periodSummary': GoalPeriodHelpers.formatPeriodSummary(g),
          'daysMet': GoalPeriodHelpers.countMetCheckIns(checkIns),
          'daysElapsed': GoalPeriodHelpers.daysElapsedInPeriodThrough(g, now),
          'totalDays': GoalPeriodHelpers.totalCalendarDaysInPeriod(g),
        });
      }

      return progress;
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> _buildFocusState() async {
    try {
      final state = await contextOverrideRepository.getAttentionState();
      if (state == null || !state.hasActiveOverride) {
        return {'date': DateKeys.todayKey(), 'isActive': false};
      }

      final override = state.activeOverride;
      final expiresAt = state.overrideExpiresAt?.toLocal();
      final endsAtStr = expiresAt != null
          ? '${expiresAt.hour.toString().padLeft(2, '0')}:${expiresAt.minute.toString().padLeft(2, '0')}'
          : null;

      return {
        'date': DateKeys.todayKey(),
        'isActive': true,
        'type': override.name,
        if (endsAtStr != null) 'endsAt': endsAtStr,
      };
    } catch (_) {
      return {'date': DateKeys.todayKey(), 'isActive': false};
    }
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
      final coachingStyle = profile?.coachingStyle.name ?? 'balanced';

      String defaultEnforcementMode = 'disciplined';
      if (profilePreferenceService != null) {
        try {
          final pref = await profilePreferenceService!.getPreference();
          defaultEnforcementMode =
              pref?.defaultEnforcementMode.name ?? 'disciplined';
        } catch (_) {}
      }

      // Compute behaviour stats from last 7 days
      final stats = await _buildBehaviourStats();

      return {
        'coachingStyle': coachingStyle,
        'defaultEnforcementMode': defaultEnforcementMode,
        ...stats,
      };
    } catch (_) {
      return {
        'coachingStyle': 'balanced',
        'defaultEnforcementMode': 'disciplined',
      };
    }
  }

  /// Computes average tasks/day, most active hour, and most-used enforcement mode
  /// over the last 7 days, for inclusion in [behaviorPreferences].
  Future<Map<String, dynamic>> _buildBehaviourStats() async {
    try {
      final today = DateTime.now();
      var totalTasks = 0;
      final hourCounts = <int, int>{};
      final modeCounts = <String, int>{};

      for (var daysBack = 0; daysBack < 7; daysBack++) {
        final day = today.subtract(Duration(days: daysBack));
        final dateKey =
            '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';

        List<PlannedTaskRow> rows;
        try {
          rows = await collectTasksForDateKey(planningRepository, dateKey);
        } catch (_) {
          continue;
        }

        totalTasks += rows.length;

        for (final row in rows) {
          final task = row.task;
          if (task.reminderTimeIso != null &&
              task.reminderTimeIso!.isNotEmpty) {
            final dt = DateTime.tryParse(task.reminderTimeIso!)?.toLocal();
            if (dt != null) {
              hourCounts[dt.hour] = (hourCounts[dt.hour] ?? 0) + 1;
            }
          }
          if (task.modeRefId != null) {
            modeCounts[task.modeRefId!] =
                (modeCounts[task.modeRefId!] ?? 0) + 1;
          }
        }
      }

      final avgPerDay = (totalTasks / 7).round();

      String? mostActiveHour;
      if (hourCounts.isNotEmpty) {
        final topHour = hourCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
        mostActiveHour =
            '${topHour.toString().padLeft(2, '0')}:00';
      }

      String? mostUsedMode;
      if (modeCounts.isNotEmpty) {
        mostUsedMode = modeCounts.entries
            .reduce((a, b) => a.value > b.value ? a : b)
            .key;
      }

      return {
        'averageTasksPerDay': avgPerDay,
        if (mostActiveHour != null) 'mostActiveHour': mostActiveHour,
        if (mostUsedMode != null) 'mostUsedEnforcementMode': mostUsedMode,
      };
    } catch (_) {
      return {};
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

  /// Summaries of plans already confirmed/executed in this Coach session.
  Future<List<String>> _buildCompletedInSession(String sessionId) async {
    try {
      final entries =
          await historyRepository.getRecentForSession(sessionId, limit: 10);
      final lines = <String>[];
      for (final e in entries.reversed) {
        if (!e.executed) continue;
        final summary = e.assistantSummary?.trim();
        if (summary != null && summary.isNotEmpty) {
          lines.add(summary);
        }
      }
      return lines;
    } catch (_) {
      return [];
    }
  }

  /// Phase 3: Full conversation history as proper user/assistant message pairs.
  ///
  /// Reads the last 10 interactions for this session and formats them as
  /// OpenAI-compatible role/content messages. When assistantSummary is stored
  /// on the entry (Phase 3+ persistence), it becomes the assistant turn.
  Future<List<Map<String, dynamic>>> buildConversationHistory(
    String sessionId,
  ) async {
    try {
      final entries =
          await historyRepository.getRecentForSession(sessionId, limit: 10);
      final history = <Map<String, dynamic>>[];
      for (final e in entries.reversed) {
        history.add({'role': 'user', 'content': e.userInput});
        // If an assistant summary is stored, include it as the assistant turn
        final summary = e.assistantSummary;
        if (summary != null && summary.isNotEmpty) {
          history.add({'role': 'assistant', 'content': summary});
        }
      }
      return history;
    } catch (_) {
      return [];
    }
  }

  /// Builds the top-5 recurring activity patterns from the last 14 days.
  ///
  /// Groups tasks by normalised category; for each category returns:
  ///   { category, lastUsedTime, lastUsedDuration (min), frequency }
  Future<List<Map<String, dynamic>>> _buildRecentPatterns() async {
    try {
      final today = DateTime.now();

      // category → { count, lastTime, lastDuration }
      final categoryData = <String, _CategoryStats>{};

      for (var daysBack = 0; daysBack < 14; daysBack++) {
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
          final rawLabel = task.category ?? task.title;
          final category = _normaliser.normalise(rawLabel);

          String? timeStr;
          if (task.reminderTimeIso != null &&
              task.reminderTimeIso!.isNotEmpty) {
            final dt = DateTime.tryParse(task.reminderTimeIso!)?.toLocal();
            if (dt != null) {
              timeStr =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            }
          }

          final existing = categoryData[category];
          if (existing == null) {
            categoryData[category] = _CategoryStats(
              count: 1,
              lastTime: timeStr,
              totalDuration: task.durationMinutes,
              durationCount: 1,
            );
          } else {
            categoryData[category] = existing.copyWith(
              count: existing.count + 1,
              // Keep most recent time (daysBack == 0 is today)
              lastTime: daysBack == 0 ? (timeStr ?? existing.lastTime) : existing.lastTime,
              totalDuration: existing.totalDuration + task.durationMinutes,
              durationCount: existing.durationCount + 1,
            );
          }
        }
      }

      // Sort by frequency, take top 5
      final sorted = categoryData.entries.toList()
        ..sort((a, b) => b.value.count.compareTo(a.value.count));

      return sorted.take(5).map((e) {
        final stats = e.value;
        final avgDuration = stats.durationCount > 0
            ? (stats.totalDuration / stats.durationCount).round()
            : null;
        return <String, dynamic>{
          'category': e.key,
          if (stats.lastTime != null) 'lastUsedTime': stats.lastTime,
          if (avgDuration != null) 'lastUsedDuration': '$avgDuration min',
          'frequency': stats.count,
        };
      }).toList();
    } catch (_) {
      return [];
    }
  }
}

// ─── Internal helper ──────────────────────────────────────────────────────────

class _CategoryStats {
  const _CategoryStats({
    required this.count,
    required this.lastTime,
    required this.totalDuration,
    required this.durationCount,
  });

  final int count;
  final String? lastTime;
  final int totalDuration;
  final int durationCount;

  _CategoryStats copyWith({
    int? count,
    String? lastTime,
    int? totalDuration,
    int? durationCount,
  }) {
    return _CategoryStats(
      count: count ?? this.count,
      lastTime: lastTime ?? this.lastTime,
      totalDuration: totalDuration ?? this.totalDuration,
      durationCount: durationCount ?? this.durationCount,
    );
  }
}
