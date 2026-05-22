import '../data/context_override_repository.dart';
import '../domain/models/context_override.dart';
import '../domain/models/post_override_review.dart';
import '../domain/models/user_attention_state.dart';

// ─── Preset duration type ─────────────────────────────────────────────────────

/// A single preset duration option shown in the quick-activate UI.
class OverridePreset {
  const OverridePreset({required this.label, this.duration});

  /// Display label (e.g. "30 min", "Until I end it").
  final String label;

  /// Duration to add to `now` for `overrideExpiresAt`.
  /// `null` means indefinite ("Until I end it").
  final Duration? duration;
}

/// Returns the list of preset duration options for a given [ContextOverride].
/// Pure function — no I/O.
List<OverridePreset> presetDurations(ContextOverride type) {
  switch (type) {
    case ContextOverride.meeting:
      return const [
        OverridePreset(label: '30 min', duration: Duration(minutes: 30)),
        OverridePreset(label: '1 hour', duration: Duration(hours: 1)),
        OverridePreset(label: '2 hours', duration: Duration(hours: 2)),
        OverridePreset(label: 'Until I end it'),
      ];

    case ContextOverride.focus:
      return const [
        OverridePreset(label: '45 min', duration: Duration(minutes: 45)),
        OverridePreset(label: '90 min', duration: Duration(minutes: 90)),
        OverridePreset(label: '2 hours', duration: Duration(hours: 2)),
        OverridePreset(label: 'Custom'), // duration resolved by UI slider
        OverridePreset(label: 'Until I end it'),
      ];

    case ContextOverride.sleep:
      // Sleep is typically schedule-driven; manual start always indefinite.
      return const [
        OverridePreset(label: 'Until I end it'),
      ];

    case ContextOverride.vacation:
      return const [
        OverridePreset(label: 'Until I end it'),
      ];

    case ContextOverride.doNotDisturb:
      return const [
        OverridePreset(label: '30 min', duration: Duration(minutes: 30)),
        OverridePreset(label: '1 hour', duration: Duration(hours: 1)),
        OverridePreset(label: '2 hours', duration: Duration(hours: 2)),
        OverridePreset(label: 'Until I end it'),
      ];

    case ContextOverride.none:
      return const [];
  }
}

// ─── Service ──────────────────────────────────────────────────────────────────

/// Orchestrates override lifecycle: activate, end, expire, sleep window config.
///
/// All mutations go through this service — nothing writes to
/// [ContextOverrideRepository] directly except this class.
class ContextOverrideService {
  ContextOverrideService({
    required ContextOverrideRepository repository,
    DateTime Function()? now,
  }) : _repository = repository,
       _now = now ?? DateTime.now;

  final ContextOverrideRepository _repository;
  final DateTime Function() _now;

  // ─── Activate ─────────────────────────────────────────────────────────────

  /// Activate an override. [expiresAt] is null for indefinite overrides.
  Future<void> activateOverride({
    required ContextOverride type,
    DateTime? expiresAt,
  }) async {
    assert(type != ContextOverride.none, 'Cannot activate ContextOverride.none');
    final current = await _currentOrEmpty();
    final nowMs = _now().millisecondsSinceEpoch;
    final updated = current.copyWith(
      activeOverride: type,
      overrideExpiresAt: expiresAt,
      lastOverrideActivatedAt: nowMs,
      lastAttentionResetAt: null, // reset — new override starting
      updatedAtMs: nowMs,
    );
    await _repository.upsertAttentionState(updated);
  }

  // ─── End manually ─────────────────────────────────────────────────────────

  /// End the current override immediately (user tapped "End now").
  ///
  /// Records [lastAttentionResetAt], clears [activeOverride], and returns a
  /// [PostOverrideReview]. In Phase B, [suppressedItems] is always empty —
  /// Phase C will populate it from the real suppressed intent queue.
  Future<PostOverrideReview> endOverride() async {
    final current = await _currentOrEmpty();
    if (!current.hasActiveOverride) {
      // Nothing to end — return a no-op review.
      return PostOverrideReview(
        overrideType: ContextOverride.none,
        activeFromMs: 0,
        activeUntilMs: _now().millisecondsSinceEpoch,
        suppressedItems: const [],
      );
    }
    return await _doEnd(current);
  }

  // ─── Auto-expiry check ────────────────────────────────────────────────────

  /// Check whether the current override has expired. If so, end it and return
  /// the [PostOverrideReview]. Returns null if nothing expired.
  ///
  /// Must be called:
  ///   - On app foreground resume
  ///   - Every 5 minutes while an override is active
  Future<PostOverrideReview?> checkAndExpireIfNeeded([DateTime? nowOverride]) async {
    final now = nowOverride ?? _now();
    final current = await _currentOrEmpty();
    if (!current.hasActiveOverride) return null;
    if (!current.isExpired(now)) return null;
    return await _doEnd(current);
  }

  // ─── Sleep window config ──────────────────────────────────────────────────

  Future<void> setSleepWindow({
    required String start,
    required String end,
  }) async {
    final current = await _currentOrEmpty();
    final updated = current.copyWith(
      sleepWindowStart: start,
      sleepWindowEnd: end,
      updatedAtMs: _now().millisecondsSinceEpoch,
    );
    await _repository.upsertAttentionState(updated);
  }

  Future<void> clearSleepWindow() async {
    final current = await _currentOrEmpty();
    final updated = current.copyWith(
      sleepWindowStart: null,
      sleepWindowEnd: null,
      updatedAtMs: _now().millisecondsSinceEpoch,
    );
    await _repository.upsertAttentionState(updated);
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  Future<UserAttentionState> _currentOrEmpty() async {
    return await _repository.getAttentionState() ?? UserAttentionState.empty();
  }

  Future<PostOverrideReview> _doEnd(UserAttentionState current) async {
    final nowMs = _now().millisecondsSinceEpoch;
    final review = PostOverrideReview(
      overrideType: current.activeOverride,
      activeFromMs: current.lastOverrideActivatedAt ?? nowMs,
      activeUntilMs: nowMs,
      suppressedItems: const [], // Phase C will populate this
    );
    final updated = current.copyWith(
      activeOverride: ContextOverride.none,
      overrideExpiresAt: null,
      lastAttentionResetAt: nowMs,
      updatedAtMs: nowMs,
    );
    await _repository.upsertAttentionState(updated);
    return review;
  }
}
