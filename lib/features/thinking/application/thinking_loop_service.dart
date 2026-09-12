import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ai/ai_proxy_client.dart';
import '../../../core/ai/ai_remote_config_service.dart';
import '../../../core/utils/date_keys.dart';
import '../../analytics/application/insight_generation_orchestrator.dart';
import '../../analytics/data/insight_cache_repository.dart';
import '../../analytics/domain/models/behavior_feature_object.dart';
import '../../analytics/domain/models/detected_pattern.dart';
import '../../analytics/domain/models/generated_insight.dart';
import '../../direction/data/direction_repository.dart';
import '../../direction/domain/direction_periods.dart';
import '../../time_tracker/data/activity_category_rule_repository.dart';
import '../../time_tracker/data/activity_event_repository.dart';
import '../../time_tracker/domain/models/activity_category_rule.dart';
import '../../time_tracker/domain/models/activity_event.dart';
import '../../time_tracker/domain/reflection_activity_snapshot.dart';
import '../../time_tracker/domain/week_periods.dart';
import '../../time_tracker/domain/week_summary.dart';
import '../../direction/domain/models/direction_entry.dart';
import '../../intentions/application/intention_capture.dart';
import '../../intentions/data/intentions_repository.dart';
import '../../intentions/domain/models/intention.dart';
import '../../memory/data/memory_facts_repository.dart';
import '../../memory/data/people_repository.dart';
import 'reflection_parser.dart';
import 'reflection_payload.dart';

/// The Thinking Loop (humanizing Phase 7, PRD §12): every so often —
/// locally, quietly — SidePal asks itself *"given everything I know: did
/// Mike forget something? Is he avoiding something? Should an intention
/// move?"*
///
/// The deterministic layers already think; this adds ONE budgeted LLM
/// reflection pass per device-day (purpose `reflect`, system budget,
/// silent-skip, server kill switch) over the full local picture. Its
/// output is never an action — only proposals that flow through the same
/// validation machinery as everything else:
///
/// - dormant intentions → `IntentionStatus.dormant` (zero notifications
///   until engaged; the planner only reads `open`);
/// - hint updates → `aiHintsJson.preferredTimeBlock`, an ADVISORY scoring
///   input the planner already sanity-checks and weighs low;
/// - at most one observation → an `InsightType.reflectionObservation`
///   through the standard Layer-3 policy (cooldowns, caps, day-scoped
///   delivery), labeled aiInferred in metadata.
///
/// Skip semantics ("fresh inputs" — settled with Miko 2026-07-24): a pass
/// runs at most once per local day AND only when the durable inputs hash
/// changed since the last completed pass — an unchanged life must not
/// burn budget re-reflecting. Failures (offline, AI down, kill switch,
/// budget out) leave the day unmarked, so the next app open retries —
/// the extraction-service stay-pending pattern.
class ThinkingLoopService {
  ThinkingLoopService({
    required MemoryFactsRepository facts,
    required PeopleRepository people,
    required IntentionsRepository intentions,
    required InsightGenerationOrchestrator orchestrator,
    required InsightCacheRepository insightCache,
    AiProxyClient? proxy,
    AiRemoteConfigService? remoteConfig,

    /// Direction (2026-09-11): what the user says matters this
    /// year/quarter/month joins the snapshot as context (never a task).
    /// Null keeps the payload byte-identical.
    DirectionRepository? directions,

    /// Time Tracker V1.2: the timeline joins the snapshot (today + last 7
    /// days + week/month aggregates on boundary days); the pass proposes
    /// category rules and ≤1 tone-checked observation per scope.
    ActivityEventRepository? activityEvents,
    ActivityCategoryRuleRepository? categoryRules,

    /// Reminder aggregates for the strategist (FR-R-61) — injected so this
    /// service keeps no dependency on the reminders feature. Null keeps the
    /// pre-strategist payload byte-identical.
    Future<Map<String, dynamic>?> Function()? loadReminderAggregates,

    /// Receives the pass's validated reminder proposals for the day.
    Future<void> Function(List<ReminderStrategyProposal> proposals)?
    onReminderProposals,
    DateTime Function()? now,
  }) : _facts = facts,
       _people = people,
       _intentions = intentions,
       _orchestrator = orchestrator,
       _insightCache = insightCache,
       _proxy = proxy ?? AiProxyClient(),
       _remoteConfig = remoteConfig ?? AiRemoteConfigService.instance,
       _directions = directions,
       _activityEvents = activityEvents,
       _categoryRules = categoryRules,
       _loadReminderAggregates = loadReminderAggregates,
       _onReminderProposals = onReminderProposals,
       _now = now ?? DateTime.now;

  final MemoryFactsRepository _facts;
  final PeopleRepository _people;
  final IntentionsRepository _intentions;
  final InsightGenerationOrchestrator _orchestrator;
  final InsightCacheRepository _insightCache;
  final AiProxyClient _proxy;
  final AiRemoteConfigService _remoteConfig;
  final DirectionRepository? _directions;
  final ActivityEventRepository? _activityEvents;
  final ActivityCategoryRuleRepository? _categoryRules;
  final Future<Map<String, dynamic>?> Function()? _loadReminderAggregates;
  final Future<void> Function(List<ReminderStrategyProposal>)?
  _onReminderProposals;
  final DateTime Function() _now;

  static const lastDayPrefsKey = 'thinking_loop_last_day_v1';
  static const inputsHashPrefsKey = 'thinking_loop_inputs_hash_v1';

  /// Time Tracker V1.2 boundary flags: the week/month key whose aggregates
  /// were already reflected on (once per boundary). Per-account → wipe list.
  static const timeWeekDonePrefsKey = 'thinking_loop_time_week_done_v1';
  static const timeMonthDonePrefsKey = 'thinking_loop_time_month_done_v1';

  /// The synthetic entity scope reflection insights live under. The
  /// delivery-day loader merges ALL entity insights whose source window
  /// covers today, so no per-entity registration is needed.
  static const reflectionScopeId = 'reflection';

  /// Dormant proposals get the same wide, quiet window as extraction's
  /// observations — "on your radar", zero notifications until engaged.
  static const observationWindow = Duration(days: 60);

  /// In-flight guard (P2-11): bootstrap and resume both launch this
  /// unawaited within seconds of each other on a cold start; without the
  /// guard, two overlapping runs could each pass the day/hash checks and
  /// double-spend the system AI budget.
  Future<void>? _inFlight;

  /// Entry point — bootstrap and app resume. Cheap when not due.
  Future<void> reflectIfDue() {
    return _inFlight ??= _reflectIfDue().whenComplete(() => _inFlight = null);
  }

  Future<void> _reflectIfDue() async {
    try {
      final now = _now();
      final today = DateKeys.todayKey(now);
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(lastDayPrefsKey) == today) return;

      final facts = await _facts.fetchFactsOnce();
      final people = await _people.fetchPeopleOnce();
      final intentions = await _intentions.fetchIntentionsOnce();
      // Direction alone is not worth a call (nothing to connect it to),
      // so it does not join the empty-gate below.
      var directions = const <DirectionEntry>[];
      try {
        directions = await _directions?.fetchAllOnce() ?? const [];
      } catch (e) {
        debugPrint('[ThinkingLoop] direction read failed: $e');
      }
      // Time Tracker V1.2 inputs — today, the last 7 days, and the rules.
      var todayActivity = const <ActivityEvent>[];
      var recentActivity = const <ActivityEvent>[];
      var rules = const <ActivityCategoryRule>[];
      try {
        final repo = _activityEvents;
        if (repo != null) {
          todayActivity = await repo.fetchDayOnce(today);
          final from = DateTime(now.year, now.month, now.day - 7);
          recentActivity = await repo.fetchRangeOnce(
            from.millisecondsSinceEpoch,
            DateTime(now.year, now.month, now.day).millisecondsSinceEpoch,
          );
          rules = await _categoryRules?.fetchAllOnce() ?? const [];
        }
      } catch (e) {
        debugPrint('[ThinkingLoop] activity read failed: $e');
      }
      final hasActivity = todayActivity.isNotEmpty || recentActivity.isNotEmpty;
      if (facts.isEmpty && people.isEmpty && intentions.isEmpty && !hasActivity) {
        // Nothing to reflect on — but do NOT mark the day (P2-10): an
        // empty snapshot is usually a fresh install or a just-wiped
        // account switch, and onboarding/remote merge can fill Isar
        // minutes later. Leaving the day unmarked keeps the loop armed;
        // the empty re-check costs three Isar reads.
        return;
      }

      final hash = reflectionInputsHash(
        facts: facts,
        people: people,
        intentions: intentions,
        directions: directions,
        extraParts: activityHashParts(
          [...todayActivity, ...recentActivity],
          rules,
        ),
      );
      if (prefs.getString(inputsHashPrefsKey) == hash) {
        // Nothing changed since the last pass — same conclusions, zero
        // spend. Mark the day; a change tomorrow re-arms the loop.
        await prefs.setString(lastDayPrefsKey, today);
        return;
      }

      if (!await _remoteConfig.isAiEnabled()) return;

      final snapshot = buildReflectionSnapshot(
        facts: facts,
        people: people,
        intentions: intentions,
        now: now,
        directions: directions,
      );
      // Time Tracker V1.2: the activity block. Boundary aggregates only on
      // the first pass after a new ISO week / calendar month, and only the
      // PREVIOUS period's data (+ that month's Direction from history).
      Map<String, dynamic>? activity;
      String? pendingWeekKey;
      String? pendingMonthKey;
      if (_activityEvents != null && hasActivity) {
        final thisWeek = WeekPeriods.of(now);
        ({String key, Map<String, List<ActivityEvent>> eventsByDay})? weekB;
        if (prefs.getString(timeWeekDonePrefsKey) != thisWeek.key) {
          final prev = WeekPeriods.previous(thisWeek);
          final events = await _activityEvents.fetchRangeOnce(prev.startMs, prev.endMs);
          if (events.isNotEmpty) {
            weekB = (key: prev.key, eventsByDay: groupEventsByDay(events));
          }
          pendingWeekKey = thisWeek.key;
        }
        ({
          String key,
          String label,
          Map<String, List<ActivityEvent>> eventsByDay,
          List<String> directionTexts,
        })?
        monthB;
        final thisMonth = WeekPeriods.monthOf(now);
        if (prefs.getString(timeMonthDonePrefsKey) != thisMonth.key) {
          final prevMonth = WeekPeriods.monthOf(
            DateTime.fromMillisecondsSinceEpoch(thisMonth.startMs - 1),
          );
          final events = await _activityEvents.fetchRangeOnce(
            prevMonth.startMs,
            prevMonth.endMs,
          );
          if (events.isNotEmpty) {
            // That month's Direction texts — history, never current context.
            final texts = <String>[];
            for (final d in directions) {
              if (d.isEmpty) continue;
              final period = d.period;
              if (period == null) continue;
              final inMonth =
                  (d.horizon == DirectionHorizon.month && d.periodKey == prevMonth.key) ||
                  (d.horizon != DirectionHorizon.month &&
                      period.startMs <= prevMonth.startMs &&
                      period.endMs >= prevMonth.endMs);
              if (inMonth) texts.add('${d.horizon.name}: ${d.text}');
            }
            monthB = (
              key: prevMonth.key,
              label: prevMonth.label,
              eventsByDay: groupEventsByDay(events),
              directionTexts: texts,
            );
          }
          pendingMonthKey = thisMonth.key;
        }
        activity = buildActivitySnapshot(
          todayKey: today,
          todayEvents: todayActivity,
          last7Days: groupEventsByDay(recentActivity),
          rules: rules,
          weekBoundary: weekB,
          monthBoundary: monthB,
        );
        snapshot['activity'] = activity;
      }

      // FR-R-61: the strategist rides THIS pass — locally pre-computed
      // aggregates, never raw ledger rows, no additional call (FR-R-64).
      final reminderAggregates = await (_loadReminderAggregates?.call() ??
          Future<Map<String, dynamic>?>.value(null));
      final reminderTasks = <String, String>{};
      if (reminderAggregates != null) {
        snapshot['reminders'] = reminderAggregates;
        final tasks = reminderAggregates['tasks'];
        if (tasks is List) {
          for (final t in tasks) {
            if (t is Map && t['id'] is String) {
              reminderTasks[t['id'] as String] = (t['title'] as String?) ?? '';
            }
          }
        }
      }

      String content;
      try {
        content = await _proxy.chat(
          messages: [
            {'role': 'system', 'content': _kReflectionSystemPrompt},
            {'role': 'user', 'content': jsonEncode(snapshot)},
          ],
          // Pinned server-side by the purpose route; advisory here.
          temperature: 0.2,
          maxTokens: 700,
          purpose: 'reflect',
          timeout: const Duration(seconds: 30),
        );
      } on AiProxyException catch (e) {
        // Offline, AI down, kill-switched, budget out — silent skip, day
        // left unmarked so the next open retries.
        debugPrint('[ThinkingLoop] reflect skipped: ${e.message}');
        return;
      }

      final live = intentions.where((i) => i.active);
      final parsed = ReflectionParser.parse(
        content,
        knownIds: reflectionKnownIds(
          facts: facts,
          people: people,
          intentions: intentions,
          directions: directions,
        ),
        openIntentionIds: {
          for (final i in live)
            if (i.isLive && !i.isPinned) i.id,
        },
        existingTitleKeys: {
          // Tombstones included: a promise the user removed must not come
          // back from a reflection pass under a fresh id.
          for (final i in await _intentions.fetchAllIncludingTombstones())
            ReflectionParser.titleKey(i.title),
        },
        reminderTasks: reminderTasks,
        activityIds: activity == null ? const {} : activitySnapshotIds(activity),
        uncategorizedTexts: {
          for (final t in (activity?['uncategorizedTexts'] as List? ?? const []))
            if (t is String) t,
        },
      );

      if (parsed.reminderProposals.isNotEmpty) {
        await _onReminderProposals?.call(parsed.reminderProposals);
      }

      await _apply(parsed, now);
      await _applyTime(parsed, now, today: today);
      await prefs.setString(lastDayPrefsKey, today);
      await prefs.setString(inputsHashPrefsKey, hash);
      if (pendingWeekKey != null) {
        await prefs.setString(timeWeekDonePrefsKey, pendingWeekKey);
      }
      if (pendingMonthKey != null) {
        await prefs.setString(timeMonthDonePrefsKey, pendingMonthKey);
      }
    } catch (e) {
      debugPrint('[ThinkingLoop] reflectIfDue failed: $e');
    }
  }

  Future<void> _apply(ParsedReflection parsed, DateTime now) async {
    for (final candidate in parsed.dormantIntentions) {
      final intention = buildIntention(
        IntentionDraft(
          title: candidate.title,
          rawUtterance: candidate.title,
          windowStart: now,
          windowEnd: now.add(observationWindow),
          estimatedMinutes: candidate.estimatedMinutes,
          aiHintsJson: jsonEncode({
            'source': 'reflect',
            'basedOn': candidate.basedOn,
          }),
        ),
        now: now,
      ).copyWith(status: IntentionStatus.dormant);
      await _intentions.upsertIntention(intention);
    }

    for (final hint in parsed.hintUpdates) {
      // Re-fetch at apply time: the reflect network call took up to 30s,
      // and the user may have acted meanwhile (Done, edit, pin). Writing
      // the pre-call record would carry a fresher updatedAtMs and silently
      // LWW-stomp their action on every device (Tier-1 review fix). The
      // parser's open+unpinned gate is re-checked against the fresh record
      // for the same reason.
      final fresh = await _intentions.getIntention(hint.intentionId);
      if (fresh == null || !fresh.isLive || fresh.isPinned) continue;
      await _intentions.upsertIntention(
        fresh.copyWith(
          aiHintsJson: mergeHints(fresh.aiHintsJson, hint),
          updatedAtMs: now.millisecondsSinceEpoch,
        ),
      );
    }

    await _cacheObservation(parsed.observation, now);
  }

  /// Merge, never replace: an existing hint map keeps its other keys.
  @visibleForTesting
  static String mergeHints(String? existingJson, ReflectionHintUpdate hint) {
    Map<String, dynamic> hints = {};
    if (existingJson != null && existingJson.isNotEmpty) {
      try {
        final decoded = jsonDecode(existingJson);
        if (decoded is Map<String, dynamic>) hints = decoded;
      } catch (_) {}
    }
    hints['preferredTimeBlock'] = hint.preferredTimeBlock;
    hints['hintSource'] = 'reflect';
    if (hint.basedOn.isNotEmpty) {
      // Provenance for the confirm-at-delivery loop: "wrong time" strikes
      // contradict these sourcing records (P1-05).
      hints['basedOn'] = hint.basedOn;
    }
    return jsonEncode(hints);
  }

  /// Time Tracker V1.2: category rules (AI source — never over a user
  /// rule) and the per-scope observations, cached under `time:<scope>:<key>`
  /// so only the Time page reads them.
  Future<void> _applyTime(
    ParsedReflection parsed,
    DateTime now, {
    required String today,
  }) async {
    final rules = _categoryRules;
    if (rules != null) {
      for (final c in parsed.activityCategories) {
        try {
          await rules.setCategory(
            c.text,
            category: c.category,
            source: CategoryRuleSource.ai,
          );
        } catch (e) {
          debugPrint('[ThinkingLoop] category apply failed: $e');
        }
      }
    }
    for (final o in parsed.timeObservations) {
      final key = switch (o.scope) {
        'week' => WeekPeriods.previous(WeekPeriods.of(now)).key,
        'month' => WeekPeriods.monthOf(
          DateTime.fromMillisecondsSinceEpoch(WeekPeriods.monthOf(now).startMs - 1),
        ).key,
        _ => today,
      };
      await _cacheObservationForScope(
        scopeId: 'time:${o.scope}:$key',
        observation: ReflectionObservation(message: o.message, basedOn: o.basedOn),
        now: now,
        windowStartKey: today,
        windowEndKey: today,
      );
    }
  }

  /// One observation per pass, cached day-scoped under the synthetic
  /// reflection entity. No observation retires yesterday's — reflections
  /// don't linger past their day.
  Future<void> _cacheObservation(
    ReflectionObservation? observation,
    DateTime now,
  ) async {
    if (observation == null) {
      await _insightCache.replaceScopeInsights(
        scopeType: InsightScopeType.entity,
        scopeId: reflectionScopeId,
        insights: const [],
      );
      return;
    }
    final today = DateKeys.todayKey(now);
    await _cacheObservationForScope(
      scopeId: reflectionScopeId,
      observation: observation,
      now: now,
      windowStartKey: today,
      windowEndKey: today,
    );
  }

  /// Runs the Layer-3 policy for a reflection pattern under [scopeId] and
  /// caches the resulting observation insight with [observation]'s message.
  Future<void> _cacheObservationForScope({
    required String scopeId,
    required ReflectionObservation observation,
    required DateTime now,
    required String windowStartKey,
    required String windowEndKey,
  }) async {
    final pattern = DetectedPattern(
      entityId: scopeId,
      entityKind: BehaviorEntityKind.reflection,
      patternCode: PatternCode.reflectionSignal,
      patternGroup: PatternGroup.reflection,
      // Fixed low severity, sub-1.0 confidence: the claim is AI-inferred,
      // not measured — it must never outrank a deterministic insight.
      severity: 0.3,
      confidence: 0.6,
      detectedAtMs: now.millisecondsSinceEpoch,
      sourceWindowStartDateKey: windowStartKey,
      sourceWindowEndDateKey: windowEndKey,
      metadata: {'basedOn': observation.basedOn},
    );
    final out = _orchestrator.runForEntity(
      entityId: scopeId,
      patterns: [pattern],
      now: now,
    );
    if (out.hasFatalError) return;
    final withMessage = out.insights
        .map((insight) => _withObservationMessage(insight, observation))
        .toList(growable: false);
    await _insightCache.replaceScopeInsights(
      scopeType: InsightScopeType.entity,
      scopeId: scopeId,
      insights: withMessage,
    );
  }

  static GeneratedInsight _withObservationMessage(
    GeneratedInsight insight,
    ReflectionObservation observation,
  ) {
    if (insight.insightType != InsightType.reflectionObservation) {
      return insight;
    }
    return GeneratedInsight(
      insightId: insight.insightId,
      scopeType: insight.scopeType,
      scopeId: insight.scopeId,
      insightType: insight.insightType,
      insightBucket: insight.insightBucket,
      priority: insight.priority,
      messageKey: insight.messageKey,
      message: observation.message,
      action: insight.action,
      linkedPatternCodes: insight.linkedPatternCodes,
      confidence: insight.confidence,
      detectedAtMs: insight.detectedAtMs,
      sourceWindowStartDateKey: insight.sourceWindowStartDateKey,
      sourceWindowEndDateKey: insight.sourceWindowEndDateKey,
      lifecycleState: insight.lifecycleState,
      urgency: insight.urgency,
      coachingImportance: insight.coachingImportance,
      supportingMetrics: insight.supportingMetrics,
      metadata: <String, dynamic>{
        ...insight.metadata,
        'provenance': 'aiInferred',
        'basedOn': observation.basedOn,
      },
      schemaVersion: insight.schemaVersion,
    );
  }
}

const _kReflectionSystemPrompt = '''
You are the quiet reflection pass of a personal coaching app. You receive a JSON snapshot of what the app already knows about its user: memory facts, people, and intentions (promises) with their status and avoidance history.

Ask yourself: did the user forget something? Are they avoiding something? Does something deserve gentle attention? Connect ONLY the dots in the snapshot — never invent.

Return STRICT JSON, no prose:
{
  "dormantIntentions": [
    {"title": "Reconnect with college friends", "estimatedMinutes": 30, "basedOn": ["<id from the snapshot>"]}
  ],
  "hintUpdates": [
    {"intentionId": "<id of an OPEN intention>", "preferredTimeBlock": "morning|afternoon|evening", "basedOn": ["<id>"]}
  ],
  "observations": [
    {"message": "hedged, gentle observation, max 200 chars", "basedOn": ["<id>"]}
  ],
  "reminderProposals": [
    {"kind": "reschedule|ladderTuning|aggregate|drop", "taskId": "<id from snapshot.reminders.tasks>", "suggestion": "one warm sentence, max 160 chars"}
  ]
}

Rules:
- Every item MUST cite "basedOn" ids copied verbatim from the snapshot. Items without valid grounding are discarded.
- "dormantIntentions" are standing wishes the user implied but never asked to be reminded of — they create NO notifications. Max 3. Never duplicate an existing intention.
- "hintUpdates" only when the snapshot shows a timing pattern (e.g. repeated snoozes) suggesting a better time block. Max 5.
- "observations" are for a possible forget/avoid/change worth mentioning. Phrase as a hedged question or gentle notice ("You might be…", "Looks like…"), never a command or diagnosis. Max 1.
- "reminderProposals" only when snapshot.reminders shows a task genuinely struggling (repeated overdueDays, ignored, reschedules): "reschedule" = a better time, "ladderTuning" = gentler or firmer follow-ups, "aggregate" = misses should be batched quietly, "drop" = worth asking whether to keep it. Max 3, one per task, only ids from snapshot.reminders.tasks. These are SUGGESTIONS the user applies themselves - phrase them as offers, never verdicts.
- snapshot.direction (when present) is what the user says matters this year/quarter/month, in their own words. It is context, not a task. You may make ONE gentle observation connecting the facts/intentions to it when the link is real (e.g. a promise that serves the month's focus keeps getting pushed) — cite the direction id in basedOn. Never judge or preach, never quote it back at length, and never propose a dormantIntention just to "work on" the direction.
- snapshot.activity (when present) is the user's OWN time log: today's rows, the last 7 days' totals by activity/category/hour band, and on some days a weekBoundary / monthBoundary block for the period that just ended (monthBoundary may carry that month's "direction" — what they said mattered then). Recorded, not planned.
  - "timeObservations": at most ONE per scope ("day" for today, "week" only when weekBoundary is present, "month" only when monthBoundary is present). Each {"scope","message" (≤200 chars, one sentence, observational — "Most of your focused work happened after 9 PM", "You logged 4 gym sessions this week"), "basedOn": [ids from snapshot.activity — row ids or the block ids]}. For "month", put the direction text next to what the time shows and stop there — no advice.
  - TONE, strictly: describe, never judge. Never use: wasted, should, failed, bad, lazy, "you need to", "you ought to", "unproductive", "too much", "too little", "not enough", or any comparison implying a correct amount of time. No advice, no verdicts, no praise-as-pressure. If nothing is genuinely notable, return [] — silence is the right answer.
  - "activityCategories": for texts listed in snapshot.activity.uncategorizedTexts ONLY, propose [{"text": "<exact text as sent>", "category": one of snapshot.activity.categories}]. Skip anything ambiguous.
- Empty arrays are the right answer for an unremarkable snapshot: {"dormantIntentions":[],"hintUpdates":[],"observations":[],"reminderProposals":[],"timeObservations":[],"activityCategories":[]}.
''';
