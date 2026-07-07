import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/context_override_repository.dart';
import '../domain/models/context_override.dart';
import '../domain/models/post_override_review.dart';
import '../domain/models/user_attention_state.dart';
import 'context_override_service.dart';
import 'sleep_window_util.dart';

// ─── Repository ───────────────────────────────────────────────────────────────

final contextOverrideRepositoryProvider = Provider<ContextOverrideRepository>(
  (ref) => IsarContextOverrideRepository(),
);

// ─── Service ──────────────────────────────────────────────────────────────────

final contextOverrideServiceProvider = Provider<ContextOverrideService>((ref) {
  return ContextOverrideService(
    repository: ref.read(contextOverrideRepositoryProvider),
  );
});

// ─── Reactive attention state stream ─────────────────────────────────────────

/// Reactive stream of the current [UserAttentionState].
/// Emits every time the Isar record changes.
final attentionStateProvider = StreamProvider<UserAttentionState?>((ref) {
  final repo = ref.read(contextOverrideRepositoryProvider);
  return repo.watchAttentionState();
});

// ─── Effective override ───────────────────────────────────────────────────────

/// The actual override currently in effect, accounting for:
///   - Active manual override (not expired)
///   - Scheduled sleep window
///   - Expiry
///
/// This is the single provider that UI and services should read.
final effectiveOverrideProvider = Provider<ContextOverride>((ref) {
  final stateAsync = ref.watch(attentionStateProvider);
  final state = stateAsync.valueOrNull;
  if (state == null) return ContextOverride.none;
  return effectiveOverride(state, DateTime.now());
});

// ─── Pending recovery review ──────────────────────────────────────────────────

/// Holds the [PostOverrideReview] that should be shown on the home screen
/// after an override ends. Cleared when the user dismisses the card.
final pendingRecoveryReviewProvider = StateProvider<PostOverrideReview?>(
  (ref) => null,
);
