import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/app/notification_intention_actions.dart';
import 'package:sidepal/features/intentions/domain/models/intention.dart';

/// P1-05 — the minimal learning loop: `nudged` is a live status, and
/// "Wrong time" strikes retire reflected time hints.

Intention _intention(IntentionStatus status, {bool active = true}) =>
    Intention(
      id: 'intention_1',
      title: 'Call cousin Sara',
      rawUtterance: 'call my cousin',
      windowStartMs: 1000,
      windowEndMs: 100000,
      estimatedMinutes: 15,
      status: status,
      active: active,
      createdAtMs: 1,
      updatedAtMs: 1,
    );

void main() {
  group('Intention.isLive / isPlannable', () {
    test('nudged behaves exactly like open on live surfaces', () {
      expect(_intention(IntentionStatus.open).isLive, isTrue);
      expect(_intention(IntentionStatus.nudged).isLive, isTrue);
      expect(_intention(IntentionStatus.open).isPlannable, isTrue);
      expect(_intention(IntentionStatus.nudged).isPlannable, isTrue);
    });

    test('terminal and dormant statuses stay non-plannable', () {
      for (final status in [
        IntentionStatus.dormant,
        IntentionStatus.done,
        IntentionStatus.dismissed,
        IntentionStatus.expired,
      ]) {
        expect(_intention(status).isPlannable, isFalse, reason: status.name);
      }
      expect(
        _intention(IntentionStatus.nudged, active: false).isPlannable,
        isFalse,
        reason: 'tombstoned',
      );
    });
  });

  group('applyWrongTimeStrike', () {
    test('first strike only counts — the hint survives', () {
      final result = applyWrongTimeStrike({
        'preferredTimeBlock': 'evening',
        'basedOn': ['memfact_1'],
        'hintSource': 'reflect',
      });
      expect(result.hints['wrongTimeStrikes'], 1);
      expect(result.hints['preferredTimeBlock'], 'evening');
      expect(result.contradictedFactIds, isEmpty);
    });

    test('second strike retires the hint and contradicts its sources', () {
      final result = applyWrongTimeStrike({
        'wrongTimeStrikes': 1,
        'preferredTimeBlock': 'evening',
        'basedOn': ['memfact_1', 'person_1'],
        'hintSource': 'reflect',
      });
      expect(result.hints['wrongTimeStrikes'], 2);
      expect(result.hints.containsKey('preferredTimeBlock'), isFalse);
      expect(result.contradictedFactIds, ['memfact_1', 'person_1']);
      // Other keys survive — merge, never replace.
      expect(result.hints['hintSource'], 'reflect');
    });

    test('strikes without a hint never contradict anything', () {
      final result = applyWrongTimeStrike({'wrongTimeStrikes': 5});
      expect(result.hints['wrongTimeStrikes'], 6);
      expect(result.contradictedFactIds, isEmpty);
    });

    test('does not mutate the input map', () {
      final input = {'preferredTimeBlock': 'morning'};
      applyWrongTimeStrike(input);
      expect(input, {'preferredTimeBlock': 'morning'});
    });
  });
}
