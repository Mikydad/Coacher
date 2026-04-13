import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../domain/models/reminder_config.dart';

@Deprecated('Reminders are stored in Isar; this JSON file cache is no longer used by the app.')
class ReminderCacheStore {
  const ReminderCacheStore();

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/reminder_cache.json');
  }

  Future<void> save(List<ReminderConfig> reminders) async {
    final file = await _file();
    final payload = reminders.map((r) => r.toMap()).toList();
    await file.writeAsString(jsonEncode(payload), flush: true);
  }

  Future<List<ReminderConfig>> load() async {
    final file = await _file();
    if (!await file.exists()) return const [];
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return const [];
    final data = jsonDecode(raw) as List<dynamic>;
    return data.map((it) => ReminderConfig.fromMap(Map<String, dynamic>.from(it as Map))).toList();
  }
}
