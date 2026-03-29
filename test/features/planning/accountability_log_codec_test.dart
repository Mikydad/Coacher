import 'dart:convert';

import 'package:coach_for_life/features/planning/application/accountability_log_codec.dart';
import 'package:coach_for_life/features/planning/domain/models/accountability_log.dart';
import 'package:coach_for_life/features/planning/domain/models/flow_transition_event.dart';
import 'package:flutter_test/flutter_test.dart';

AccountabilityLog _log({
  required String id,
  required int createdAtMs,
}) {
  return AccountabilityLog(
    id: id,
    taskId: 'task-$id',
    action: AccountabilityAction.defer,
    reasonCategory: OverrideReasonCategory.energyFocusMismatch,
    reasonNote: 'I needed a short reset before continuing.',
    modeRefId: 'disciplined',
    taskPriority: 2,
    createdAtMs: createdAtMs,
  );
}

void main() {
  test('export JSON contains expected fields', () {
    final raw = AccountabilityLogCodec.toJson([_log(id: 'a1', createdAtMs: 100)]);
    final data = jsonDecode(raw) as List<dynamic>;
    expect(data, hasLength(1));
    final row = Map<String, dynamic>.from(data.first as Map);
    expect(row['id'], 'a1');
    expect(row['taskPriority'], 2);
  });

  test('export CSV contains header and one row', () {
    final csv = AccountabilityLogCodec.toCsv([_log(id: 'a1', createdAtMs: 100)]);
    final lines = csv.split('\n');
    expect(lines.first, contains('id,taskId,action'));
    expect(lines.length, 2);
  });

  test('idsOlderThan returns ids in cutoff window', () {
    final ids = AccountabilityLogCodec.idsOlderThan(
      logs: [
        _log(id: 'old', createdAtMs: 50),
        _log(id: 'new', createdAtMs: 150),
      ],
      cutOffMs: 100,
    );
    expect(ids, ['old']);
  });
}
