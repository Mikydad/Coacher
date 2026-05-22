import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/utils/stable_id.dart';
import '../data/ai_interaction_history_repository.dart';
import '../domain/models/ai_chat_message.dart';
import '../domain/models/ai_planned_changes.dart';
import 'ai_action_executor.dart';
import 'ai_intent_parser.dart';

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
  })  : _intentParser = intentParser,
        _actionExecutor = actionExecutor,
        _historyRepository = historyRepository,
        _analyticsLogger = analyticsLogger,
        _sessionId = StableId.generate('session');

  final AiIntentParser _intentParser;
  final AiActionExecutor _actionExecutor;
  final AiInteractionHistoryRepository _historyRepository;
  final AiAnalyticsLogger? _analyticsLogger;

  String _sessionId;
  final List<AiChatMessage> _messages = [];
  AiPlannedChanges? _pendingPlan;
  bool _isLoading = false;
  bool _inputFocusRequested = false;

  // ─── Getters ──────────────────────────────────────────────────────────────

  List<AiChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get hasPendingPlan => _pendingPlan != null;
  AiPlannedChanges? get pendingPlan => _pendingPlan;
  bool get inputFocusRequested => _inputFocusRequested;
  String get sessionId => _sessionId;

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

    // 4. Parse intent
    AiPlannedChanges result;
    try {
      result = await _intentParser.parse(userInput.trim(), _sessionId);
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
      // Follow-up question — show text only, no preview card
      _addMessage(AiChatMessage(
        id: StableId.generate('msg'),
        role: ChatRole.assistant,
        content: result.followUpQuestion!,
        timestamp: DateTime.now(),
      ));
      _pendingPlan = null;
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

    // 6. Persist interaction
    await _historyRepository.save(
      sessionId: _sessionId,
      userInput: userInput.trim(),
      parsedActions: result.actions,
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

  Future<void> confirmPlan() async {
    final plan = _pendingPlan;
    if (plan == null) return;

    _setLoading(true);

    final result = await _actionExecutor.execute(plan.actions);

    await _historyRepository.markConfirmed(_sessionId);
    await _historyRepository.markExecuted(_sessionId);

    _pendingPlan = null;
    _demoteCurrentPlan();
    _setLoading(false);

    final summary = result.hasFailures
        ? 'Done with some issues:\n${result.toSummaryMessage()}'
        : result.successes.isNotEmpty
            ? result.toSummaryMessage()
            : 'Done!';

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

    notifyListeners();
  }

  void cancelPlan() {
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

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _logEvent(String name, [Map<String, dynamic>? props]) {
    unawaited(
      Future.microtask(() => _analyticsLogger?.call(name, props ?? {})),
    );
  }
}
