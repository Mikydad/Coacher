import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/di/providers.dart';
import 'package:sidepal/features/reminders/application/recovery_view.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_occurrence_enums.dart';
import 'package:sidepal/features/reminders/presentation/recovery_card.dart';

ReminderOccurrence _occ({
  required String id,
  required String title,
  String modeRefId = 'flexible',
  int criticality = 1,
}) => ReminderOccurrence(
  id: id,
  entityId: id,
  entityKind: 'task',
  dateKey: '2026-08-30',
  scheduledAtMs: DateTime(2026, 8, 30, 14, 0).millisecondsSinceEpoch,
  windowMinutes: 30,
  entityTitle: title,
  modeRefId: modeRefId,
  state: ReminderOccurrenceState.overdue,
  criticality: criticality,
  overdueSinceMs: DateTime(2026, 8, 30, 14, 30).millisecondsSinceEpoch,
  createdAtMs: 1,
  updatedAtMs: 1,
);

RecoveryRow _row(ReminderOccurrence o) =>
    RecoveryRow(occurrence: o, insistence: RecoveryInsistence.forMode(o.modeRefId));

Widget _host(
  RecoveryView view, {
  void Function(String)? onOpenTask,
  void Function(RecoveryRow, ReminderResolutionKind)? onResolve,
}) {
  return ProviderScope(
    overrides: [
      recoveryViewProvider.overrideWith((ref) => Stream.value(view)),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: RecoveryCard(onOpenTask: onOpenTask, onResolve: onResolve),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('renders nothing when there is nothing owed', (tester) async {
    await tester.pumpWidget(_host(const RecoveryView()));
    await tester.pump();

    expect(find.byType(Card), findsNothing);
    expect(find.textContaining('need you'), findsNothing);
  });

  testWidgets('leads with a count and lists the task', (tester) async {
    await tester.pumpWidget(
      _host(
        RecoveryView(
          rows: [_row(_occ(id: 't1', title: 'Study'))],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('1 task needs you'), findsOneWidget);
    expect(find.text('Study'), findsOneWidget);
    expect(find.text('Do now'), findsOneWidget);
  });

  testWidgets('pluralises the headline', (tester) async {
    await tester.pumpWidget(
      _host(
        RecoveryView(
          rows: [
            _row(_occ(id: 'a', title: 'Study')),
            _row(_occ(id: 'b', title: 'Gym')),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('2 tasks need you'), findsOneWidget);
  });

  testWidgets(
    'only a Flexible row offers the dismiss affordance (FR-R-40..42)',
    (tester) async {
      await tester.pumpWidget(
        _host(
          RecoveryView(
            rows: [
              _row(_occ(id: 'f', title: 'Flexible one')),
              _row(
                _occ(id: 'd', title: 'Disciplined one', modeRefId: 'disciplined'),
              ),
              _row(_occ(id: 'e', title: 'Extreme one', modeRefId: 'extreme')),
            ],
          ),
        ),
      );
      await tester.pump();

      // Three rows, but only one "Not today".
      expect(find.text('Do now'), findsNWidgets(3));
      expect(find.byTooltip('Not today'), findsOneWidget);
    },
  );

  testWidgets('the stricter modes say what they want', (tester) async {
    await tester.pumpWidget(
      _host(
        RecoveryView(
          rows: [
            _row(
              _occ(id: 'd', title: 'Disciplined one', modeRefId: 'disciplined'),
            ),
            _row(_occ(id: 'e', title: 'Extreme one', modeRefId: 'extreme')),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('needs a decision'), findsOneWidget);
    expect(find.textContaining('do it or reschedule'), findsOneWidget);
  });

  testWidgets('caps the visible rows and counts the rest', (tester) async {
    await tester.pumpWidget(
      _host(
        RecoveryView(
          rows: [
            for (var i = 0; i < 8; i++)
              _row(_occ(id: 't$i', title: 'Task $i')),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Do now'), findsNWidgets(RecoveryViewBuilder.maxRows));
    expect(find.text('+3 more waiting'), findsOneWidget);
  });

  testWidgets('shows the routine digest without making rows of it', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(const RecoveryView(routineMisses: ['Water', 'Stretch'])),
    );
    await tester.pump();

    expect(find.text('Missed today: Water, Stretch'), findsOneWidget);
    expect(find.text('Do now'), findsNothing);
  });

  testWidgets('Do now reports the entity', (tester) async {
    String? opened;
    await tester.pumpWidget(
      _host(
        RecoveryView(rows: [_row(_occ(id: 'task-42', title: 'Study'))]),
        onOpenTask: (id) => opened = id,
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Do now'));
    await tester.pump();

    expect(opened, 'task-42');
  });

  group('waited label', () {
    final since = DateTime(2026, 8, 30, 14, 30);
    int ms(DateTime d) => d.millisecondsSinceEpoch;

    test('reads in minutes, then hours, then days', () {
      expect(
        recoveryWaitedLabel(ms(since), now: since.add(const Duration(minutes: 20))),
        'Waiting 20m',
      );
      expect(
        recoveryWaitedLabel(ms(since), now: since.add(const Duration(hours: 5))),
        'Waiting 5h',
      );
      expect(
        recoveryWaitedLabel(ms(since), now: since.add(const Duration(days: 1))),
        'Waiting since yesterday',
      );
      expect(
        recoveryWaitedLabel(ms(since), now: since.add(const Duration(days: 3))),
        'Waiting 3d',
      );
    });

    test('a just-missed item does not claim 0m', () {
      expect(recoveryWaitedLabel(ms(since), now: since), 'Just missed');
    });

    test('a missing timestamp still says something true', () {
      expect(recoveryWaitedLabel(null), 'Overdue');
    });
  });

  group('the modes demand different things (FR-R-40..42)', () {
    testWidgets('Flexible gets no overflow — the gentlest mode stays plain', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          RecoveryView(rows: [_row(_occ(id: 'f', title: 'Study'))]),
          onResolve: (_, __) {},
        ),
      );
      await tester.pump();

      expect(find.byTooltip('Not today'), findsOneWidget);
      expect(find.byTooltip('Other options'), findsNothing);
    });

    testWidgets('Disciplined and Extreme offer a disposition instead', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          RecoveryView(
            rows: [
              _row(_occ(id: 'd', title: 'D', modeRefId: 'disciplined')),
              _row(_occ(id: 'e', title: 'E', modeRefId: 'extreme')),
            ],
          ),
          onResolve: (_, __) {},
        ),
      );
      await tester.pump();

      expect(find.byTooltip('Not today'), findsNothing);
      expect(find.byTooltip('Other options'), findsNWidgets(2));
    });

    testWidgets('the overflow reports the chosen disposition', (tester) async {
      ReminderResolutionKind? chosen;
      RecoveryRow? from;
      await tester.pumpWidget(
        _host(
          RecoveryView(
            rows: [
              _row(_occ(id: 'd', title: 'Study', modeRefId: 'disciplined')),
            ],
          ),
          onResolve: (row, kind) {
            from = row;
            chosen = kind;
          },
        ),
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Other options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move to tomorrow'));
      await tester.pumpAndSettle();

      expect(chosen, ReminderResolutionKind.rescheduled);
      expect(from!.occurrence.entityId, 'd');
    });

    testWidgets('Disciplined offers Skip', (tester) async {
      ReminderResolutionKind? chosen;
      await tester.pumpWidget(
        _host(
          RecoveryView(
            rows: [
              _row(_occ(id: 'd', title: 'D-task', modeRefId: 'disciplined')),
            ],
          ),
          onResolve: (_, kind) => chosen = kind,
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Other options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();
      expect(chosen, ReminderResolutionKind.skipped);
    });

    testWidgets('Extreme offers no Skip — Do, or move it (D4)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          RecoveryView(
            rows: [_row(_occ(id: 'e', title: 'E-task', modeRefId: 'extreme'))],
          ),
          onResolve: (_, __) {},
        ),
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Other options'));
      await tester.pumpAndSettle();

      expect(find.text('Move to tomorrow'), findsOneWidget);
      // The one-tap give-up D4 excludes, even with a reason attached.
      expect(find.text('Skip'), findsNothing);
    });
  });
}
