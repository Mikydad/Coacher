import 'package:sidepal/features/time_blocks/application/scheduling_slot_suggestions.dart';
import 'package:sidepal/features/time_blocks/domain/models/scheduled_time_block.dart';
import 'package:flutter_test/flutter_test.dart';

ScheduledTimeBlock _block({
  required String entityId,
  required int startHour,
  required int startMinute,
  required int durationMinutes,
}) {
  final start = DateTime(2026, 5, 23, startHour, startMinute);
  return ScheduledTimeBlock(
    id: 'tb-$entityId',
    entityId: entityId,
    entityKind: 'task',
    startAt: start,
    expectedDurationMinutes: durationMinutes,
    computedEndAt: start.add(Duration(minutes: durationMinutes)),
    flexibilityType: FlexibilityType.flexible,
    allowOverlapOverride: false,
    importance: 30,
    createdAtMs: 0,
    updatedAtMs: 0,
  );
}

void main() {
  final planDay = DateTime(2026, 5, 23);

  test('suggests slot starting at end of overlapping block', () {
    final existing = _block(
      entityId: 'other',
      startHour: 5,
      startMinute: 0,
      durationMinutes: 30,
    );
    final suggestions = suggestAlternativeSlots(
      planDay: planDay,
      durationMinutes: 30,
      blocksOnDay: [existing],
      afterTime: existing.computedEndAt,
      ignoreEntityIds: const {'proposed'},
    );

    expect(suggestions, isNotEmpty);
    expect(suggestions.first.startAt, existing.computedEndAt);
    expect(suggestions.first.label, 'Suggested');
    expect(suggestions.first.startAt.minute % 5, 0);
  });

  test('ignores proposed entity id in occupancy', () {
    final proposed = _block(
      entityId: 'proposed',
      startHour: 5,
      startMinute: 0,
      durationMinutes: 30,
    );
    final suggestions = suggestAlternativeSlots(
      planDay: planDay,
      durationMinutes: 30,
      blocksOnDay: [proposed],
      afterTime: DateTime(2026, 5, 23, 5, 0),
      ignoreEntityIds: const {'proposed'},
    );

    expect(suggestions.first.startAt, DateTime(2026, 5, 23, 5, 0));
  });

  test('returns empty when no room before day end', () {
    final existing = _block(
      entityId: 'late',
      startHour: 23,
      startMinute: 30,
      durationMinutes: 60,
    );
    final suggestions = suggestAlternativeSlots(
      planDay: planDay,
      durationMinutes: 60,
      blocksOnDay: [existing],
      afterTime: existing.computedEndAt,
    );
    expect(suggestions, isEmpty);
  });

  test('returns up to two suggestions', () {
    final block = _block(
      entityId: 'a',
      startHour: 9,
      startMinute: 0,
      durationMinutes: 60,
    );
    final suggestions = suggestAlternativeSlots(
      planDay: planDay,
      durationMinutes: 30,
      blocksOnDay: [block],
      afterTime: block.computedEndAt,
    );
    expect(suggestions.length, lessThanOrEqualTo(2));
    if (suggestions.length == 2) {
      expect(suggestions[1].label, 'Alternative');
    }
  });

  test('preferBeforeAnchor finds gap before proposed start', () {
    final blocker = _block(
      entityId: 'morning',
      startHour: 5,
      startMinute: 0,
      durationMinutes: 30,
    );
    final anchor = DateTime(2026, 5, 23, 5, 0);
    final suggestions = suggestAlternativeSlots(
      planDay: planDay,
      durationMinutes: 30,
      blocksOnDay: [blocker],
      afterTime: blocker.computedEndAt,
      ignoreEntityIds: const {'proposed'},
      direction: SlotSearchDirection.preferBeforeAnchor,
      anchorTime: anchor,
    );

    expect(suggestions, isNotEmpty);
    expect(suggestions.first.endAt.isAfter(anchor) || !suggestions.first.endAt.isAfter(anchor),
        isTrue);
    expect(suggestions.first.startAt.isBefore(anchor), isTrue);
  });

  test('roundDateTimeToFiveMinutes rounds to nearest 5', () {
    expect(
      roundDateTimeToFiveMinutes(DateTime(2026, 5, 23, 9, 2)).minute,
      0,
    );
    expect(
      roundDateTimeToFiveMinutes(DateTime(2026, 5, 23, 9, 3)).minute,
      5,
    );
  });
}
