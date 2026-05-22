import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'context_override_providers.dart';
import '../presentation/post_override_review_card.dart';

/// Runs `checkAndExpireIfNeeded` every 5 minutes while any override is active,
/// and sets `pendingRecoveryReviewProvider` when an override expires.
///
/// Lifecycle:
///   - Call [start] once from the app's lifecycle observer.
///   - The timer auto-cancels when no override is active and re-arms when one
///     becomes active (driven by [attentionStateProvider]).
///   - Call [dispose] when the observer is disposed.
class ContextOverrideExpiryPoller {
  ContextOverrideExpiryPoller(this._ref);

  final Ref _ref;
  Timer? _timer;

  static const _interval = Duration(minutes: 5);

  /// Start the poller. Safe to call multiple times — only one timer runs.
  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(_interval, (_) => _tick());
  }

  void dispose() {
    _timer?.cancel();
    _timer = null;
  }

  /// Called on each tick AND on every app foreground resume.
  Future<void> checkNow() => _tick();

  Future<void> _tick() async {
    final service = _ref.read(contextOverrideServiceProvider);
    final review = await service.checkAndExpireIfNeeded();
    if (review != null) {
      _ref.read(pendingRecoveryReviewProvider.notifier).state = review;
      await persistPendingReviewFlag(true);
    }
  }
}

/// Riverpod provider so the poller can be read anywhere.
final contextOverrideExpiryPollerProvider =
    Provider<ContextOverrideExpiryPoller>((ref) {
  final poller = ContextOverrideExpiryPoller(ref);
  poller.start();
  ref.onDispose(poller.dispose);
  return poller;
});
