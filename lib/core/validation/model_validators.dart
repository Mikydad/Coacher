class ModelValidators {
  const ModelValidators._();

  static void requireNotBlank(String value, String fieldName) {
    if (value.trim().isEmpty) {
      throw ArgumentError('$fieldName must not be empty');
    }
  }

  static void requireRange({
    required int value,
    required int min,
    required int max,
    required String fieldName,
  }) {
    if (value < min || value > max) {
      throw ArgumentError('$fieldName must be between $min and $max');
    }
  }

  static void validateScore({required int completionPercent, String? reason}) {
    requireRange(
      value: completionPercent,
      min: 0,
      max: 100,
      fieldName: 'completionPercent',
    );
    if (completionPercent < 100 && (reason == null || reason.trim().isEmpty)) {
      throw ArgumentError('reason is required when completionPercent is below 100');
    }
  }
}
