import 'package:coach_for_life/features/reminders/application/adaptive_reminder_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cadence matrix tightens from flexible to extreme on urgent blocks', () {
    final flexible = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: 'flexible',
      blockUrgencyScore: 90,
    );
    final extreme = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: 'extreme',
      blockUrgencyScore: 90,
    );
    expect(extreme.initialSnoozeMinutes, lessThan(flexible.initialSnoozeMinutes));
    expect(extreme.maxEscalationLevel, greaterThan(flexible.maxEscalationLevel));
  });

  test('escalation transitions shorten snooze over time', () {
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: 'disciplined',
      blockUrgencyScore: 85,
    );
    final step1 = AdaptiveReminderPolicy.nextStep(
      cadence: cadence,
      currentEscalationLevel: 0,
      emergencyBypass: false,
    );
    final step2 = AdaptiveReminderPolicy.nextStep(
      cadence: cadence,
      currentEscalationLevel: step1.nextEscalationLevel,
      emergencyBypass: false,
    );
    expect(step2.snoozeMinutes, lessThanOrEqualTo(step1.snoozeMinutes));
    expect(step2.requireAppOpenNudge, isTrue);
  });

  test('safety guardrail: emergency bypass disables hard gate', () {
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: 'extreme',
      blockUrgencyScore: 90,
    );
    final step = AdaptiveReminderPolicy.nextStep(
      cadence: cadence,
      currentEscalationLevel: 3,
      emergencyBypass: true,
    );
    expect(step.enableNonEssentialActionGate, isFalse);
  });

  test('disciplined auto-repeat schedule is staged then hourly', () {
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: 'disciplined',
      blockUrgencyScore: 50,
    );
    final offsets = AdaptiveReminderPolicy.autoRepeatOffsets(cadence);
    expect(offsets.take(3).toList(), [3, 6, 10]);
    expect(offsets.skip(3).take(3).toList(), [20, 30, 40]);
    expect(offsets[6], 100);
  });

  test('extreme auto-repeat schedule matches configured windows', () {
    final cadence = AdaptiveReminderPolicy.cadenceFor(
      modeRefId: 'extreme',
      blockUrgencyScore: 90,
    );
    final offsets = AdaptiveReminderPolicy.autoRepeatOffsets(cadence);
    expect(offsets.take(3).toList(), [3, 6, 10]);
    expect(offsets.skip(3).take(5).toList(), [16, 22, 28, 34, 40]);
    expect(offsets.skip(8).take(5).toList(), [100, 160, 220, 280, 340]);
  });
}
