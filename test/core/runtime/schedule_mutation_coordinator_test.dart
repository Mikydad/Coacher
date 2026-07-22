import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sidepal/core/runtime/mutation_request.dart';
import 'package:sidepal/core/runtime/schedule_domain_event.dart';
import 'package:sidepal/core/runtime/schedule_domain_event_bus.dart';
import 'package:sidepal/core/runtime/schedule_mutation_coordinator.dart';
import 'package:sidepal/core/runtime/unified_recompute_graph.dart';

void main() {
  final coordinator = ScheduleMutationCoordinator.instance;
  final graph = UnifiedRecomputeGraph.instance;
  final bus = ScheduleDomainEventBus.instance;

  setUp(() {
    graph.debugDurationOverride = Duration.zero;
  });

  tearDown(() {
    coordinator.resetForTests();
    bus.resetForTests();
  });

  group('ScheduleMutationCoordinator validation', () {
    test('returns failed result when container not attached', () async {
      const request = ReminderChangedMutation(
        entityId: 'task-1',
        sourceContext: 'test',
      );

      final result = await coordinator.run(request);

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('not initialised'));
    });

    test('returns failed result when entityId is empty', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      coordinator.attachContainer(container);

      const request = ReminderChangedMutation(
        entityId: '',
        sourceContext: 'test',
      );

      final result = await coordinator.run(request);

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('entityId must not be empty'));
    });
  });

  group('ScheduleMutationCoordinator pipeline', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
      coordinator.attachContainer(container);
    });

    tearDown(() => container.dispose());

    test('TaskCompletedMutation succeeds and emits TaskCompletedEvent',
        () async {
      final events = <ScheduleDomainEvent>[];
      final sub = bus.listen(events.add);
      addTearDown(sub.cancel);

      final result = await coordinator.run(
        const TaskCompletedMutation(
          entityId: 'task-99',
          sourceContext: 'test',
          dateStr: '2026-05-28',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(result.success, isTrue);
      expect(events, hasLength(1));
      expect(events.first, isA<TaskCompletedEvent>());
      expect((events.first as TaskCompletedEvent).entityId, 'task-99');
    });

    test('TaskCompletedMutation schedules a recompute on the graph', () async {
      await coordinator.run(
        const TaskCompletedMutation(
          entityId: 'task-100',
          sourceContext: 'test',
          dateStr: '2026-05-28',
        ),
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(graph.flushCountForTests, 1);
    });

    test('unimplemented mutation returns failed result', () async {
      final result = await coordinator.run(
        const TaskCreatedMutation(
          entityId: 'task-101',
          sourceContext: 'test',
          dateStr: '2026-05-28',
        ),
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('migrate call site'));
    });

    test('event has correct fields', () async {
      final events = <ScheduleDomainEvent>[];
      final sub = bus.listen(events.add);
      addTearDown(sub.cancel);

      await coordinator.run(
        const TaskCompletedMutation(
          entityId: 'task-102',
          sourceContext: 'timer_screen',
          dateStr: '2026-05-28',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      final event = events.first as TaskCompletedEvent;
      expect(event.entityId, 'task-102');
      expect(event.entityKind, 'task');
      expect(event.dateStr, '2026-05-28');
    });
  });
}
