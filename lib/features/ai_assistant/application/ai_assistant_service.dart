import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/stable_id.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_chat_message.dart';
import '../domain/models/ai_planned_changes.dart';
import 'ai_action_executor.dart';
import 'ai_informational_output_guard.dart';
import 'ai_intent_parser.dart';
import 'proactive_chat_conversion_tracker.dart';
import 'entity_normaliser.dart';

/// Signature for fire-and-forget analytics logging from the service layer.
typedef AiAnalyticsLogger = void Function(
  String eventName,
  Map<String, dynamic> properties,
);

typedef AiScheduleCacheInvalidator = void Function(String sessionId);

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
    AiScheduleCacheInvalidator? onScheduleMutated,
  })  : _intentParser = intentParser,
        _actionExecutor = actionExecutor,
        _historyRepository = historyRepository,
        _analyticsLogger = analyticsLogger,
        _normaliser = normaliser ?? const EntityNormaliser(),
        _onScheduleMutated = onScheduleMutated,
        _sessionId = StableId.generate('session');

  final AiIntentParser _intentParser;
  final AiActionExecutor _actionExecutor;
  final AiInteractionHistoryRepository _historyRepository;

  /// Exposed for UI (e.g. pick-up-where-you-left-off banner).
  AiInteractionHistoryRepository get historyRepository => _historyRepository;
  final AiAnalyticsLogger? _analyticsLogger;
  final EntityNormaliser _normaliser;
  final AiScheduleCacheInvalidator? _onScheduleMutated;

  String _sessionId;
  final List<AiChatMessage> _messages = [];
  AiPlannedChanges? _pendingPlan;
  bool _isLoading = false;
  bool _inputFocusRequested = false;

  /// Set by [editPlan] — only then do we pass [previousPlan] into the parser.
  bool _refiningPendingPlan = false;

  /// A partial plan the model proposed that is still missing a detail (the
  /// parser asked a follow-up). Kept so the user's NEXT message refines it
  /// instead of starting over — otherwise "schedule as you suggested" loops
  /// back to the same question.
  AiPlannedChanges? _pendingClarification;

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

    // 0. While a plan is awaiting confirmation, treat a plain yes/no as the
    // answer to "confirm changes?" — never send it to the parser, which would
    // re-propose the same plan.
    if (_pendingPlan != null && _handlePendingPlanShortReply(userInput.trim())) {
      return;
    }

    // 0b. Typed confirmation of a *suggested* plan ("confirm", "ok", "it's
    // good"). Suggest responses park the plan on the message as draftPlan with
    // no pending plan, so without this the affirmation would be re-parsed as a
    // brand-new request — the "What should I call this task?" loop.
    if (_pendingPlan == null &&
        _tryConfirmLatestDraftOnAffirmation(userInput.trim())) {
      return;
    }

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

    // Pass a previous plan when the user tapped Edit, OR when we're waiting on
    // the answer to a missing-detail question — so the reply refines that plan
    // instead of the model re-proposing from scratch (which caused the
    // "What time should I schedule it?" loop).
    final previousForParser = _refiningPendingPlan
        ? _pendingPlan
        : _pendingClarification;
    _refiningPendingPlan = false;
    _pendingClarification = null;

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
      final question = AiInformationalOutputGuard.sanitize(result.followUpQuestion!);
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: question,
        timestamp: DateTime.now(),
      ));
      _pendingPlan = null;
      // Remember the clarification — including the question itself — so the
      // user's answer refines it. Kept even with no partial actions: dropping
      // it made short answers parse bare and re-trigger the same question.
      _pendingClarification = result;
    } else if (result.isInformational || result.isUnsupported) {
      final raw = result.informationalMessage ??
          "I couldn't find an answer for that right now.";
      final message = AiInformationalOutputGuard.sanitize(raw);
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
      final raw = result.informationalMessage ??
          'Here\'s what I\'d suggest based on your schedule.';
      final message = AiInformationalOutputGuard.sanitize(raw);
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: message,
        timestamp: DateTime.now(),
        draftPlan: result.actions.isNotEmpty ? result : null,
        suggestedPrompts: result.suggestedPrompts,
      ));
      _pendingPlan = null;
      // A free-text reply to a suggestion ("make it 30 minutes", "move it to
      // 9am") must refine THIS plan, not start from scratch.
      _pendingClarification = result.actions.isNotEmpty ? result : null;
      _logEvent('aiSuggestPlanShown', {
        'sessionId': _sessionId,
        'actionCount': result.actions.length,
      });
    } else if (result.actions.isEmpty) {
      _pendingPlan = null;
      const fallback =
          "I didn't quite catch what you'd like me to do there. I'm best at "
          "planning your day, managing tasks and goals, and answering "
          "schedule questions — ask \"what can you do?\" for the full list.";
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: fallback,
        timestamp: DateTime.now(),
        suggestedPrompts: const [
          'What can you do?',
          'Help me plan tomorrow',
        ],
      ));
    } else {
      // Plan ready — show preview card. Prefer the model's own short
      // confirmation line when the agent provided one.
      _pendingPlan = result;
      final previewText = result.informationalMessage?.trim();
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: previewText?.isNotEmpty == true
            ? previewText!
            : 'Here\'s what I\'ll do:',
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
    _onScheduleMutated?.call(_sessionId);

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
    _pendingClarification = null;
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
    _pendingClarification = null;
    _isLoading = false;
    _inputFocusRequested = false;
    _proactiveSuggestionId = null;
    _proactiveSuggestionType = null;
    notifyListeners();
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  static final _rejectionPattern = RegExp(
    r'^(n+o+(pe|o*)?|nah+|cancel( that| it)?|stop|never ?mind|no thanks?|'
    r"don'?t|forget it)[.!]*$",
  );

  static final _affirmationPattern = RegExp(
    r'^(y+e+s+|yes please|ye[ap]h?|yep|sure|ok(ay)?|confirm|apply( it| this)?|'
    r'do it|go ahead|sounds? good|please do|perfect|great|love it|looks good|'
    r"(it|that|this)('?s| is) (all )?(good|great|fine|perfect)|as it is|"
    r'(schedule|do) (it )?as (you )?suggested)[.!]*$',
  );

  /// Handles a short yes/no-style reply while a plan is pending.
  /// Returns true when the reply was consumed (confirmed or cancelled).
  /// Typed affirmation while the latest assistant message carries an
  /// un-adopted draft plan → adopt it and run the normal confirm flow.
  bool _tryConfirmLatestDraftOnAffirmation(String input) {
    final normalized = input.toLowerCase().trim();
    if (normalized.split(RegExp(r'\s+')).length > 4) return false;
    if (!_affirmationPattern.hasMatch(normalized)) return false;

    // The draft must be the most recent assistant turn — never adopt a plan
    // the conversation has already moved past.
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.role != ChatRole.assistant) continue;
      final plan = m.draftPlan;
      if (plan == null || plan.actions.isEmpty) return false;
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.user,
        content: input,
        timestamp: DateTime.now(),
      ));
      applySuggestedPlan(m.id);
      unawaited(confirmPlan());
      return true;
    }
    return false;
  }

  bool _handlePendingPlanShortReply(String input) {
    final normalized = input.toLowerCase().trim();
    // Only intercept short replies — full sentences go to the parser.
    if (normalized.split(RegExp(r'\s+')).length > 4) return false;

    if (_rejectionPattern.hasMatch(normalized)) {
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.user,
        content: input,
        timestamp: DateTime.now(),
      ));
      cancelPlan();
      return true;
    }

    if (_affirmationPattern.hasMatch(normalized)) {
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.user,
        content: input,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
      unawaited(confirmPlan());
      return true;
    }

    return false;
  }

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

  String? _assistantSummaryForHistory(AiPlannedChanges result) {
    if (result.requiresFollowUp) {
      // Include the partial plan so the next turn's model context knows what
      // the question was about (titles/times survive even when the visible
      // chat text is just the question).
      if (result.actions.isNotEmpty) {
        return '${result.followUpQuestion} '
            '(pending: ${_compactActionsSummary(result)})';
      }
      return result.followUpQuestion;
    }
    if (result.isInformational || result.isUnsupported) {
      return result.informationalMessage;
    }
    if (result.isSuggest) {
      // The prose alone can lose the concrete times to the history cap; the
      // compact action list keeps them recoverable on the next turn.
      final msg = result.informationalMessage ?? '';
      return result.actions.isEmpty
          ? msg
          : '$msg [Proposed: ${_compactActionsSummary(result)}]';
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

  /// Compact, lossless-enough action list for model context: keeps titles AND
  /// scheduling params (time/date/duration) that the prose summary can lose.
  String _compactActionsSummary(AiPlannedChanges plan) {
    const keys = [
      'title', 'taskTitle', 'time', 'date', 'destinationDate',
      'destinationTime', 'duration', 'reminderTime', 'goalTitle',
    ];
    return plan.actions.take(6).map((a) {
      final kept = [
        for (final k in keys)
          if ((a.parameters[k]?.toString() ?? '').isNotEmpty)
            '$k=${a.parameters[k]}',
      ].join(', ');
      return kept.isEmpty ? a.actionType.name : '${a.actionType.name}($kept)';
    }).join('; ');
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
