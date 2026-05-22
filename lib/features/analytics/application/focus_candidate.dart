import '../../../features/coaching/domain/models/enforcement_mode.dart';
import '../domain/models/detected_behavior_pattern.dart';
import '../domain/models/generated_insight.dart';
import 'layer4_delivery_policy.dart';

// ─── Realtime context ─────────────────────────────────────────────────────────

/// V1 real-time signals that affect immediate behavioral leverage.
/// Future phases may add session state, notification state, etc.
class FocusRealtimeContext {
  const FocusRealtimeContext({
    required this.timingProfile,
    this.upcomingScheduledCount = 0,
    this.overdueCount = 0,
    this.highestOverdueSeverity = 0.0,
    this.isInFocusSession = false,
    this.overdueMaxDurationMinutes = 0,
  });

  /// Current time-of-day block.
  final DeliveryTimingProfile timingProfile;

  /// Number of items scheduled in the next 60–120 minutes.
  final int upcomingScheduledCount;

  /// Total overdue items count.
  final int overdueCount;

  /// 0–1 severity of the most severe overdue item.
  final double highestOverdueSeverity;

  /// Whether the user is currently in an active focus/timer session.
  final bool isInFocusSession;

  /// Duration in minutes of the longest overdue item (for urgency scaling).
  final int overdueMaxDurationMinutes;

  static const FocusRealtimeContext empty = FocusRealtimeContext(
    timingProfile: DeliveryTimingProfile.afternoon,
  );
}

// ─── Focus candidate ─────────────────────────────────────────────────────────

/// A single evaluated candidate fed into [FocusScoringEngine].
/// Bundles an insight with its supporting patterns, current realtime context,
/// and the entity's [EnforcementMode] for urgency weighting.
class FocusCandidate {
  const FocusCandidate({
    required this.insight,
    required this.supportingPatterns,
    required this.realtimeContext,
    this.enforcementMode = EnforcementMode.disciplined,
  });

  final GeneratedInsight insight;
  final List<DetectedBehaviorPattern> supportingPatterns;
  final FocusRealtimeContext realtimeContext;

  /// Per-entity enforcement intensity — used to weight urgency in scoring.
  /// Defaults to [EnforcementMode.disciplined] (×1.0 — no change) when
  /// the entity has no explicit mode configured.
  final EnforcementMode enforcementMode;
}
