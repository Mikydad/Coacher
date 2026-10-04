import 'ai_planned_changes.dart';

/// Lifecycle of one Coach proposal (AI chat fix plan Phase 1.1, D1/D5).
enum AiProposalStatus {
  /// The model asked a clarifying question; the next message answers it.
  awaitingAnswer,

  /// A suggestion the user has not adopted (draft card with Apply). A
  /// refinement ("make it 9am") carries it; a question does not.
  suggested,

  /// A preview card is live; Confirm executes exactly this plan.
  awaitingConfirm,

  /// The user tapped Edit: the next message refines this plan.
  editing,

  /// Terminal: executed (fully or partially).
  applied,

  /// Terminal: the user cancelled or declined it.
  cancelled,

  /// Terminal: a newer turn replaced it before it was confirmed.
  superseded,
}

/// The ONE record of "what is the plan being discussed" — replaces the old
/// trio `_pendingPlan` / `_pendingClarification` / `_refiningPendingPlan`,
/// whose interactions let an applied suggestion stay the plan under
/// discussion and let a demoted card's plan survive an error turn
/// (review §1.1 #1, §2.1 #3).
class AiProposal {
  const AiProposal({
    required this.id,
    required this.status,
    required this.plan,
    this.messageId,
    this.historyEntryId,
    this.proposedOnDateKey,
  });

  final String id;
  final AiProposalStatus status;
  final AiPlannedChanges plan;

  /// Local day key when the proposal was made (Phase 2.2): relative dates
  /// are re-validated against it at Confirm.
  final String? proposedOnDateKey;

  /// Deterministic batch id (Phase 2.1): confirming this proposal twice —
  /// double tap, crash and retry — resolves to ONE persisted batch.
  String get batchId => 'ai_batch_$id';

  /// The assistant message that carries this proposal's card or draft.
  final String? messageId;

  /// The history row the proposing turn wrote (Phase 1.5): confirmation
  /// marks THIS row, never "the newest row of the session".
  final int? historyEntryId;

  bool get isAwaitingConfirm => status == AiProposalStatus.awaitingConfirm;
  bool get isTerminal =>
      status == AiProposalStatus.applied ||
      status == AiProposalStatus.cancelled ||
      status == AiProposalStatus.superseded;

  /// The answer-only streaming path must not serve a turn that is the
  /// answer to a pending question or an edit of a live plan.
  bool get blocksStreaming =>
      status == AiProposalStatus.awaitingAnswer ||
      status == AiProposalStatus.editing;

  /// What the parser receives as the plan being refined.
  ///  - a pending question or an Edit: always;
  ///  - an un-adopted suggestion: only when the new turn is not a question
  ///    (a question after a suggestion is a question, D1);
  ///  - a live preview card: never — the card is confirmed or superseded,
  ///    not refined by prose (Edit exists for that);
  ///  - terminal: never.
  AiPlannedChanges? carryForward({required bool newTurnIsQuestion}) {
    switch (status) {
      case AiProposalStatus.awaitingAnswer:
      case AiProposalStatus.editing:
        return plan;
      case AiProposalStatus.suggested:
        return newTurnIsQuestion ? null : plan;
      case AiProposalStatus.awaitingConfirm:
      case AiProposalStatus.applied:
      case AiProposalStatus.cancelled:
      case AiProposalStatus.superseded:
        return null;
    }
  }

  AiProposal copyWith({
    AiProposalStatus? status,
    AiPlannedChanges? plan,
    String? messageId,
    int? historyEntryId,
    String? proposedOnDateKey,
  }) => AiProposal(
    id: id,
    status: status ?? this.status,
    plan: plan ?? this.plan,
    messageId: messageId ?? this.messageId,
    historyEntryId: historyEntryId ?? this.historyEntryId,
    proposedOnDateKey: proposedOnDateKey ?? this.proposedOnDateKey,
  );

  @override
  String toString() =>
      'AiProposal($id, ${status.name}, ${plan.actions.length} actions)';
}
