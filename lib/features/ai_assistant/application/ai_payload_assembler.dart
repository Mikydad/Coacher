import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/context/context_snapshot_service.dart';
import '../../../core/scheduling/free_window_calculator.dart';
import '../../../core/utils/date_keys.dart';
import '../../time_blocks/data/time_block_repository.dart';
import '../../goals/application/goal_progress_math.dart';
import '../../goals/domain/models/user_goal.dart';
import '../../coaching/data/coaching_style_repository.dart';
import '../../context_override/data/context_override_repository.dart';
import '../../goals/data/goals_repository.dart';
import '../../goals/domain/models/goal_check_in.dart';
import '../../goals/domain/models/goal_enums.dart';
import '../../direction/data/direction_repository.dart';
import '../../direction/domain/direction_context_lines.dart';
import '../../time_tracker/data/activity_event_repository.dart';
import '../../time_tracker/domain/day_summary.dart';
import '../../time_tracker/domain/timeline_builder.dart';
import '../../time_tracker/domain/timeline_text.dart';
import '../../intentions/data/intentions_repository.dart';
import '../../intentions/domain/models/intention.dart';
import '../../memory/data/memory_facts_repository.dart';
import '../../memory/data/people_repository.dart';
import '../../memory/domain/models/memory_fact.dart';
import '../../memory/domain/models/person.dart';
import '../../planning/application/planned_task_collect.dart';
import '../../planning/data/planning_repository.dart';
import '../../profile/application/profile_preference_service.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_intent_kind.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import 'entity_normaliser.dart';

/// Assembles the [AiOperatingLayerPayload] from live app data.
///
/// Design rules:
/// - All values are human-readable; no raw IDs or internal references.
/// - Reading is best-effort: errors in one source never crash the whole assembly.
class AiPayloadAssembler {
  AiPayloadAssembler({
    required this.planningRepository,
    required this.goalsRepository,
    required this.contextOverrideRepository,
    required this.coachingStyleRepository,
    required this.historyRepository,
    this.profilePreferenceService,
    this.memoryFactsRepository,
    this.peopleRepository,
    this.intentionsRepository,
    this.directionRepository,
    this.activityEventRepository,
    this.contextSnapshotService,
    this.timeBlockRepository,
    EntityNormaliser? normaliser,
    Duration scheduleCacheTtl = const Duration(seconds: 30),
  }) : _normaliser = normaliser ?? const EntityNormaliser(),
       _scheduleCacheTtl = scheduleCacheTtl;

  final PlanningRepository planningRepository;
  final GoalsRepository goalsRepository;
  final ContextOverrideRepository contextOverrideRepository;
  final CoachingStyleRepository coachingStyleRepository;
  final AiInteractionHistoryRepository historyRepository;
  final ProfilePreferenceService? profilePreferenceService;
  final MemoryFactsRepository? memoryFactsRepository;
  final PeopleRepository? peopleRepository;
  final IntentionsRepository? intentionsRepository;

  /// Direction (2026-09-11): the user's year/quarter/month focus lines —
  /// per-turn (never session-cached: the user can edit it mid-session).
  final DirectionRepository? directionRepository;

  /// Time Tracker (V1.1): today's timeline, per-turn — the day's truth.
  final ActivityEventRepository? activityEventRepository;

  /// Phase 4b: coarse device-context labels ("free_25m") — never raw
  /// signals — join the prompt when available.
  final ContextSnapshotService? contextSnapshotService;

  /// Goal time blocks (fix plan Phase 3.2): scheduled goal work is busy
  /// time too; the old free windows saw planned tasks only.
  final TimeBlockRepository? timeBlockRepository;
  final EntityNormaliser _normaliser;
  final Duration _scheduleCacheTtl;

  final Map<String, _CachedScheduleSlice> _scheduleCache = {};

  /// Clears cached schedule data after the user confirms plan changes.
  void invalidateSessionCache(String sessionId) {
    _scheduleCache.remove(sessionId);
  }

  Future<AiOperatingLayerPayload> assemble(
    String userInput,
    String sessionId, {
    String? previousPlanSummary,
    AiIntentRoute? intentRoute,
    Map<String, dynamic>? proactiveContext,
    String? featureGuideText,
    bool voiceMode = false,
  }) async {
    final schedule = await _scheduleSliceForSession(sessionId);

    final dynamicResults = await Future.wait([
      _buildSessionHistory(sessionId),
      buildConversationHistory(sessionId),
      _buildCompletedInSession(sessionId),
      // Memory sections are per-turn (never session-cached): rememberFact /
      // updateFact / forgetFact auto-commit mid-session and the local write
      // IS the update.
      _buildMemoryFacts(userInput),
      _buildPeopleDigest(),
      _buildEpisodicSummaries(),
      _buildOpenPromises(),
      _buildDeviceContext(),
      _buildDirection(),
      _buildTodayActivityLog(),
    ]);

    // Route-conditioned trimming (fix-wave Phase 6, §8 M7/P3): a bare
    // "hi" used to ship the full week overview and 14-day patterns to
    // OpenAI every turn. Sections a turn cannot use are dropped from the
    // SENT payload — the slice itself stays whole in the session cache, so
    // a follow-up that needs more pays no extra reads. Suggest/mutate
    // turns keep everything: planning needs the full picture.
    final focus = intentRoute?.focusDate;
    final planningTurn = intentRoute == null || intentRoute.isPlanningTurn;
    final sendWeek = planningTurn || focus == AiFocusDate.week;
    // Tomorrow is ALWAYS sent (fix plan Phase 3.3): trimming it on query
    // turns and then printing "Tomorrow's tasks: (none)" told the model a
    // planned day was empty (review §1.1 #5). Week counts and 14-day
    // patterns stay planning-only.
    final sendPatterns = planningTurn;

    return AiOperatingLayerPayload(
      userInput: userInput,
      activeTasks: schedule.activeTasks,
      goals: schedule.goals,
      goalProgress: schedule.goalProgress,
      todaySchedule: schedule.todaySchedule,
      tomorrowTasks: schedule.tomorrowTasks,
      tomorrowSchedule: schedule.tomorrowSchedule,
      weekOverview: sendWeek ? schedule.weekOverview : const [],
      focusState: schedule.focusState,
      contextOverride: schedule.contextOverride,
      behaviorPreferences: schedule.behaviorPreferences,
      sessionHistory: dynamicResults[0] as List<Map<String, dynamic>>,
      recentPatterns: sendPatterns ? schedule.recentPatterns : const [],
      conversationHistory: dynamicResults[1] as List<Map<String, dynamic>>,
      completedInSession: dynamicResults[2] as List<String>,
      intentHint: intentRoute?.toPromptHint(),
      intentKind: intentRoute?.kind.name,
      proactiveContext: proactiveContext,
      previousPlan: previousPlanSummary,
      featureGuide: featureGuideText,
      // Free windows come from the day's whole busy picture — tasks with a
      // duration, goal blocks, calendar busy intervals — inside the user's
      // waking bounds (Phase 3.2, D3).
      todayFreeWindows: FreeWindowCalculator.computeFormatted(
        schedule.todayBusy,
        fromMinuteOfDay: _nowMinuteOfDay(),
        dayStart: schedule.wakingStartMinute,
        dayEnd: schedule.wakingEndMinute,
      ),
      tomorrowFreeWindows: FreeWindowCalculator.computeFormatted(
        schedule.tomorrowBusy,
        dayStart: schedule.wakingStartMinute,
        dayEnd: schedule.wakingEndMinute,
      ),
      todayCalendarAvailable: schedule.todayCalendarAvailable,
      tomorrowCalendarAvailable: schedule.tomorrowCalendarAvailable,
      wakingWindow:
          '${FreeWindowCalculator.formatMinute(schedule.wakingStartMinute)}–'
          '${FreeWindowCalculator.formatMinute(schedule.wakingEndMinute)}',
      taskHandles: schedule.taskHandles,
      goalHandles: schedule.goalHandles,
      memoryFacts: dynamicResults[3] as List<String>,
      peopleDigest: dynamicResults[4] as List<String>,
      episodicSummaries: dynamicResults[5] as List<String>,
      openPromises: dynamicResults[6] as List<String>,
      deviceContext: dynamicResults[7] as List<String>,
      direction: dynamicResults[8] as List<String>,
      todayActivityLog: dynamicResults[9] as List<String>,
      voiceMode: voiceMode,
    );
  }

  /// Coarse ContextSnapshot labels — per-turn, best-effort, never raw.
  Future<List<String>> _buildDeviceContext() async {
    final service = contextSnapshotService;
    if (service == null) return const [];
    try {
      final snapshot = await service.capture();
      return snapshot.coarseLabels();
    } catch (_) {
      return const [];
    }
  }

  static int _nowMinuteOfDay() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  /// Computes free windows between scheduled blocks inside the waking day
  /// (07:00–22:00), as human-readable strings like "14:00–16:30 (2h 30m)".
  ///
  /// Thin delegate to the shared [FreeWindowCalculator] (extracted in
  /// Phase 1 so the OpportunityPlanner shares the same definition of free).
  @visibleForTesting
  static List<String> computeFreeWindows(
    List<Map<String, dynamic>> scheduleMaps, {
    int fromMinuteOfDay = 0,
  }) {
    return FreeWindowCalculator.computeFormatted(
      scheduleMaps,
      fromMinuteOfDay: fromMinuteOfDay,
    );
  }

  // ─── Memory sections (humanizing Phase 2) ──────────────────────────────────

  static const int _kMaxMemoryFacts = 20;
  static const int _kMaxPeople = 10;
  static const int _kMaxEpisodicSummaries = 3;
  static const Duration _kReferenceStampThrottle = Duration(hours: 6);

  /// Long-term memory as grounded lines `[mem:<id>|<label>] content`.
  /// Injected facts get their [MemoryFact.lastReferencedAtMs] stamped
  /// fire-and-forget (throttled — a chatty session must not produce
  /// dozens of outbox writes per turn).
  Future<List<String>> _buildMemoryFacts([String userInput = '']) async {
    final repo = memoryFactsRepository;
    if (repo == null) return const [];
    try {
      final all = await repo.fetchFactsOnce();
      final candidates = all
          .where((f) => f.kind != MemoryFactKind.episodicSummary)
          .toList(growable: false);
      final facts = selectMemoryFacts(
        candidates,
        userInput: userInput,
        limit: _kMaxMemoryFacts,
      );
      if (facts.isEmpty) return const [];

      final cutoff = DateTime.now()
          .subtract(_kReferenceStampThrottle)
          .millisecondsSinceEpoch;
      final toStamp = facts
          .where((f) => (f.lastReferencedAtMs ?? 0) < cutoff)
          .map((f) => f.id)
          .toList(growable: false);
      if (toStamp.isNotEmpty) {
        unawaited(
          repo.markReferenced(toStamp).catchError((Object e) {
            debugPrint('[AiPayloadAssembler] markReferenced failed: $e');
          }),
        );
      }

      return facts.map(renderMemoryFactLine).toList(growable: false);
    } catch (e) {
      debugPrint('[AiPayloadAssembler] memory facts failed: $e');
      return const [];
    }
  }

  /// Scored selection instead of newest-N (fix-wave Phase 6, §8 M6): the
  /// old slice was strictly recency-ranked, so after ~3 chatty sessions a
  /// foundational fact ("has type-1 diabetes", "works night shifts") was
  /// evicted from the prompt by newer trivia — and the Coach's amnesia
  /// looked like a model failure while the fact still showed in "What
  /// SidePal knows". Blend: what the user CONFIRMED outranks inference,
  /// durable kinds outrank observations, facts matching the current input
  /// jump the queue, and the long-collected (previously never-read)
  /// lastReferencedAtMs finally participates.
  @visibleForTesting
  static List<MemoryFact> selectMemoryFacts(
    List<MemoryFact> candidates, {
    required String userInput,
    required int limit,
  }) {
    if (candidates.length <= limit) return candidates;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const dayMs = 24 * 60 * 60 * 1000;
    final inputTokens = userInput
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.length > 3)
        .toSet();

    double score(MemoryFact f) {
      var s = switch (f.provenance) {
        MemoryProvenance.userConfirmed => 2.0,
        MemoryProvenance.userStated => 1.5,
        MemoryProvenance.derivedDeterministic => 0.7,
        MemoryProvenance.aiInferred => 0.3,
      };
      s += switch (f.kind) {
        MemoryFactKind.preference || MemoryFactKind.semanticFact => 1.5,
        MemoryFactKind.promiseNote => 0.8,
        MemoryFactKind.learnedPattern => 0.7,
        _ => 0.4,
      };
      final ageDays = (nowMs - f.updatedAtMs) / dayMs;
      if (ageDays < 7) {
        s += 1.0;
      } else if (ageDays < 30) {
        s += 0.5;
      }
      final referencedAgo = f.lastReferencedAtMs;
      if (referencedAgo != null && (nowMs - referencedAgo) < 7 * dayMs) {
        s += 0.5;
      }
      if (inputTokens.isNotEmpty &&
          f.content
              .toLowerCase()
              .split(RegExp(r'[^a-z0-9]+'))
              .any((t) => t.length > 3 && inputTokens.contains(t))) {
        s += 3.0;
      }
      return s;
    }

    final scored = [for (final f in candidates) (fact: f, score: score(f))]
      ..sort((a, b) => b.score.compareTo(a.score));
    return [for (final e in scored.take(limit)) e.fact];
  }

  /// The grounding contract line format (PRD §5.3). The label tells the
  /// model how hard it may lean on the fact: stated → assert, observed →
  /// assert as pattern, inferred → hedge or ask.
  @visibleForTesting
  static String renderMemoryFactLine(MemoryFact fact) {
    final label = switch (fact.provenance) {
      MemoryProvenance.userStated ||
      MemoryProvenance.userConfirmed => 'stated',
      MemoryProvenance.derivedDeterministic => 'observed',
      MemoryProvenance.aiInferred => 'inferred',
    };
    return '[mem:${fact.id}|$label] ${fact.content}';
  }

  Future<List<String>> _buildPeopleDigest() async {
    final repo = peopleRepository;
    if (repo == null) return const [];
    try {
      final people = await repo.fetchPeopleOnce();
      return people
          .take(_kMaxPeople)
          .map(renderPersonLine)
          .toList(growable: false);
    } catch (e) {
      debugPrint('[AiPayloadAssembler] people digest failed: $e');
      return const [];
    }
  }

  @visibleForTesting
  static String renderPersonLine(Person person) {
    final rel = person.relationship?.trim();
    final relPart = (rel == null || rel.isEmpty) ? person.kind.name : rel;
    final buffer = StringBuffer('${person.displayName} ($relPart)');
    final last = person.lastInteractionAtMs;
    if (last != null) {
      final days = DateTime.now()
          .difference(DateTime.fromMillisecondsSinceEpoch(last))
          .inDays;
      if (days <= 0) {
        buffer.write(' — interacted today');
      } else if (days == 1) {
        buffer.write(' — last interaction yesterday');
      } else {
        buffer.write(' — last interaction $days days ago');
      }
    }
    return buffer.toString();
  }

  /// Latest summarize-then-purge outputs, newest first, dated.
  Future<List<String>> _buildEpisodicSummaries() async {
    final repo = memoryFactsRepository;
    if (repo == null) return const [];
    try {
      final all = await repo.fetchFactsOnce();
      return all
          .where((f) => f.kind == MemoryFactKind.episodicSummary)
          .take(_kMaxEpisodicSummaries)
          .map((f) {
            final day = DateTime.fromMillisecondsSinceEpoch(f.createdAtMs);
            final key =
                '${day.year}-${day.month.toString().padLeft(2, '0')}-'
                '${day.day.toString().padLeft(2, '0')}';
            return '($key) ${f.content}';
          })
          .toList(growable: false);
    } catch (e) {
      debugPrint('[AiPayloadAssembler] episodic summaries failed: $e');
      return const [];
    }
  }

  /// Open + dormant intentions — the Coach must never re-capture a promise
  /// it already holds.
  Future<List<String>> _buildOpenPromises() async {
    final repo = intentionsRepository;
    if (repo == null) return const [];
    try {
      final all = await repo.fetchIntentionsOnce();
      final lines = <String>[];
      for (final i in all) {
        if (!i.active) continue;
        if (i.isLive) {
          final end = DateTime.fromMillisecondsSinceEpoch(i.windowEndMs);
          final key =
              '${end.year}-${end.month.toString().padLeft(2, '0')}-'
              '${end.day.toString().padLeft(2, '0')}';
          lines.add('${i.title} (by $key)');
        } else if (i.status == IntentionStatus.dormant) {
          lines.add('${i.title} (dormant — waiting for an opportunity)');
        }
      }
      return lines.take(15).toList(growable: false);
    } catch (e) {
      debugPrint('[AiPayloadAssembler] open promises failed: $e');
      return const [];
    }
  }

  /// Current-period Direction lines. A previous period must never leak in
  /// (history ≠ current direction) — `buildDirectionContextLines` enforces
  /// that; this just reads and delegates.
  Future<List<String>> _buildDirection() async {
    final repo = directionRepository;
    if (repo == null) return const [];
    try {
      final entries = await repo.fetchAllOnce();
      return buildDirectionContextLines(entries, DateTime.now());
    } catch (e) {
      debugPrint('[AiPayloadAssembler] direction failed: $e');
      return const [];
    }
  }

  /// Today's timeline as plain rows + a totals tail. Recorded truth; the
  /// prompt tells the model to describe it and never judge it.
  Future<List<String>> _buildTodayActivityLog() async {
    final repo = activityEventRepository;
    if (repo == null) return const [];
    try {
      final events = await repo.fetchDayOnce(DateKeys.todayKey());
      if (events.isEmpty) return const [];
      final rows = buildTimeline(events);
      return renderTimelineLines(rows, summary: buildDaySummary(rows));
    } catch (e) {
      debugPrint('[AiPayloadAssembler] activity log failed: $e');
      return const [];
    }
  }

  Future<_CachedScheduleSlice> _scheduleSliceForSession(
    String sessionId,
  ) async {
    final cached = _scheduleCache[sessionId];
    if (cached != null && !cached.isExpired(_scheduleCacheTtl)) {
      return cached;
    }

    final todayKey = DateKeys.todayKey();
    final tomorrowKey = DateKeys.tomorrowKey();
    final results = await Future.wait([
      _rowsFor(todayKey, enforcePlanDate: true),
      _rowsFor(tomorrowKey),
      _buildGoalSections(),
      _buildWeekOverview(),
      _buildFocusState(),
      _buildContextOverride(),
      _buildBehaviorPreferences(),
      _buildRecentPatterns(),
      _buildWakingBounds(),
      _buildDayBusyExtras(todayKey),
      _buildDayBusyExtras(tomorrowKey),
    ]);
    final todayRows = results[0] as List<PlannedTaskRow>;
    final tomorrowRows = results[1] as List<PlannedTaskRow>;
    final goalSections = results[2] as _GoalSections;
    final waking = results[8] as ({int start, int end});
    final todayExtras = results[9] as _DayBusyExtras;
    final tomorrowExtras = results[10] as _DayBusyExtras;

    // Handles (D2): "t1".. today then tomorrow, "g1".. goals — opaque,
    // per turn, never persisted. They let the model name an existing item
    // exactly instead of by a title the resolver has to guess at.
    final taskHandles = <String, AiTaskHandle>{};
    var n = 0;
    List<Map<String, dynamic>> withRefs(List<PlannedTaskRow> rows) {
      final maps = _taskMapsFromRows(rows);
      for (var i = 0; i < rows.length; i++) {
        final ref = 't${++n}';
        final row = rows[i];
        taskHandles[ref] = AiTaskHandle(
          taskId: row.task.id,
          routineId: row.routineId,
          blockId: row.blockId,
          dateKey: row.dateKey,
          title: row.task.title,
        );
        maps[i]['ref'] = ref;
      }
      return maps;
    }

    final activeTasks = withRefs(todayRows);
    final tomorrowTasks = withRefs(tomorrowRows);
    final todaySchedule = _scheduleMapsFromRows(todayRows);
    final tomorrowSchedule = _scheduleMapsFromRows(tomorrowRows);

    final slice = _CachedScheduleSlice(
      fetchedAt: DateTime.now(),
      activeTasks: activeTasks,
      goals: goalSections.goals,
      goalProgress: goalSections.progress,
      todaySchedule: todaySchedule,
      tomorrowTasks: tomorrowTasks,
      tomorrowSchedule: tomorrowSchedule,
      weekOverview: results[3] as List<Map<String, dynamic>>,
      focusState: results[4] as Map<String, dynamic>,
      contextOverride: results[5] as Map<String, dynamic>?,
      behaviorPreferences: results[6] as Map<String, dynamic>,
      recentPatterns: results[7] as List<Map<String, dynamic>>,
      todayBusy: [...todaySchedule, ...todayExtras.blocks],
      tomorrowBusy: [...tomorrowSchedule, ...tomorrowExtras.blocks],
      todayCalendarAvailable: todayExtras.calendarAvailable,
      tomorrowCalendarAvailable: tomorrowExtras.calendarAvailable,
      wakingStartMinute: waking.start,
      wakingEndMinute: waking.end,
      taskHandles: taskHandles,
      goalHandles: goalSections.handles,
    );
    _scheduleCache[sessionId] = slice;
    return slice;
  }

  Future<List<PlannedTaskRow>> _rowsFor(
    String dateKey, {
    bool enforcePlanDate = false,
  }) async {
    try {
      return await collectTasksForDateKey(
        planningRepository,
        dateKey,
        enforceTaskPlanDate: enforcePlanDate,
      );
    } catch (_) {
      return const [];
    }
  }

  /// Waking bounds (D3): the configured sleep window when set (bed →
  /// wake), else 07:00–22:00.
  Future<({int start, int end})> _buildWakingBounds() async {
    const fallback = (
      start: FreeWindowCalculator.dayStartMinute,
      end: FreeWindowCalculator.dayEndMinute,
    );
    try {
      final state = await contextOverrideRepository.getAttentionState();
      if (state == null || !state.hasSleepWindow) return fallback;
      final bed = _parseHm(state.sleepWindowStart!);
      final wake = _parseHm(state.sleepWindowEnd!);
      if (bed == null || wake == null) return fallback;
      // A window that wraps midnight (23:00–07:00) means the waking day is
      // wake → bed; a same-day nap-style window falls back.
      if (wake < bed && bed - wake >= 6 * 60) return (start: wake, end: bed);
      return fallback;
    } catch (_) {
      return fallback;
    }
  }

  static int? _parseHm(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h * 60 + m;
  }

  /// Busy blocks beyond planned tasks for one day: goal time blocks and
  /// device-calendar busy intervals (Phase 3.2). Calendar availability is
  /// reported separately so the prompt never presents "unavailable" as
  /// "free" (review §1.1 #5).
  Future<_DayBusyExtras> _buildDayBusyExtras(String dateKey) async {
    final day = DateKeys.parseLocalDateKey(dateKey);
    final blocks = <Map<String, dynamic>>[];

    final tbRepo = timeBlockRepository;
    if (tbRepo != null) {
      try {
        final dayStart = DateTime(day.year, day.month, day.day);
        final dayEnd = dayStart.add(const Duration(days: 1));
        final found = await tbRepo.listBlocksForDateRange(dayStart, dayEnd);
        for (final b in found) {
          if (b.entityKind == 'task') continue; // already a scheduled task
          final start = b.startAt.toLocal();
          final end = b.computedEndAt.toLocal();
          blocks.add({
            'title': 'Goal time',
            'startTime': FreeWindowCalculator.formatMinute(
              start.hour * 60 + start.minute,
            ),
            'endTime': FreeWindowCalculator.formatMinute(
              end.hour * 60 + end.minute,
            ),
          });
        }
      } catch (e) {
        debugPrint('[AiPayloadAssembler] goal blocks failed: $e');
      }
    }

    bool? calendarAvailable;
    final snapshots = contextSnapshotService;
    if (snapshots != null) {
      try {
        final busy = await snapshots.calendarBusyForDay(day);
        calendarAvailable = busy != null;
        if (busy != null) {
          blocks.addAll(calendarBusyToScheduleMaps(busy, day));
        }
      } catch (_) {
        calendarAvailable = false;
      }
    }
    return _DayBusyExtras(blocks: blocks, calendarAvailable: calendarAvailable);
  }

  // ─── Private builders ─────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> _buildWeekOverview() async {
    try {
      final today = DateTime.now();
      final dayFutures = <Future<Map<String, dynamic>>>[];
      for (var offset = 0; offset < 7; offset++) {
        // Calendar arithmetic, not Duration (fix-wave Phase 6, R9): on a
        // 25h fall-back day, now+24h lands on the SAME calendar day —
        // duplicate date keys, a wrong "tomorrow" label, double-counted
        // stats. DateTime normalizes d+offset correctly across DST.
        final day = DateTime(today.year, today.month, today.day + offset);
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
    // Busy = has a time AND a duration. A reminder-only task is a
    // notification, not occupied time (fix plan Phase 3.2 — its "?" end
    // time used to become a 30-minute pseudo-block).
    final scheduled = rows.where((r) {
      final iso = r.task.reminderTimeIso;
      return iso != null && iso.isNotEmpty && r.task.durationMinutes >= 1;
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
      return {'title': t.title, 'startTime': startStr, 'endTime': endStr};
    }).toList();
  }

  /// Active goals, their progress in their own units (Phase 3.1), and the
  /// "g1".. handles — one pass over the repository.
  Future<_GoalSections> _buildGoalSections() async {
    try {
      final now = DateTime.now();
      final todayKey = DateKeys.todayKey(now);
      final active = (await goalsRepository.fetchGoalsOnce())
          .where((g) => g.status == GoalStatus.active)
          .toList();

      final entries = <({UserGoal goal, GoalWindowProgress progress, List<String> steps})>[];
      for (final g in active) {
        final periodStart = DateTime.fromMillisecondsSinceEpoch(g.periodStartMs).toLocal();
        final periodEnd = DateTime.fromMillisecondsSinceEpoch(g.periodEndMs).toLocal();
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
        final steps = <String>[];
        try {
          final actions = await goalsRepository.getActions(g.id);
          final today = DateKeys.parseLocalDateKey(todayKey);
          for (final a in actions) {
            if (a.isScheduledOn(today) && !a.isCompletedOn(todayKey)) {
              steps.add(a.title);
              if (steps.length == 3) break;
            }
          }
        } catch (_) {}
        entries.add((
          goal: g,
          progress: GoalProgressMath.compute(g, checkIns, now),
          steps: steps,
        ));
      }

      // Behind-pace goals first, then the nearest deadline; cap 8.
      entries.sort((a, b) {
        if (a.progress.behindPace != b.progress.behindPace) {
          return a.progress.behindPace ? -1 : 1;
        }
        return a.goal.periodEndMs.compareTo(b.goal.periodEndMs);
      });
      final shown = entries.take(8).toList();

      final goals = <Map<String, dynamic>>[];
      final progress = <Map<String, dynamic>>[];
      final handles = <String, AiGoalHandle>{};
      var n = 0;
      for (final e in shown) {
        final g = e.goal;
        final ref = 'g${++n}';
        handles[ref] = AiGoalHandle(goalId: g.id, title: g.title);
        final deadline = DateTime.fromMillisecondsSinceEpoch(g.periodEndMs).toLocal();
        final unit = e.progress.unitLabel;
        final target = '${e.progress.targetText}${unit.isEmpty ? '' : ' $unit'}';
        goals.add({
          'ref': ref,
          'title': g.title,
          'target': target,
          'deadline': DateKeys.yyyymmdd(deadline),
          'category': g.categoryId,
          'cadence': GoalProgressMath.cadenceLabelFor(g),
        });
        progress.add({
          'ref': ref,
          'title': g.title,
          'logged': e.progress.loggedText,
          'target': e.progress.targetText,
          'unit': unit,
          'window': e.progress.windowLabel,
          'daysLogged': e.progress.daysLogged,
          'daysElapsed': e.progress.daysElapsed,
          'daysInWindow': e.progress.daysInWindow,
          'behindPace': e.progress.behindPace,
          'cadence': GoalProgressMath.cadenceLabelFor(g),
          'category': g.categoryId,
          if (e.steps.isNotEmpty) 'stepsDueToday': e.steps,
        });
      }
      return _GoalSections(goals: goals, progress: progress, handles: handles);
    } catch (_) {
      return const _GoalSections(goals: [], progress: [], handles: {});
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
        } catch (e) {
          debugPrint('ai_payload_assembler: swallowed error: $e');
        }
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
        final day = DateTime(today.year, today.month, today.day - daysBack);
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
        mostActiveHour = '${topHour.toString().padLeft(2, '0')}:00';
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
      final entries = await historyRepository.getRecentForSession(
        sessionId,
        limit: 10,
      );
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
      final entries = await historyRepository.getRecentForSession(
        sessionId,
        limit: 10,
      );
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
  ///
  /// Fix plan Phase 4.1: the newest [_kVerbatimTurns] turns ride verbatim;
  /// anything older in the session is folded into ONE deterministic
  /// "earlier in this session" line (no model call), within a character
  /// budget — a long session used to fall off a cliff at turn 11.
  Future<List<Map<String, dynamic>>> buildConversationHistory(
    String sessionId,
  ) async {
    try {
      final entries = await historyRepository.getRecentForSession(
        sessionId,
        limit: _kHistoryRowsRead,
      );
      final chronological = entries.reversed.toList();
      final verbatimStart = chronological.length > _kVerbatimTurns
          ? chronological.length - _kVerbatimTurns
          : 0;
      final history = <Map<String, dynamic>>[];

      if (verbatimStart > 0) {
        final older = chronological.sublist(0, verbatimStart);
        final parts = <String>[];
        for (final e in older) {
          final u = e.userInput.trim();
          final a = (e.assistantSummary ?? '').trim();
          final clipU = u.length > 80 ? '${u.substring(0, 77)}…' : u;
          final clipA = a.length > 120 ? '${a.substring(0, 117)}…' : a;
          parts.add(clipA.isEmpty ? 'user: $clipU' : 'user: $clipU / coach: $clipA');
        }
        var rolled = parts.join(' · ');
        if (rolled.length > _kRollingSummaryChars) {
          rolled = '…${rolled.substring(rolled.length - _kRollingSummaryChars)}';
        }
        history.add({
          'role': 'assistant',
          'content': '[Earlier in this session: $rolled]',
        });
      }

      for (final e in chronological.sublist(verbatimStart)) {
        history.add({'role': 'user', 'content': e.userInput});
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

  static const int _kVerbatimTurns = 8;
  static const int _kHistoryRowsRead = 30;
  static const int _kRollingSummaryChars = 900;

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
        final day = DateTime(today.year, today.month, today.day - daysBack);
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
              lastTime: daysBack == 0
                  ? (timeStr ?? existing.lastTime)
                  : existing.lastTime,
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

class _GoalSections {
  const _GoalSections({
    required this.goals,
    required this.progress,
    required this.handles,
  });
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> progress;
  final Map<String, AiGoalHandle> handles;
}

class _DayBusyExtras {
  const _DayBusyExtras({required this.blocks, required this.calendarAvailable});
  final List<Map<String, dynamic>> blocks;
  final bool? calendarAvailable;
}

class _CachedScheduleSlice {
  _CachedScheduleSlice({
    required this.fetchedAt,
    required this.activeTasks,
    required this.goals,
    required this.goalProgress,
    required this.todaySchedule,
    required this.tomorrowTasks,
    required this.tomorrowSchedule,
    required this.weekOverview,
    required this.focusState,
    required this.contextOverride,
    required this.behaviorPreferences,
    required this.recentPatterns,
    required this.todayBusy,
    required this.tomorrowBusy,
    required this.todayCalendarAvailable,
    required this.tomorrowCalendarAvailable,
    required this.wakingStartMinute,
    required this.wakingEndMinute,
    required this.taskHandles,
    required this.goalHandles,
  });

  final DateTime fetchedAt;
  final List<Map<String, dynamic>> activeTasks;
  final List<Map<String, dynamic>> goals;
  final List<Map<String, dynamic>> goalProgress;
  final List<Map<String, dynamic>> todaySchedule;
  final List<Map<String, dynamic>> tomorrowTasks;
  final List<Map<String, dynamic>> tomorrowSchedule;
  final List<Map<String, dynamic>> weekOverview;
  final Map<String, dynamic> focusState;
  final Map<String, dynamic>? contextOverride;
  final Map<String, dynamic> behaviorPreferences;
  final List<Map<String, dynamic>> recentPatterns;
  final List<Map<String, dynamic>> todayBusy;
  final List<Map<String, dynamic>> tomorrowBusy;
  final bool? todayCalendarAvailable;
  final bool? tomorrowCalendarAvailable;
  final int wakingStartMinute;
  final int wakingEndMinute;
  final Map<String, AiTaskHandle> taskHandles;
  final Map<String, AiGoalHandle> goalHandles;

  bool isExpired(Duration ttl) => DateTime.now().difference(fetchedAt) > ttl;
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
