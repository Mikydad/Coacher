import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../storage/app_storage_dir.dart';
import 'offline_operation.dart';

/// Disk persistence for the offline outbox (pre-launch audit M3).
///
/// Writes go to a temp file and are RENAMED over the target (atomic on
/// iOS/Android), so a kill mid-write can never leave truncated JSON; a
/// corrupt file (from a pre-fix build) is set aside as `.corrupt-<ts>` for
/// diagnostics and the queue starts empty instead of breaking bootstrap.
/// Callers serialise `save` (see `SyncService._persistQueue`) — two
/// interleaved writers of one file are the other way to corrupt it.
class OfflineSyncQueue {
  const OfflineSyncQueue();

  Future<File> _file() async {
    final dir = await getAppStorageDirectory();
    return File('${dir.path}/offline_sync_queue.json');
  }

  Future<List<OfflineOperation>> load() async {
    final file = await _file();
    if (!await file.exists()) return const [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return const [];
    try {
      final arr = jsonDecode(raw) as List<dynamic>;
      return arr
          .map(
            (it) =>
                OfflineOperation.fromMap(Map<String, dynamic>.from(it as Map)),
          )
          .toList();
    } catch (e) {
      debugPrint('OfflineSyncQueue: corrupt queue file set aside: $e');
      try {
        await file.rename(
          '${file.path}.corrupt-${DateTime.now().millisecondsSinceEpoch}',
        );
      } catch (_) {
        // Best effort; an unreadable file is skipped either way.
      }
      return const [];
    }
  }

  Future<void> save(List<OfflineOperation> operations) async {
    final file = await _file();
    final payload = operations.map((o) => o.toMap()).toList();
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(payload), flush: true);
    await tmp.rename(file.path);
  }
}
