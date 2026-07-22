import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';
import 'package:sidepal/features/profile/application/profile_preference_service.dart';
import 'package:sidepal/features/profile/data/profile_preference_repository.dart';
import 'package:sidepal/features/profile/domain/models/user_profile_preference.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── In-memory stub repo ──────────────────────────────────────────────────────

class _FakeRepo implements ProfilePreferenceRepository {
  UserProfilePreference? _stored;

  @override
  Future<UserProfilePreference?> getPreference() async => _stored;

  @override
  Future<void> upsertPreference(UserProfilePreference pref) async {
    _stored = pref;
  }

  @override
  Stream<UserProfilePreference?> watchPreference() => Stream.value(_stored);
}

// ─── Helper ───────────────────────────────────────────────────────────────────

ProfilePreferenceService _makeService(
  _FakeRepo repo, {
  DateTime? fixedNow,
}) {
  final nowFn = fixedNow != null ? () => fixedNow : DateTime.now;
  return ProfilePreferenceService(repository: repo, now: nowFn);
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  final fixedNow = DateTime(2026, 5, 18, 12);
  final fixedMs = fixedNow.millisecondsSinceEpoch;

  // ─── setDisplayName ─────────────────────────────────────────────────────

  group('setDisplayName', () {
    test('persists the name', () async {
      final repo = _FakeRepo();
      await _makeService(repo, fixedNow: fixedNow).setDisplayName('Alice');
      expect(repo._stored?.displayName, 'Alice');
    });

    test('trims surrounding whitespace', () async {
      final repo = _FakeRepo();
      await _makeService(repo, fixedNow: fixedNow).setDisplayName('  Bob  ');
      expect(repo._stored?.displayName, 'Bob');
    });

    test('sets updatedAtMs to now', () async {
      final repo = _FakeRepo();
      await _makeService(repo, fixedNow: fixedNow).setDisplayName('Carol');
      expect(repo._stored?.updatedAtMs, fixedMs);
    });

    test('second call overwrites the first', () async {
      final repo = _FakeRepo();
      final svc = _makeService(repo, fixedNow: fixedNow);
      await svc.setDisplayName('First');
      await svc.setDisplayName('Second');
      expect(repo._stored?.displayName, 'Second');
    });

    test('preserves defaultEnforcementMode when only name changes', () async {
      final repo = _FakeRepo();
      repo._stored = UserProfilePreference(
        id: kUserProfilePreferenceId,
        displayName: 'Old',
        defaultEnforcementMode: EnforcementMode.extreme,
        updatedAtMs: 0,
      );
      await _makeService(repo, fixedNow: fixedNow).setDisplayName('New');
      expect(repo._stored?.defaultEnforcementMode, EnforcementMode.extreme);
    });

    test('uses kUserProfilePreferenceId for fresh install', () async {
      final repo = _FakeRepo(); // empty
      await _makeService(repo, fixedNow: fixedNow).setDisplayName('Dave');
      expect(repo._stored?.id, kUserProfilePreferenceId);
    });
  });

  // ─── setDefaultEnforcementMode ──────────────────────────────────────────

  group('setDefaultEnforcementMode', () {
    test('persists flexible mode', () async {
      final repo = _FakeRepo();
      await _makeService(repo, fixedNow: fixedNow)
          .setDefaultEnforcementMode(EnforcementMode.flexible);
      expect(repo._stored?.defaultEnforcementMode, EnforcementMode.flexible);
    });

    test('persists extreme mode', () async {
      final repo = _FakeRepo();
      await _makeService(repo, fixedNow: fixedNow)
          .setDefaultEnforcementMode(EnforcementMode.extreme);
      expect(repo._stored?.defaultEnforcementMode, EnforcementMode.extreme);
    });

    test('sets updatedAtMs to now', () async {
      final repo = _FakeRepo();
      await _makeService(repo, fixedNow: fixedNow)
          .setDefaultEnforcementMode(EnforcementMode.disciplined);
      expect(repo._stored?.updatedAtMs, fixedMs);
    });

    test('preserves displayName when only mode changes', () async {
      final repo = _FakeRepo();
      repo._stored = UserProfilePreference(
        id: kUserProfilePreferenceId,
        displayName: 'Miko',
        defaultEnforcementMode: EnforcementMode.disciplined,
        updatedAtMs: 0,
      );
      await _makeService(repo, fixedNow: fixedNow)
          .setDefaultEnforcementMode(EnforcementMode.flexible);
      expect(repo._stored?.displayName, 'Miko');
    });
  });

  // ─── getPreference — default fallback ───────────────────────────────────

  group('getPreference', () {
    test('returns stored preference when present', () async {
      final repo = _FakeRepo();
      repo._stored = UserProfilePreference(
        id: kUserProfilePreferenceId,
        displayName: 'Eve',
        defaultEnforcementMode: EnforcementMode.extreme,
        updatedAtMs: fixedMs,
      );
      final pref = await _makeService(repo).getPreference();
      expect(pref.displayName, 'Eve');
      expect(pref.defaultEnforcementMode, EnforcementMode.extreme);
    });

    test('returns in-memory default when nothing stored', () async {
      final repo = _FakeRepo(); // empty
      final pref = await _makeService(repo).getPreference();
      expect(pref.displayName, '');
      expect(pref.defaultEnforcementMode, EnforcementMode.disciplined);
      expect(pref.id, kUserProfilePreferenceId);
    });
  });
}
