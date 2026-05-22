import 'package:coach_for_life/features/context_override/application/context_override_service.dart';
import 'package:coach_for_life/features/context_override/data/context_override_repository.dart';
import 'package:coach_for_life/features/context_override/domain/models/context_override.dart';
import 'package:coach_for_life/features/context_override/domain/models/user_attention_state.dart';
import 'package:flutter_test/flutter_test.dart';

// ─── Fake repository ──────────────────────────────────────────────────────────

class _FakeContextOverrideRepository implements ContextOverrideRepository {
  UserAttentionState? _stored;

  @override
  Future<UserAttentionState?> getAttentionState() async => _stored;

  @override
  Future<void> upsertAttentionState(UserAttentionState state) async {
    _stored = state;
  }

  @override
  Stream<UserAttentionState?> watchAttentionState() => Stream.value(_stored);
}

// ─── Tests ────────────────────────────────────────────────────────────────────

void main() {
  late _FakeContextOverrideRepository repo;
  late ContextOverrideService service;
  final fixedNow = DateTime(2026, 5, 18, 9, 0);

  setUp(() {
    repo = _FakeContextOverrideRepository();
    service = ContextOverrideService(
      repository: repo,
      now: () => fixedNow,
    );
  });

  group('activateOverride', () {
    test('persists override type and activatedAt', () async {
      await service.activateOverride(type: ContextOverride.meeting);
      final state = await repo.getAttentionState();
      expect(state?.activeOverride, ContextOverride.meeting);
      expect(state?.lastOverrideActivatedAt, fixedNow.millisecondsSinceEpoch);
      expect(state?.overrideExpiresAt, isNull);
    });

    test('persists expiresAt when duration provided', () async {
      final expires = fixedNow.add(const Duration(hours: 1));
      await service.activateOverride(
        type: ContextOverride.focus,
        expiresAt: expires,
      );
      final state = await repo.getAttentionState();
      expect(state?.activeOverride, ContextOverride.focus);
      expect(state?.overrideExpiresAt, expires);
    });

    test('resets lastAttentionResetAt on new activation', () async {
      // First, set a previous reset.
      repo._stored = UserAttentionState(
        id: kUserAttentionStateId,
        activeOverride: ContextOverride.none,
        manuallyMuted: false,
        updatedAtMs: 0,
        lastAttentionResetAt: 12345,
      );
      await service.activateOverride(type: ContextOverride.meeting);
      final state = await repo.getAttentionState();
      expect(state?.lastAttentionResetAt, isNull);
    });
  });

  group('endOverride', () {
    test('clears activeOverride and records lastAttentionResetAt', () async {
      await service.activateOverride(type: ContextOverride.vacation);
      await service.endOverride();
      final state = await repo.getAttentionState();
      expect(state?.activeOverride, ContextOverride.none);
      expect(state?.lastAttentionResetAt, fixedNow.millisecondsSinceEpoch);
    });

    test('returns a PostOverrideReview with correct overrideType', () async {
      await service.activateOverride(type: ContextOverride.sleep);
      final review = await service.endOverride();
      expect(review.overrideType, ContextOverride.sleep);
    });

    test('returns no-op review when no override is active', () async {
      final review = await service.endOverride();
      expect(review.overrideType, ContextOverride.none);
    });
  });

  group('checkAndExpireIfNeeded', () {
    test('returns null when no active override', () async {
      final review = await service.checkAndExpireIfNeeded();
      expect(review, isNull);
    });

    test('returns null before expiry time', () async {
      final future = fixedNow.add(const Duration(hours: 2));
      await service.activateOverride(
        type: ContextOverride.meeting,
        expiresAt: future,
      );
      // Check with fixedNow (before expiry).
      final review = await service.checkAndExpireIfNeeded(fixedNow);
      expect(review, isNull);
    });

    test('returns review after expiry time', () async {
      final past = fixedNow.subtract(const Duration(minutes: 5));
      await service.activateOverride(
        type: ContextOverride.meeting,
        expiresAt: past,
      );
      final review = await service.checkAndExpireIfNeeded(fixedNow);
      expect(review, isNotNull);
      expect(review!.overrideType, ContextOverride.meeting);
    });

    test('clears override state after expiry', () async {
      final past = fixedNow.subtract(const Duration(minutes: 1));
      await service.activateOverride(
        type: ContextOverride.focus,
        expiresAt: past,
      );
      await service.checkAndExpireIfNeeded(fixedNow);
      final state = await repo.getAttentionState();
      expect(state?.activeOverride, ContextOverride.none);
    });
  });

  group('sleep window config', () {
    test('setSleepWindow persists start and end', () async {
      await service.setSleepWindow(start: '23:00', end: '07:00');
      final state = await repo.getAttentionState();
      expect(state?.sleepWindowStart, '23:00');
      expect(state?.sleepWindowEnd, '07:00');
    });

    test('clearSleepWindow removes both fields', () async {
      await service.setSleepWindow(start: '23:00', end: '07:00');
      await service.clearSleepWindow();
      final state = await repo.getAttentionState();
      expect(state?.sleepWindowStart, isNull);
      expect(state?.sleepWindowEnd, isNull);
    });
  });
}
