import 'package:coach_for_life/features/planning/domain/models/flow_transition_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('validateReasonNote accepts one or two sentences', () {
    expect(
      () => FlowTransitionEvent.validateReasonNote('Dependency blocked. Waiting for review.'),
      returnsNormally,
    );
    expect(
      () => FlowTransitionEvent.validateReasonNote('Urgent interruption happened'),
      returnsNormally,
    );
  });

  test('validateReasonNote rejects empty and 3+ sentences', () {
    expect(
      () => FlowTransitionEvent.validateReasonNote(''),
      throwsArgumentError,
    );
    expect(
      () => FlowTransitionEvent.validateReasonNote('One. Two. Three.'),
      throwsArgumentError,
    );
  });

  test('moveWithReason requires category and note', () {
    final valid = FlowTransitionEvent(
      id: 'e1',
      taskId: 't1',
      type: FlowTransitionType.moveWithReason,
      reasonCategory: OverrideReasonCategory.scheduleConflict,
      reasonNote: 'Conflicts with a fixed appointment.',
      createdAtMs: 1,
    );
    expect(() => valid.validate(), returnsNormally);

    final invalid = FlowTransitionEvent(
      id: 'e2',
      taskId: 't1',
      type: FlowTransitionType.moveWithReason,
      createdAtMs: 1,
    );
    expect(() => invalid.validate(), throwsArgumentError);
  });
}
