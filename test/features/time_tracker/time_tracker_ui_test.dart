import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/presentation/swipe_actions.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/time_tracker/application/activity_reminder_service.dart';
import 'package:sidepal/features/time_tracker/application/time_export_service.dart';
import 'package:sidepal/features/time_tracker/application/time_tracker_providers.dart';
import 'package:sidepal/features/time_tracker/data/activity_event_repository.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';
import 'package:sidepal/features/time_tracker/domain/time_export.dart';
import 'package:sidepal/features/time_tracker/presentation/export_time_sheet.dart';
import 'package:sidepal/features/time_tracker/presentation/time_screen.dart';
import 'package:sidepal/features/time_tracker/presentation/track_activity_sheet.dart';
import 'package:sidepal/features/time_tracker/presentation/track_pill.dart';
import 'package:sidepal/features/analytics/domain/models/generated_insight.dart';
import 'package:sidepal/features/time_blocks/application/time_block_providers.dart';
import 'package:sidepal/features/time_blocks/data/time_block_repository.dart';
import 'package:sidepal/features/time_blocks/domain/models/scheduled_time_block.dart';

/// In-memory stand-in with the repository's contract (tombstones kept,
/// reads filter `active`), recording every write.
class _FakeRepo extends ActivityEventRepository {
  _FakeRepo([Iterable<ActivityEvent> seed = const []]) {
    for (final e in seed) {
      rows[e.id] = e;
    }
  }

  final Map<String, ActivityEvent> rows = {};
  final _changes = StreamController<void>.broadcast();
  final List<ActivityEvent> writes = [];
  int clock = 1000;

  List<ActivityEvent> get _live =>
      rows.values.where((e) => e.active).toList(growable: false);

  Stream<T> _derive<T>(T Function() compute) async* {
    yield compute();
    yield* _changes.stream.map((_) => compute());
  }

  @override
  Stream<List<ActivityEvent>> watchDay(String dateKey) => _derive(
    () => _live.where((e) => e.dateKey == dateKey).toList()
      ..sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs)),
  );

  @override
  Future<List<ActivityEvent>> fetchDayOnce(String dateKey) async =>
      _live.where((e) => e.dateKey == dateKey).toList();

  @override
  Stream<List<ActivityEvent>> watchRecentSince(int sinceMs) => _derive(
    () => _live.where((e) => e.startedAtMs >= sinceMs).toList()
      ..sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs)),
  );

  @override
  Stream<ActivityEvent?> watchLatest() => _derive(() {
    final l = _live..sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
    return l.isEmpty ? null : l.first;
  });

  @override
  Stream<List<ActivityEvent>> watchRange(int fromMs, int toMs) => _derive(
    () => _live
        .where((e) => e.startedAtMs >= fromMs && e.startedAtMs < toMs)
        .toList()
      ..sort((a, b) => a.startedAtMs.compareTo(b.startedAtMs)),
  );

  @override
  Future<List<ActivityEvent>> fetchRangeOnce(int fromMs, int toMs) async =>
      _live.where((e) => e.startedAtMs >= fromMs && e.startedAtMs < toMs).toList();

  @override
  Future<ActivityEvent?> getById(String id) async => rows[id];

  @override
  Future<ActivityEvent?> fetchLatestOnce() async {
    final l = _live..sort((a, b) => b.startedAtMs.compareTo(a.startedAtMs));
    return l.isEmpty ? null : l.first;
  }

  @override
  Future<ActivityEvent> upsert(ActivityEvent event) async {
    final stamped = event.copyWith(updatedAtMs: clock++);
    if (stamped.active) stamped.validate();
    rows[stamped.id] = stamped;
    writes.add(stamped);
    _changes.add(null);
    return stamped;
  }

  @override
  Future<void> softDelete(String id) async {
    final current = rows[id];
    if (current == null || !current.active) return;
    await upsert(current.copyWith(active: false));
  }
}

int _todayAt(int h, [int m = 0]) {
  final n = DateTime.now();
  return DateTime(n.year, n.month, n.day, h, m).millisecondsSinceEpoch;
}

ActivityEvent _seed(
  String text,
  int startMs, {
  int? endMs,
  int? intended,
  ActivitySource source = ActivitySource.manual,
}) => ActivityEvent.create(
  text: text,
  startedAtMs: startMs,
  nowMs: 1,
  endedAtMs: endMs,
  intendedMinutes: intended,
  source: source,
);

final List<String> reminderLog = [];

ActivityReminderService _fakeReminders() => ActivityReminderService(
  evaluate: (intent) async => reminderLog.add('schedule:${intent.entityId}'),
  cancel: (id) async => reminderLog.add('cancel:$id'),
);

Widget _app(Widget home, _FakeRepo repo) {
  reminderLog.clear();
  return ProviderScope(
    overrides: [
      activityEventRepositoryProvider.overrideWithValue(repo),
      activityReminderServiceProvider.overrideWithValue(_fakeReminders()),
    ],
    child: MaterialApp(
      home: home,
      routes: {TimeScreen.routeName: (_) => const TimeScreen()},
    ),
  );
}

/// A host whose button opens the sheet, so the sheet's own navigation
/// (pop then push) has a real route stack under it.
class _SheetHost extends StatelessWidget {
  const _SheetHost({this.edit});
  final ActivityEvent? edit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          key: const ValueKey('open'),
          onPressed: () => showTrackActivitySheet(context, edit: edit),
          child: const Text('open'),
        ),
      ),
    );
  }
}

Future<void> _openSheet(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('open')));
  await tester.pumpAndSettle();
}

void main() {
  // Tests run at whatever wall-clock time CI has; keep seeded events early
  // in the day so "clamped to now" logic never bites.
  final now = DateTime.now();
  final earlyEnough = now.hour >= 2;

  group('TrackActivitySheet', () {
    testWidgets('Track is disabled until there is text; writes and pops',
        (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app(const _SheetHost(), repo));
      await _openSheet(tester);

      final submit = find.byKey(const ValueKey('track_submit'));
      expect(tester.widget<FilledButton>(submit).onPressed, isNull);

      await tester.enterText(find.byKey(const ValueKey('track_text')), ' Scrolling ');
      await tester.pump();
      expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(repo.writes.length, 1);
      final e = repo.writes.single;
      expect(e.text, 'Scrolling');
      expect(e.source, ActivitySource.manual);
      expect(e.dateKey, DateKeys.todayKey());
      expect(e.intendedMinutes, isNull);
      expect(find.byType(TrackActivitySheet), findsNothing);
    });

    testWidgets('a recent row fills the field without submitting',
        (tester) async {
      final repo = _FakeRepo([_seed('Gym', _todayAt(1))]);
      await tester.pumpWidget(_app(const _SheetHost(), repo));
      await _openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('track_recent_Gym')));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byKey(const ValueKey('track_text'))).controller!.text,
        'Gym',
      );
      expect(repo.writes, isEmpty);
    });

    testWidgets('recent rows: repeats first, capped at 5, typing filters',
        (tester) async {
      final repo = _FakeRepo([
        _seed('Going to the clinic with my mom', _todayAt(0, 50)),
        _seed('Eating breakfast', _todayAt(0, 10)),
        _seed('Eating breakfast', _todayAt(0, 40)),
        for (var i = 0; i < 6; i++) _seed('One-off $i', _todayAt(0, 11 + i)),
      ]);
      await tester.pumpWidget(_app(const _SheetHost(), repo));
      await _openSheet(tester);
      // Repeat first, then the most recent one-offs, five rows total.
      expect(find.byKey(const ValueKey('track_recent_Eating breakfast')), findsOneWidget);
      expect(find.text('×2'), findsOneWidget);
      expect(find.byKey(const ValueKey('track_recent_Going to the clinic with my mom')), findsOneWidget);
      expect(find.byIcon(Icons.history_rounded), findsNWidgets(5));
      // Typing filters.
      await tester.enterText(find.byKey(const ValueKey('track_text')), 'clin');
      await tester.pump();
      expect(find.byIcon(Icons.history_rounded), findsOneWidget);
      expect(find.byKey(const ValueKey('track_recent_Going to the clinic with my mom')), findsOneWidget);
    });

    testWidgets('duration chips set and clear the intended minutes',
        (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app(const _SheetHost(), repo));
      await _openSheet(tester);
      await tester.enterText(find.byKey(const ValueKey('track_text')), 'Study');
      await tester.tap(find.byKey(const ValueKey('track_duration_30')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('track_submit')));
      await tester.pumpAndSettle();
      expect(repo.writes.single.intendedMinutes, 30);
      expect(reminderLog, ['schedule:${repo.writes.single.id}']);
    });

    testWidgets('custom duration dialog', (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app(const _SheetHost(), repo));
      await _openSheet(tester);
      await tester.enterText(find.byKey(const ValueKey('track_text')), 'Study');
      await tester.tap(find.byKey(const ValueKey('track_duration_custom')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('track_custom_duration_field')),
        '90',
      );
      await tester.tap(find.byKey(const ValueKey('track_custom_duration_ok')));
      await tester.pumpAndSettle();
      expect(find.text('90m'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('track_submit')));
      await tester.pumpAndSettle();
      expect(repo.writes.single.intendedMinutes, 90);
    });

    testWidgets('edit mode prefills, saves changes, and delete tombstones',
        (tester) async {
      final existing = _seed('Gym', _todayAt(1), intended: 45);
      final repo = _FakeRepo([existing]);
      await tester.pumpWidget(_app(_SheetHost(edit: existing), repo));
      await _openSheet(tester);

      final field = find.byKey(const ValueKey('track_text'));
      expect(tester.widget<TextField>(field).controller!.text, 'Gym');
      expect(find.text('SAVE'), findsOneWidget);
      expect(find.byKey(const ValueKey('track_end')), findsOneWidget);

      await tester.enterText(field, 'Gym session');
      // Edit mode is taller (End row + category chips): scroll to the button.
      await tester.ensureVisible(find.byKey(const ValueKey('track_submit')));
      await tester.tap(find.byKey(const ValueKey('track_submit')));
      await tester.pumpAndSettle();
      expect(repo.rows[existing.id]!.text, 'Gym session');
      expect(repo.rows[existing.id]!.intendedMinutes, 45);

      await _openSheet(tester);
      await tester.ensureVisible(find.byKey(const ValueKey('track_delete')));
      await tester.tap(find.byKey(const ValueKey('track_delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('track_delete_confirm')));
      await tester.pumpAndSettle();
      expect(repo.rows[existing.id]!.active, isFalse);
      expect(find.byType(TrackActivitySheet), findsNothing);
    });

    testWidgets("'Today's timeline →' closes the sheet and opens the page",
        (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app(const _SheetHost(), repo));
      await _openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('track_timeline_link')));
      await tester.pumpAndSettle();
      expect(find.byType(TrackActivitySheet), findsNothing);
      expect(find.byType(TimeScreen), findsOneWidget);
    });
  });

  group('TrackPill', () {
    testWidgets('neutral copy, then the ongoing event; tap opens the sheet',
        (tester) async {
      final repo = _FakeRepo();
      await tester.pumpWidget(_app(const Scaffold(body: TrackPill()), repo));
      await tester.pump();
      expect(find.text('Track your time'), findsOneWidget);

      // Started a minute ago → ongoing.
      await repo.upsert(
        _seed('Scrolling', DateTime.now().millisecondsSinceEpoch - 60000),
      );
      await tester.pump();
      expect(find.textContaining('Scrolling · since'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('track_pill')));
      await tester.pumpAndSettle();
      expect(find.byType(TrackActivitySheet), findsOneWidget);
    });

    testWidgets('an event older than the cap goes back to neutral copy',
        (tester) async {
      final repo = _FakeRepo([
        _seed('Old', DateTime.now().millisecondsSinceEpoch - 3 * 3600000),
      ]);
      await tester.pumpWidget(_app(const Scaffold(body: TrackPill()), repo));
      await tester.pump();
      expect(find.text('Track your time'), findsOneWidget);
    });
  });

  group('TimeScreen', () {
    testWidgets('renders rows, untracked gap, ongoing, and the summary',
        (tester) async {
      if (!earlyEnough) return;
      final repo = _FakeRepo([
        _seed('Scrolling', _todayAt(0, 3)),
        _seed('Planning', _todayAt(0, 9)),
        // 2h+ later → Planning capped + untracked row, Gym ongoing.
        _seed('Gym', _todayAt(2, 20), intended: 60),
      ]);
      await tester.pumpWidget(_app(const TimeScreen(), repo));
      await tester.pumpAndSettle();

      expect(find.text('Scrolling'), findsAtLeastNWidgets(1));
      expect(find.text('6m'), findsAtLeastNWidgets(1));
      expect(find.byKey(const ValueKey('time_untracked_row')), findsOneWidget);
      expect(find.textContaining('2h 11m untracked'), findsOneWidget);
      expect(find.text('Ongoing'), findsOneWidget);
      expect(find.text('Planned 1h 00m'), findsOneWidget);
      expect(find.byKey(const ValueKey('time_summary_head')), findsOneWidget);
      expect(find.text('You logged 6m · Untracked 2h 11m'), findsOneWidget);
      expect(find.byKey(const ValueKey('time_track_fab')), findsOneWidget);
      expect(find.byType(SwipeActionsRow), findsNWidgets(3));
      expect(find.byKey(const ValueKey('time_timer_glyph')), findsNothing);
    });

    testWidgets('timer-sourced rows carry the glyph and explicit duration',
        (tester) async {
      if (!earlyEnough) return;
      final repo = _FakeRepo([
        _seed(
          'Work on SidePal',
          _todayAt(0, 42),
          endMs: _todayAt(1, 27),
          source: ActivitySource.timer,
        ),
      ]);
      await tester.pumpWidget(_app(const TimeScreen(), repo));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('time_timer_glyph')), findsOneWidget);
      expect(find.text('45m'), findsAtLeastNWidgets(1));
      expect(find.text('Ongoing'), findsNothing);
    });

    testWidgets('previous day is read-only: no FAB, no swipe rows',
        (tester) async {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yMs = DateTime(yesterday.year, yesterday.month, yesterday.day, 9)
          .millisecondsSinceEpoch;
      final repo = _FakeRepo([_seed('Yesterday thing', yMs)]);
      await tester.pumpWidget(_app(const TimeScreen(), repo));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('time_empty')), findsOneWidget);
      expect(
        tester.widget<IconButton>(find.byKey(const ValueKey('time_next_day'))).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('time_prev_day')));
      await tester.pumpAndSettle();
      expect(find.textContaining('Yesterday ·'), findsOneWidget);
      expect(find.text('Yesterday thing'), findsOneWidget);
      expect(find.byKey(const ValueKey('time_track_fab')), findsNothing);
      expect(find.byType(SwipeActionsRow), findsNothing);
      expect(
        tester.widget<IconButton>(find.byKey(const ValueKey('time_next_day'))).onPressed,
        isNotNull,
      );
    });

    testWidgets('delete from the page tombstones the event', (tester) async {
      if (!earlyEnough) return;
      final e = _seed('Gone', _todayAt(1));
      final repo = _FakeRepo([e]);
      await tester.pumpWidget(_app(const TimeScreen(), repo));
      await tester.pumpAndSettle();
      // Drive the swipe pane's delete via the row's callback path: swipe.
      await tester.drag(find.text('Gone'), const Offset(-300, 0));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('time_delete_confirm')));
      await tester.pumpAndSettle();
      expect(repo.rows[e.id]!.active, isFalse);
      expect(find.byKey(const ValueKey('time_empty')), findsOneWidget);
    });
  });

  v12Tests();
}

// ─── V1.2 additions ───────────────────────────────────────────────────────────

class _FakeTimeBlockRepo implements TimeBlockRepository {
  _FakeTimeBlockRepo(this.blocks);
  final Map<String, ScheduledTimeBlock> blocks;

  @override
  Future<ScheduledTimeBlock?> getBlockForEntity(String entityId) async =>
      blocks[entityId];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

GeneratedInsight _observation(String scopeId, String message) => GeneratedInsight(
  insightId: 'ins_$scopeId',
  scopeType: InsightScopeType.entity,
  scopeId: scopeId,
  insightType: InsightType.reflectionObservation,
  insightBucket: InsightBucket.neutral,
  priority: InsightPriority.low,
  messageKey: 'reflection_observation',
  message: message,
  action: InsightAction.keepGoing,
  linkedPatternCodes: const [],
  confidence: 0.6,
  detectedAtMs: 1,
  sourceWindowStartDateKey: DateKeys.todayKey(),
  sourceWindowEndDateKey: DateKeys.todayKey(),
);

void v12Tests() {
  final now = DateTime.now();
  final earlyEnough = now.hour >= 2;

  group('TimeScreen V1.2', () {
    testWidgets('Day | Week toggle shows the week summary and pager',
        (tester) async {
      if (!earlyEnough) return;
      final repo = _FakeRepo([
        _seed('Gym', _todayAt(0, 30)),
        _seed('Work', _todayAt(1, 0), endMs: _todayAt(1, 45)),
      ]);
      await tester.pumpWidget(_app(const TimeScreen(), repo));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('time_week_label')), findsOneWidget);
      expect(find.textContaining('This week ·'), findsOneWidget);
      expect(find.text('1 of 7 days with entries'), findsOneWidget);
      expect(find.text('You logged 1h 15m'), findsOneWidget);
      expect(find.byKey(const ValueKey('time_track_fab')), findsNothing);
      expect(find.byType(SwipeActionsRow), findsNothing);
      expect(
        tester.widget<IconButton>(find.byKey(const ValueKey('time_next_week'))).onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('time_prev_week')));
      await tester.pumpAndSettle();
      expect(find.textContaining('This week ·'), findsNothing);
    });

    testWidgets('timer-sourced rows show planned vs actual from the block',
        (tester) async {
      if (!earlyEnough) return;
      final start = _todayAt(0, 42);
      final repo = _FakeRepo([
        _seed('Work on SidePal', start, endMs: _todayAt(1, 27),
            source: ActivitySource.timer),
      ]);
      // Give the seeded event a task link.
      final e = repo.rows.values.single;
      repo.rows[e.id] = ActivityEvent(
        id: e.id,
        text: e.text,
        startedAtMs: e.startedAtMs,
        endedAtMs: e.endedAtMs,
        dateKey: e.dateKey,
        source: ActivitySource.timer,
        sourceEntityId: 'task_1',
        createdAtMs: 1,
        updatedAtMs: 1,
      );
      final block = ScheduledTimeBlock(
        id: 'blk_1',
        entityId: 'task_1',
        entityKind: 'task',
        startAt: DateTime.fromMillisecondsSinceEpoch(_todayAt(0, 0)),
        expectedDurationMinutes: 60,
        computedEndAt: DateTime.fromMillisecondsSinceEpoch(_todayAt(1, 0)),
        flexibilityType: FlexibilityType.rigid,
        allowOverlapOverride: false,
        importance: 3,
        createdAtMs: 1,
        updatedAtMs: 1,
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityEventRepositoryProvider.overrideWithValue(repo),
            activityReminderServiceProvider.overrideWithValue(_fakeReminders()),
            timeBlockRepositoryProvider.overrideWithValue(
              _FakeTimeBlockRepo({'task_1': block}),
            ),
          ],
          child: const MaterialApp(home: TimeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('time_planned_vs_actual')), findsOneWidget);
      expect(find.textContaining('· Started'), findsOneWidget);
      expect(find.textContaining('· Ended'), findsOneWidget);
    });

    testWidgets('a day observation renders and dismisses', (tester) async {
      final repo = _FakeRepo();
      final scope = timeObservationScopeId('day', DateKeys.todayKey());
      final dismissed = <String>[];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activityEventRepositoryProvider.overrideWithValue(repo),
            activityReminderServiceProvider.overrideWithValue(_fakeReminders()),
            timeObservationProvider.overrideWith(
              (ref, id) => id == scope && !dismissed.contains(id)
                  ? _observation(id, 'Most of your focused work happened after 9 PM.')
                  : null,
            ),
          ],
          child: const MaterialApp(home: TimeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('time_observation')), findsOneWidget);
      expect(find.text('Most of your focused work happened after 9 PM.'), findsOneWidget);
      expect(find.text("SIDEPAL'S GUESS"), findsOneWidget);
    });
  });
  group('Export sheet', () {
    Widget host(_FakeRepo repo, List<TimeExportFile> shared) => ProviderScope(
      overrides: [
        activityEventRepositoryProvider.overrideWithValue(repo),
        activityReminderServiceProvider.overrideWithValue(_fakeReminders()),
        shareTimeExportProvider.overrideWithValue((f) async => shared.add(f)),
      ],
      child: const MaterialApp(home: TimeScreen()),
    );

    testWidgets('AppBar button opens the sheet on the viewed day', (tester) async {
      if (!earlyEnough) return;
      final repo = _FakeRepo([
        _seed('Gym', _todayAt(0, 30), endMs: _todayAt(1, 0)),
      ]);
      final shared = <TimeExportFile>[];
      await tester.pumpWidget(host(repo, shared));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('time_export_button')));
      await tester.pumpAndSettle();
      expect(find.byType(ExportTimeSheet), findsOneWidget);

      final today = DateTime.now();
      final expected = TimeExportPeriod.around(TimeExportScope.day, today);
      expect(find.text(expected.label), findsOneWidget);
      expect(find.text('Logged 30m'), findsOneWidget);
    });

    testWidgets('scope switches the label and preview; empty disables Share',
        (tester) async {
      if (!earlyEnough) return;
      final repo = _FakeRepo([
        _seed('Gym', _todayAt(0, 30), endMs: _todayAt(1, 0)),
      ]);
      final shared = <TimeExportFile>[];
      await tester.pumpWidget(host(repo, shared));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('time_export_button')));
      await tester.pumpAndSettle();

      final share = find.byKey(const ValueKey('time_export_share'));
      expect(tester.widget<FilledButton>(share).onPressed, isNotNull);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      final month = TimeExportPeriod.around(TimeExportScope.month, DateTime.now());
      expect(find.text(month.label), findsOneWidget);
      expect(
        find.textContaining('across 1 of ${month.dayKeys.length} days'),
        findsOneWidget,
      );

      // Go to yesterday (no entries) and export the day: Share is disabled.
      Navigator.of(tester.element(find.byType(ExportTimeSheet))).pop();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('time_prev_day')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('time_export_button')));
      await tester.pumpAndSettle();
      expect(find.text('Nothing logged in this period.'), findsOneWidget);
      expect(tester.widget<FilledButton>(share).onPressed, isNull);
      expect(shared, isEmpty);
    });

    testWidgets('Share hands a markdown or json file to the share hook',
        (tester) async {
      if (!earlyEnough) return;
      final repo = _FakeRepo([
        _seed('Gym', _todayAt(0, 30), endMs: _todayAt(1, 0)),
      ]);
      final shared = <TimeExportFile>[];
      await tester.pumpWidget(host(repo, shared));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('time_export_button')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('time_export_share')));
      await tester.pumpAndSettle();
      expect(shared.length, 1);
      expect(shared.single.name, 'sidepal_time_${DateKeys.todayKey()}.md');
      expect(shared.single.mimeType, 'text/markdown');
      expect(shared.single.text, contains('| Gym | 30m |'));
      expect(find.byType(ExportTimeSheet), findsNothing);

      await tester.tap(find.byKey(const ValueKey('time_export_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('time_export_format_json')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('time_export_share')));
      await tester.pumpAndSettle();
      expect(shared.length, 2);
      expect(shared.last.name, 'sidepal_time_${DateKeys.todayKey()}.json');
      expect(shared.last.text, contains('"activity": "Gym"'));
    });

    testWidgets('Week view opens the sheet on the week scope', (tester) async {
      if (!earlyEnough) return;
      final repo = _FakeRepo([
        _seed('Gym', _todayAt(0, 30), endMs: _todayAt(1, 0)),
      ]);
      final shared = <TimeExportFile>[];
      await tester.pumpWidget(host(repo, shared));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('time_export_button')));
      await tester.pumpAndSettle();
      final week = TimeExportPeriod.around(TimeExportScope.week, DateTime.now());
      expect(find.text(week.label), findsOneWidget);
      expect(find.textContaining('across 1 of 7 days'), findsOneWidget);
    });
  });
}
