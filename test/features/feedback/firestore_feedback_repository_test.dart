import 'dart:typed_data';

import 'package:sidepal/core/sync/sync_service.dart';
import 'package:sidepal/features/feedback/data/firestore_feedback_repository.dart';
import 'package:sidepal/features/feedback/domain/models/feedback_report.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

FeedbackReport _report() => FeedbackReport(
  id: 'feedback_1',
  userId: 'user_1',
  type: FeedbackType.bug,
  message: 'Home screen shows no tasks after midnight.',
  context: const {'appVersion': '1.0.1'},
  createdAtMs: 1000,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeFirebaseFirestore fs;

  setUp(() {
    fs = FakeFirebaseFirestore();
    SyncService.debugSkipQueuePersistenceForTests = true;
    SyncService.instance.debugResetQueueInMemoryOnly();
  });

  tearDown(() {
    SyncService.instance.debugResetQueueInMemoryOnly();
    SyncService.debugSkipQueuePersistenceForTests = false;
  });

  FirestoreFeedbackRepository repo({
    ScreenshotUploader? uploader,
    bool failingWriter = false,
  }) => FirestoreFeedbackRepository(
    uploader:
        uploader ??
        (_, _, _, {contentType = 'image/png'}) async => 'https://unused',
    docWriter: failingWriter
        ? (_, _) async => throw Exception('offline')
        : (path, payload) => fs.doc(path).set(payload),
  );

  test('writes the report without a screenshot', () async {
    await repo().submit(_report());

    final doc = await fs.doc('feedback/feedback_1').get();
    expect(doc.exists, isTrue);
    final data = doc.data()!;
    expect(data['userId'], 'user_1');
    expect(data['type'], 'bug');
    expect(data['status'], 'new');
    expect(data.containsKey('screenshotUrl'), isFalse);
  });

  test('uploads screenshot first and stores its URL on the create', () async {
    Uint8List? uploadedBytes;
    String? uploadedContentType;
    final r = repo(
      uploader: (bytes, uid, reportId, {contentType = 'image/png'}) async {
        uploadedBytes = bytes;
        uploadedContentType = contentType;
        return 'https://storage/feedback/${uid}_$reportId.png';
      },
    );

    await r.submit(
      _report(),
      screenshotBytes: Uint8List.fromList([1, 2]),
      screenshotContentType: 'image/jpeg',
    );

    expect(uploadedBytes, isNotNull);
    expect(uploadedContentType, 'image/jpeg');
    final data = (await fs.doc('feedback/feedback_1').get()).data()!;
    expect(
      data['screenshotUrl'],
      'https://storage/feedback/user_1_feedback_1.png',
    );
  });

  test('degrades to text-only when the screenshot upload throws', () async {
    final r = repo(
      uploader: (_, _, _, {contentType = 'image/png'}) async =>
          throw Exception('no network'),
    );

    await r.submit(_report(), screenshotBytes: Uint8List.fromList([1]));

    final data = (await fs.doc('feedback/feedback_1').get()).data()!;
    expect(data.containsKey('screenshotUrl'), isFalse);
    expect(
      (data['context'] as Map)['screenshotUploadFailed'],
      'true',
    );
  });

  test('queues the payload for offline replay when the write fails', () async {
    await repo(failingWriter: true).submit(_report());

    expect(SyncService.instance.pendingCount.value, 1);
  });

  test('rejects an invalid report before any IO', () async {
    final invalid = FeedbackReport(
      id: 'feedback_1',
      userId: 'user_1',
      type: FeedbackType.bug,
      message: '',
      context: const {},
      createdAtMs: 1000,
    );
    await expectLater(repo().submit(invalid), throwsArgumentError);
    expect((await fs.doc('feedback/feedback_1').get()).exists, isFalse);
  });
}
