import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/sync/sync_service.dart';
import '../domain/models/feedback_report.dart';
import 'feedback_repository.dart';
import 'feedback_screenshot_storage.dart';

typedef ScreenshotUploader =
    Future<String> Function(Uint8List pngBytes, String uid, String reportId);
typedef FeedbackDocWriter =
    Future<void> Function(String path, Map<String, dynamic> payload);

/// Writes feedback reports to the top-level `feedback` Firestore collection.
///
/// Firestore rules only allow *creates* on `feedback/{id}`, so the screenshot
/// is uploaded first and its URL included in the one and only write — a
/// follow-up update would be rejected.
class FirestoreFeedbackRepository implements FeedbackRepository {
  FirestoreFeedbackRepository({
    ScreenshotUploader? uploader,
    FeedbackDocWriter? docWriter,
  }) : _uploader = uploader ?? FeedbackScreenshotStorage().upload,
       _docWriter = docWriter ?? _firestoreSet;

  final ScreenshotUploader _uploader;
  final FeedbackDocWriter _docWriter;

  static Future<void> _firestoreSet(
    String path,
    Map<String, dynamic> payload,
  ) => FirebaseFirestore.instance.doc(path).set(payload);

  @override
  Future<void> submit(
    FeedbackReport report, {
    Uint8List? screenshotPngBytes,
  }) async {
    report.validate();
    var effective = report;
    if (screenshotPngBytes != null) {
      try {
        final url = await _uploader(
          screenshotPngBytes,
          report.userId,
          report.id,
        );
        effective = report.copyWith(screenshotUrl: url);
      } catch (_) {
        // Screenshot bytes are never queued for replay (the offline queue
        // carries Firestore JSON only) — degrade to a text-only report.
        effective = report.copyWith(
          context: {...report.context, 'screenshotUploadFailed': 'true'},
        );
      }
    }
    final path = 'feedback/${effective.id}';
    final payload = effective.toMap();
    try {
      await _docWriter(path, payload);
    } catch (_) {
      await SyncService.instance.enqueueUpsert(
        entityType: 'feedbackReport',
        documentPath: path,
        payload: payload,
      );
    }
  }
}
