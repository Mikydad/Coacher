/// Describes which subsystems need to recompute after a schedule mutation.
///
/// Use the named factory constructors to get the correct scope for each
/// mutation type, then pass to [UnifiedRecomputeGraph.schedule].
class RecomputeScope {
  const RecomputeScope({
    this.overlaps = false,
    this.analytics = false,
    this.focus = false,
    this.suggestions = false,
    this.layer34 = false,
    this.aiSummary = false,
    this.notifications = false,
  });

  /// Re-check time block overlap/conflict detection.
  final bool overlaps;

  /// Invalidate the analytics bundle (streaks embedded).
  final bool analytics;

  /// Invalidate coaching focus (light path only — no layer34 re-run).
  final bool focus;

  /// Invalidate proactive suggestions.
  final bool suggestions;

  /// Invalidate layer 3 delivery insights + layer 4 delivery decision.
  final bool layer34;

  /// Invalidate the current AI summary.
  final bool aiSummary;

  /// Trigger notification reconciliation via AttentionOrchestratorService.
  final bool notifications;

  /// Merge two scopes with bitwise OR — used by the debounce coalescing logic.
  RecomputeScope merge(RecomputeScope other) {
    return RecomputeScope(
      overlaps: overlaps || other.overlaps,
      analytics: analytics || other.analytics,
      focus: focus || other.focus,
      suggestions: suggestions || other.suggestions,
      layer34: layer34 || other.layer34,
      aiSummary: aiSummary || other.aiSummary,
      notifications: notifications || other.notifications,
    );
  }

  bool get isEmpty =>
      !overlaps &&
      !analytics &&
      !focus &&
      !suggestions &&
      !layer34 &&
      !aiSummary &&
      !notifications;

  // ─── Named factories (from scope matrix in PRD) ───────────────────────────

  /// Task create / update / delete — all subsystems.
  factory RecomputeScope.forTaskMutation() => const RecomputeScope(
        overlaps: true,
        analytics: true,
        focus: true,
        suggestions: true,
        layer34: true,
        aiSummary: true,
        notifications: true,
      );

  /// Task completed — analytics + focus + suggestions + layer34 + notifications.
  factory RecomputeScope.forTaskCompletion() => const RecomputeScope(
        analytics: true,
        focus: true,
        suggestions: true,
        layer34: true,
        aiSummary: true,
        notifications: true,
      );

  /// Task deferred — analytics + suggestions + notifications.
  factory RecomputeScope.forTaskDeferred() => const RecomputeScope(
        analytics: true,
        suggestions: true,
        notifications: true,
      );

  /// Time block changed — overlaps + suggestions + notifications.
  factory RecomputeScope.forTimeBlockChange() => const RecomputeScope(
        overlaps: true,
        suggestions: true,
        notifications: true,
      );

  /// Reminder changed — notifications only.
  factory RecomputeScope.forReminderChange() => const RecomputeScope(
        notifications: true,
      );

  /// Context override changed — notifications only.
  factory RecomputeScope.forContextOverrideChange() => const RecomputeScope(
        notifications: true,
      );

  /// Goal changed — analytics + focus + suggestions + layer34.
  factory RecomputeScope.forGoalChange() => const RecomputeScope(
        analytics: true,
        focus: true,
        suggestions: true,
        layer34: true,
      );

  /// Full refresh — all flags true. Used by sync and lifecycle events.
  factory RecomputeScope.forFullRefresh() => const RecomputeScope(
        overlaps: true,
        analytics: true,
        focus: true,
        suggestions: true,
        layer34: true,
        aiSummary: true,
        notifications: true,
      );

  @override
  String toString() =>
      'RecomputeScope(overlaps:$overlaps analytics:$analytics focus:$focus '
      'suggestions:$suggestions layer34:$layer34 aiSummary:$aiSummary '
      'notifications:$notifications)';
}
