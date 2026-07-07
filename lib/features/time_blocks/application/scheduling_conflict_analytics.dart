/// Encodes inline conflict resolution metadata in [AnalyticsEvent.reason].
String inlineConflictResolutionReason({
  required String movedEntity,
  required Object suggestionIndex,
  String? conflictingEntityId,
}) {
  final index = suggestionIndex.toString();
  final parts = <String>['movedEntity=$movedEntity', 'suggestionIndex=$index'];
  if (conflictingEntityId != null && conflictingEntityId.isNotEmpty) {
    parts.add('conflictEntityId=$conflictingEntityId');
  }
  return parts.join(';');
}
