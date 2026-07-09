import '../../../../core/validation/model_validators.dart';

/// What kind of feedback the user is sending.
enum FeedbackType { bug, feature, question, other }

/// A single feedback/bug report submitted from the app.
///
/// Stored as `feedback/{id}` in Firestore. The map produced by [toMap] must
/// stay in lockstep with the `hasOnly` key list in `firestore.rules`
/// (`match /feedback/{feedbackId}`) — a unit test in
/// `test/features/feedback/feedback_report_model_test.dart` guards the pair.
class FeedbackReport {
  const FeedbackReport({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    required this.context,
    this.screenshotUrl,
    this.status = 'new',
    required this.createdAtMs,
    this.schemaVersion = 1,
  });

  static const int maxMessageLength = 2000;

  /// Document id — used as the Firestore doc path, not serialized in the body.
  final String id;
  final String userId;
  final FeedbackType type;
  final String message;

  /// Flat diagnostic snapshot (app version, device, screen, sync state, …).
  /// Values are pre-stringified so rules and the console stay simple.
  final Map<String, String> context;
  final String? screenshotUrl;
  final String status;
  final int createdAtMs;
  final int schemaVersion;

  FeedbackReport copyWith({
    Map<String, String>? context,
    String? screenshotUrl,
  }) => FeedbackReport(
    id: id,
    userId: userId,
    type: type,
    message: message,
    context: context ?? this.context,
    screenshotUrl: screenshotUrl ?? this.screenshotUrl,
    status: status,
    createdAtMs: createdAtMs,
    schemaVersion: schemaVersion,
  );

  void validate() {
    ModelValidators.requireNotBlank(id, 'feedbackReport.id');
    ModelValidators.requireNotBlank(userId, 'feedbackReport.userId');
    ModelValidators.requireNotBlank(message, 'feedbackReport.message');
    ModelValidators.requireRange(
      value: message.length,
      min: 1,
      max: maxMessageLength,
      fieldName: 'feedbackReport.message.length',
    );
    ModelValidators.requireNotBlank(status, 'feedbackReport.status');
    ModelValidators.requireRange(
      value: schemaVersion,
      min: 1,
      max: 9999,
      fieldName: 'feedbackReport.schemaVersion',
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'type': type.name,
    'message': message,
    'context': context,
    if (screenshotUrl != null) 'screenshotUrl': screenshotUrl,
    'status': status,
    'createdAtMs': createdAtMs,
    'schemaVersion': schemaVersion,
  };

  static FeedbackReport fromMap(String id, Map<String, dynamic> map) =>
      FeedbackReport(
        id: id,
        userId: map['userId'] as String? ?? '',
        type: _typeFromStorage(map['type'] as String?),
        message: map['message'] as String? ?? '',
        context: {
          for (final e in (map['context'] as Map? ?? const {}).entries)
            '${e.key}': '${e.value}',
        },
        screenshotUrl: map['screenshotUrl'] as String?,
        status: map['status'] as String? ?? 'new',
        createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
        schemaVersion: (map['schemaVersion'] as num?)?.toInt() ?? 1,
      );
}

FeedbackType _typeFromStorage(String? raw) {
  for (final v in FeedbackType.values) {
    if (v.name == raw) return v;
  }
  return FeedbackType.other;
}
