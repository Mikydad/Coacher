import '../domain/models/delivery_decision.dart';
import '../domain/models/generated_insight.dart';
import 'layer4_delivery_policy.dart';

class DeliverySelectionContext {
  const DeliverySelectionContext({
    required this.now,
    required this.scopeId,
    this.preferredSurface = DeliverySurface.home,
    this.justCompletedTask = false,
    this.isActiveFocusFlow = false,
    this.forceSilent = false,
    this.deliveryHistory = const <DeliveryHistoryEntry>[],
  });

  final DateTime now;
  final String scopeId;
  final DeliverySurface preferredSurface;
  final bool justCompletedTask;
  final bool isActiveFocusFlow;
  final bool forceSilent;
  final List<DeliveryHistoryEntry> deliveryHistory;
}

class DeliveryCandidateEvaluation {
  const DeliveryCandidateEvaluation({
    required this.insightId,
    required this.accepted,
    required this.reasonCodes,
  });

  final String insightId;
  final bool accepted;
  final List<DeliveryReasonCode> reasonCodes;
}

class DeliverySelectionResult {
  const DeliverySelectionResult({
    required this.decision,
    required this.evaluations,
    required this.suppressionDiagnostics,
  });

  final DeliveryDecision decision;
  final List<DeliveryCandidateEvaluation> evaluations;
  final DeliverySuppressionDiagnostics suppressionDiagnostics;
}

class DeliverySuppressionDiagnostics {
  const DeliverySuppressionDiagnostics({
    required this.acceptedCount,
    required this.rejectedCount,
    required this.lowConfidenceSuppressed,
    required this.cooldownSuppressed,
    required this.focusBlocked,
  });

  final int acceptedCount;
  final int rejectedCount;
  final int lowConfidenceSuppressed;
  final int cooldownSuppressed;
  final int focusBlocked;
}

DeliverySelectionResult selectDeliveryDecision({
  required List<GeneratedInsight> insights,
  required DeliverySelectionContext context,
  Layer4DeliveryPolicyConfig config = kLayer4DeliveryPolicyConfig,
}) {
  final profile = resolveTimingProfile(
    now: context.now,
    justCompletedTask: context.justCompletedTask,
  );
  final sorted = List<GeneratedInsight>.from(insights)
    ..sort((a, b) => compareDeliveryCandidates(a, b, profile: profile));

  final evaluations = <DeliveryCandidateEvaluation>[];
  final accepted = <GeneratedInsight>[];
  var lowConfidenceSuppressed = 0;
  var cooldownSuppressed = 0;
  var focusBlocked = 0;

  if (context.forceSilent) {
    for (final insight in sorted) {
      evaluations.add(
        DeliveryCandidateEvaluation(
          insightId: insight.insightId,
          accepted: false,
          reasonCodes: const <DeliveryReasonCode>[
            DeliveryReasonCode.silentModeActive,
          ],
        ),
      );
    }
    return DeliverySelectionResult(
      decision: DeliveryDecision(
        selectedPrimaryInsightId: null,
        selectedSecondaryInsightId: null,
        targetSurface: DeliverySurface.none,
        shouldNotify: false,
        decisionReasonCodes: const <DeliveryReasonCode>[
          DeliveryReasonCode.silentModeActive,
          DeliveryReasonCode.noEligibleCandidates,
          DeliveryReasonCode.notifyGateBlocked,
        ],
        evaluatedAtMs: context.now.millisecondsSinceEpoch,
      ),
      evaluations: evaluations,
      suppressionDiagnostics: DeliverySuppressionDiagnostics(
        acceptedCount: 0,
        rejectedCount: evaluations.length,
        lowConfidenceSuppressed: 0,
        cooldownSuppressed: 0,
        focusBlocked: 0,
      ),
    );
  }

  if (context.isActiveFocusFlow) {
    for (final insight in sorted) {
      evaluations.add(
        DeliveryCandidateEvaluation(
          insightId: insight.insightId,
          accepted: false,
          reasonCodes: const <DeliveryReasonCode>[
            DeliveryReasonCode.blockedByActiveFocus,
          ],
        ),
      );
      focusBlocked += 1;
    }
    return DeliverySelectionResult(
      decision: DeliveryDecision(
        selectedPrimaryInsightId: null,
        selectedSecondaryInsightId: null,
        targetSurface: DeliverySurface.none,
        shouldNotify: false,
        decisionReasonCodes: const <DeliveryReasonCode>[
          DeliveryReasonCode.blockedByActiveFocus,
          DeliveryReasonCode.noEligibleCandidates,
          DeliveryReasonCode.notifyGateBlocked,
        ],
        evaluatedAtMs: context.now.millisecondsSinceEpoch,
      ),
      evaluations: evaluations,
      suppressionDiagnostics: DeliverySuppressionDiagnostics(
        acceptedCount: 0,
        rejectedCount: evaluations.length,
        lowConfidenceSuppressed: 0,
        cooldownSuppressed: 0,
        focusBlocked: focusBlocked,
      ),
    );
  }

  for (final insight in sorted) {
    final reasons = <DeliveryReasonCode>[];
    if (isLowConfidence(insight, config: config)) {
      reasons.add(DeliveryReasonCode.suppressedLowConfidence);
      lowConfidenceSuppressed += 1;
      evaluations.add(
        DeliveryCandidateEvaluation(
          insightId: insight.insightId,
          accepted: false,
          reasonCodes: reasons,
        ),
      );
      continue;
    }
    if (_isSuppressedByCooldown(insight, context: context, config: config)) {
      reasons.add(DeliveryReasonCode.suppressedCooldown);
      cooldownSuppressed += 1;
      evaluations.add(
        DeliveryCandidateEvaluation(
          insightId: insight.insightId,
          accepted: false,
          reasonCodes: reasons,
        ),
      );
      continue;
    }
    if (profile == DeliveryTimingProfile.morning &&
        insight.action == InsightAction.doNow) {
      reasons.add(DeliveryReasonCode.timingMorningBias);
    }
    if (profile == DeliveryTimingProfile.evening &&
        insight.insightBucket == InsightBucket.reinforcement) {
      reasons.add(DeliveryReasonCode.timingEveningBias);
    }
    if (profile == DeliveryTimingProfile.postCompletion &&
        insight.insightBucket == InsightBucket.reinforcement) {
      reasons.add(DeliveryReasonCode.postCompletionBias);
    }
    evaluations.add(
      DeliveryCandidateEvaluation(
        insightId: insight.insightId,
        accepted: true,
        reasonCodes: reasons,
      ),
    );
    accepted.add(insight);
  }

  if (accepted.isEmpty || config.selection.maxPrimary <= 0) {
    return DeliverySelectionResult(
      decision: DeliveryDecision(
        selectedPrimaryInsightId: null,
        selectedSecondaryInsightId: null,
        targetSurface: DeliverySurface.none,
        shouldNotify: false,
        decisionReasonCodes: const <DeliveryReasonCode>[
          DeliveryReasonCode.noEligibleCandidates,
          DeliveryReasonCode.notifyGateBlocked,
        ],
        evaluatedAtMs: context.now.millisecondsSinceEpoch,
      ),
      evaluations: evaluations,
      suppressionDiagnostics: DeliverySuppressionDiagnostics(
        acceptedCount: 0,
        rejectedCount: evaluations.length,
        lowConfidenceSuppressed: lowConfidenceSuppressed,
        cooldownSuppressed: cooldownSuppressed,
        focusBlocked: focusBlocked,
      ),
    );
  }

  final primary = accepted.first;
  final secondary = config.selection.maxSecondary > 0 && accepted.length > 1
      ? accepted[1]
      : null;
  final notifyEligible = passesNotificationGate(primary, config: config);
  final surface = _targetSurfaceForPrimary(
    preferredSurface: context.preferredSurface,
    notifyEligible: notifyEligible,
  );
  final shouldNotify = notifyEligible;

  final reasonCodes = <DeliveryReasonCode>[
    DeliveryReasonCode.selectedPrimary,
    if (secondary != null) DeliveryReasonCode.selectedSecondary,
    switch (surface) {
      DeliverySurface.home => DeliveryReasonCode.routedToHome,
      DeliverySurface.progress => DeliveryReasonCode.routedToProgress,
      DeliverySurface.notification => DeliveryReasonCode.routedToNotification,
      DeliverySurface.none => DeliveryReasonCode.noEligibleCandidates,
    },
    if (shouldNotify)
      DeliveryReasonCode.notifyGatePassed
    else
      DeliveryReasonCode.notifyGateBlocked,
  ];

  return DeliverySelectionResult(
    decision: DeliveryDecision(
      selectedPrimaryInsightId: primary.insightId,
      selectedSecondaryInsightId: secondary?.insightId,
      targetSurface: surface,
      shouldNotify: shouldNotify,
      decisionReasonCodes: reasonCodes,
      evaluatedAtMs: context.now.millisecondsSinceEpoch,
    ),
    evaluations: evaluations,
    suppressionDiagnostics: DeliverySuppressionDiagnostics(
      acceptedCount: accepted.length,
      rejectedCount: evaluations.length - accepted.length,
      lowConfidenceSuppressed: lowConfidenceSuppressed,
      cooldownSuppressed: cooldownSuppressed,
      focusBlocked: focusBlocked,
    ),
  );
}

DeliverySurface _targetSurfaceForPrimary({
  required DeliverySurface preferredSurface,
  required bool notifyEligible,
}) {
  switch (preferredSurface) {
    case DeliverySurface.home:
    case DeliverySurface.progress:
      return preferredSurface;
    case DeliverySurface.notification:
      return notifyEligible ? DeliverySurface.notification : DeliverySurface.home;
    case DeliverySurface.none:
      return DeliverySurface.home;
  }
}

bool _isSuppressedByCooldown(
  GeneratedInsight insight, {
  required DeliverySelectionContext context,
  required Layer4DeliveryPolicyConfig config,
}) {
  for (final entry in context.deliveryHistory) {
    if (entry.insightId != insight.insightId) continue;
    if (entry.scopeType != insight.scopeType) continue;
    if (entry.scopeId != insight.scopeId) continue;
    if (entry.cooldownUntilMs > context.now.millisecondsSinceEpoch) {
      return true;
    }
    final adaptiveHours = cooldownHoursForPriority(
      insight.priority,
      config: config,
    );
    final adaptiveUntil =
        entry.deliveredAtMs + Duration(hours: adaptiveHours).inMilliseconds;
    if (adaptiveUntil > context.now.millisecondsSinceEpoch) {
      return true;
    }
  }
  return false;
}
