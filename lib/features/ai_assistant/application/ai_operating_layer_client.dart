import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/ai/ai_remote_config_service.dart';
import '../domain/models/ai_action.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import '../domain/models/ai_planned_changes.dart';
import '../domain/models/ai_response_type.dart';
import 'ai_operating_layer_response_parser.dart';
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

// ─── System prompt ────────────────────────────────────────────────────────────
//
// ## LLM response schemas (developer reference)
//
// All model output is JSON inside the chat completion `content` field.
// Parsed by [parseOperatingLayerJsonMap] in `ai_operating_layer_response_parser.dart`.
//
// | Schema | responseType   | When to use |
// |--------|----------------|-------------|
// | A      | mutate         | User asked to create/move/delete — returns `actions[]` |
// | B      | followUp       | Required field missing — returns `followUpQuestion` |
// | C      | informational  | Read-only schedule/goal answer — returns `message` |
// | D      | unsupported    | Feature outside Coach AI scope — returns `message` |
// | E      | suggest        | Collaborative plan — returns `message` + optional `actions[]` |
//
// Legacy: absent `responseType` + non-empty `actions` → mutate; `followUpQuestion` → followUp.
//
const String _kSystemPrompt = '''
You are the AI Operating Layer for a personal productivity app called "Coach for Life".

You handle three kinds of user messages:
1. **Questions / summaries** — answer from the schedule and goal data in the prompt (read-only).
2. **Planning suggestions** — propose a plan in plain language with optional draft actions (Schema E).
3. **Change requests** — return structured actions for preview and confirmation (writes).

## Supported action types (mutate only)
createTask, editTask, moveTask, deleteTask,
createGoal, modifyGoal, deleteGoal,
addReminder, removeReminder, rescheduleReminder,
activateContextOverride, endContextOverride,
suggestFreeTimeBlock, moveConflictingTasks

## Output format
You MUST respond with valid JSON matching ONE of these schemas:

### Schema A — Plan ready (mutate)
{
  "responseType": "mutate",
  "actions": [
    {
      "actionType": "<one of the supported types>",
      "parameters": { ... },
      "confidence": 0.0–1.0
    }
  ],
  "conflicts": ["<human-readable conflict string>", ...]
}

### Schema B — Missing information (follow-up)
{
  "responseType": "followUp",
  "actions": [],
  "conflicts": [],
  "followUpQuestion": "<single, friendly question asking for the missing detail>"
}

### Schema C — Informational answer (read-only)
{
  "responseType": "informational",
  "message": "<clear summary citing only payload data>",
  "suggestedPrompts": ["<optional follow-up the user might tap>", ...]
}

Use Schema C when the user asks what is scheduled, what is on their plan, summaries of today/tomorrow, or goal overview — WITHOUT asking you to create, move, delete, or change anything.

If a schedule section is empty, say so explicitly (e.g. "Nothing scheduled for tomorrow yet.").

For goal progress questions, cite goalProgress and use the user's coachingStyle from behaviorPreferences for tone (supportive vs direct).

For week questions, summarize from weekOverview counts — give tomorrow in detail only when asked.

Example informational answers:
- "What's my plan for tomorrow?" → list tomorrowSchedule/tomorrowTasks or say nothing scheduled.
- "How am I doing on my goals?" → cite daysMet vs target from goalProgress.
- "What does my week look like?" → summarize weekOverview task counts per day.

### Schema D — Unsupported request
{
  "responseType": "unsupported",
  "message": "<honest limit, e.g. community/circles/billing not available in Coach AI yet>"
}

Use Schema D only when the user asks for features outside tasks, goals, reminders, schedule, and focus/context overrides.

### Schema E — Suggested plan (propose, not apply)
{
  "responseType": "suggest",
  "message": "<narrative explaining the proposed plan>",
  "actions": [ ... optional draft actions ... ],
  "conflicts": [],
  "suggestedPrompts": ["Apply this plan", ...]
}

Use Schema E when the user asks you to plan, suggest, recommend, or help fill their schedule — WITHOUT explicitly commanding a single add/create/delete. Include draft actions when you can propose specific tasks.

## Parameter keys by action type
- createTask / editTask:        title (str), time (HH:MM), duration (int, minutes), date (YYYY-MM-DD or "today"/"tomorrow")
- moveTask:                     taskTitle (str), destinationDate (YYYY-MM-DD or "tomorrow"), destinationTime (HH:MM, optional)
- deleteTask:                   taskTitle (str)
- createGoal:                   title (str), target (str), deadline (YYYY-MM-DD)
- modifyGoal:                   goalTitle (str), field (str), newValue (str)
- deleteGoal:                   goalTitle (str)
- addReminder / rescheduleReminder: taskTitle (str), reminderTime (HH:MM), date (YYYY-MM-DD)
- removeReminder:               taskTitle (str)
- activateContextOverride:      overrideType ("focus"|"meeting"|"sleep"|"doNotDisturb"|"vacation"), durationMinutes (int, null = indefinite)
- endContextOverride:           (no parameters needed)
- suggestFreeTimeBlock:         durationMinutes (int)

## Rules
- For informational answers: NEVER invent tasks or times — use ONLY activeTasks, todaySchedule, tomorrowTasks, tomorrowSchedule, and goals from the prompt.
- For mutate requests: NEVER invent values — use only what the user said or what appears in activeTasks/goals.
- If a required field is missing and cannot be clearly inferred, use Schema B (follow-up question).
- Ask ONLY one question at a time.
- A single mutate request may produce multiple actions — return all of them.
- Dates and times are always in the user's local timezone.
- Keep conflict strings short and human-readable (max 12 words each).
- If focusState.isActive == true, avoid scheduling new tasks during the active override window.
- If recentPatterns are provided, prefer times/durations matching the user's past patterns.

## Coaching-style phrasing (applies to message and followUpQuestion)
- supportive:   Warm, encouraging tone.
- balanced:     Neutral, professional.
- disciplined:  Firm, no-fluff.
- intense:      Terse, commanding.
Use the coachingStyle from behaviorPreferences to calibrate your wording.

## Multi-turn context
If conversationHistory is present, treat it as prior turns of this session.
If previousPlan is present, the user is refining an earlier plan — carry over unchanged actions
and only modify what the user explicitly specified in the new message.

## Delta-only planning (critical — mutate only)
Each user message describes ONLY new changes for this turn — not the full session.
- If activeTasks or todaySchedule already lists a task with a scheduled time, do NOT include
  createTask, addReminder, or rescheduleReminder for that item unless the user's CURRENT
  message explicitly names that task and asks to change it.
- If completedInSession is present, those items are already applied — never repeat them in
  actions or follow-up questions.
- Do not ask follow-up questions about tasks the user already confirmed or that appear in
  activeTasks with a time set.
''';

// ─── OpenAI implementation ────────────────────────────────────────────────────

const String _kOpenAiUrl = 'https://api.openai.com/v1/chat/completions';

class OpenAiOperatingLayerClient implements AiOperatingLayerClient {
  const OpenAiOperatingLayerClient({
    required this.apiKey,
    this.model = 'gpt-4o-mini',
    this.timeoutSeconds = 20,
  });

  final String apiKey;
  final String model;
  final int timeoutSeconds;

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

    final requestBody = jsonEncode({
      'model': model,
      'temperature': 0.2,
      'max_tokens': 800,
      'response_format': {'type': 'json_object'},
      'messages': messages,
    });

    http.Response response;
    try {
      response = await http
          .post(
            Uri.parse(_kOpenAiUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: requestBody,
          )
          .timeout(Duration(seconds: timeoutSeconds));
    } catch (e) {
      throw AiOperatingLayerException('Network error: $e');
    }

    if (response.statusCode != 200) {
      throw AiOperatingLayerException(
        'OpenAI request failed',
        statusCode: response.statusCode,
      );
    }

    return _parseResponse(response.body, payload.userInput);
  }

  String _buildUserPrompt(AiOperatingLayerPayload payload) {
    final buffer = StringBuffer();
    buffer.writeln('User request: "${payload.userInput}"');
    buffer.writeln();

    if (payload.intentHint != null) {
      buffer.writeln(payload.intentHint);
      buffer.writeln();
    }

    if (payload.activeTasks.isNotEmpty) {
      buffer.writeln("Today's tasks:");
      for (final t in payload.activeTasks) {
        buffer.writeln('  - ${t['title']} at ${t['time'] ?? 'no time'} (${t['duration'] ?? '?'} min, ${t['status'] ?? 'pending'})');
      }
      buffer.writeln();
    }

    if (payload.goals.isNotEmpty) {
      buffer.writeln('Active goals:');
      for (final g in payload.goals) {
        buffer.writeln('  - ${g['title']} (target: ${g['target'] ?? '?'}, deadline: ${g['deadline'] ?? '?'})');
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
        buffer.writeln('  - ${t['title']} at ${t['time'] ?? 'no time'} (${t['duration'] ?? '?'}, ${t['status'] ?? 'pending'})');
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
      buffer.writeln('Proactive suggestion context: ${payload.proactiveContext}');
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

    buffer.writeln(AiCapabilityRegistry.formatForPrompt());

    buffer.writeln();
    buffer.writeln(
      'Choose the correct responseType. For questions about schedule/goals use informational. '
      'For change requests use mutate. Return valid JSON only.',
    );
    return buffer.toString();
  }

  AiPlannedChanges _parseResponse(String body, String sessionId) {
    try {
      final outer = jsonDecode(body) as Map<String, dynamic>;
      final choices = outer['choices'] as List?;
      if (choices == null || choices.isEmpty) {
        throw const AiOperatingLayerException('No choices in response');
      }
      final content =
          ((choices.first as Map)['message'] as Map)['content'] as String? ?? '';
      final inner = jsonDecode(content) as Map<String, dynamic>;
      return parseOperatingLayerJsonMap(inner, sessionId);
    } catch (e) {
      throw AiOperatingLayerException('Failed to parse AI response: $e');
    }
  }
}

// ─── Factory helper ───────────────────────────────────────────────────────────

/// Builds the correct client from Remote Config.
/// Returns [MockAiOperatingLayerClient] if the API key is empty.
Future<AiOperatingLayerClient> buildAiOperatingLayerClient() async {
  final apiKey = await AiRemoteConfigService.instance.getOpenAiApiKey();
  final model = await AiRemoteConfigService.instance.getOpenAiModel();

  if (apiKey.isEmpty) {
    debugPrint('[AiOperatingLayer] No API key — using mock client.');
    return const MockAiOperatingLayerClient();
  }

  return OpenAiOperatingLayerClient(apiKey: apiKey, model: model);
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

    final unsupported = AiCapabilityRegistry.detectUnsupported(payload.userInput);
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
    final schedule =
        forTomorrow ? payload.tomorrowSchedule : payload.todaySchedule;
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
