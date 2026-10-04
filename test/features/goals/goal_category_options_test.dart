import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/goals/application/goal_category_options.dart';
import 'package:sidepal/features/goals/domain/models/goal_categories.dart';
import 'package:sidepal/features/goals/presentation/widgets/goal_category_pill_row.dart';

/// Categories come from ALL goals, deduped case-insensitively, built-ins
/// first (Miko, 2026-09-24).
void main() {
  test('built-ins first, custom A–Z, case-insensitive dedupe, trimmed', () {
    final out = goalCategoryOptions([
      'study',
      'Music',
      ' cooking ',
      'music',
      'Fitness',
      '',
      'Art',
    ]);
    expect(out.sublist(0, GoalCategories.all.length), GoalCategories.all);
    expect(out.sublist(GoalCategories.all.length), ['Art', 'cooking', 'Music']);
  });

  test('a built-in typed with different casing is not a new category', () {
    final out = goalCategoryOptions(['STUDY', 'Focus']);
    expect(out, GoalCategories.all);
  });

  test("the editor's current pick stays visible before any goal has it", () {
    final out = goalCategoryOptions(const [], extra: 'Guitar');
    expect(out.last, 'Guitar');
    expect(goalCategoryOptions(const [], extra: '  ').length,
        GoalCategories.all.length);
  });

  testWidgets('the pill row: New first, taps report ids', (tester) async {
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoalCategoryPillRow(
            categories: const ['study', 'Music'],
            selectedId: 'Music',
            onSelected: (id) => picked = id,
            onCreated: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('New'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Music'), findsOneWidget);
    await tester.tap(find.text('Study'));
    expect(picked, 'study');
  });
}
