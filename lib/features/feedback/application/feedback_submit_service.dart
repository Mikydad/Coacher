import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/utils/stable_id.dart';
import '../data/feedback_repository.dart';
import '../data/firestore_feedback_repository.dart';
import '../domain/models/feedback_report.dart';
import 'feedback_context_collector.dart';

final feedbackRepositoryProvider = Provider<FeedbackRepository>(
  (_) => FirestoreFeedbackRepository(),
);

final feedbackSubmitServiceProvider = Provider<FeedbackSubmitService>(
  (ref) => FeedbackSubmitService(
    repository: ref.watch(feedbackRepositoryProvider),
    collector: ref.watch(feedbackContextCollectorProvider),
  ),
);

/// Thrown when a submission arrives inside the cool-down window.
class FeedbackRateLimitedException implements Exception {
  const FeedbackRateLimitedException(this.secondsRemaining);

  final int secondsRemaining;
}

/// Shared submission path for the Profile feedback form and the tester
/// bug-report sheet: cool-down check → context snapshot → repository.
class FeedbackSubmitService {
  FeedbackSubmitService({required this.repository, required this.collector});

  static const Duration minInterval = Duration(seconds: 30);
  static const String _kLastSubmitKey = 'feedback_last_submit_ms_v1';

  final FeedbackRepository repository;
  final FeedbackContextCollector collector;

  Future<void> submit({
    required FeedbackType type,
    required String message,
    Uint8List? screenshotPngBytes,
    Map<String, String>? contextOverride,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final lastMs = prefs.getInt(_kLastSubmitKey) ?? 0;
    final elapsed = nowMs - lastMs;
    if (elapsed < minInterval.inMilliseconds) {
      throw FeedbackRateLimitedException(
        ((minInterval.inMilliseconds - elapsed) / 1000).ceil(),
      );
    }

    final report = FeedbackReport(
      id: StableId.generate('feedback'),
      userId: FirestorePaths.activeUid,
      type: type,
      message: message.trim(),
      context: contextOverride ?? await collector.collect(),
      createdAtMs: nowMs,
    );
    await repository.submit(report, screenshotPngBytes: screenshotPngBytes);

    // Only a successful (or queued-for-replay) submit arms the cool-down.
    await prefs.setInt(_kLastSubmitKey, nowMs);
  }
}
