import 'package:sidepal/features/feedback/domain/models/feedback_report.dart';
import 'package:flutter_test/flutter_test.dart';

FeedbackReport _report({
  String message = 'The timer froze on the focus page.',
  String? screenshotUrl,
}) => FeedbackReport(
  id: 'feedback_1',
  userId: 'user_1',
  type: FeedbackType.bug,
  message: message,
  context: const {'appVersion': '1.0.1', 'tabIndex': '0'},
  screenshotUrl: screenshotUrl,
  createdAtMs: 1000,
);

void main() {
  group('FeedbackReport.validate', () {
    test('accepts a well-formed report', () {
      expect(() => _report().validate(), returnsNormally);
    });

    test('rejects blank message', () {
      expect(() => _report(message: '   ').validate(), throwsArgumentError);
    });

    test('rejects message over maxMessageLength', () {
      final tooLong = 'x' * (FeedbackReport.maxMessageLength + 1);
      expect(() => _report(message: tooLong).validate(), throwsArgumentError);
    });

    test('accepts message exactly at maxMessageLength', () {
      final atLimit = 'x' * FeedbackReport.maxMessageLength;
      expect(() => _report(message: atLimit).validate(), returnsNormally);
    });

    test('rejects blank userId', () {
      final report = FeedbackReport(
        id: 'feedback_1',
        userId: '',
        type: FeedbackType.bug,
        message: 'hi',
        context: const {},
        createdAtMs: 1000,
      );
      expect(report.validate, throwsArgumentError);
    });
  });

  group('FeedbackReport serialization', () {
    test('toMap omits screenshotUrl when null', () {
      expect(_report().toMap().containsKey('screenshotUrl'), isFalse);
    });

    test('toMap includes screenshotUrl when set', () {
      expect(
        _report(screenshotUrl: 'https://x/y.png').toMap()['screenshotUrl'],
        'https://x/y.png',
      );
    });

    test('round-trips through fromMap', () {
      final original = _report(screenshotUrl: 'https://x/y.png');
      final restored = FeedbackReport.fromMap('feedback_1', original.toMap());
      expect(restored.id, original.id);
      expect(restored.userId, original.userId);
      expect(restored.type, original.type);
      expect(restored.message, original.message);
      expect(restored.context, original.context);
      expect(restored.screenshotUrl, original.screenshotUrl);
      expect(restored.status, original.status);
      expect(restored.createdAtMs, original.createdAtMs);
      expect(restored.schemaVersion, original.schemaVersion);
    });

    test('fromMap falls back to FeedbackType.other for unknown type', () {
      final map = _report().toMap()..['type'] = 'rant';
      expect(FeedbackReport.fromMap('id', map).type, FeedbackType.other);
    });

    // Lockstep guard: this exact key set is mirrored by the hasOnly list in
    // firestore.rules (match /feedback/{feedbackId}). If this test fails,
    // update BOTH the rules and this expectation together.
    test('toMap key set matches the firestore.rules hasOnly list', () {
      expect(_report(screenshotUrl: 'https://x/y.png').toMap().keys.toSet(), {
        'userId',
        'type',
        'message',
        'context',
        'screenshotUrl',
        'status',
        'createdAtMs',
        'schemaVersion',
      });
    });
  });
}
