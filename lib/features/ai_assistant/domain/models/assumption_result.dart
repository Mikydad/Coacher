/// The source of data used to build an [AssumptionResult].
enum AssumptionSource { taskHistory, goalHistory, noMatch }

/// Carries pre-filled parameters and metadata inferred from the user's history.
///
/// Produced by [AiAssumptionEngine.infer] for a single incomplete [AiAction].
class AssumptionResult {
  const AssumptionResult({
    required this.confidence,
    required this.suggestedParameters,
    required this.reasonLabel,
    required this.source,
  });

  /// 0.0–1.0 confidence in the inference.
  final double confidence;

  /// Pre-filled values keyed by parameter name (only null fields in the original
  /// action should be filled — the engine never overwrites user-provided values).
  final Map<String, dynamic> suggestedParameters;

  /// Human-readable label shown in the preview card.
  /// e.g. "Based on your latest fitness setup"
  final String reasonLabel;

  /// Where the data came from.
  final AssumptionSource source;

  /// A no-match result: confidence 0, empty parameters.
  static const AssumptionResult noMatch = AssumptionResult(
    confidence: 0.0,
    suggestedParameters: {},
    reasonLabel: '',
    source: AssumptionSource.noMatch,
  );

  bool get hasMatch => source != AssumptionSource.noMatch && confidence >= 0.80;
}
