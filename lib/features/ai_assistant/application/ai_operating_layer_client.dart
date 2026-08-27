import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/ai/ai_proxy_client.dart';
import '../../../core/ai/ai_remote_config_service.dart';
import '../domain/models/ai_action.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import '../domain/models/ai_planned_changes.dart';
import '../domain/models/ai_response_type.dart';
import 'ai_action_param_normaliser.dart';
import 'ai_capability_registry.dart';

// ─── Abstract client ──────────────────────────────────────────────────────────

/// Provider-agnostic client for the AI Operating Layer.
///
/// Concrete implementations convert a [AiOperatingLayerPayload] into a
/// structured [AiPlannedChanges] without writing to any database.
abstract class AiOperatingLayerClient {
  /// Parse the user's intent and return a plan (or a follow-up question).
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload);
}

// ─── Exception ────────────────────────────────────────────────────────────────

class AiOperatingLayerException implements Exception {
  const AiOperatingLayerException(
    this.message, {
    this.statusCode,
    this.isNetwork = false,
    this.isTimeout = false,
    this.turnId,
  });

  final String message;
  final int? statusCode;

  /// Connectivity failure (P2-13) — surfaces show "you're offline" copy
  /// instead of a generic error that blames the request.
  final bool isNetwork;

  /// The round-trip TOOK TOO LONG (fix-wave Phase 3, §8 H3) — distinct
  /// copy from offline, and the abandoned turn was already charged, so a
  /// retry should reuse [turnId].
  final bool isTimeout;

  /// The turnId of the failed turn. A retry that passes it back rides the
  /// server's same-turn window (loopIndex > 0 within 3 minutes is FREE) —
  /// without it, every retry double-charged the hourly quota (§8 H1/H3).
  final String? turnId;

  bool get isRateLimit => statusCode == 429;

  @override
  String toString() =>
      'AiOperatingLayerException($message'
      '${statusCode != null ? ", status=$statusCode" : ""}'
      '${isNetwork ? ", network" : ""}${isTimeout ? ", timeout" : ""})';
}

// ─── System prompt (agent mode) ───────────────────────────────────────────────
//
// The model converses in natural language and uses OpenAI tool calling for
// everything structured:
//   - propose_changes  → mapped to the preview/confirm card (writes NEVER
//     execute without the user pressing Confirm)
//   - get_day_schedule → read-only lookup for days beyond today/tomorrow
// Plain text responses become informational chat messages (markdown-lite).
//
/// Appended to the system prompt on spoken turns (Voice Mode, latency
/// batch 2026-08-07): the reply is read aloud, so short conversational
/// prose is both faster to generate and better to hear. Tool use is
/// deliberately untouched — a spoken "add a task tomorrow" still plans.
const String _kVoiceModeAddendum = '''

## VOICE MODE (this turn)
The user is speaking by voice and your reply will be read aloud.
- Reply in 1–3 short conversational sentences (under 60 words total).
- No lists, no markdown, no headings — spoken prose only.
- Tools and propose_changes work exactly as normal.
''';

/// Replaces [_kVoiceModeAddendum] on STREAMED voice turns (Level 2): the
/// aiChatStream endpoint has no tools, so the tool language must go — and a
/// misrouted change request must degrade honestly instead of the model
/// claiming (or describing) changes nothing will apply.
const String _kVoiceStreamAddendum = '''

## VOICE MODE (this turn)
The user is speaking by voice and your reply will be read aloud.
- Reply in 1–3 short conversational sentences (under 60 words total).
- No lists, no markdown, no headings — spoken prose only.
- This turn is answer-only: you cannot look up other days or change anything.
  If the user asks you to create, change, or delete something, do NOT claim
  it is done and do NOT describe a concrete plan — say one short line asking
  them to repeat it as a direct request (like "add workout at 6am") so you
  can set it up properly.
''';

/// Messages for the aiChatStream endpoint (voice Level 2): same system
/// prompt and context-grounded user prompt as the agent path, with the
/// stream addendum instead of the tool-preserving voice addendum. Prior
/// turns ride along so streamed replies stay conversation-aware; tool_calls
/// entries (assistant maps without a text content) are skipped — the
/// streaming endpoint speaks plain role/content only.
List<Map<String, String>> buildConversationalStreamMessages(
  AiOperatingLayerPayload payload,
) {
  final priorTurns = payload.conversationHistory.isNotEmpty
      ? payload.conversationHistory
      : payload.sessionHistory;
  return [
    {'role': 'system', 'content': '$_kSystemPrompt$_kVoiceStreamAddendum'},
    for (final h in priorTurns)
      if (h['role'] is String && h['content'] is String)
        {'role': h['role'] as String, 'content': h['content'] as String},
    {
      'role': 'user',
      'content': ProxyAiOperatingLayerClient._buildUserPrompt(payload),
    },
  ];
}

const String _kSystemPrompt = '''
You are Coach — the in-app AI coach of "SidePal", a personal productivity app.
Talk like a sharp, warm human coach texting with someone you know well: natural,
specific, brief. You know this user's real schedule, goals, progress, and habits —
they are provided in every message. Ground everything you say in that data and
briefly explain WHY ("your Study goal is at 2/5 days and you're free 14:00–16:00, so…").

## How you work
- Just talk. Answer questions, give advice, banter briefly, encourage — like a
  good coach. You are not limited to app topics: answer general questions
  (motivation, habits, how-to-focus, small talk) genuinely and briefly, then
  connect back to their day when it helps.
- When you need schedule data for a day that is NOT in your context, call
  get_day_schedule.
- When you want to CHANGE anything (create/edit/move/delete tasks, goals,
  reminders, focus modes), you MUST call propose_changes. The user sees a card
  and must press Confirm/Apply — you can NEVER change anything directly.
- EXCEPTION — intentions: when the user states a promise WITHOUT a fixed
  clock time ("I need to call my cousin tomorrow", "I promised to send those
  photos this week"), call propose_changes with a single createIntention
  action. Intentions auto-commit (no card): SidePal finds a good moment
  inside the window and nudges then. Reply with one short line like
  "Got it — I'll find a good time tomorrow." If the user names an exact
  time, that's a task/reminder, NOT an intention. If the window or the
  action is genuinely unclear, ask ONE clarifying question ("This week or
  by Friday?") instead of guessing — then capture.
- EXCEPTION — memory: when the user explicitly asks you to remember,
  correct, or forget something about their life ("remember that my sister's
  name is Sarah", "actually I prefer evening workouts", "forget what I said
  about the gym"), call propose_changes with rememberFact / updateFact /
  forgetFact. These also auto-commit (no card). Reply with one short
  acknowledgment. Only durable personal facts belong in memory — never
  scheduling chatter.
- Never say "I'll set that up now", "done", "I've scheduled…", or "setting it
  up" — nothing happens until the user confirms the card. Say "Here's the plan —
  confirm below" instead.
- If you describe a concrete plan (specific items + times), you must also make
  the propose_changes call in the SAME turn. Never describe a plan in prose
  without the tool call — the user would have no button to apply it.
- Never invent tasks, times, or progress numbers — only use provided data and
  tool results.
- When a FEATURE GUIDE block is present, the user is asking how the app works.
  Teach from that guide in your own friendly coach voice — stay accurate to
  the guide, connect it to their real data when it helps ("you're on a 3-day
  streak, so strict mode…"). Keep it under 100 words and end with one concrete
  next step they can take in the app.

## Memory grounding
- Long-term memory arrives as lines like "[mem:<id>|<label>] content".
  When something you say about the user's life comes from one of these,
  append its marker — just "[mem:<id>]" — at the END of the sentence that
  uses it. The app renders the marker as a small "from your memory" chip,
  so the user always sees WHY you know. Never read the marker aloud or
  explain it; never invent mem ids.
- Respect the label: "stated" facts you may assert plainly. "observed"
  facts are patterns the app measured — assert them as patterns ("you
  usually…"). "inferred" facts are guesses — hedge ("seems like…",
  "I have a feeling…") or ask, never assert.
- Never claim something personal about the user that is in neither the
  provided data nor memory. If you need it, ask — one question.

## When the user accepts your last suggestion
If your previous message suggested a plan and the user approves it
("it's good", "do it", "yes", "as you suggested", "as it is", "sounds good"),
immediately call propose_changes with the concrete items and the exact times
you already suggested. Do NOT ask "what time?" again — you already chose times;
reuse them. If your earlier times are no longer visible in the conversation,
pick sensible times from the free windows yourself instead of asking again.

## propose_changes: rules
- Parameter keys are EXACT — the app reads only these: createTask/editTask
  {title, time ("HH:mm", 24-hour), duration (minutes, integer), date
  ("today" | "tomorrow" | "YYYY-MM-DD")}; moveTask {taskTitle,
  destinationDate}; deleteTask {taskTitle}; createGoal {title, target,
  deadline}; modifyGoal {goalTitle, field ("title" | "target" |
  "deadline" | "intensity"), newValue}; deleteGoal {goalTitle};
  addReminder/rescheduleReminder {taskTitle, reminderTime ("HH:mm")};
  removeReminder {taskTitle}. Never invent keys like startTime, start,
  when, or durationMinutes — the app cannot read them.
- For edit/move/delete, pass the task or goal title as the user said it —
  the app matches it to the real item and shows the user exactly what
  will change before anything is applied.
- Presentation "preview" → the user gave a clear command ("add workout at 6am").
  Keep your text to one short confirmation line.
- createIntention parameters: title (short action phrase, e.g. "Call cousin
  Sara"), rawUtterance (the user's exact words), window ("today" |
  "tomorrow" | "this_week" | "weekend"), estimatedMinutes, importance
  ("low" | "normal" | "high"), activityTags (e.g. ["call"]), and optional
  aiHints ({"preferredTimeBlock": "morning" | "afternoon" | "evening"} when
  you have a real basis for an opinion). Never mix createIntention with
  other action types in one call.
- rememberFact parameters: content (third-person statement, ≤200 chars,
  e.g. "Prefers morning workouts"), kind ("semanticFact" | "preference" |
  "learnedPattern" | "promiseNote" | "observation"), rawUtterance (the
  user's exact words), optional personName. updateFact parameters: factRef
  (the current content of the fact to change, as close to verbatim as you
  know it) and newContent. forgetFact parameters: factRef. Never mix
  memory actions with other action types in one call.
- Presentation "suggestion" → the plan is YOUR idea ("help me plan tomorrow",
  "what should I do?"). Write a short coaching message: one sentence reading
  their day, the items with times and a reason each, one engaging closing line.
- EVERY createTask needs a concrete time. If the user didn't give one, pick a
  sensible time from their free windows — never leave it blank.
- For a brand-new activity that has no matching existing task (e.g. "sleep at
  11pm", "meditate"), use createTask with that time — do NOT use addReminder,
  which only attaches to a task that already exists.

## Planning method (when suggesting)
1. Check goalProgress — who is behind (daysMet vs target pace)?
2. Place items inside the free windows provided — never on top of existing
   blocks. "reminder only" items are notifications, not busy time.
3. Match times/durations to recentPatterns when available.
4. If the day is full or the data looks odd (e.g. everything between midnight
   and 5am), say what you see and ask ONE question instead of forcing a plan.

## Boundaries
- Circles/community, billing, and account settings are managed in the app's own
  screens, not by you. Say so honestly in one clause, then offer the nearest
  thing you CAN do.
- Never claim a change happened before the user confirmed the plan card —
  propose_changes only PROPOSES; the app applies nothing until Confirm.
- One question at a time. Never repeat a sentence you already sent this
  conversation — if the user seems stuck, change approach and offer choices.

## Style
- Match coachingStyle from behaviorPreferences: supportive = warm; balanced =
  neutral pro; disciplined = firm, no fluff; intense = terse, commanding.
- Contractions, direct address, no corporate filler ("I am unable to…").
- Keep most replies under 80 words; plans under 120.
- Light markdown allowed: **bold** and "- " bullets. No headings, no tables.
- Dates/times are in the user's local timezone. Today's date is in the context.
''';

// ─── Proxy implementation ─────────────────────────────────────────────────────
//
// OpenAI is reached exclusively through the `aiChat` Cloud Function — the API
// key never leaves the server. The model is pinned server-side.

/// Executes read-only tools for the Coach agent loop.
///
/// Kept deliberately tiny in Phase 1: one lookup for days that are not
/// pre-loaded into the payload context.
class AiCoachToolRunner {
  const AiCoachToolRunner({required this.dayScheduleLookup});

  /// Returns a compact human-readable schedule for a YYYY-MM-DD date key.
  final Future<String> Function(String dateKey) dayScheduleLookup;

  Future<String> run(String name, Map<String, dynamic> args) async {
    switch (name) {
      case 'get_day_schedule':
        final date = args['date']?.toString() ?? '';
        if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
          return 'Error: date must be YYYY-MM-DD.';
        }
        try {
          return await dayScheduleLookup(date);
        } catch (e) {
          return 'Error: could not read schedule for $date.';
        }
      default:
        return 'Error: unknown tool "$name".';
    }
  }
}

/// OpenAI tool definitions for the Coach agent.
const List<Map<String, dynamic>> kCoachAgentTools = [
  {
    'type': 'function',
    'function': {
      'name': 'propose_changes',
      'description':
          'Propose schedule/goal/reminder changes. The user sees a preview '
          'card and must confirm — nothing is applied directly. Use '
          'presentation "preview" for explicit user commands and '
          '"suggestion" for plans that are your own idea.',
      'parameters': {
        'type': 'object',
        'properties': {
          'presentation': {
            'type': 'string',
            'enum': ['preview', 'suggestion'],
          },
          'message': {
            'type': 'string',
            'description':
                'Short coaching message to show with the plan (used when you '
                'return no assistant text).',
          },
          'actions': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'actionType': {
                  'type': 'string',
                  // suggestFreeTimeBlock/moveConflictingTasks are
                  // deliberately NOT offered: decorative read-only kinds
                  // with no executor — they used to throw mid-batch and
                  // poison confirmed plans into rollback (§8 E6). The six
                  // mutation verbs returned in fix-wave Phase 1 with real
                  // handlers (resolver-stamped ids, true edits, the full
                  // deletion set).
                  'enum': [
                    'createTask',
                    'editTask',
                    'moveTask',
                    'deleteTask',
                    'createGoal',
                    'modifyGoal',
                    'deleteGoal',
                    'addReminder',
                    'removeReminder',
                    'rescheduleReminder',
                    'activateContextOverride',
                    'endContextOverride',
                    'createIntention',
                    'rememberFact',
                    'updateFact',
                    'forgetFact',
                  ],
                },
                'parameters': {
                  'type': 'object',
                  'description':
                      'EXACT keys per actionType — createTask/editTask: '
                      'title, time ("HH:mm" 24-hour), duration (minutes, '
                      'integer), date ("today" | "tomorrow" | YYYY-MM-DD); '
                      'moveTask: taskTitle, destinationDate; deleteTask: '
                      'taskTitle; createGoal: title, target, deadline; '
                      'modifyGoal: goalTitle, field ("title" | "target" | '
                      '"deadline" | "intensity"), newValue; deleteGoal: '
                      'goalTitle; addReminder/rescheduleReminder: taskTitle, '
                      'reminderTime ("HH:mm"); removeReminder: taskTitle. '
                      'Never use startTime/start/when/durationMinutes — the '
                      'app reads only the keys above.',
                },
                'confidence': {'type': 'number'},
              },
              'required': ['actionType', 'parameters'],
            },
          },
        },
        'required': ['presentation', 'actions'],
      },
    },
  },
  {
    'type': 'function',
    'function': {
      'name': 'get_day_schedule',
      'description':
          'Read the tasks scheduled on a specific day that is not already in '
          'your context (context always includes today and tomorrow).',
      'parameters': {
        'type': 'object',
        'properties': {
          'date': {'type': 'string', 'description': 'YYYY-MM-DD'},
        },
        'required': ['date'],
      },
    },
  },
];

class ProxyAiOperatingLayerClient implements AiOperatingLayerClient {
  ProxyAiOperatingLayerClient({
    AiProxyClient? proxy,
    this.toolRunner,
    this.timeoutSeconds = 20,
  }) : _proxy = proxy ?? AiProxyClient();

  final AiProxyClient _proxy;
  final AiCoachToolRunner? toolRunner;
  final int timeoutSeconds;

  /// Max agent iterations per user turn (mirrors the server-side cap).
  static const int kMaxLoops = 3;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    final userPrompt = _buildUserPrompt(payload);

    // Use full conversationHistory (Phase 3) if present, else fall back to sessionHistory
    final priorTurns = payload.conversationHistory.isNotEmpty
        ? payload.conversationHistory
        : payload.sessionHistory;

    final messages = <Map<String, dynamic>>[
      {
        'role': 'system',
        'content': payload.voiceMode
            ? '$_kSystemPrompt$_kVoiceModeAddendum'
            : _kSystemPrompt,
      },
      // Inject prior session turns as context
      for (final h in priorTurns) h,
      {'role': 'user', 'content': userPrompt},
    ];

    // A retry reuses the failed turn's id so the server's same-turn window
    // makes it quota-free (fix-wave Phase 3); its rounds shift to
    // loopIndex >= 1, which is what the server's free-follow-up branch
    // keys on.
    final retryTurnId = payload.retryTurnId;
    final turnId = retryTurnId ??
        'turn_${DateTime.now().millisecondsSinceEpoch}_${payload.userInput.hashCode.toRadixString(16)}';
    final loopIndexOffset = retryTurnId != null ? 1 : 0;

    // One prose-plan repair per turn — a model that ignores the nudge twice
    // isn't going to comply on the third ask.
    var proseRepairAttempted = false;

    for (var loop = 0; loop <= kMaxLoops; loop++) {
      AiProxyChatResult result;
      final roundSw = Stopwatch()..start();
      try {
        result = await _proxy.chatWithTools(
          messages: messages,
          tools: kCoachAgentTools,
          turnId: turnId,
          loopIndex: (loop + loopIndexOffset).clamp(0, kMaxLoops),
          temperature: 0.45,
          // Voice turns cap lower: short spoken prose generates faster.
          // 500 (not less) so a propose_changes tool call's JSON payload
          // is never truncated mid-plan.
          maxTokens: payload.voiceMode ? 500 : 800,
          purpose: payload.voiceMode ? 'coach_agent_voice' : 'coach_agent',
          timeout: Duration(seconds: timeoutSeconds),
        );
      } on AiProxyException catch (e) {
        throw AiOperatingLayerException(
          e.message,
          statusCode: e.statusCode,
          isNetwork: e.isNetwork,
          isTimeout: e.isTimeout,
          turnId: turnId,
        );
      }
      if (kDebugMode) {
        // Per-round ledger: a slow turn is usually a HIDDEN second round
        // (read-only tool call before the answer) — name the tools so the
        // log says which one earned its round trip.
        debugPrint(
          '[ai-timing] round=$loop call=${roundSw.elapsedMilliseconds}ms '
          'tools=${result.toolCalls.isEmpty ? '-' : result.toolCalls.map((c) => c.name).join(',')}',
        );
      }

      // propose_changes is terminal — merge EVERY such call in the round
      // (models legally split one plan across two calls; taking only the
      // first silently dropped the rest) and map once.
      final proposeCalls = result.toolCalls
          .where((c) => c.name == 'propose_changes')
          .toList();
      if (proposeCalls.isNotEmpty) {
        final mapped = _mapProposedChanges(
          proposeCalls,
          result.content,
          payload.userInput,
        );
        if (mapped != null) return mapped;
        // The tool was called but nothing usable parsed. Degrading to
        // informational here is how plans became text-only bubbles with no
        // Confirm card — instead answer every call with a tool error and
        // let the model retry within the loop budget.
        if (loop < kMaxLoops) {
          messages.add(_assistantToolCallMessage(result));
          for (final call in result.toolCalls) {
            messages.add({
              'role': 'tool',
              'tool_call_id': call.id,
              'content':
                  'Error: actions was empty or malformed. Call '
                  'propose_changes again with concrete actions, using '
                  'EXACTLY the documented parameter keys.',
            });
          }
          continue;
        }
        return AiPlannedChanges(
          sessionId: payload.userInput,
          followUpQuestion:
              'I had trouble putting that plan together — could you say '
              'it once more?',
        );
      }

      // No tool calls → the model's text IS the reply — unless the text
      // DESCRIBES a concrete plan (times + confirm framing). Prose plans
      // give the user no button to press; nudge the model into the tool
      // call it skipped instead of shipping a dead-end bubble.
      if (!result.hasToolCalls) {
        final text = result.content?.trim();
        if (text == null || text.isEmpty) break;
        if (payload.intentKind != 'query' &&
            !proseRepairAttempted &&
            loop < kMaxLoops &&
            looksPlanShapedProse(text)) {
          proseRepairAttempted = true;
          messages.add({'role': 'assistant', 'content': text});
          messages.add({
            'role': 'user',
            'content':
                'You described a plan without calling propose_changes — '
                'the user has no button to apply it. Call propose_changes '
                'now with exactly those items and times.',
          });
          continue;
        }
        return AiPlannedChanges(
          sessionId: payload.userInput,
          responseType: AiResponseType.informational,
          informationalMessage: text,
        );
      }

      // Read-only tool calls: execute, feed results back, continue the loop.
      messages.add(_assistantToolCallMessage(result));
      for (final call in result.toolCalls) {
        Map<String, dynamic> args;
        try {
          args = Map<String, dynamic>.from(jsonDecode(call.arguments) as Map);
        } catch (_) {
          args = const {};
        }
        final toolResult = toolRunner != null
            ? await toolRunner!.run(call.name, args)
            : 'Error: tool unavailable.';
        messages.add({
          'role': 'tool',
          'tool_call_id': call.id,
          'content': toolResult,
        });
      }
    }

    return AiPlannedChanges(
      sessionId: payload.userInput,
      followUpQuestion:
          "I lost my train of thought there — could you say that once more?",
    );
  }

  static Map<String, dynamic> _assistantToolCallMessage(
    AiProxyChatResult result,
  ) => {
    'role': 'assistant',
    if (result.content != null && result.content!.isNotEmpty)
      'content': result.content,
    'tool_calls': [
      for (final call in result.toolCalls)
        {
          'id': call.id,
          'type': 'function',
          'function': {'name': call.name, 'arguments': call.arguments},
        },
    ],
  };

  /// Maps the round's propose_changes calls onto the preview pipeline,
  /// unioning actions across calls. Every action is normalized at ingestion
  /// (alias keys, "2 pm" → "14:00") so the missing-field detector and the
  /// executor see the documented contract regardless of model drift.
  ///
  /// Returns null when NOTHING usable parsed — the caller repairs with a
  /// tool-error round instead of degrading the plan to informational prose
  /// (the old degrade is how plans became text-only bubbles with no card).
  AiPlannedChanges? _mapProposedChanges(
    List<AiProxyToolCall> calls,
    String? assistantText,
    String sessionId,
  ) {
    final actions = <AiAction>[];
    String? presentation;
    String? argsMessage;
    for (final call in calls) {
      Map<String, dynamic> args;
      try {
        args = Map<String, dynamic>.from(jsonDecode(call.arguments) as Map);
      } catch (_) {
        continue;
      }
      presentation ??= args['presentation']?.toString();
      final msg = args['message']?.toString().trim();
      if (argsMessage == null && msg != null && msg.isNotEmpty) {
        argsMessage = msg;
      }
      var actionsRaw = args['actions'];
      // Models sometimes double-encode the array as a JSON string.
      if (actionsRaw is String) {
        try {
          actionsRaw = jsonDecode(actionsRaw);
        } catch (_) {}
      }
      if (actionsRaw is! List) continue;
      for (final entry in actionsRaw) {
        if (entry is! Map) continue;
        try {
          actions.add(
            AiActionParamNormaliser.normalise(
              AiAction.fromJson(Map<String, dynamic>.from(entry)),
            ),
          );
        } catch (e) {
          if (kDebugMode) debugPrint('[ai-map] dropped action entry: $e');
        }
      }
    }

    if (actions.isEmpty) return null;

    final message = (assistantText?.trim().isNotEmpty ?? false)
        ? assistantText!.trim()
        : argsMessage;
    final isSuggestion = presentation != 'preview';
    return AiPlannedChanges(
      sessionId: sessionId,
      responseType: isSuggestion
          ? AiResponseType.suggest
          : AiResponseType.mutate,
      informationalMessage: message,
      actions: actions,
    );
  }

  /// Test hook — the prompt layout (e.g. the FEATURE GUIDE block) is a
  /// behavioral contract worth pinning without a network call.
  @visibleForTesting
  static String debugBuildUserPrompt(AiOperatingLayerPayload payload) =>
      _buildUserPrompt(payload);

  static String _buildUserPrompt(AiOperatingLayerPayload payload) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    // Weekday named + phrasing rule (2026-08-25): without it the model
    // resolved "Sunday" to a date key and echoed the number back at the
    // user ("created for 2026-08-30" instead of "on Sunday").
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    buffer.writeln(
      'Today is ${weekdays[now.weekday - 1]}, '
      '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} (local). '
      'When speaking to the user, refer to dates the way people do — '
      '"today", "tomorrow", or the weekday name ("on Sunday") — never a '
      'raw YYYY-MM-DD; keep the numeric form only inside tool parameters.',
    );
    buffer.writeln();
    buffer.writeln('User request: "${payload.userInput}"');
    buffer.writeln();

    if (payload.intentHint != null) {
      buffer.writeln(payload.intentHint);
      buffer.writeln();
    }

    if (payload.featureGuide != null) {
      buffer.writeln(
        "FEATURE GUIDE (app documentation for the user's question):",
      );
      buffer.writeln(payload.featureGuide);
      buffer.writeln();
    }

    if (payload.activeTasks.isNotEmpty) {
      buffer.writeln("Today's tasks:");
      for (final t in payload.activeTasks) {
        buffer.writeln(
          '  - ${t['title']} at ${t['time'] ?? 'no time'} (${t['duration'] ?? '?'} min, ${t['status'] ?? 'pending'})',
        );
      }
      buffer.writeln();
    }

    if (payload.goals.isNotEmpty) {
      buffer.writeln('Active goals:');
      for (final g in payload.goals) {
        buffer.writeln(
          '  - ${g['title']} (target: ${g['target'] ?? '?'}, deadline: ${g['deadline'] ?? '?'})',
        );
      }
      buffer.writeln();
    }

    if (payload.goalProgress.isNotEmpty) {
      buffer.writeln('Goal progress this period:');
      for (final g in payload.goalProgress) {
        buffer.writeln(
          '  - ${g['title']}: ${g['daysMet']}/${g['target']} '
          '(${g['daysElapsed']}/${g['totalDays']} days, ${g['periodSummary']})',
        );
      }
      buffer.writeln();
    }

    if (payload.todaySchedule.isNotEmpty) {
      buffer.writeln("Today's schedule blocks:");
      for (final s in payload.todaySchedule) {
        buffer.writeln('  - ${s['title']} ${s['startTime']}–${s['endTime']}');
      }
      buffer.writeln();
    } else {
      buffer.writeln("Today's schedule blocks: (none)");
      buffer.writeln();
    }

    if (payload.tomorrowTasks.isNotEmpty) {
      buffer.writeln("Tomorrow's tasks:");
      for (final t in payload.tomorrowTasks) {
        buffer.writeln(
          '  - ${t['title']} at ${t['time'] ?? 'no time'} (${t['duration'] ?? '?'}, ${t['status'] ?? 'pending'})',
        );
      }
      buffer.writeln();
    } else {
      buffer.writeln("Tomorrow's tasks: (none)");
      buffer.writeln();
    }

    if (payload.tomorrowSchedule.isNotEmpty) {
      buffer.writeln("Tomorrow's schedule blocks:");
      for (final s in payload.tomorrowSchedule) {
        buffer.writeln('  - ${s['title']} ${s['startTime']}–${s['endTime']}');
      }
      buffer.writeln();
    } else {
      buffer.writeln("Tomorrow's schedule blocks: (none)");
      buffer.writeln();
    }

    if (payload.todayFreeWindows.isNotEmpty) {
      buffer.writeln(
        'Free windows today (07:00–22:00, remaining): '
        '${payload.todayFreeWindows.join(', ')}',
      );
      buffer.writeln();
    }

    if (payload.tomorrowFreeWindows.isNotEmpty) {
      buffer.writeln(
        'Free windows tomorrow (07:00–22:00): '
        '${payload.tomorrowFreeWindows.join(', ')}',
      );
      buffer.writeln();
    }

    if (payload.weekOverview.isNotEmpty) {
      buffer.writeln('Week overview (next 7 days):');
      for (final day in payload.weekOverview) {
        buffer.writeln(
          '  - ${day['label']} (${day['date']}): '
          '${day['taskCount']} tasks, ${day['scheduledCount']} scheduled',
        );
      }
      buffer.writeln();
    }

    if (payload.proactiveContext != null) {
      buffer.writeln(
        'Proactive suggestion context: ${payload.proactiveContext}',
      );
      buffer.writeln();
    }

    if (payload.contextOverride != null) {
      buffer.writeln('Active override: ${payload.contextOverride}');
    }

    if (payload.focusState['isActive'] == true) {
      final type = payload.focusState['type'] ?? 'unknown';
      final endsAt = payload.focusState['endsAt'];
      buffer.writeln(
        'Focus state: ACTIVE ($type${endsAt != null ? ", ends at $endsAt" : ""})',
      );
    }

    if (payload.behaviorPreferences.isNotEmpty) {
      buffer.writeln('User preferences: ${payload.behaviorPreferences}');
    }

    if (payload.recentPatterns.isNotEmpty) {
      buffer.writeln('Recent activity patterns:');
      for (final p in payload.recentPatterns) {
        buffer.writeln(
          '  - ${p['category']}: ${p['frequency']} times in last 14 days'
          '${p['lastUsedTime'] != null ? ", usually at ${p['lastUsedTime']}" : ""}'
          '${p['lastUsedDuration'] != null ? ", ~${p['lastUsedDuration']}" : ""}',
        );
      }
      buffer.writeln();
    }

    if (payload.memoryFacts.isNotEmpty) {
      buffer.writeln(
        'What you know about the user (long-term memory — cite the [mem:…] '
        'marker when you use one):',
      );
      for (final line in payload.memoryFacts) {
        buffer.writeln('  - $line');
      }
      buffer.writeln();
    }

    if (payload.peopleDigest.isNotEmpty) {
      buffer.writeln('People in their life:');
      for (final line in payload.peopleDigest) {
        buffer.writeln('  - $line');
      }
      buffer.writeln();
    }

    if (payload.episodicSummaries.isNotEmpty) {
      buffer.writeln('Summaries of recent conversations:');
      for (final line in payload.episodicSummaries) {
        buffer.writeln('  - $line');
      }
      buffer.writeln();
    }

    if (payload.openPromises.isNotEmpty) {
      buffer.writeln(
        'Promises already captured (do NOT create these again):',
      );
      for (final line in payload.openPromises) {
        buffer.writeln('  - $line');
      }
      buffer.writeln();
    }

    if (payload.deviceContext.isNotEmpty) {
      buffer.writeln(
        'Device context (coarse labels only — never invent details '
        'beyond them):',
      );
      for (final label in payload.deviceContext) {
        buffer.writeln('  - $label');
      }
      buffer.writeln();
    }

    if (payload.completedInSession.isNotEmpty) {
      buffer.writeln(
        'Already applied this session (do NOT repeat in actions or follow-ups):',
      );
      for (final line in payload.completedInSession) {
        buffer.writeln('  - $line');
      }
      buffer.writeln();
    }

    if (payload.previousPlan != null) {
      buffer.writeln('Previous plan (user is refining this):');
      buffer.writeln('  ${payload.previousPlan}');
      buffer.writeln();
    }

    return buffer.toString();
  }
}

// ─── Factory helper ───────────────────────────────────────────────────────────

/// Builds the correct client from Remote Config.
///
/// When the `ai_enabled` kill switch is off: release builds get
/// [DisabledAiOperatingLayerClient] — an honest "Coach is unavailable"
/// answer for every turn. The old behavior routed production to
/// [MockAiOperatingLayerClient], whose canned "Morning Workout" plan
/// REALLY executed on confirm — during exactly the incidents where trust
/// matters most, the coach fabricated (fix-wave Phase 0, §8 H6). The mock
/// stays available in debug builds for offline UI work.
Future<AiOperatingLayerClient> buildAiOperatingLayerClient({
  AiCoachToolRunner? toolRunner,
}) async {
  final aiEnabled = await AiRemoteConfigService.instance.isAiEnabled();

  if (!aiEnabled) {
    if (kDebugMode) {
      debugPrint('[AiOperatingLayer] AI disabled remotely — mock (debug).');
      return const MockAiOperatingLayerClient();
    }
    debugPrint('[AiOperatingLayer] AI disabled remotely — honest fallback.');
    return const DisabledAiOperatingLayerClient();
  }

  return ProxyAiOperatingLayerClient(toolRunner: toolRunner);
}

// ─── Disabled client (kill switch) ────────────────────────────────────────────

/// The honest kill-switch client: every turn gets the same truthful
/// unavailable answer. Never fabricates plans, never executes anything.
class DisabledAiOperatingLayerClient implements AiOperatingLayerClient {
  const DisabledAiOperatingLayerClient();

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    return AiPlannedChanges(
      sessionId: payload.userInput,
      responseType: AiResponseType.informational,
      informationalMessage:
          "I'm taking a short break for maintenance — your schedule, "
          'tasks, goals, and reminders all keep working as normal from '
          "the app's own screens. Check back in a bit.",
    );
  }
}

// ─── Mock client ──────────────────────────────────────────────────────────────

/// Deterministic mock — schedule queries return informational answers;
/// other inputs return a sample createTask plan for testing.
class MockAiOperatingLayerClient implements AiOperatingLayerClient {
  const MockAiOperatingLayerClient({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (shouldFail) {
      throw const AiOperatingLayerException('Mock forced failure');
    }

    final unsupported = AiCapabilityRegistry.detectUnsupported(
      payload.userInput,
    );
    if (unsupported != null) {
      return AiPlannedChanges(
        sessionId: payload.userInput,
        responseType: AiResponseType.unsupported,
        informationalMessage: unsupported.message,
        suggestedPrompts: unsupported.suggestedPrompts,
      );
    }

    if (_looksLikeScheduleQuery(payload.userInput)) {
      return _mockInformationalScheduleAnswer(payload);
    }

    if (_looksLikeSuggestRequest(payload.userInput)) {
      return _mockSuggestPlanAnswer(payload);
    }

    return AiPlannedChanges(
      sessionId: payload.userInput,
      actions: [
        AiAction(
          actionType: ActionType.createTask,
          parameters: {
            'title': 'Morning Workout',
            'time': '06:00',
            'duration': 30,
            'date': 'tomorrow',
          },
          confidence: 0.95,
        ),
      ],
      conflicts: const [],
    );
  }

  static bool _looksLikeScheduleQuery(String input) {
    final lower = input.toLowerCase();
    const queryWords = [
      'what',
      'show',
      'tell me',
      'list',
      'how many',
      'what\'s',
      'whats',
    ];
    const scheduleWords = [
      'plan',
      'schedule',
      'tomorrow',
      'today',
      'on my',
      'this week',
    ];
    final hasQuery = queryWords.any(lower.contains);
    final hasSchedule = scheduleWords.any(lower.contains);
    return hasQuery && hasSchedule;
  }

  static bool _looksLikeSuggestRequest(String input) {
    final lower = input.toLowerCase();
    const suggestWords = [
      'help me plan',
      'suggest',
      'recommend',
      'plan my',
      'plan tomorrow',
    ];
    return suggestWords.any(lower.contains);
  }

  static AiPlannedChanges _mockSuggestPlanAnswer(
    AiOperatingLayerPayload payload,
  ) {
    final lower = payload.userInput.toLowerCase();
    final forTomorrow = lower.contains('tomorrow');
    final date = forTomorrow ? 'tomorrow' : 'today';

    return AiPlannedChanges(
      sessionId: payload.userInput,
      responseType: AiResponseType.suggest,
      informationalMessage:
          '${forTomorrow ? 'Tomorrow' : 'Today'} morning looks open. '
          'I\'d add Study at 9:00 and a Workout at 18:00.',
      actions: [
        AiAction(
          actionType: ActionType.createTask,
          parameters: {
            'title': 'Study',
            'time': '09:00',
            'duration': 45,
            'date': date,
          },
          confidence: 0.9,
        ),
        AiAction(
          actionType: ActionType.createTask,
          parameters: {
            'title': 'Workout',
            'time': '18:00',
            'duration': 30,
            'date': date,
          },
          confidence: 0.85,
        ),
      ],
      suggestedPrompts: const ['Apply this plan'],
    );
  }

  static AiPlannedChanges _mockInformationalScheduleAnswer(
    AiOperatingLayerPayload payload,
  ) {
    final lower = payload.userInput.toLowerCase();
    final forTomorrow = lower.contains('tomorrow');
    final tasks = forTomorrow ? payload.tomorrowTasks : payload.activeTasks;
    final schedule = forTomorrow
        ? payload.tomorrowSchedule
        : payload.todaySchedule;
    final label = forTomorrow ? 'tomorrow' : 'today';

    final buffer = StringBuffer('Here\'s your plan for $label:\n');
    if (schedule.isNotEmpty) {
      for (final block in schedule) {
        buffer.writeln(
          '• ${block['title']} ${block['startTime']}–${block['endTime']}',
        );
      }
    } else if (tasks.isNotEmpty) {
      for (final task in tasks) {
        buffer.writeln(
          '• ${task['title']} at ${task['time']} (${task['duration']})',
        );
      }
    } else {
      buffer.writeln('Nothing scheduled yet.');
    }

    return AiPlannedChanges(
      sessionId: payload.userInput,
      responseType: AiResponseType.informational,
      informationalMessage: buffer.toString().trim(),
      suggestedPrompts: forTomorrow
          ? const ['Add a task for tomorrow at 9am']
          : const ['What\'s my plan for tomorrow?'],
    );
  }
}
