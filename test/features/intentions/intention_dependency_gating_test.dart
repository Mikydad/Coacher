// P1-07 — dependency gating.
//
// "Before visiting parents" / anchored-on-another-promise intentions are
// captured and radar-visible but must stay SILENT (no nudge ladder, no
// geofence fire) until the dependency resolves. These tests pin the model
// semantics the nudge sync and geofence arming filter on, plus the
// copyWith(clearDependency:) primitive the auto-promotion hook in
// IntentionsRepository.updateStatus(done) relies on.

import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/intentions/domain/models/intention.dart';

Intention _intention({
  String? dependsOnText,
  String? anchorEntityId,
  IntentionStatus status = IntentionStatus.open,
  bool active = true,
}) {
  return Intention(
    id: 'intention_1',
    title: 'Send the photos',
    rawUtterance: 'I promised to send the photos after I call mom',
    windowStartMs: 0,
    windowEndMs: 3_600_000,
    estimatedMinutes: 10,
    dependsOnText: dependsOnText,
    anchorEntityId: anchorEntityId,
    status: status,
    active: active,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

void main() {
  group('hasUnresolvedDependency', () {
    test('false when both fields are null or blank', () {
      expect(_intention().hasUnresolvedDependency, isFalse);
      expect(
        _intention(dependsOnText: '  ', anchorEntityId: '')
            .hasUnresolvedDependency,
        isFalse,
      );
    });

    test('true on free-text dependency', () {
      expect(
        _intention(dependsOnText: 'before visiting parents')
            .hasUnresolvedDependency,
        isTrue,
      );
    });

    test('true on anchor link', () {
      expect(
        _intention(anchorEntityId: 'intention_anchor')
            .hasUnresolvedDependency,
        isTrue,
      );
    });
  });

  group('isNudgeable', () {
    test('live + no dependency → nudgeable', () {
      expect(_intention().isNudgeable, isTrue);
      expect(_intention(status: IntentionStatus.nudged).isNudgeable, isTrue);
    });

    test('dependency-gated live intention is plannable but NOT nudgeable', () {
      final gated = _intention(anchorEntityId: 'intention_anchor');
      expect(gated.isPlannable, isTrue, reason: 'stays radar-visible');
      expect(gated.isNudgeable, isFalse, reason: 'stays silent');
    });

    test('dormant/terminal intentions are never nudgeable', () {
      expect(_intention(status: IntentionStatus.dormant).isNudgeable, isFalse);
      expect(_intention(status: IntentionStatus.done).isNudgeable, isFalse);
      expect(_intention(active: false).isNudgeable, isFalse);
    });
  });

  group('copyWith(clearDependency:)', () {
    test('clears both dependency fields (auto-promotion primitive)', () {
      final gated = _intention(
        dependsOnText: 'after I call mom',
        anchorEntityId: 'intention_anchor',
      );
      final promoted = gated.copyWith(clearDependency: true, updatedAtMs: 99);
      expect(promoted.dependsOnText, isNull);
      expect(promoted.anchorEntityId, isNull);
      expect(promoted.isNudgeable, isTrue);
      expect(promoted.updatedAtMs, 99);
    });

    test('plain copyWith preserves dependency fields', () {
      final gated = _intention(anchorEntityId: 'intention_anchor');
      final copy = gated.copyWith(title: 'Renamed');
      expect(copy.anchorEntityId, 'intention_anchor');
      expect(copy.hasUnresolvedDependency, isTrue);
    });
  });
}
