import 'dart:typed_data';

import '../domain/models/feedback_report.dart';

abstract class FeedbackRepository {
  /// Persists [report], optionally attaching [screenshotPngBytes] first.
  ///
  /// Must not throw for screenshot-upload failures (degrade to text-only)
  /// or for Firestore write failures (queue for offline replay).
  Future<void> submit(FeedbackReport report, {Uint8List? screenshotPngBytes});
}
