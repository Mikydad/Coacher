import 'dart:convert';
import 'dart:io';

import '../../../core/firebase/firestore_paths.dart';
import '../../../core/storage/app_storage_dir.dart';
import '../domain/task_timer_engine.dart';
import '../domain/models/timer_session.dart';

class TimerRuntimeCache {
  const TimerRuntimeCache();

  Future<File> _file() async {
    final dir = await getAppStorageDirectory();
    return File('${dir.path}/timer_runtime.json');
  }

  Future<void> save({
    required TimerSessionTargetType targetType,
    required String taskId,
    required String blockId,
    required String label,
    required ExecutionPhase phase,
    required Duration elapsed,
    DateTime? runningSince,
    int? targetDurationMinutes,

    /// Time Tracker (2026-09-12): the timer-sourced activity event this
    /// session opened, so a crash-restore still ends the right one.
    String? activityEventId,
  }) async {
    final file = await _file();
    final payload = <String, dynamic>{
      // Audit H4: the file is device-local; the owner tag stops a resumed
      // session (label, task ids) from being restored into another account.
      'ownerUid': FirestorePaths.activeUid,
      'targetType': targetType.storageValue,
      'taskId': taskId,
      'blockId': blockId,
      'label': label,
      'phase': phase.name,
      'elapsedMs': elapsed.inMilliseconds,
      'runningSinceMs': runningSince?.millisecondsSinceEpoch,
      'targetDurationMinutes': targetDurationMinutes,
      'activityEventId': ?activityEventId,
    };
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<Map<String, dynamic>?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final owner = data['ownerUid'];
    if (owner is String && owner != FirestorePaths.activeUid) {
      await clear();
      return null;
    }
    return data;
  }

  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
