/// Weekly effectiveness metrics for proactive suggestions (debug/tuning only).
class ProactiveSuggestionAnalyticsSummary {
  const ProactiveSuggestionAnalyticsSummary({
    required this.weekStartKey,
    required this.totalGenerated,
    required this.byType,
    this.chatConversionsByType = const {},
  });

  final String weekStartKey;
  final int totalGenerated;
  final Map<String, int> byType;
  final Map<String, int> chatConversionsByType;
}
