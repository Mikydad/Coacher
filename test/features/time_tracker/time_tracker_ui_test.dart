import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/presentation/swipe_actions.dart';
import 'package:sidepal/core/utils/date_keys.dart';
import 'package:sidepal/features/time_tracker/application/activity_reminder_service.dart';
import 'package:sidepal/features/time_tracker/application/time_tracker_providers.dart';
import 'package:sidepal/features/time_tracker/data/activity_event_repository.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';
import 'package:sidepal/features/time_tracker/presentation/time_screen.dart';
import 'package:sidepal/features/time_tracker/presentation/track_activity_sheet.dart';
import 'package:sidepal/features/time_tracker/presentation/track_pill.dart';

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

    testWidgets('a recent chip fills the field without submitting',
        (tester) async {
      final repo = _FakeRepo([_seed('Gym', _todayAt(1))]);
      await tester.pumpWidget(_app(const _SheetHost(), repo));
      await _openSheet(tester);
      await tester.tap(find.byKey(const ValueKey('track_chip_Gym')));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byKey(const ValueKey('track_text'))).controller!.text,
        'Gym',
      );
      expect(repo.writes, isEmpty);
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
      await tester.tap(find.byKey(const ValueKey('track_submit')));
      await tester.pumpAndSettle();
      expect(repo.rows[existing.id]!.text, 'Gym session');
      expect(repo.rows[existing.id]!.intendedMinutes, 45);

      await _openSheet(tester);
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
      expect(find.text("Track what you're doing"), findsOneWidget);

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
      expect(find.text("Track what you're doing"), findsOneWidget);
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

      expect(find.text('Scrolling'), findsOneWidget);
      expect(find.text('6m'), findsOneWidget);
      expect(find.byKey(const ValueKey('time_untracked_row')), findsOneWidget);
      expect(find.text('2h 11m untracked'), findsOneWidget);
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
      expect(find.text('45m'), findsOneWidget);
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
}
