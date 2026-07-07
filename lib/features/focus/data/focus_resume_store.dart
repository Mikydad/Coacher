import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:io';

import '../../../core/storage/app_storage_dir.dart';
import '../../../core/utils/date_keys.dart';

/// Local, offline-safe record of how long each task has been focused on today.
///
/// Timer sessions live in Firestore and may not be readable immediately after a
/// partial stop (queued write). This file-backed store lets a partial task
/// resume from its last elapsed time instantly, without a network round-trip.
class FocusResumeStore {
  const FocusResumeStore();

  Future<File> _file() async {
    final dir = await getAppStorageDirectory();
    return File('${dir.path}/focus_resume.json');
  }

  Future<Map<String, dynamic>> _read() async {
    try {
      final file = await _file();
      if (!await file.exists()) return {};
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) return {};
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      return {};
    } catch (_) {
      return {};
    }
  }

  /// Persists [elapsed] for [taskId] under today's date key. Older days are
  /// dropped so the file never grows unbounded.
  Future<void> saveElapsed(String taskId, Duration elapsed) async {
    if (taskId.isEmpty) return;
    try {
      final todayKey = DateKeys.todayKey();
      final byTask = <String, dynamic>{
        ...?(await _read())[todayKey] as Map<String, dynamic>?,
      };
      byTask[taskId] = elapsed.inSeconds;
      final file = await _file();
      await file.writeAsString(jsonEncode({todayKey: byTask}), flush: true);
    } catch (_) {
      // Best-effort; resume is a convenience, never block the stop flow.
    }
  }

  /// Reads stored elapsed for [taskId] for today, or `null` if none.
  Future<Duration?> readElapsed(String taskId) async {
    if (taskId.isEmpty) return null;
    final todayKey = DateKeys.todayKey();
    final byTask = (await _read())[todayKey];
    if (byTask is! Map<String, dynamic>) return null;
    final seconds = byTask[taskId];
    if (seconds is! num) return null;
    return Duration(seconds: seconds.toInt().clamp(0, 24 * 60 * 60));
  }

  /// Clears the stored elapsed for [taskId] (e.g. after full completion).
  Future<void> clear(String taskId) async {
    if (taskId.isEmpty) return;
    try {
      final todayKey = DateKeys.todayKey();
      final byTask = <String, dynamic>{
        ...?(await _read())[todayKey] as Map<String, dynamic>?,
      };
      if (!byTask.containsKey(taskId)) return;
      byTask.remove(taskId);
      final file = await _file();
      await file.writeAsString(jsonEncode({todayKey: byTask}), flush: true);
    } catch (e) {
      debugPrint('focus_resume_store: swallowed error: $e');
    }
  }
}
