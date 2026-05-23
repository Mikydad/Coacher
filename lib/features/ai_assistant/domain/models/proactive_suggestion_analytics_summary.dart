/// Weekly effectiveness metrics for proactive suggestions (debug/tuning only).
class ProactiveSuggestionAnalyticsSummary {
  const ProactiveSuggestionAnalyticsSummary({
    required this.weekStartKey,
    required this.totalGenerated,
    required this.byType,
  });

  final String weekStartKey;
  final int totalGenerated;
  final Map<String, int> byType;
}
