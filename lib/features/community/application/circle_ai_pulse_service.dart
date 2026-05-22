import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../core/ai/ai_remote_config_service.dart';
import '../../../core/utils/stable_id.dart';
import '../data/activity_feed_repository.dart';
import '../data/ai_pulse_repository.dart';
import '../data/challenge_repository.dart';
import '../domain/models/challenge.dart';
import '../domain/models/ai_pulse.dart';
import '../domain/models/activity_feed_item.dart';
import '../domain/models/circle_enums.dart';

const _kOpenAiChatUrl = 'https://api.openai.com/v1/chat/completions';
const _kDefaultModel = 'gpt-4o-mini';

/// Generates daily and weekly AI pulses for a circle.
///
/// Delegates to the OpenAI API directly using the same endpoint as
/// [OpenAiCoachingClient], but with circle-specific prompts.
/// Does NOT modify [CoachingAiClient] or any existing AI code.
class CircleAiPulseService {
  CircleAiPulseService({
    required AiPulseRepository pulseRepo,
    required ActivityFeedRepository feedRepo,
    required ChallengeRepository challengeRepo,
  })  : _pulseRepo = pulseRepo,
        _feedRepo = feedRepo,
        _challengeRepo = challengeRepo;

  final AiPulseRepository _pulseRepo;
  final ActivityFeedRepository _feedRepo;
  final ChallengeRepository _challengeRepo;

  /// Generates a daily pulse for [circleId] if not on cooldown.
  /// Returns `null` if on cooldown or if AI fails.
  Future<AiPulse?> generateDailyPulse(String circleId) async {
    try {
      if (await _pulseRepo.isOnCooldown(
          circleId, AiPulseType.daily,
          cooldownMinutes: 240)) {
        return null;
      }

      final now = DateTime.now();
      final cutoff =
          now.subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
      final feedItems = await _feedRepo.watchFeed(circleId).first;
      final recent = feedItems.where((f) => f.createdAtMs >= cutoff).toList();

      if (recent.isEmpty) return null;

      final pulse = await _callAi(
        circleId: circleId,
        type: AiPulseType.daily,
        prompt: CircleAiPromptBuilder.buildDailyPulsePrompt(
            circleId: circleId, feedItems: recent),
      );
      if (pulse != null) await _pulseRepo.savePulse(pulse);
      return pulse;
    } catch (e) {
      debugPrint('[CircleAiPulseService] daily pulse error: $e');
      return null;
    }
  }

  /// Generates a weekly pulse for [circleId] if not on cooldown.
  Future<AiPulse?> generateWeeklyPulse(String circleId) async {
    try {
      if (await _pulseRepo.isOnCooldown(
          circleId, AiPulseType.weekly,
          cooldownMinutes: 24 * 60)) {
        return null;
      }

      final now = DateTime.now();
      final cutoff =
          now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      final feedItems = await _feedRepo.watchFeed(circleId, limit: 100).first;
      final recent = feedItems.where((f) => f.createdAtMs >= cutoff).toList();

      final challenges =
          await _challengeRepo.watchChallenges(circleId).first;
      final activeChallenges =
          challenges.where((c) => c.status == ChallengeStatus.active).toList();

      final pulse = await _callAi(
        circleId: circleId,
        type: AiPulseType.weekly,
        prompt: CircleAiPromptBuilder.buildWeeklyPulsePrompt(
          circleId: circleId,
          feedItems: recent,
          activeChallengeCount: activeChallenges.length,
        ),
      );
      if (pulse != null) await _pulseRepo.savePulse(pulse);
      return pulse;
    } catch (e) {
      debugPrint('[CircleAiPulseService] weekly pulse error: $e');
      return null;
    }
  }

  // ── AI call ────────────────────────────────────────────────────────────────

  Future<AiPulse?> _callAi({
    required String circleId,
    required AiPulseType type,
    required String prompt,
  }) async {
    try {
      final apiKey = await AiRemoteConfigService.instance.getOpenAiApiKey();
      if (apiKey.isEmpty) return null;

      final modelRaw =
          await AiRemoteConfigService.instance.getOpenAiModel();
      final model = modelRaw.isEmpty ? _kDefaultModel : modelRaw;

      final body = jsonEncode({
        'model': model,
        'temperature': 0.4,
        'max_tokens': 400,
        'response_format': {'type': 'json_object'},
        'messages': [
          {
            'role': 'system',
            'content':
                'You are an AI coaching assistant for small accountability circles. '
                    'Respond ONLY with valid JSON matching the requested schema.'
          },
          {'role': 'user', 'content': prompt},
        ],
      });

      final response = await http
          .post(
            Uri.parse(_kOpenAiChatUrl),
            headers: {
              'Authorization': 'Bearer $apiKey',
              'Content-Type': 'application/json',
            },
            body: body,
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode != 200) {
        debugPrint(
            '[CircleAiPulseService] HTTP ${response.statusCode}');
        return null;
      }

      return _parsePulse(
          circleId: circleId,
          type: type,
          responseBody: response.body);
    } catch (e) {
      debugPrint('[CircleAiPulseService] AI call failed: $e');
      return null;
    }
  }

  AiPulse? _parsePulse({
    required String circleId,
    required AiPulseType type,
    required String responseBody,
  }) {
    try {
      final outer = jsonDecode(responseBody) as Map<String, dynamic>;
      final choices = outer['choices'] as List?;
      if (choices == null || choices.isEmpty) return null;
      final content =
          ((choices.first as Map)['message'] as Map)['content'] as String? ??
              '';
      final inner = jsonDecode(content) as Map<String, dynamic>;

      final lines = ((inner['memberLines'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              [])
          .map(MemberPulseLine.fromMap)
          .toList();

      return AiPulse(
        id: StableId.generate('pulse'),
        circleId: circleId,
        type: type,
        summary: inner['summary'] as String? ?? '',
        memberLines: lines,
        suggestedChallenge:
            inner['suggestedChallenge'] as String?,
        generatedAtMs: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      debugPrint('[CircleAiPulseService] parse error: $e');
      return null;
    }
  }
}

// ─── Prompt builder ───────────────────────────────────────────────────────────

/// Standalone prompt builder — keeps [CircleAiPulseService] testable
/// and avoids adding new methods to [CoachingAiClient].
class CircleAiPromptBuilder {
  const CircleAiPromptBuilder._();

  static String buildDailyPulsePrompt({
    required String circleId,
    required List<ActivityFeedItem> feedItems,
  }) {
    final lines = feedItems.map(_describeEvent).join('\n');
    return '''
Given the following activity from an accountability circle in the last 24 hours,
produce a concise group pulse.

Activity:
$lines

Return JSON:
{
  "summary": "<1-sentence overall status>",
  "memberLines": [{"userId": "...", "displayName": "...", "insight": "<1 insight>"}],
  "suggestedChallenge": "<1-sentence challenge suggestion or null>"
}
''';
  }

  static String buildWeeklyPulsePrompt({
    required String circleId,
    required List<ActivityFeedItem> feedItems,
    required int activeChallengeCount,
  }) {
    final lines = feedItems.map(_describeEvent).join('\n');
    return '''
Given the following activity from an accountability circle over the last 7 days
(active challenges: $activeChallengeCount),
produce a weekly group pulse.

Activity:
$lines

Return JSON:
{
  "summary": "<1-sentence weekly summary>",
  "memberLines": [{"userId": "...", "displayName": "...", "insight": "<1 insight>"}],
  "suggestedChallenge": "<1-sentence challenge suggestion or null>"
}
''';
  }

  static String _describeEvent(ActivityFeedItem item) {
    final who = item.displayName.isEmpty ? item.userId : item.displayName;
    final what = item.entityTitle ?? item.eventType.storageValue;
    return '- $who: ${item.eventType.storageValue} ($what)';
  }
}
