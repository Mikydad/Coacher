import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PatternDetectionRunScope { entity, batch }

class PatternDetectionDebugEvent {
  const PatternDetectionDebugEvent({
    required this.scope,
    required this.dateKey,
    required this.startedAtMs,
    required this.elapsedMs,
    required this.entitiesProcessed,
    required this.patternsEmitted,
    required this.ruleErrors,
    required this.skippedUnchanged,
    required this.success,
    this.entityId,
    this.note,
  });

  final PatternDetectionRunScope scope;
  final String dateKey;
  final int startedAtMs;
  final int elapsedMs;
  final int entitiesProcessed;
  final int patternsEmitted;
  final int ruleErrors;
  final bool skippedUnchanged;
  final bool success;
  final String? entityId;
  final String? note;
}

class PatternDetectionDebugStore {
  PatternDetectionDebugStore({this.maxEvents = 100});

  final int maxEvents;
  final List<PatternDetectionDebugEvent> _events =
      <PatternDetectionDebugEvent>[];
  final StreamController<List<PatternDetectionDebugEvent>> _controller =
      StreamController<List<PatternDetectionDebugEvent>>.broadcast();

  List<PatternDetectionDebugEvent> get events =>
      List<PatternDetectionDebugEvent>.unmodifiable(_events);

  Stream<List<PatternDetectionDebugEvent>> watch() async* {
    yield events;
    yield* _controller.stream;
  }

  void record(PatternDetectionDebugEvent event) {
    _events.add(event);
    if (_events.length > maxEvents) {
      _events.removeAt(0);
    }
    if (!_controller.isClosed) {
      _controller.add(events);
    }
  }

  Future<void> dispose() async {
    await _controller.close();
  }
}

final patternDetectionDebugStoreProvider = Provider<PatternDetectionDebugStore>(
  (ref) {
    final store = PatternDetectionDebugStore();
    ref.onDispose(() => store.dispose());
    return store;
  },
);

final patternDetectionDebugEventsProvider =
    StreamProvider<List<PatternDetectionDebugEvent>>((ref) {
      return ref.read(patternDetectionDebugStoreProvider).watch();
    });
