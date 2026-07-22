import 'package:sidepal/features/coaching/application/default_mode_resolver.dart';
import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DefaultModeResolver matrix (priority only)', () {
    test('flexible profile: low/medium stay flexible, high → disciplined', () {
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.flexible,
          priority: 1,
        ),
        'flexible',
      );
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.flexible,
          priority: 3,
        ),
        'flexible',
      );
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.flexible,
          priority: 5,
        ),
        'disciplined',
      );
    });

    test('disciplined profile: low → flexible, medium/high → disciplined', () {
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.disciplined,
          priority: 2,
        ),
        'flexible',
      );
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.disciplined,
          priority: 3,
        ),
        'disciplined',
      );
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.disciplined,
          priority: 4,
        ),
        'disciplined',
      );
    });

    test('extreme profile: only high importance gets extreme', () {
      // Drinking water (low priority) must not be extreme.
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.extreme,
          priority: 1,
        ),
        'disciplined',
      );
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.extreme,
          priority: 3,
        ),
        'disciplined',
      );
      // Submitting the project (high priority) escalates hard.
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.extreme,
          priority: 5,
        ),
        'extreme',
      );
    });
  });

  group('block urgency as the second importance signal', () {
    test('urgent block (≥80) lifts a default-priority task to high band', () {
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.extreme,
          priority: 3,
          blockUrgencyScore: 85,
        ),
        'extreme',
      );
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.flexible,
          priority: 3,
          blockUrgencyScore: 90,
        ),
        'disciplined',
      );
    });

    test('casual block never downgrades an explicitly important task', () {
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.extreme,
          priority: 5,
          blockUrgencyScore: 10,
        ),
        'extreme',
      );
    });

    test('low urgency + low priority resolves to the low band', () {
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.disciplined,
          priority: 2,
          blockUrgencyScore: 20,
        ),
        'flexible',
      );
    });

    test('mid urgency lifts a low-priority task to medium band', () {
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.disciplined,
          priority: 1,
          blockUrgencyScore: 60,
        ),
        'disciplined',
      );
    });
  });

  group('input clamping', () {
    test('out-of-range priority and urgency are clamped, not crashed', () {
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.extreme,
          priority: 99,
        ),
        'extreme',
      );
      expect(
        DefaultModeResolver.resolveModeRefId(
          profileDefault: EnforcementMode.flexible,
          priority: -1,
          blockUrgencyScore: 500,
        ),
        'disciplined', // clamped priority 1 (low) + clamped urgency 100 (high)
      );
    });
  });
}
