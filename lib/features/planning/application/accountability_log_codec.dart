import 'dart:convert';

import '../domain/models/accountability_log.dart';
import '../domain/models/flow_transition_event.dart';

abstract final class AccountabilityLogCodec {
  static String toJson(List<AccountabilityLog> logs) {
    return jsonEncode(logs.map((l) => l.toMap()).toList());
  }

  static String toCsv(List<AccountabilityLog> logs) {
    final rows = <String>[
      'id,taskId,action,reasonCategory,reasonNote,modeRefId,taskPriority,createdAtMs',
    ];
    for (final l in logs) {
      rows.add(
        [
          _csv(l.id),
          _csv(l.taskId),
          _csv(l.action.storageValue),
          _csv(l.reasonCategory.storageValue),
          _csv(l.reasonNote),
          _csv(l.modeRefId ?? ''),
          _csv(l.taskPriority?.toString() ?? ''),
          _csv(l.createdAtMs.toString()),
        ].join(','),
      );
    }
    return rows.join('\n');
  }

  static List<String> idsOlderThan({
    required List<AccountabilityLog> logs,
    required int cutOffMs,
  }) {
    return logs.where((l) => l.createdAtMs <= cutOffMs).map((l) => l.id).toList();
  }

  static String _csv(String value) => '"${value.replaceAll('"', '""')}"';
}
