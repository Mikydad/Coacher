import 'ai_planned_changes.dart';

// ─── Role enum ───────────────────────────────────────────────────────────────

enum ChatRole { user, assistant, system }

// ─── Chat message model ───────────────────────────────────────────────────────

/// A single message in the Coach AI conversation thread.
///
/// - [role] == [ChatRole.user]      → rendered as a right-aligned bubble.
/// - [role] == [ChatRole.assistant] → rendered as a left-aligned text or as
///   a [PlannedChangesCard] when [plannedChanges] is non-null.
/// - [isLoading] == true            → rendered as the "thinking…" indicator.
class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.plannedChanges,
    this.draftPlan,
    this.suggestedPrompts = const [],
    this.isLoading = false,
    this.isCurrentPlan = false,
    this.isExecuted = false,
    this.isCancelled = false,
    this.autoCommittedBatchId,
    this.isError = false,
    this.retryInput,
    this.retryTurnId,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  /// Non-null only for assistant messages that carry a preview card.
  final AiPlannedChanges? plannedChanges;

  /// Draft plan from suggest mode — shown after user taps Apply this plan.
  final AiPlannedChanges? draftPlan;

  /// Optional follow-up chips under an informational assistant message.
  final List<String> suggestedPrompts;

  /// True while the AI is still processing (shows loading dots).
  final bool isLoading;

  /// True for the most recently generated, unconfirmed plan.
  /// Controls whether action buttons (Confirm / Edit / Cancel) are shown.
  final bool isCurrentPlan;

  /// True after the user confirmed and actions were applied.
  final bool isExecuted;

  /// True after the user cancelled/rejected this plan — the card renders
  /// inert (no Confirm), mirroring the Applied state for the other outcome.
  final bool isCancelled;

  /// Batch id of an auto-committed write (createIntention — the one action
  /// type that skips the preview card, decision log 2026-07-23). Non-null
  /// renders inline [View] [Undo] affordances under the bubble.
  final String? autoCommittedBatchId;

  /// A failed turn (fix-wave Phase 3, §8 H1): rendered with error styling
  /// and — when [retryInput] is set — a Retry chip that re-runs the turn.
  final bool isError;

  /// The user input the failed turn was answering; Retry re-sends it.
  final String? retryInput;

  /// The failed turn's id — Retry passes it back so the server treats the
  /// re-run as a free same-turn follow-up instead of double-charging.
  final String? retryTurnId;

  bool get hasPreviewCard => plannedChanges != null && !isLoading;
  bool get hasDraftPlan =>
      draftPlan != null && plannedChanges == null && !isLoading;

  AiChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    AiPlannedChanges? plannedChanges,
    Object? draftPlan = _sentinel,
    List<String>? suggestedPrompts,
    bool? isLoading,
    bool? isCurrentPlan,
    bool? isExecuted,
    bool? isCancelled,
    String? autoCommittedBatchId,
    bool? isError,
    String? retryInput,
    String? retryTurnId,
    bool clearDraftPlan = false,
    bool clearPlannedChanges = false,
    bool clearAutoCommittedBatchId = false,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      plannedChanges: clearPlannedChanges
          ? null
          : (plannedChanges ?? this.plannedChanges),
      draftPlan: clearDraftPlan
          ? null
          : (draftPlan == _sentinel
                ? this.draftPlan
                : draftPlan as AiPlannedChanges?),
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
      isLoading: isLoading ?? this.isLoading,
      isCurrentPlan: isCurrentPlan ?? this.isCurrentPlan,
      isExecuted: isExecuted ?? this.isExecuted,
      isCancelled: isCancelled ?? this.isCancelled,
      autoCommittedBatchId: clearAutoCommittedBatchId
          ? null
          : (autoCommittedBatchId ?? this.autoCommittedBatchId),
      isError: isError ?? this.isError,
      retryInput: retryInput ?? this.retryInput,
      retryTurnId: retryTurnId ?? this.retryTurnId,
    );
  }

  @override
  String toString() =>
      'AiChatMessage(${role.name}, loading: $isLoading, "${content.length > 40 ? content.substring(0, 40) : content}")';
}

const _sentinel = Object();
