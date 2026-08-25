import 'package:flutter/foundation.dart';

import '../../../core/ai/ai_proxy_client.dart';
import '../../../core/ai/ai_remote_config_service.dart';
import '../../../core/utils/stable_id.dart';
import '../../ai_assistant/data/ai_interaction_history_repository.dart';
import '../../intentions/application/intention_capture.dart';
import '../../intentions/data/intentions_repository.dart';
import '../../intentions/domain/models/intention.dart';
import '../data/memory_facts_repository.dart';
import '../data/memory_session_state_repository.dart';
import '../data/people_repository.dart';
import '../domain/models/memory_fact.dart';
import '../domain/models/person.dart';
import '../../thinking/application/reflection_parser.dart';
import 'memory_extraction_parser.dart';

/// Post-conversation memory extraction + summarize-then-purge (PRD §5.2).
///
/// Client-triggered, purpose-routed (`extract_memory`, system budget,
/// silent-skip), ≤1 call per session end. The failure story is explicit:
/// if extraction can't run (offline, AI down, budget out) the 48h purge
/// DEFERS for that session — up to 7 days, then a deterministic truncation
/// summary is written and the raw turns purge. Memory continuity is never
/// silently lost, and raw turns never outlive the deferral ceiling.
class MemoryExtractionService {
  MemoryExtractionService({
    required AiInteractionHistoryRepository history,
    required MemoryFactsRepository facts,
    required PeopleRepository people,
    required MemorySessionStateRepository sessionState,
    required IntentionsRepository intentions,
    AiProxyClient? proxy,
    AiRemoteConfigService? remoteConfig,
  }) : _history = history,
       _facts = facts,
       _people = people,
       _sessionState = sessionState,
       _intentions = intentions,
       _proxy = proxy ?? AiProxyClient(),
       _remoteConfig = remoteConfig ?? AiRemoteConfigService.instance;

  final AiInteractionHistoryRepository _history;
  final MemoryFactsRepository _facts;
  final PeopleRepository _people;
  final MemorySessionStateRepository _sessionState;
  final IntentionsRepository _intentions;
  final AiProxyClient _proxy;
  final AiRemoteConfigService _remoteConfig;

  /// A session is considered ended after this much silence.
  static const Duration inactivityGate = Duration(minutes: 30);

  /// Raw turns purge this long after the session's last interaction —
  /// but only once the session is extracted or truncated.
  static const Duration purgeAfter = Duration(hours: 48);

  /// How long the purge may defer waiting for extraction to succeed.
  static const Duration deferralCeiling = Duration(days: 7);

  /// Dormant observations get a wide, quiet window; they generate zero
  /// notifications until engaged (only `open` intentions are plannable).
  static const Duration observationWindow = Duration(days: 60);

  // ─── Session lifecycle ──────────────────────────────────────────────────

  /// Called on every Coach turn — keeps the session's inactivity clock
  /// fresh so maintenance knows when it actually ended.
  Future<void> noteSessionActivity(String sessionId) async {
    try {
      await _sessionState.markPending(
        sessionId,
        DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[MemoryExtraction] noteSessionActivity failed: $e');
    }
  }

  /// Best-effort immediate extraction — called when a session visibly ends
  /// (Coach sheet closed / session reset). Failures stay `pending` and the
  /// maintenance sweep retries.
  Future<void> onSessionEnded(String sessionId) async {
    try {
      final state = await _sessionState.getBySessionId(sessionId);
      if (state == null || state.status != 'pending') return;
      await _extractSession(sessionId);
    } catch (e) {
      debugPrint('[MemoryExtraction] onSessionEnded failed: $e');
    }
  }

  // ─── Maintenance (bootstrap) ────────────────────────────────────────────

  /// The summarize-then-purge sweep. Replaces the blind 48h delete.
  Future<void> runMaintenance({DateTime? now}) async {
    final clock = now ?? DateTime.now();
    final nowMs = clock.millisecondsSinceEpoch;
    try {
      await _adoptLegacySessions(nowMs);

      // 1. Retry extraction for ended-but-unextracted sessions.
      final pending = await _sessionState.pendingSessions();
      for (final state in pending) {
        final idleMs = nowMs - state.lastInteractionAtMs;
        if (idleMs < inactivityGate.inMilliseconds) continue;
        final extracted = await _extractSession(state.sessionId);
        if (!extracted && idleMs > deferralCeiling.inMilliseconds) {
          // Deferral ceiling hit — write the deterministic truncation
          // summary so continuity survives, then let the purge proceed.
          await _writeTruncationSummary(state.sessionId);
          await _sessionState.markTruncated(state.sessionId);
        }
      }

      // 2. Purge raw turns older than 48h — ONLY for settled sessions.
      final oldRows = await _history.getOlderThan(
        nowMs - purgeAfter.inMilliseconds,
      );
      final oldSessionIds = oldRows.map((r) => r.sessionId).toSet();
      final purgeable = <String>[];
      for (final sessionId in oldSessionIds) {
        final state = await _sessionState.getBySessionId(sessionId);
        if (state == null) continue; // adopted next sweep
        if (state.status == 'pending') continue; // deferred
        if (nowMs - state.lastInteractionAtMs < purgeAfter.inMilliseconds) {
          continue; // session tail is younger than the purge window
        }
        purgeable.add(sessionId);
      }
      await _history.purgeSessions(purgeable);

      // 3. Drop bookkeeping for sessions long gone.
      await _sessionState.deleteBefore(
        nowMs - (deferralCeiling.inMilliseconds * 2),
      );
    } catch (e) {
      debugPrint('[MemoryExtraction] runMaintenance failed: $e');
    }
  }

  /// Sessions that predate this feature (or missed their activity note)
  /// get a state row so they flow through the same extract-then-purge path.
  Future<void> _adoptLegacySessions(int nowMs) async {
    final oldRows = await _history.getOlderThan(nowMs);
    final latestBySession = <String, int>{};
    for (final row in oldRows) {
      final current = latestBySession[row.sessionId] ?? 0;
      if (row.timestampMs > current) {
        latestBySession[row.sessionId] = row.timestampMs;
      }
    }
    for (final entry in latestBySession.entries) {
      final existing = await _sessionState.getBySessionId(entry.key);
      if (existing == null) {
        await _sessionState.markPending(entry.key, entry.value);
      }
    }
  }

  // ─── Extraction ─────────────────────────────────────────────────────────

  /// Runs extract_memory for one session. Returns true when the session
  /// reached `extracted` (including the trivial-session no-op).
  Future<bool> _extractSession(String sessionId) async {
    final rows = await _history.getAllForSession(sessionId);
    if (rows.isEmpty) {
      await _sessionState.markExtracted(sessionId);
      return true;
    }
    final transcript = _buildTranscript(rows);
    if (transcript.trim().isEmpty) {
      await _sessionState.markExtracted(sessionId);
      return true;
    }

    if (!await _remoteConfig.isAiEnabled()) {
      await _sessionState.bumpAttemptCount(sessionId);
      return false;
    }

    String content;
    try {
      content = await _proxy.chat(
        messages: [
          {'role': 'system', 'content': _kExtractionSystemPrompt},
          {'role': 'user', 'content': transcript},
        ],
        // Temperature/model/token cap are pinned server-side by the
        // purpose routing table; values here are advisory.
        temperature: 0,
        maxTokens: 900,
        purpose: 'extract_memory',
        timeout: const Duration(seconds: 30),
      );
    } on AiProxyException catch (e) {
      // Offline, AI down, kill-switched, or system budget exhausted —
      // all silent-skip: stay pending, the sweep retries, purge defers.
      debugPrint('[MemoryExtraction] extract_memory failed: ${e.message}');
      await _sessionState.bumpAttemptCount(sessionId);
      return false;
    } catch (e) {
      debugPrint('[MemoryExtraction] extract_memory failed: $e');
      await _sessionState.bumpAttemptCount(sessionId);
      return false;
    }

    final parsed = MemoryExtractionParser.parse(content, transcript);
    await _persistExtraction(sessionId, parsed, transcript);
    await _sessionState.markExtracted(sessionId);
    return true;
  }

  Future<void> _persistExtraction(
    String sessionId,
    ParsedExtraction parsed,
    String transcript,
  ) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // People first, so facts can link personId.
    final personIdByName = <String, String>{};
    for (final candidate in parsed.people) {
      final existing = await _people.findByReference(candidate.name);
      if (existing != null) {
        personIdByName[candidate.name.toLowerCase()] = existing.id;
        // A conversation mentioning them is a deterministic interaction.
        await _people.recordInteraction(existing.id, nowMs);
        continue;
      }
      final person = Person(
        id: StableId.generate('person'),
        displayName: candidate.name,
        relationship: candidate.relationship,
        kind: normalizeRelationship(candidate.relationship),
        aliases: candidate.aliases,
        provenance: candidate.provenance,
        lastInteractionAtMs: nowMs,
        createdAtMs: nowMs,
        updatedAtMs: nowMs,
      );
      await _people.upsertPerson(person);
      personIdByName[candidate.name.toLowerCase()] = person.id;
    }

    // Facts, deduped against live content.
    final existingFacts = await _facts.fetchFactsOnce();
    final existingContents = existingFacts
        .map((f) => MemoryExtractionParser.normalizeForMatch(f.content))
        .toSet();
    for (final candidate in parsed.facts) {
      final normalized = MemoryExtractionParser.normalizeForMatch(
        candidate.content,
      );
      if (existingContents.contains(normalized)) continue;
      existingContents.add(normalized);

      String? personId;
      if (candidate.personName != null) {
        personId = personIdByName[candidate.personName!.toLowerCase()];
        personId ??= (await _people.findByReference(candidate.personName!))?.id;
      }
      await _facts.upsertFact(
        MemoryFact(
          id: StableId.generate('memfact'),
          kind: candidate.kind,
          content: candidate.content,
          structuredJson: candidate.structuredJson,
          personId: personId,
          provenance: candidate.provenance,
          confidence: candidate.confidence,
          sourceQuote: candidate.sourceQuote,
          sourceSessionId: sessionId,
          createdAtMs: nowMs,
          updatedAtMs: nowMs,
        ),
      );
    }

    // Dormant observations → dormant intentions ("on your radar"; zero
    // notifications until the user or an opportunity wakes them). Deduped
    // against every existing title — tombstones included, so a promise the
    // user removed can't be resurrected from an old chat observation.
    final existingTitleKeys = {
      for (final i in await _intentions.fetchAllIncludingTombstones())
        ReflectionParser.titleKey(i.title),
    };
    for (final observation in parsed.observations) {
      if (existingTitleKeys.contains(
        ReflectionParser.titleKey(observation.title),
      )) {
        continue;
      }
      final now = DateTime.now();
      final intention = buildIntention(
        IntentionDraft(
          title: observation.title,
          rawUtterance: observation.title,
          windowStart: now,
          windowEnd: now.add(observationWindow),
          estimatedMinutes: observation.estimatedMinutes,
        ),
        now: now,
      ).copyWith(status: IntentionStatus.dormant);
      await _intentions.upsertIntention(intention);
    }

    // Episodic summary — the LLM distillation (aiInferred: hedged, labeled).
    if (parsed.summary != null) {
      await _facts.upsertFact(
        MemoryFact(
          id: StableId.generate('memfact'),
          kind: MemoryFactKind.episodicSummary,
          content: parsed.summary!.length > 200
              ? parsed.summary!.substring(0, 200)
              : parsed.summary!,
          provenance: MemoryProvenance.aiInferred,
          confidence: 0.8,
          sourceSessionId: sessionId,
          createdAtMs: nowMs,
          updatedAtMs: nowMs,
        ),
      );
    }
  }

  /// The deterministic fallback summary (no LLM): first user turns,
  /// truncated. Weaker than a real distillation, but continuity survives.
  Future<void> _writeTruncationSummary(String sessionId) async {
    final rows = await _history.getAllForSession(sessionId);
    if (rows.isEmpty) return;
    final topics = rows
        .map((r) => r.userInput.trim())
        .where((s) => s.isNotEmpty)
        .take(3)
        .join('; ');
    if (topics.isEmpty) return;
    final content = 'Talked about: $topics';
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await _facts.upsertFact(
      MemoryFact(
        id: StableId.generate('memfact'),
        kind: MemoryFactKind.episodicSummary,
        content: content.length > 200 ? content.substring(0, 200) : content,
        provenance: MemoryProvenance.derivedDeterministic,
        confidence: 1.0,
        sourceSessionId: sessionId,
        createdAtMs: nowMs,
        updatedAtMs: nowMs,
      ),
    );
  }

  static String _buildTranscript(List<dynamic> rows) {
    final buffer = StringBuffer();
    for (final row in rows) {
      final userInput = (row.userInput as String).trim();
      if (userInput.isNotEmpty) buffer.writeln('User: $userInput');
      final summary = (row.assistantSummary as String?)?.trim();
      if (summary != null && summary.isNotEmpty) {
        buffer.writeln('Assistant: $summary');
      }
    }
    // Bound the payload — extraction reads the shape of the conversation,
    // not every token of a marathon session.
    final text = buffer.toString();
    return text.length > 12000 ? text.substring(text.length - 12000) : text;
  }
}

const _kExtractionSystemPrompt = '''
You extract durable memory from a coaching-app conversation transcript between a user and their assistant.

Return STRICT JSON only, no prose:
{
  "facts": [
    {
      "kind": "semanticFact|preference|learnedPattern|promiseNote|observation",
      "content": "third-person statement about the user, max 200 chars",
      "quote": "VERBATIM sentence from a 'User:' line that states this, or null",
      "personName": "name if the fact is about a specific person, else null",
      "structured": {"preferredTimeBlock": "morning|afternoon|evening"} or null,
      "confidence": 0.0-1.0
    }
  ],
  "people": [
    {
      "name": "Sarah",
      "relationship": "sister" or null,
      "aliases": ["my sister"],
      "quote": "VERBATIM 'User:' sentence introducing them, or null"
    }
  ],
  "observations": [
    {"title": "Reconnect with college friends", "estimatedMinutes": 30}
  ],
  "summary": "2-4 sentence summary of what was discussed and decided, or null if trivial"
}

Rules:
- Extract only DURABLE information: stable life facts, preferences, patterns, people, standing wishes. Not one-off scheduling chatter.
- "quote" must be copied VERBATIM from the transcript. If you are inferring rather than quoting, set quote to null — inferences are welcome but must not carry a quote.
- "observations" are standing wishes with no deadline ("wants to get back into climbing"). Max 3.
- Max 8 facts, 5 people. Empty arrays are fine; so is {"facts":[],"people":[],"observations":[],"summary":null}.
- Never invent people or facts not grounded in the transcript.
''';
