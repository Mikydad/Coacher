import 'package:coach_for_life/features/time_blocks/application/scheduling_slot_suggestions.dart';
import 'package:coach_for_life/features/time_blocks/presentation/conflict_move_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ConflictMovePanel Apply invokes move callback', (tester) async {
    TimeSlotSuggestion? applied;
    final suggestion = TimeSlotSuggestion(
      startAt: DateTime(2026, 5, 23, 5, 30),
      durationMinutes: 30,
      label: 'Suggested',
      suggestionIndex: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConflictMovePanel(
            entityTitle: 'Morning Routine',
            currentRangeLabel: '05:00 – 05:30',
            suggestions: [suggestion],
            durationMinutes: 30,
            onApplySuggestion: (s) => applied = s,
            onCustomTime: () {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(applied, isNotNull);
    expect(applied!.suggestionIndex, 0);
  });
}
