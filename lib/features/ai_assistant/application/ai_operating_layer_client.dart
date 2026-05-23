import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/ai/ai_remote_config_service.dart';
import '../domain/models/ai_action.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import '../domain/models/ai_planned_changes.dart';

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

const String _kSystemPrompt = '''
You are the AI Operating Layer for a personal productivity app called "Coach for Life".

Your job is to convert a user's natural-language request into a structured JSON plan.

## Supported action types
createTask, editTask, moveTask, deleteTask,
createGoal, modifyGoal, deleteGoal,
addReminder, removeReminder, rescheduleReminder,
activateContextOverride, endContextOverride,
suggestFreeTimeBlock, moveConflictingTasks

## Output format
You MUST respond with valid JSON matching one of these two schemas:

### Schema A — Plan ready
{
  "actions": [
    {
      "actionType": "<one of the supported types>",
      "parameters": { ... },
      "confidence": 0.0–1.0
    }
  ],
  "conflicts": ["<human-readable conflict string>", ...]
}

### Schema B — Missing information
{
  "actions": [],
  "conflicts": [],
  "followUpQuestion": "<single, friendly question asking for the missing detail>"
}

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
- NEVER invent values — use only what the user said or what appears in activeTasks/goals.
- If a required field is missing and cannot be clearly inferred, use Schema B (follow-up question).
- Ask ONLY one question at a time.
- A single request may produce multiple actions — return all of them.
- Dates and times are always in the user's local timezone.
- Keep conflict strings short and human-readable (max 12 words each).
- If focusState.isActive == true, avoid scheduling new tasks during the active override window.
- If recentPatterns are provided, prefer times/durations matching the user's past patterns.

## Coaching-style phrasing (applies to followUpQuestion and plan summaries only)
- supportive:   Warm, encouraging tone. "Great choice! Here's what I'll add…"
- balanced:     Neutral, professional. "Here's the plan: …"
- disciplined:  Firm, no-fluff. "Scheduled. Stay on track."
- intense:      Terse, commanding. "Locked in. Execute."
Use the coachingStyle from behaviorPreferences to calibrate your wording.

## Multi-turn context
If conversationHistory is present, treat it as prior turns of this session.
If previousPlan is present, the user is refining an earlier plan — carry over unchanged actions
and only modify what the user explicitly specified in the new message.

## Delta-only planning (critical)
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

    if (payload.todaySchedule.isNotEmpty) {
      buffer.writeln("Today's schedule blocks:");
      for (final s in payload.todaySchedule) {
        buffer.writeln('  - ${s['title']} ${s['startTime']}–${s['endTime']}');
      }
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

    buffer.writeln();
    buffer.writeln(
      'Parse ONLY the new change requested in this message. Return a JSON plan.',
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

      // Schema B — follow-up question
      final followUp = inner['followUpQuestion'] as String?;
      if (followUp != null && followUp.isNotEmpty) {
        return AiPlannedChanges(
          sessionId: sessionId,
          followUpQuestion: followUp,
        );
      }

      // Schema A — plan
      final actionsRaw = inner['actions'] as List? ?? [];
      final actions = actionsRaw
          .map((a) => AiAction.fromJson(Map<String, dynamic>.from(a as Map)))
          .toList();

      final conflictsRaw = inner['conflicts'] as List? ?? [];
      final conflicts = conflictsRaw.map((c) => c.toString()).toList();

      return AiPlannedChanges(
        sessionId: sessionId,
        actions: actions,
        conflicts: conflicts,
      );
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

/// Deterministic mock — returns a single createTask action for testing.
class MockAiOperatingLayerClient implements AiOperatingLayerClient {
  const MockAiOperatingLayerClient({this.shouldFail = false});

  final bool shouldFail;

  @override
  Future<AiPlannedChanges> parseIntent(AiOperatingLayerPayload payload) async {
    await Future<void>.delayed(const Duration(milliseconds: 600));

    if (shouldFail) {
      throw const AiOperatingLayerException('Mock forced failure');
    }

    // Simulate a simple createTask response
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
}
