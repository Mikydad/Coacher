import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/ai/ai_proxy_client.dart';
import '../../../core/ai/ai_remote_config_service.dart';
import '../domain/models/ai_action.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import '../domain/models/ai_planned_changes.dart';
import '../domain/models/ai_response_type.dart';
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
  const AiOperatingLayerException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isRateLimit => statusCode == 429;

  @override
  String toString() =>
      'AiOperatingLayerException($message'
      '${statusCode != null ? ", status=$statusCode" : ""})';
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
const String _kSystemPrompt = '''
You are Coach — the in-app AI coach of "Coach for Life", a personal productivity app.
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
- Never say "I'll set that up now", "done", "I've scheduled…", or "setting it
  up" — nothing happens until the user confirms the card. Say "Here's the plan —
  confirm below" instead.
- If you describe a concrete plan (specific items + times), you must also make
  the propose_changes call in the SAME turn. Never describe a plan in prose
  without the tool call — the user would have no button to apply it.
- Never invent tasks, times, or progress numbers — only use provided data and
  tool results.

## When the user accepts your last suggestion
If your previous message suggested a plan and the user approves it
("it's good", "do it", "yes", "as you suggested", "as it is", "sounds good"),
immediately call propose_changes with the concrete items and the exact times
you already suggested. Do NOT ask "what time?" again — you already chose times;
reuse them. If your earlier times are no longer visible in the conversation,
pick sensible times from the free windows yourself instead of asking again.

## propose_changes: rules
- Presentation "preview" → the user gave a clear command ("add workout at 6am").
  Keep your text to one short confirmation line.
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
                    'suggestFreeTimeBlock',
                    'moveConflictingTasks',
                  ],
                },
                'parameters': {'type': 'object'},
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
      {'role': 'system', 'content': _kSystemPrompt},
      // Inject prior session turns as context
      for (final h in priorTurns) h,
      {'role': 'user', 'content': userPrompt},
    ];

    final turnId =
        'turn_${DateTime.now().millisecondsSinceEpoch}_${payload.userInput.hashCode.toRadixString(16)}';

    for (var loop = 0; loop <= kMaxLoops; loop++) {
      AiProxyChatResult result;
      try {
        result = await _proxy.chatWithTools(
          messages: messages,
          tools: kCoachAgentTools,
          turnId: turnId,
          loopIndex: loop,
          temperature: 0.45,
          maxTokens: 800,
          purpose: 'coach_agent',
          timeout: Duration(seconds: timeoutSeconds),
        );
      } on AiProxyException catch (e) {
        throw AiOperatingLayerException(e.message, statusCode: e.statusCode);
      }

      // A propose_changes call is terminal — map it to the preview pipeline.
      for (final call in result.toolCalls) {
        if (call.name == 'propose_changes') {
          return _mapProposedChanges(call, result.content, payload.userInput);
        }
      }

      // No tool calls → the model's text IS the reply.
      if (!result.hasToolCalls) {
        final text = result.content?.trim();
        if (text == null || text.isEmpty) break;
        return AiPlannedChanges(
          sessionId: payload.userInput,
          responseType: AiResponseType.informational,
          informationalMessage: text,
        );
      }

      // Read-only tool calls: execute, feed results back, continue the loop.
      messages.add({
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
      });
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

  /// Maps a propose_changes tool call onto the existing preview pipeline.
  AiPlannedChanges _mapProposedChanges(
    AiProxyToolCall call,
    String? assistantText,
    String sessionId,
  ) {
    Map<String, dynamic> args;
    try {
      args = Map<String, dynamic>.from(jsonDecode(call.arguments) as Map);
    } catch (_) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion:
            'I had trouble putting that plan together — could you rephrase it?',
      );
    }

    final actionsRaw = args['actions'];
    final actions = <AiAction>[];
    if (actionsRaw is List) {
      for (final entry in actionsRaw) {
        if (entry is! Map) continue;
        try {
          actions.add(AiAction.fromJson(Map<String, dynamic>.from(entry)));
        } catch (_) {
          // Skip malformed entries; keep the rest of the plan.
        }
      }
    }

    final message = (assistantText?.trim().isNotEmpty ?? false)
        ? assistantText!.trim()
        : (args['message']?.toString().trim().isNotEmpty ?? false)
        ? args['message'].toString().trim()
        : null;

    if (actions.isEmpty) {
      return AiPlannedChanges(
        sessionId: sessionId,
        responseType: AiResponseType.informational,
        informationalMessage:
            message ?? "I couldn't turn that into concrete changes yet.",
      );
    }

    final isSuggestion = args['presentation'] != 'preview';
    return AiPlannedChanges(
      sessionId: sessionId,
      responseType: isSuggestion
          ? AiResponseType.suggest
          : AiResponseType.mutate,
      informationalMessage: message,
      actions: actions,
    );
  }

  String _buildUserPrompt(AiOperatingLayerPayload payload) {
    final buffer = StringBuffer();
    final now = DateTime.now();
    buffer.writeln(
      'Today is ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')} (local).',
    );
    buffer.writeln();
    buffer.writeln('User request: "${payload.userInput}"');
    buffer.writeln();

    if (payload.intentHint != null) {
      buffer.writeln(payload.intentHint);
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
/// Returns [MockAiOperatingLayerClient] when AI is disabled remotely.
Future<AiOperatingLayerClient> buildAiOperatingLayerClient({
  AiCoachToolRunner? toolRunner,
}) async {
  final aiEnabled = await AiRemoteConfigService.instance.isAiEnabled();

  if (!aiEnabled) {
    debugPrint('[AiOperatingLayer] AI disabled remotely — using mock client.');
    return const MockAiOperatingLayerClient();
  }

  return ProxyAiOperatingLayerClient(toolRunner: toolRunner);
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
