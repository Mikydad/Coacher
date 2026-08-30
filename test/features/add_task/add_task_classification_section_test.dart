import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/add_task/presentation/sections/add_task_classification_section.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';

Widget _host({
  required ReminderTaxonomy taxonomy,
  bool isCritical = false,
  ValueChanged<ReminderTaxonomy>? onTaxonomyChanged,
  ValueChanged<bool>? onCriticalChanged,
}) => MaterialApp(
  home: Scaffold(
    body: SingleChildScrollView(
      child: AddTaskClassificationSection(
        taxonomy: taxonomy,
        isCritical: isCritical,
        onTaxonomyChanged: onTaxonomyChanged ?? (_) {},
        onCriticalChanged: onCriticalChanged ?? (_) {},
      ),
    ),
  ),
);

void main() {
  testWidgets('offers all three classes', (tester) async {
    await tester.pumpWidget(_host(taxonomy: ReminderTaxonomy.flexible));

    expect(find.text('EXPIRES'), findsOneWidget);
    expect(find.text('FLEXIBLE'), findsOneWidget);
    expect(find.text('ROUTINE'), findsOneWidget);
  });

  testWidgets('explains what the selected class means for a miss', (
    tester,
  ) async {
    await tester.pumpWidget(_host(taxonomy: ReminderTaxonomy.routine));
    expect(find.textContaining('one daily line'), findsOneWidget);

    await tester.pumpWidget(_host(taxonomy: ReminderTaxonomy.timeSensitive));
    await tester.pumpAndSettle();
    expect(find.textContaining('never nagged'), findsOneWidget);
  });

  testWidgets('Critical is offered only for the expiring class', (
    tester,
  ) async {
    await tester.pumpWidget(_host(taxonomy: ReminderTaxonomy.flexible));
    await tester.pumpAndSettle();
    expect(find.text('Critical'), findsNothing);

    await tester.pumpWidget(_host(taxonomy: ReminderTaxonomy.routine));
    await tester.pumpAndSettle();
    expect(find.text('Critical'), findsNothing);

    await tester.pumpWidget(_host(taxonomy: ReminderTaxonomy.timeSensitive));
    await tester.pumpAndSettle();
    expect(find.text('Critical'), findsOneWidget);
  });

  testWidgets('tapping a segment reports the taxonomy behind its label', (
    tester,
  ) async {
    ReminderTaxonomy? picked;
    await tester.pumpWidget(
      _host(
        taxonomy: ReminderTaxonomy.flexible,
        onTaxonomyChanged: (t) => picked = t,
      ),
    );

    await tester.tap(find.text('ROUTINE'));
    await tester.pump();
    expect(picked, ReminderTaxonomy.routine);

    await tester.tap(find.text('EXPIRES'));
    await tester.pump();
    expect(picked, ReminderTaxonomy.timeSensitive);
  });

  testWidgets('the Critical toggle reports its change', (tester) async {
    bool? critical;
    await tester.pumpWidget(
      _host(
        taxonomy: ReminderTaxonomy.timeSensitive,
        onCriticalChanged: (v) => critical = v,
      ),
    );

    await tester.tap(find.text('Critical'));
    await tester.pump();
    expect(critical, isTrue);
  });
}
