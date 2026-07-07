import '../../../../core/validation/model_validators.dart';
import 'generated_insight.dart';

const int kDeliveryDecisionSchemaVersion = 1;
const int kDeliveryHistorySchemaVersion = 1;

enum DeliverySurface { none, home, progress, notification }

DeliverySurface deliverySurfaceFromStorage(String? raw) {
  for (final value in DeliverySurface.values) {
    if (value.name == raw) return value;
  }
  return DeliverySurface.none;
}

enum DeliveryReasonCode {
  selectedPrimary,
  selectedSecondary,
  noEligibleCandidates,
  silentModeActive,
  suppressedLowConfidence,
  suppressedCooldown,
  blockedByActiveFocus,
  routedToHome,
  routedToProgress,
  routedToNotification,
  notifyGatePassed,
  notifyGateBlocked,
  timingMorningBias,
  timingEveningBias,
  postCompletionBias,
}

DeliveryReasonCode deliveryReasonCodeFromStorage(String? raw) {
  for (final value in DeliveryReasonCode.values) {
    if (value.name == raw) return value;
  }
  return DeliveryReasonCode.noEligibleCandidates;
}

enum DeliverySuppressionStatus { none, lowConfidence, cooldown, interrupted }

DeliverySuppressionStatus deliverySuppressionStatusFromStorage(String? raw) {
  for (final value in DeliverySuppressionStatus.values) {
    if (value.name == raw) return value;
  }
  return DeliverySuppressionStatus.none;
}

class DeliveryDecision {
  const DeliveryDecision({
    required this.selectedPrimaryInsightId,
    this.selectedSecondaryInsightId,
    required this.targetSurface,
    required this.shouldNotify,
    required this.decisionReasonCodes,
    required this.evaluatedAtMs,
    this.schemaVersion = kDeliveryDecisionSchemaVersion,
  });

  final String? selectedPrimaryInsightId;
  final String? selectedSecondaryInsightId;
  final DeliverySurface targetSurface;
  final bool shouldNotify;
  final List<DeliveryReasonCode> decisionReasonCodes;
  final int evaluatedAtMs;
  final int schemaVersion;

  void validate() {
    if (selectedPrimaryInsightId != null) {
      ModelValidators.requireNotBlank(
        selectedPrimaryInsightId!,
        'deliveryDecision.selectedPrimaryInsightId',
      );
    }
    if (selectedSecondaryInsightId != null) {
      ModelValidators.requireNotBlank(
        selectedSecondaryInsightId!,
        'deliveryDecision.selectedSecondaryInsightId',
      );
    }
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'deliveryDecision.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    if (selectedPrimaryInsightId != null)
      'selectedPrimaryInsightId': selectedPrimaryInsightId,
    if (selectedSecondaryInsightId != null)
      'selectedSecondaryInsightId': selectedSecondaryInsightId,
    'targetSurface': targetSurface.name,
    'shouldNotify': shouldNotify,
    'decisionReasonCodes': decisionReasonCodes.map((e) => e.name).toList(),
    'evaluatedAtMs': evaluatedAtMs,
    'schemaVersion': schemaVersion,
  };

  static DeliveryDecision fromMap(Map<String, dynamic> map) {
    final rawReasonCodes = map['decisionReasonCodes'];
    final reasonCodes = <DeliveryReasonCode>[];
    if (rawReasonCodes is List) {
      for (final value in rawReasonCodes) {
        if (value is String) {
          reasonCodes.add(deliveryReasonCodeFromStorage(value));
        }
      }
    }
    return DeliveryDecision(
      selectedPrimaryInsightId: map['selectedPrimaryInsightId'] as String?,
      selectedSecondaryInsightId: map['selectedSecondaryInsightId'] as String?,
      targetSurface: deliverySurfaceFromStorage(
        map['targetSurface'] as String?,
      ),
      shouldNotify: map['shouldNotify'] as bool? ?? false,
      decisionReasonCodes: reasonCodes,
      evaluatedAtMs: (map['evaluatedAtMs'] as num?)?.toInt() ?? 0,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kDeliveryDecisionSchemaVersion,
    );
  }
}

class DeliveryHistoryEntry {
  const DeliveryHistoryEntry({
    required this.insightId,
    required this.surface,
    required this.scopeType,
    required this.scopeId,
    required this.deliveredAtMs,
    required this.priority,
    required this.confidence,
    required this.suppressionStatus,
    required this.cooldownUntilMs,
    this.schemaVersion = kDeliveryHistorySchemaVersion,
  });

  final String insightId;
  final DeliverySurface surface;
  final InsightScopeType scopeType;
  final String scopeId;
  final int deliveredAtMs;
  final InsightPriority priority;
  final double confidence;
  final DeliverySuppressionStatus suppressionStatus;
  final int cooldownUntilMs;
  final int schemaVersion;

  void validate() {
    ModelValidators.requireNotBlank(
      insightId,
      'deliveryHistoryEntry.insightId',
    );
    ModelValidators.requireNotBlank(scopeId, 'deliveryHistoryEntry.scopeId');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'deliveryHistoryEntry.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'insightId': insightId,
    'surface': surface.name,
    'scopeType': scopeType.name,
    'scopeId': scopeId,
    'deliveredAtMs': deliveredAtMs,
    'priority': priority.name,
    'confidence': confidence.clamp(0.0, 1.0),
    'suppressionStatus': suppressionStatus.name,
    'cooldownUntilMs': cooldownUntilMs,
    'schemaVersion': schemaVersion,
  };

  static DeliveryHistoryEntry fromMap(Map<String, dynamic> map) {
    return DeliveryHistoryEntry(
      insightId: map['insightId'] as String? ?? '',
      surface: deliverySurfaceFromStorage(map['surface'] as String?),
      scopeType: insightScopeTypeFromStorage(map['scopeType'] as String?),
      scopeId: map['scopeId'] as String? ?? '',
      deliveredAtMs: (map['deliveredAtMs'] as num?)?.toInt() ?? 0,
      priority: insightPriorityFromStorage(map['priority'] as String?),
      confidence: ((map['confidence'] as num?)?.toDouble() ?? 0).clamp(
        0.0,
        1.0,
      ),
      suppressionStatus: deliverySuppressionStatusFromStorage(
        map['suppressionStatus'] as String?,
      ),
      cooldownUntilMs: (map['cooldownUntilMs'] as num?)?.toInt() ?? 0,
      schemaVersion:
          (map['schemaVersion'] as num?)?.toInt() ??
          kDeliveryHistorySchemaVersion,
    );
  }
}
