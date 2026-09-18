import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/add_task/presentation/sections/add_task_advanced_section.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

/// "If you miss it" lives inside Advanced settings (Miko, 2026-09-18) and
/// only while a reminder is on.
Widget _host({
  required bool reminderEnabled,
  bool expanded = true,
  bool isHabitAnchor = false,
  bool isCritical = false,
  ValueChanged<ReminderTaxonomy>? onTaxonomyChanged,
  ValueChanged<bool>? onCriticalChanged,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: AddTaskAdvancedSection(
        sectionKey: GlobalKey(),
        expanded: expanded,
        isHabitAnchor: isHabitAnchor,
        strictModeRequired: false,
        isRigid: false,
        onToggleExpanded: () {},
        onHabitAnchorChanged: (_) {},
        onStrictChanged: (_) {},
        onRigidChanged: (_) {},
        reminderEnabled: reminderEnabled,
        taxonomy: ReminderTaxonomy.flexible,
        isCritical: isCritical,
        onTaxonomyChanged: onTaxonomyChanged ?? (_) {},
        onCriticalChanged: onCriticalChanged ?? (_) {},
      ),
    ),
  ),
);

void main() {
  testWidgets('with a reminder on, the chooser and Critical are inside', (
    tester,
  ) async {
    await tester.pumpWidget(_host(reminderEnabled: true));
    await tester.pumpAndSettle();

    expect(find.text('If you miss it'), findsOneWidget);
    expect(find.text('COMES BACK'), findsOneWidget);
    expect(find.text('Critical'), findsOneWidget);
    // The existing toggles are still there.
    expect(find.text('Habit anchor'), findsOneWidget);
    expect(find.text('Fixed time slot'), findsOneWidget);
  });

  testWidgets('with no reminder, the chooser is absent — nothing to shape', (
    tester,
  ) async {
    await tester.pumpWidget(_host(reminderEnabled: false));
    await tester.pumpAndSettle();

    expect(find.text('If you miss it'), findsNothing);
    expect(find.text('Critical'), findsNothing);
    expect(find.text('Habit anchor'), findsOneWidget);
  });

  testWidgets('the collapsed subtitle names Critical when it is set', (
    tester,
  ) async {
    // Collapsed children stay in the tree, so read the composed subtitle
    // rather than counting "Critical" occurrences.
    await tester.pumpWidget(
      _host(
        reminderEnabled: true,
        expanded: false,
        isHabitAnchor: true,
        isCritical: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Habit anchor · Critical'), findsOneWidget);

    await tester.pumpWidget(_host(reminderEnabled: true, expanded: false));
    await tester.pumpAndSettle();
    expect(
      find.text('Habit, strict rules, fixed time, if you miss it'),
      findsOneWidget,
    );
  });

  testWidgets('changes flow out through the callbacks', (tester) async {
    ReminderTaxonomy? picked;
    bool? critical;
    await tester.pumpWidget(
      _host(
        reminderEnabled: true,
        onTaxonomyChanged: (t) => picked = t,
        onCriticalChanged: (v) => critical = v,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('ADDS UP'));
    await tester.pump();
    expect(picked, ReminderTaxonomy.routine);

    await tester.tap(find.text('Critical'));
    await tester.pump();
    expect(critical, isTrue);
  });
}
