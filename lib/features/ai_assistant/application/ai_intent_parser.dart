import '../domain/models/ai_action.dart';
import '../domain/models/ai_planned_changes.dart';
import '../domain/models/ai_operating_layer_payload.dart';
import 'ai_assumption_engine.dart';
import 'ai_conflict_detector.dart';
import 'ai_missing_field_detector.dart';
import 'ai_operating_layer_client.dart';
import 'ai_payload_assembler.dart';
import 'ai_plan_deduplicator.dart';

/// Orchestrates the full parse pipeline for a single user turn:
///
///   1. Assemble context payload from live app data.
///   2. Call the AI client to parse the user's intent.
///   3. Run the Missing Field Detector on every returned action.
///   4. For each incomplete action, try the Assumption Engine.
///   5. Run the Conflict Detector on the complete action list.
///   6. Return [AiPlannedChanges] — with plan, conflicts, or a follow-up question.
class AiIntentParser {
  const AiIntentParser({
    required this.client,
    required this.assembler,
    required this.assumptionEngine,
    this.conflictDetector,
  });

  final AiOperatingLayerClient client;
  final AiPayloadAssembler assembler;
  final AiAssumptionEngine assumptionEngine;
  final AiConflictDetector? conflictDetector;

  Future<AiPlannedChanges> parse(
    String userInput,
    String sessionId, {
    AiPlannedChanges? previousPlan,
  }) async {
    // Build a human-readable summary of the previous plan for the AI context
    final previousPlanSummary = previousPlan != null && previousPlan.actions.isNotEmpty
        ? previousPlan.actions
            .map((a) => '${a.actionType.name}: ${a.parameters}')
            .join('; ')
        : null;

    // Step 1 — Assemble payload
    late AiOperatingLayerPayload payload;
    try {
      payload = await assembler.assemble(
        userInput,
        sessionId,
        previousPlanSummary: previousPlanSummary,
      );
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

    // Step 4 — Missing field check + Assumption Engine
    var enrichedActions = await _enrichWithAssumptions(result.actions);

    // Step 4b — Drop actions that duplicate tasks already on today's list
    enrichedActions = AiPlanDeduplicator.filter(
      enrichedActions,
      payload.activeTasks,
      userInput,
      isRefiningPreviousPlan: previousPlan != null,
    );
    if (enrichedActions.isEmpty &&
        result.actions.isNotEmpty &&
        previousPlan == null) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion:
            "That already appears on today's list. What else would you like to add?",
      );
    }

    final missingCheck = AiMissingFieldDetector.checkAll(enrichedActions);
    if (!missingCheck.isComplete) {
      return AiPlannedChanges(
        sessionId: sessionId,
        followUpQuestion: missingCheck.questionToAsk,
        actions: enrichedActions,
      );
    }

    // Step 5 — Conflict detection (reminder collision, context, enforcement)
    final allConflicts = List<String>.from(result.conflicts);
    final allBlocked = <String>[];

    if (conflictDetector != null) {
      try {
        final detected = await conflictDetector!.detect(enrichedActions);
        allConflicts.addAll(detected.softConflicts);
        allBlocked.addAll(detected.hardBlocks);
      } catch (_) {
        // Conflict detection is best-effort — never block the pipeline
      }
    }

    return result.copyWith(
      actions: enrichedActions,
      conflicts: allConflicts,
      blockedByContext: allBlocked,
    );
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// For each action that is still incomplete after the first missing-field
  /// check, runs the Assumption Engine and merges any confident suggestions.
  Future<List<AiAction>> _enrichWithAssumptions(
    List<AiAction> actions,
  ) async {
    final results = <AiAction>[];
    for (final action in actions) {
      final check = AiMissingFieldDetector.check(action);
      if (check.isComplete) {
        results.add(action);
        continue;
      }

      // Try the Assumption Engine
      final assumption = await assumptionEngine.infer(action);
      if (!assumption.hasMatch) {
        results.add(action);
        continue;
      }

      // Merge suggested parameters (only null fields)
      final mergedParams = Map<String, dynamic>.from(action.parameters);
      assumption.suggestedParameters.forEach((key, value) {
        if (mergedParams[key] == null) {
          mergedParams[key] = value;
        }
      });

      results.add(action.copyWith(
        parameters: mergedParams,
        reasonLabel: assumption.reasonLabel,
      ));
    }
    return results;
  }
}
