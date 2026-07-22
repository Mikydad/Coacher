import 'package:sidepal/features/context_override/domain/models/interruption_level.dart';
import 'package:sidepal/features/reminders/application/interruption_level_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('InterruptionLevelResolver', () {
    // ── Emergency bypass always returns critical ───────────────────────────

    test('emergency bypass → critical regardless of mode and escalation', () {
      for (final mode in ['flexible', 'disciplined', 'extreme']) {
        for (final level in [0, 1, 2, 5]) {
          expect(
            InterruptionLevelResolver.resolve(
              enforcementMode: mode,
              escalationLevel: level,
              emergencyBypass: true,
            ),
            InterruptionLevel.critical,
            reason: 'mode=$mode escalation=$level with emergencyBypass',
          );
        }
      }
    });

    // ── Flexible mode ─────────────────────────────────────────────────────

    test('flexible escalation=0 → low', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'flexible',
          escalationLevel: 0,
          emergencyBypass: false,
        ),
        InterruptionLevel.low,
      );
    });

    test('flexible escalation>=1 → medium', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'flexible',
          escalationLevel: 1,
          emergencyBypass: false,
        ),
        InterruptionLevel.medium,
      );
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'flexible',
          escalationLevel: 3,
          emergencyBypass: false,
        ),
        InterruptionLevel.medium,
      );
    });

    // ── Disciplined mode ──────────────────────────────────────────────────

    test('disciplined escalation=0 → medium', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'disciplined',
          escalationLevel: 0,
          emergencyBypass: false,
        ),
        InterruptionLevel.medium,
      );
    });

    test('disciplined escalation=1 → medium', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'disciplined',
          escalationLevel: 1,
          emergencyBypass: false,
        ),
        InterruptionLevel.medium,
      );
    });

    test('disciplined escalation=2 → high', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'disciplined',
          escalationLevel: 2,
          emergencyBypass: false,
        ),
        InterruptionLevel.high,
      );
    });

    test('disciplined escalation=5 → high', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'disciplined',
          escalationLevel: 5,
          emergencyBypass: false,
        ),
        InterruptionLevel.high,
      );
    });

    // ── Extreme mode ──────────────────────────────────────────────────────

    test('extreme escalation=0 → high', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'extreme',
          escalationLevel: 0,
          emergencyBypass: false,
        ),
        InterruptionLevel.high,
      );
    });

    test('extreme escalation=1 → high', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'extreme',
          escalationLevel: 1,
          emergencyBypass: false,
        ),
        InterruptionLevel.high,
      );
    });

    test('extreme escalation=2 → critical', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'extreme',
          escalationLevel: 2,
          emergencyBypass: false,
        ),
        InterruptionLevel.critical,
      );
    });

    test('extreme escalation=10 → critical', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'extreme',
          escalationLevel: 10,
          emergencyBypass: false,
        ),
        InterruptionLevel.critical,
      );
    });

    // ── Unknown mode defaults to flexible ─────────────────────────────────

    test('unknown mode treated as flexible', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'unknown_mode',
          escalationLevel: 0,
          emergencyBypass: false,
        ),
        InterruptionLevel.low,
      );
    });

    test('empty mode treated as flexible', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: '',
          escalationLevel: 0,
          emergencyBypass: false,
        ),
        InterruptionLevel.low,
      );
    });

    // ── Case insensitive ──────────────────────────────────────────────────

    test('mode string is case-insensitive', () {
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'EXTREME',
          escalationLevel: 2,
          emergencyBypass: false,
        ),
        InterruptionLevel.critical,
      );
      expect(
        InterruptionLevelResolver.resolve(
          enforcementMode: 'Disciplined',
          escalationLevel: 2,
          emergencyBypass: false,
        ),
        InterruptionLevel.high,
      );
    });
  });
}
