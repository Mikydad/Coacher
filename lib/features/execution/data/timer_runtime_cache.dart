import 'dart:convert';
import 'dart:io';

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
  }) async {
    final file = await _file();
    final payload = <String, dynamic>{
      'targetType': targetType.storageValue,
      'taskId': taskId,
      'blockId': blockId,
      'label': label,
      'phase': phase.name,
      'elapsedMs': elapsed.inMilliseconds,
      'runningSinceMs': runningSince?.millisecondsSinceEpoch,
      'targetDurationMinutes': targetDurationMinutes,
    };
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<Map<String, dynamic>?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return null;
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  Future<void> clear() async {
    final file = await _file();
    if (await file.exists()) {
      await file.delete();
    }
  }
}
