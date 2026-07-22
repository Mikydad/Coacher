import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';
import 'package:sidepal/features/profile/domain/models/user_profile_preference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const nowMs = 1_700_000_000_000;

  UserProfilePreference _pref({
    String displayName = 'Alice',
    EnforcementMode mode = EnforcementMode.disciplined,
  }) => UserProfilePreference(
    id: kUserProfilePreferenceId,
    displayName: displayName,
    defaultEnforcementMode: mode,
    updatedAtMs: nowMs,
  );

  // ─── Serialization round-trip ──────────────────────────────────────────────

  group('toMap / fromMap round-trip', () {
    test('preserves all fields across serialize → deserialize', () {
      final original = _pref(
        displayName: 'Bob',
        mode: EnforcementMode.extreme,
      );
      final restored = UserProfilePreference.fromMap(original.toMap());

      expect(restored.id, original.id);
      expect(restored.displayName, original.displayName);
      expect(restored.defaultEnforcementMode, original.defaultEnforcementMode);
      expect(restored.updatedAtMs, original.updatedAtMs);
      expect(restored.schemaVersion, original.schemaVersion);
    });

    test('round-trips flexible mode', () {
      final p = _pref(mode: EnforcementMode.flexible);
      expect(
        UserProfilePreference.fromMap(p.toMap()).defaultEnforcementMode,
        EnforcementMode.flexible,
      );
    });

    test('round-trips empty display name', () {
      final p = _pref(displayName: '');
      expect(
        UserProfilePreference.fromMap(p.toMap()).displayName,
        '',
      );
    });
  });

  // ─── fromMap defaults ──────────────────────────────────────────────────────

  group('fromMap defaults for missing keys', () {
    test('missing id → kUserProfilePreferenceId', () {
      final m = _pref().toMap()..remove('id');
      expect(
        UserProfilePreference.fromMap(m).id,
        kUserProfilePreferenceId,
      );
    });

    test('missing displayName → empty string', () {
      final m = _pref().toMap()..remove('displayName');
      expect(UserProfilePreference.fromMap(m).displayName, '');
    });

    test('missing defaultEnforcementMode → disciplined', () {
      final m = _pref().toMap()..remove('defaultEnforcementMode');
      expect(
        UserProfilePreference.fromMap(m).defaultEnforcementMode,
        EnforcementMode.disciplined,
      );
    });

    test('unknown enforcement mode string → disciplined', () {
      final m = _pref().toMap();
      m['defaultEnforcementMode'] = 'not_a_real_mode';
      expect(
        UserProfilePreference.fromMap(m).defaultEnforcementMode,
        EnforcementMode.disciplined,
      );
    });
  });

  // ─── copyWith ─────────────────────────────────────────────────────────────

  group('copyWith', () {
    test('overrides only displayName', () {
      final original = _pref(displayName: 'Alice', mode: EnforcementMode.flexible);
      final copy = original.copyWith(displayName: 'Bob');
      expect(copy.displayName, 'Bob');
      expect(copy.defaultEnforcementMode, EnforcementMode.flexible);
      expect(copy.id, original.id);
    });

    test('overrides only defaultEnforcementMode', () {
      final original = _pref(mode: EnforcementMode.disciplined);
      final copy = original.copyWith(
        defaultEnforcementMode: EnforcementMode.extreme,
      );
      expect(copy.defaultEnforcementMode, EnforcementMode.extreme);
      expect(copy.displayName, original.displayName);
    });

    test('id is immutable through copyWith', () {
      final original = _pref();
      final copy = original.copyWith(displayName: 'X');
      expect(copy.id, kUserProfilePreferenceId);
    });

    test('no-arg copyWith returns identical values', () {
      final original = _pref(displayName: 'Alice', mode: EnforcementMode.extreme);
      final copy = original.copyWith();
      expect(copy.displayName, original.displayName);
      expect(copy.defaultEnforcementMode, original.defaultEnforcementMode);
      expect(copy.updatedAtMs, original.updatedAtMs);
    });
  });

  // ─── validate ────────────────────────────────────────────────────────────

  group('validate', () {
    test('valid pref does not throw', () {
      expect(() => _pref().validate(), returnsNormally);
    });

    test('blank id throws', () {
      final p = UserProfilePreference(
        id: '',
        displayName: 'Alice',
        defaultEnforcementMode: EnforcementMode.disciplined,
        updatedAtMs: nowMs,
      );
      expect(() => p.validate(), throwsA(isA<ArgumentError>()));
    });
  });
}
