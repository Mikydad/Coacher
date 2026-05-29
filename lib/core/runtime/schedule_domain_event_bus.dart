import 'dart:async';

import 'package:flutter/foundation.dart';

import 'schedule_domain_event.dart';

/// Framework-independent broadcast event bus for schedule domain events.
///
/// [ScheduleMutationCoordinator] emits events here after every successful
/// mutation. Riverpod providers and services subscribe to [stream] rather
/// than being invalidated or called directly by each mutation site.
///
/// Design rules:
/// - This class has NO Riverpod or Flutter dependency — it is a plain-Dart
///   singleton usable from services, background workers, and unit tests.
/// - Subscriber errors are caught and logged; they never propagate to the
///   emitter or crash other subscribers.
/// - Call [dispose] in tests to release the stream controller.
class ScheduleDomainEventBus {
  ScheduleDomainEventBus._();

  static final ScheduleDomainEventBus instance = ScheduleDomainEventBus._();

  StreamController<ScheduleDomainEvent> _controller =
      StreamController<ScheduleDomainEvent>.broadcast();

  /// The stream of all domain events. Subscribe with a
  /// `ref.onDispose`-guarded listener to avoid memory leaks in Riverpod.
  Stream<ScheduleDomainEvent> get stream => _controller.stream;

  /// Subscribe to all domain events.
  ///
  /// Errors thrown inside [onEvent] are caught and logged — they do not
  /// propagate back to the bus or affect other subscribers. The returned
  /// [StreamSubscription] should be cancelled in a `ref.onDispose` guard
  /// (or equivalent) to avoid memory leaks.
  StreamSubscription<ScheduleDomainEvent> listen(
    void Function(ScheduleDomainEvent event) onEvent,
  ) {
    return _controller.stream.listen(
      (event) {
        try {
          onEvent(event);
        } catch (e, st) {
          debugPrint('[ScheduleDomainEventBus] subscriber error: $e\n$st');
        }
      },
    );
  }

  /// Emit [event] to all current subscribers.
  ///
  /// Errors inside individual subscribers are caught by [listen]; this
  /// method itself does not throw.
  void emit(ScheduleDomainEvent event) {
    if (_controller.isClosed) return;
    try {
      _controller.add(event);
    } catch (e, st) {
      debugPrint('[ScheduleDomainEventBus] emit error: $e\n$st');
    }
  }

  /// Close the underlying stream. Call in tests to clean up.
  /// A new controller is created so the singleton can be reused.
  void dispose() {
    _controller.close();
    _controller = StreamController<ScheduleDomainEvent>.broadcast();
  }

  /// Reset to a fresh state — convenience wrapper for tests.
  @visibleForTesting
  void resetForTests() => dispose();
}
