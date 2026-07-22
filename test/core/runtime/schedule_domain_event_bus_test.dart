import 'package:flutter_test/flutter_test.dart';

import 'package:sidepal/core/runtime/schedule_domain_event.dart';
import 'package:sidepal/core/runtime/schedule_domain_event_bus.dart';

void main() {
  final bus = ScheduleDomainEventBus.instance;

  tearDown(() => bus.resetForTests());

  group('ScheduleDomainEventBus', () {
    test('emitting an event delivers to all subscribers', () async {
      final received = <ScheduleDomainEvent>[];
      final received2 = <ScheduleDomainEvent>[];

      final sub1 = bus.listen(received.add);
      final sub2 = bus.listen(received2.add);

      const event = TaskCreatedEvent(
        entityId: 'task-1',
        occurredAtMs: 1000,
        dateStr: '2026-05-28',
      );
      bus.emit(event);

      await Future<void>.delayed(Duration.zero);

      expect(received, [event]);
      expect(received2, [event]);

      await sub1.cancel();
      await sub2.cancel();
    });

    test('a subscriber that throws does not crash the bus or other subscribers',
        () async {
      final received = <ScheduleDomainEvent>[];

      bus.listen((_) => throw Exception('subscriber error'));
      final sub2 = bus.listen(received.add);

      const event = TaskUpdatedEvent(
        entityId: 'task-2',
        occurredAtMs: 2000,
        dateStr: '2026-05-28',
      );

      expect(() => bus.emit(event), returnsNormally);

      await Future<void>.delayed(Duration.zero);
      expect(received, [event]);

      await sub2.cancel();
    });

    test('dispose closes the stream and a new stream is available', () async {
      final receivedBefore = <ScheduleDomainEvent>[];
      final sub = bus.listen(receivedBefore.add);

      bus.emit(const TaskDeletedEvent(
        entityId: 'task-3',
        occurredAtMs: 3000,
        dateStr: '2026-05-28',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(receivedBefore.length, 1);

      await sub.cancel();
      bus.dispose();

      // After dispose a fresh stream is available — no events from before
      final receivedAfter = <ScheduleDomainEvent>[];
      final sub2 = bus.listen(receivedAfter.add);

      bus.emit(const TaskCompletedEvent(
        entityId: 'task-4',
        occurredAtMs: 4000,
        dateStr: '2026-05-28',
      ));
      await Future<void>.delayed(Duration.zero);
      expect(receivedAfter.length, 1);

      await sub2.cancel();
    });

    test('emit on a disposed bus is a no-op', () {
      bus.dispose();
      expect(
        () => bus.emit(const FocusChangedEvent(
          entityId: 'focus-1',
          occurredAtMs: 5000,
        )),
        returnsNormally,
      );
    });

    test('events carry correct fields', () {
      const event = TaskDeferredEvent(
        entityId: 'task-5',
        occurredAtMs: 6000,
        fromDateStr: '2026-05-28',
        toDateStr: '2026-05-29',
      );

      expect(event.entityId, 'task-5');
      expect(event.entityKind, 'task');
      expect(event.fromDateStr, '2026-05-28');
      expect(event.toDateStr, '2026-05-29');
    });
  });
}
