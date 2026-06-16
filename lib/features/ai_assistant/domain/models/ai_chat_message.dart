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
    this.suggestedPrompts = const [],
    this.isLoading = false,
    this.isCurrentPlan = false,
    this.isExecuted = false,
  });

  final String id;
  final ChatRole role;
  final String content;
  final DateTime timestamp;

  /// Non-null only for assistant messages that carry a preview card.
  final AiPlannedChanges? plannedChanges;

  /// Optional follow-up chips under an informational assistant message.
  final List<String> suggestedPrompts;

  /// True while the AI is still processing (shows loading dots).
  final bool isLoading;

  /// True for the most recently generated, unconfirmed plan.
  /// Controls whether action buttons (Confirm / Edit / Cancel) are shown.
  final bool isCurrentPlan;

  /// True after the user confirmed and actions were applied.
  final bool isExecuted;

  bool get hasPreviewCard => plannedChanges != null && !isLoading;

  AiChatMessage copyWith({
    String? id,
    ChatRole? role,
    String? content,
    DateTime? timestamp,
    AiPlannedChanges? plannedChanges,
    List<String>? suggestedPrompts,
    bool? isLoading,
    bool? isCurrentPlan,
    bool? isExecuted,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      plannedChanges: plannedChanges ?? this.plannedChanges,
      suggestedPrompts: suggestedPrompts ?? this.suggestedPrompts,
      isLoading: isLoading ?? this.isLoading,
      isCurrentPlan: isCurrentPlan ?? this.isCurrentPlan,
      isExecuted: isExecuted ?? this.isExecuted,
    );
  }

  @override
  String toString() =>
      'AiChatMessage(${role.name}, loading: $isLoading, "${content.length > 40 ? content.substring(0, 40) : content}")';
}
