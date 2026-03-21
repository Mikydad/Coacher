import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'offline_operation.dart';

class OfflineSyncQueue {
  const OfflineSyncQueue();

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/offline_sync_queue.json');
  }

  Future<List<OfflineOperation>> load() async {
    final file = await _file();
    if (!await file.exists()) return const [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return const [];
    final arr = jsonDecode(raw) as List<dynamic>;
    return arr
        .map((it) => OfflineOperation.fromMap(Map<String, dynamic>.from(it as Map)))
        .toList();
  }

  Future<void> save(List<OfflineOperation> operations) async {
    final file = await _file();
    final payload = operations.map((o) => o.toMap()).toList();
    await file.writeAsString(jsonEncode(payload), flush: true);
  }
}
