/// Tracks proactive → chat conversion for weekly tuning summaries.
abstract final class ProactiveChatConversionTracker {
  static final Map<String, int> conversionsByType = {};

  static void record(String suggestionType) {
    conversionsByType[suggestionType] =
        (conversionsByType[suggestionType] ?? 0) + 1;
  }

  static Map<String, int> snapshot() => Map.unmodifiable(conversionsByType);
}
