import 'package:coach_for_life/features/planning/domain/models/accountability_log.dart';
import 'package:coach_for_life/features/planning/domain/models/flow_transition_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromMap handles legacy docs with missing optional fields', () {
    final log = AccountabilityLog.fromMap({
      'id': 'a1',
      'taskId': 't1',
      'action': 'defer',
      'reasonCategory': 'scheduleConflict',
      'reasonNote': 'I had to move this because of an unavoidable overlap.',
      'createdAtMs': 10,
    });
    expect(log.id, 'a1');
    expect(log.modeRefId, isNull);
    expect(log.taskPriority, isNull);
    expect(log.reasonCategory, OverrideReasonCategory.scheduleConflict);
  });
}
