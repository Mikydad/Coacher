import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/stable_id.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_chat_message.dart';
import '../domain/models/ai_planned_changes.dart';
import 'ai_action_executor.dart';
import 'ai_intent_parser.dart';
import 'proactive_chat_conversion_tracker.dart';
import 'entity_normaliser.dart';

/// Signature for fire-and-forget analytics logging from the service layer.
typedef AiAnalyticsLogger = void Function(
  String eventName,
  Map<String, dynamic> properties,
);

/// Single entry point for the Coach AI presentation layer.
///
/// Owns the in-memory session: conversation thread, pending plan, session ID.
/// All mutations go through [sendMessage], [confirmPlan], [cancelPlan], [editPlan].
class AiAssistantService extends ChangeNotifier {
  AiAssistantService({
    required AiIntentParser intentParser,
    required AiActionExecutor actionExecutor,
    required AiInteractionHistoryRepository historyRepository,
    AiAnalyticsLogger? analyticsLogger,
    EntityNormaliser? normaliser,
  })  : _intentParser = intentParser,
        _actionExecutor = actionExecutor,
        _historyRepository = historyRepository,
        _analyticsLogger = analyticsLogger,
        _normaliser = normaliser ?? const EntityNormaliser(),
        _sessionId = StableId.generate('session');

  final AiIntentParser _intentParser;
  final AiActionExecutor _actionExecutor;
  final AiInteractionHistoryRepository _historyRepository;

  /// Exposed for UI (e.g. pick-up-where-you-left-off banner).
  AiInteractionHistoryRepository get historyRepository => _historyRepository;
  final AiAnalyticsLogger? _analyticsLogger;
  final EntityNormaliser _normaliser;

  String _sessionId;
  final List<AiChatMessage> _messages = [];
  AiPlannedChanges? _pendingPlan;
  bool _isLoading = false;
  bool _inputFocusRequested = false;

  /// Set by [editPlan] — only then do we pass [previousPlan] into the parser.
  bool _refiningPendingPlan = false;

  String? _proactiveSuggestionId;
  String? _proactiveSuggestionType;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get hasPendingPlan => _pendingPlan != null;
  AiPlannedChanges? get pendingPlan => _pendingPlan;
  bool get inputFocusRequested => _inputFocusRequested;
  String get sessionId => _sessionId;

  /// Links this session to a proactive card the user tapped before opening Coach.
  void setProactiveContext({
    String? suggestionId,
    String? suggestionType,
  }) {
    _proactiveSuggestionId = suggestionId;
    _proactiveSuggestionType = suggestionType;
  }

  Map<String, dynamic>? get _proactiveContextForPayload {
    if (_proactiveSuggestionId == null) return null;
    return {
      'suggestionId': _proactiveSuggestionId,
      if (_proactiveSuggestionType != null)
        'suggestionType': _proactiveSuggestionType,
    };
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  Future<void> sendMessage(String userInput) async {
    if (userInput.trim().isEmpty) return;

    // 1. Append user message
    _addMessage(AiChatMessage(
      id: StableId.generate('msg'),
      role: ChatRole.user,
      content: userInput.trim(),
      timestamp: DateTime.now(),
    ));

    // 2. Append loading message (thinking…)
    final loadingId = StableId.generate('msg');
    _addMessage(AiChatMessage(
      id: loadingId,
      role: ChatRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      isLoading: true,
    ));
    _setLoading(true);

    // 3. Mark any existing plan as no longer current
    _demoteCurrentPlan();

    // Only pass previous plan when the user tapped Edit on the pending card.
    // Otherwise a brand-new request (e.g. "add reading") was being treated as a
    // delta and the model often returned an empty actions list.
    final previousForParser =
        _refiningPendingPlan ? _pendingPlan : null;
    _refiningPendingPlan = false;

    // 4. Parse intent
    AiPlannedChanges result;
    try {
      result = await _intentParser.parse(
        userInput.trim(),
        _sessionId,
        previousPlan: previousForParser,
        proactiveContext: _proactiveContextForPayload,
      );
    } catch (e) {
      _replaceLoadingMessage(
        loadingId,
        "I ran into an unexpected error. Please try again.",
      );
      _setLoading(false);
      return;
    }

    // 5. Remove loading message, add real response
    _removeMessage(loadingId);
    _setLoading(false);

    if (result.requiresFollowUp) {
      final question = result.followUpQuestion!;
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: question,
        timestamp: DateTime.now(),
      ));
      _pendingPlan = null;
    } else if (result.isInformational || result.isUnsupported) {
      final message = result.informationalMessage ??
          "I couldn't find an answer for that right now.";
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: message,
        timestamp: DateTime.now(),
        suggestedPrompts: result.suggestedPrompts,
      ));
      _pendingPlan = null;
      if (result.isInformational) {
        _logEvent('aiInformationalAnswer', {
          'sessionId': _sessionId,
          'responseType': result.responseType.name,
        });
      } else {
        _logEvent('aiUnsupportedRequest', {
          'sessionId': _sessionId,
          'responseType': result.responseType.name,
        });
      }
    } else if (result.isSuggest) {
      final message = result.informationalMessage ??
          'Here\'s what I\'d suggest based on your schedule.';
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: message,
        timestamp: DateTime.now(),
        draftPlan: result.actions.isNotEmpty ? result : null,
        suggestedPrompts: result.suggestedPrompts,
      ));
      _pendingPlan = null;
      _logEvent('aiSuggestPlanShown', {
        'sessionId': _sessionId,
        'actionCount': result.actions.length,
      });
    } else if (result.actions.isEmpty) {
      _pendingPlan = null;
      const fallback =
          "I can answer questions about your schedule or help you add and move tasks. "
          "Try asking \"What's my plan for tomorrow?\" or \"Add a workout at 6am tomorrow.\"";
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: fallback,
        timestamp: DateTime.now(),
      ));
    } else {
      // Plan ready — show preview card
      _pendingPlan = result;
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: 'Here\'s what I\'ll do:',
        timestamp: DateTime.now(),
        plannedChanges: result,
        isCurrentPlan: true,
      ));
    }

    // 6. Persist interaction (user turn + assistant summary for multi-turn context)
    await _historyRepository.save(
      sessionId: _sessionId,
      userInput: userInput.trim(),
      parsedActions: result.actions,
      assistantSummary: _assistantSummaryForHistory(result),
      responseType: result.responseType.name,
    );

    // 7. Analytics
    _logEvent('aiCommandSubmitted', {
      'sessionId': _sessionId,
      'inputLength': userInput.trim().length,
    });
    if (result.requiresFollowUp) {
      _logEvent('aiFollowupQuestionAsked', {
        'sessionId': _sessionId,
        'question': result.followUpQuestion,
      });
    }

    notifyListeners();
  }

  /// Confirms and executes [planFromCard] when provided (source of truth from the
  /// preview card). Falls back to [_pendingPlan] for backwards compatibility.
  Future<void> confirmPlan([
    AiPlannedChanges? planFromCard,
    String? previewMessageId,
  ]) async {
    final plan = planFromCard ?? _pendingPlan;
    if (plan == null) {
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content:
            'That plan is no longer active. Send a new request and confirm the latest preview.',
        timestamp: DateTime.now(),
      ));
      notifyListeners();
      return;
    }

    if (plan.actions.isEmpty) {
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content:
            'There is nothing to apply in this plan. Try describing the change again.',
        timestamp: DateTime.now(),
      ));
      notifyListeners();
      return;
    }

    _setLoading(true);

    final result = await _actionExecutor.execute(plan.actions);

    await _historyRepository.markConfirmed(_sessionId);
    await _historyRepository.markExecuted(_sessionId);

    // Store assistant summary for multi-turn conversationHistory (Phase 3)
    final executionSummary = result.hasFailures
        ? 'Already applied (do not repeat): ${result.successes.join("; ")}. Issues: ${result.failures.take(2).join("; ")}'
        : result.successes.isNotEmpty
            ? 'Already applied (do not repeat): ${result.successes.join("; ")}'
            : 'Already applied (do not repeat): Done';
    unawaited(
      _historyRepository.saveAssistantSummary(_sessionId, executionSummary),
    );

    // Seed resolvedCategory from the primary action for the Assumption Engine
    final primary = plan.actions.isNotEmpty ? plan.actions.first : null;
    if (primary != null) {
      final rawTitle =
          primary.parameters['title']?.toString() ??
          primary.parameters['taskTitle']?.toString() ??
          '';
      if (rawTitle.isNotEmpty) {
        final category = _normaliser.normalise(rawTitle);
        unawaited(
          _historyRepository.updateResolvedCategory(_sessionId, category),
        );
      }
    }

    _pendingPlan = null;
    _markPlanExecuted(previewMessageId, plan.sessionId);
    _demoteCurrentPlan();
    _setLoading(false);

    final summary = result.hasFailures
        ? 'Done with some issues:\n${result.toSummaryMessage()}'
        : result.successes.isNotEmpty
            ? result.toSummaryMessage()
            : 'No changes were applied. Try describing a specific task to add or update.';

    _addMessage(AiChatMessage(
      id: StableId.generate('msg'),
      role: ChatRole.assistant,
      content: summary,
      timestamp: DateTime.now(),
    ));

    _logEvent('aiCommandExecuted', {
      'sessionId': _sessionId,
      'actionCount': plan.actions.length,
      'actionTypes': plan.actions.map((a) => a.actionType.name).toList(),
    });
    _recordProactiveChatConversion();

    // Log aiSuggestionAccepted for every action that had a reason label
    for (final action in plan.actions) {
      if (action.reasonLabel != null) {
        final rawTitle =
            action.parameters['title']?.toString() ??
            action.parameters['taskTitle']?.toString() ??
            '';
        final category = rawTitle.isNotEmpty
            ? _normaliser.normalise(rawTitle)
            : 'unknown';
        _logEvent('aiSuggestionAccepted', {
          'sessionId': _sessionId,
          'category': category,
          'confidence': action.confidence,
        });
      }
    }

    notifyListeners();
  }

  void applySuggestedPlan(String messageId) {
    final idx = _messages.indexWhere((m) => m.id == messageId);
    if (idx == -1) return;

    final message = _messages[idx];
    final plan = message.draftPlan;
    if (plan == null || plan.actions.isEmpty) return;

    _demoteCurrentPlan();
    _pendingPlan = plan;
    _messages[idx] = message.copyWith(
      clearDraftPlan: true,
      plannedChanges: plan,
      isCurrentPlan: true,
    );

    _logEvent('aiSuggestPlanApplied', {
      'sessionId': _sessionId,
      'actionCount': plan.actions.length,
    });
    _recordProactiveChatConversion();

    notifyListeners();
  }

  void cancelPlan() {
    _refiningPendingPlan = false;
    _pendingPlan = null;
    _demoteCurrentPlan();

    _addMessage(AiChatMessage(
      id: StableId.generate('msg'),
      role: ChatRole.assistant,
      content: 'Plan cancelled. Let me know if you\'d like to try something else.',
      timestamp: DateTime.now(),
    ));

    _logEvent('aiCommandCanceled', {'sessionId': _sessionId});

    notifyListeners();
  }

  void editPlan() {
    _refiningPendingPlan = true;
    // Log rejection for any action that had an assumption-based reason label
    if (_pendingPlan != null) {
      for (final action in _pendingPlan!.actions) {
        if (action.reasonLabel != null) {
          final rawTitle =
              action.parameters['title']?.toString() ??
              action.parameters['taskTitle']?.toString() ??
              '';
          final category = rawTitle.isNotEmpty
              ? _normaliser.normalise(rawTitle)
              : 'unknown';
          _logEvent('aiSuggestionRejected', {
            'sessionId': _sessionId,
            'category': category,
          });
        }
      }
    }
    // Keep plan visible (read-only card) and focus the input field
    _inputFocusRequested = true;
    notifyListeners();
  }

  void clearInputFocusRequest() {
    _inputFocusRequested = false;
    // No notifyListeners needed — UI calls this after acting on it
  }

  void startNewSession() {
    _sessionId = StableId.generate('session');
    _messages.clear();
    _pendingPlan = null;
    _isLoading = false;
    _inputFocusRequested = false;
    _proactiveSuggestionId = null;
    _proactiveSuggestionType = null;
    notifyListeners();
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  void _addMessage(AiChatMessage msg) {
    _messages.add(msg);
  }

  void _removeMessage(String id) {
    _messages.removeWhere((m) => m.id == id);
  }

  void _replaceLoadingMessage(String id, String content) {
    final idx = _messages.indexWhere((m) => m.id == id);
    if (idx == -1) return;
    _messages[idx] = _messages[idx].copyWith(
      content: content,
      isLoading: false,
    );
  }

  void _demoteCurrentPlan() {
    for (var i = 0; i < _messages.length; i++) {
      if (_messages[i].isCurrentPlan) {
        _messages[i] = _messages[i].copyWith(isCurrentPlan: false);
      }
    }
  }

  void _markPlanExecuted(String? previewMessageId, String sessionId) {
    if (previewMessageId != null) {
      final idx = _messages.indexWhere((m) => m.id == previewMessageId);
      if (idx != -1) {
        _messages[idx] = _messages[idx].copyWith(
          isCurrentPlan: false,
          isExecuted: true,
        );
        return;
      }
    }
    for (var i = 0; i < _messages.length; i++) {
      final msg = _messages[i];
      if (msg.plannedChanges?.sessionId == sessionId && msg.isCurrentPlan) {
        _messages[i] = msg.copyWith(isCurrentPlan: false, isExecuted: true);
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _logEvent(String name, [Map<String, dynamic>? props]) {
    unawaited(
      Future.microtask(() => _analyticsLogger?.call(name, props ?? {})),
    );
  }

  Future<void> _persistAssistantTurn(String summary) async {
    final trimmed = summary.trim();
    if (trimmed.isEmpty) return;
    final capped = trimmed.length > 500 ? '${trimmed.substring(0, 497)}…' : trimmed;
    await _historyRepository.saveAssistantSummary(_sessionId, capped);
  }

  String? _assistantSummaryForHistory(AiPlannedChanges result) {
    if (result.requiresFollowUp) {
      return result.followUpQuestion;
    }
    if (result.isInformational || result.isUnsupported) {
      return result.informationalMessage;
    }
    if (result.isSuggest) {
      return result.informationalMessage;
    }
    if (result.actions.isEmpty) {
      return "I can answer questions about your schedule or help you add and move tasks. "
          "Try asking \"What's my plan for tomorrow?\" or \"Add a workout at 6am tomorrow.\"";
    }
    return _planPreviewSummary(result);
  }

  String _planPreviewSummary(AiPlannedChanges plan) {
    final parts = plan.actions.take(4).map((a) {
      final title = a.parameters['title']?.toString() ??
          a.parameters['taskTitle']?.toString() ??
          a.actionType.name;
      return '${a.actionType.name}: $title';
    }).join('; ');
    return 'Plan preview: $parts';
  }

  void _recordProactiveChatConversion() {
    final type = _proactiveSuggestionType;
    if (type == null || type.isEmpty) return;
    ProactiveChatConversionTracker.record(type);
    _logEvent('proactiveSuggestionChatConverted', {
      'sessionId': _sessionId,
      'suggestionId': _proactiveSuggestionId,
      'suggestionType': type,
    });
  }
}
