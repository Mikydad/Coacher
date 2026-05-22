import '../domain/models/ai_planned_changes.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import 'ai_missing_field_detector.dart';
import 'ai_operating_layer_client.dart';
import 'ai_payload_assembler.dart';

/// Orchestrates the full parse pipeline for a single user turn:
///
///   1. Assemble context payload from live app data.
///   2. Call the AI client to parse the user's intent.
///   3. Run the Missing Field Detector on every returned action.
///   4. Return [AiPlannedChanges] — either with a plan or a follow-up question.
class AiIntentParser {
  const AiIntentParser({
    required this.client,
    required this.assembler,
  });

  final AiOperatingLayerClient client;
  final AiPayloadAssembler assembler;

  Future<AiPlannedChanges> parse(String userInput, String sessionId) async {
    // Step 1 — Assemble payload
    late AiOperatingLayerPayload payload;
    try {
      payload = await assembler.assemble(userInput, sessionId);
    } catch (e) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion:
            "I'm having trouble reading your schedule right now. Could you try again?",
      );
    }

    // Step 2 — Call AI client
    late AiPlannedChanges result;
    try {
      result = await client.parseIntent(payload);
    } on AiOperatingLayerException catch (e) {
      final msg = e.isRateLimit
          ? "I've hit my request limit. Please try again in a moment."
          : "Something went wrong processing your request. Please try again.";
      return AiPlannedChanges(sessionId: sessionId, followUpQuestion: msg);
    } catch (_) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion:
            'I ran into an unexpected issue. Please try again.',
      );
    }

    // Carry the correct sessionId (client may return the user input as id)
    result = result.copyWith(sessionId: sessionId);

    // Step 3 — If the AI already asked a follow-up, propagate it
    if (result.requiresFollowUp) return result;

    // Step 4 — Missing field check on returned actions
    final missingCheck = AiMissingFieldDetector.checkAll(result.actions);
    if (!missingCheck.isComplete) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion: missingCheck.questionToAsk,
        actions: result.actions,
      );
    }

    return result;
  }
}
