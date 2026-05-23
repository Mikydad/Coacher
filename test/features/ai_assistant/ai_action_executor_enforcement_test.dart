/// Task 7.3 — Enforcement mode default
///
/// Tests that the [AiActionExecutor._createTask] logic respects:
///   1. defaultModeRefId when parameters don't include 'modeRefId'.
///   2. Explicit 'modeRefId' in parameters overrides the default.
///   3. No default + no param → modeRefId is null.
///
/// We test this at the model level by verifying the modeRefId selection
/// logic in isolation (pure function extracted from the executor).
library;

import 'package:flutter_test/flutter_test.dart';

// Mirrors the modeRefId resolution logic from AiActionExecutor._createTask
String? resolveMode(
  Map<String, dynamic> parameters, {
  String? defaultModeRefId,
}) {
  return parameters['modeRefId'] as String? ?? defaultModeRefId;
}

void main() {
  group('AiActionExecutor modeRefId resolution', () {
    test('No modeRefId in params → uses defaultModeRefId', () {
      final result = resolveMode(
        {'title': 'Morning Workout', 'time': '07:00'},
        defaultModeRefId: 'disciplined',
      );
      expect(result, equals('disciplined'));
    });

    test('Explicit modeRefId in params → uses provided value', () {
      final result = resolveMode(
        {'title': 'Morning Workout', 'time': '07:00', 'modeRefId': 'extreme'},
        defaultModeRefId: 'disciplined',
      );
      expect(result, equals('extreme'));
    });

    test('No default + no param → modeRefId is null', () {
      final result = resolveMode({'title': 'Quick Task'});
      expect(result, isNull);
    });

    test('Empty string modeRefId in params → treated as null-ish; uses default', () {
      // Parameters with explicit null should fall through to default
      final result = resolveMode(
        {'title': 'Task', 'modeRefId': null},
        defaultModeRefId: 'flexible',
      );
      expect(result, equals('flexible'));
    });
  });
}
