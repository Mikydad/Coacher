import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../execution/domain/models/timer_session.dart';

/// Elapsed focus time to restore when reopening a partially completed task.
///
/// Uses the most recent timer session for [taskId] on today's calendar date.
/// Best-effort: any read failure (offline, unsynced write, missing index)
/// resolves to [Duration.zero] so it never blocks starting a focus session.
Future<Duration> readPriorFocusElapsedForTask(
  WidgetRef ref,
  String taskId,
) async {
  if (taskId.isEmpty) return Duration.zero;

  // Local store first — reliable and offline-safe immediately after a stop.
  try {
    final local = await ref.read(focusResumeStoreProvider).readElapsed(taskId);
    if (local != null && local > Duration.zero) return local;
  } catch (_) {
    // Fall through to Firestore.
  }

  try {
    final sessions = await ref
        .read(executionRepositoryProvider)
        .getSessionsForTask(taskId);
    if (sessions.isEmpty) return Duration.zero;

    final todayKey = DateKeys.todayKey();
    final todaySessions = sessions.where((session) {
      final started = DateTime.fromMillisecondsSinceEpoch(session.startedAtMs);
      return DateKeys.yyyymmdd(started) == todayKey;
    }).toList();
    if (todaySessions.isEmpty) return Duration.zero;

    todaySessions.sort(
      (a, b) => _sessionSortMs(b).compareTo(_sessionSortMs(a)),
    );
    final latest = todaySessions.first;
    return Duration(seconds: latest.elapsedSeconds.clamp(0, 24 * 60 * 60));
  } catch (_) {
    return Duration.zero;
  }
}

int _sessionSortMs(TimerSession session) =>
    session.endedAtMs ?? session.startedAtMs;

String formatFocusElapsed(Duration elapsed) {
  final totalSeconds = elapsed.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}
