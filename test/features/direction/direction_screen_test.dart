import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/direction/application/direction_providers.dart';
import 'package:sidepal/features/direction/data/direction_repository.dart';
import 'package:sidepal/features/direction/domain/direction_periods.dart';
import 'package:sidepal/features/direction/domain/models/direction_entry.dart';
import 'package:sidepal/features/direction/presentation/direction_screen.dart';
import 'package:sidepal/features/direction/presentation/direction_strip.dart';

/// In-memory stand-in: same contract as the Isar repository (no-op on
/// unchanged text, no empty rows), counts every real write.
class _FakeDirectionRepository extends DirectionRepository {
  _FakeDirectionRepository([Iterable<DirectionEntry> seed = const []]) {
    for (final e in seed) {
      _rows[e.id] = e;
    }
  }

  final Map<String, DirectionEntry> _rows = {};
  final _controller = StreamController<List<DirectionEntry>>.broadcast();
  final List<String> writes = [];
  int clock = 1000;

  List<DirectionEntry> get _snapshot => _rows.values.toList(growable: false);

  void _emit() => _controller.add(_snapshot);

  @override
  Stream<List<DirectionEntry>> watchAll() async* {
    yield _snapshot;
    yield* _controller.stream;
  }

  @override
  Future<List<DirectionEntry>> fetchAllOnce() async => _snapshot;

  @override
  Future<DirectionEntry?> get(DirectionHorizon horizon, String periodKey) async =>
      _rows[directionEntryId(horizon, periodKey)];

  @override
  Future<DirectionEntry?> setText(DirectionPeriod period, String text) async {
    final trimmed = text.trim();
    final existing = _rows[directionEntryId(period.horizon, period.key)];
    if (existing == null && trimmed.isEmpty) return null;
    if (existing != null && existing.text == trimmed) return existing;
    final entry = DirectionEntry.forPeriod(
      period,
      text: trimmed,
      nowMs: clock++,
      createdAtMs: existing?.createdAtMs,
    );
    _rows[entry.id] = entry;
    writes.add('${period.key}=$trimmed');
    _emit();
    return entry;
  }
}

final _now = DateTime(2026, 9, 11, 22);

Widget _wrap(Widget child, _FakeDirectionRepository repo) {
  return ProviderScope(
    overrides: [
      directionRepositoryProvider.overrideWithValue(repo),
      directionClockProvider.overrideWith((ref) => _now),
    ],
    child: MaterialApp(
      home: child,
      routes: {DirectionScreen.routeName: (_) => const DirectionScreen()},
    ),
  );
}

Finder _add(DirectionHorizon h) => find.byKey(ValueKey('direction_add_${h.name}'));
Finder _field(DirectionHorizon h) =>
    find.byKey(ValueKey('direction_field_${h.name}'));
Finder _save(DirectionHorizon h) =>
    find.byKey(ValueKey('direction_save_${h.name}'));
Finder _cancel(DirectionHorizon h) =>
    find.byKey(ValueKey('direction_cancel_${h.name}'));
Finder _statement(DirectionHorizon h) =>
    find.byKey(ValueKey('direction_statement_${h.name}'));
Finder _keep(DirectionHorizon h) =>
    find.byKey(ValueKey('direction_keep_${h.name}'));

DirectionEntry _seed(DirectionHorizon h, DateTime at, String text) =>
    DirectionEntry.forPeriod(
      DirectionPeriods.current(h, at),
      text: text,
      nowMs: 1,
    );

void main() {
  group('DirectionScreen entry', () {
    testWidgets('empty → + Add rows; Add → field; Save writes and closes',
        (tester) async {
      final repo = _FakeDirectionRepository();
      await tester.pumpWidget(_wrap(const DirectionScreen(), repo));
      await tester.pump();

      for (final h in DirectionHorizon.values) {
        expect(_add(h), findsOneWidget);
        expect(_field(h), findsNothing);
      }

      await tester.tap(_add(DirectionHorizon.month));
      await tester.pump();
      expect(_field(DirectionHorizon.month), findsOneWidget);
      expect(_add(DirectionHorizon.month), findsNothing);

      await tester.enterText(_field(DirectionHorizon.month), ' Launch SidePal ');
      expect(repo.writes, isEmpty, reason: 'nothing writes before Save');
      await tester.tap(_save(DirectionHorizon.month));
      await tester.pump();
      expect(repo.writes, ['2026-09=Launch SidePal']);
      expect(_field(DirectionHorizon.month), findsNothing);
      expect(_statement(DirectionHorizon.month), findsOneWidget);
      expect(find.text('Launch SidePal'), findsOneWidget);
    });

    testWidgets('Cancel discards without writing', (tester) async {
      final repo = _FakeDirectionRepository();
      await tester.pumpWidget(_wrap(const DirectionScreen(), repo));
      await tester.pump();
      await tester.tap(_add(DirectionHorizon.year));
      await tester.pump();
      await tester.enterText(_field(DirectionHorizon.year), 'Nope');
      await tester.tap(_cancel(DirectionHorizon.year));
      await tester.pump();
      expect(repo.writes, isEmpty);
      expect(_add(DirectionHorizon.year), findsOneWidget);
    });

    testWidgets('tapping the statement reopens the editor prefilled; '
        'Save with no change never writes', (tester) async {
      final repo = _FakeDirectionRepository([
        _seed(DirectionHorizon.month, _now, 'Launch'),
      ]);
      await tester.pumpWidget(_wrap(const DirectionScreen(), repo));
      await tester.pump();
      expect(_statement(DirectionHorizon.month), findsOneWidget);

      await tester.tap(_statement(DirectionHorizon.month));
      await tester.pump();
      expect(
        tester.widget<TextField>(_field(DirectionHorizon.month)).controller!.text,
        'Launch',
      );
      await tester.tap(_save(DirectionHorizon.month));
      await tester.pump();
      expect(repo.writes, isEmpty);
      expect(_statement(DirectionHorizon.month), findsOneWidget);
    });

    testWidgets('submitting from the keyboard saves', (tester) async {
      final repo = _FakeDirectionRepository();
      await tester.pumpWidget(_wrap(const DirectionScreen(), repo));
      await tester.pump();
      await tester.tap(_add(DirectionHorizon.quarter));
      await tester.pump();
      await tester.enterText(_field(DirectionHorizon.quarter), 'Ship it');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(repo.writes, ['2026-Q3=Ship it']);
    });

    testWidgets('safety net: leaving with a dirty open editor still saves',
        (tester) async {
      final repo = _FakeDirectionRepository();
      await tester.pumpWidget(_wrap(const DirectionScreen(), repo));
      await tester.pump();
      await tester.tap(_add(DirectionHorizon.quarter));
      await tester.pump();
      await tester.enterText(_field(DirectionHorizon.quarter), 'Ship it');
      await tester.pumpWidget(_wrap(const SizedBox(), repo));
      await tester.pump();
      expect(repo.writes, ['2026-Q3=Ship it']);
    });

    testWidgets('a stream update does not clobber an open editor',
        (tester) async {
      final repo = _FakeDirectionRepository();
      await tester.pumpWidget(_wrap(const DirectionScreen(), repo));
      await tester.pump();
      await tester.tap(_add(DirectionHorizon.month));
      await tester.pump();
      await tester.enterText(_field(DirectionHorizon.month), 'Mine');
      final sep = DirectionPeriods.current(DirectionHorizon.month, _now);
      repo._rows[directionEntryId(sep.horizon, sep.key)] =
          DirectionEntry.forPeriod(sep, text: 'Theirs', nowMs: 99);
      repo._emit();
      await tester.pump();
      expect(
        tester.widget<TextField>(_field(DirectionHorizon.month)).controller!.text,
        'Mine',
      );
      // Cancel reveals the remote value as the statement.
      await tester.tap(_cancel(DirectionHorizon.month));
      await tester.pump();
      expect(find.text('Theirs'), findsOneWidget);
    });
  });

  group('DirectionScreen suggestion', () {
    testWidgets('previous period shows as a suggestion; Keep carries it',
        (tester) async {
      final aug = DirectionPeriods.previous(
        DirectionPeriods.current(DirectionHorizon.month, _now),
      );
      final repo = _FakeDirectionRepository([
        DirectionEntry.forPeriod(aug, text: 'Get ready for launch', nowMs: 1),
      ]);
      await tester.pumpWidget(_wrap(const DirectionScreen(), repo));
      await tester.pump();

      expect(find.text('Last month: Get ready for launch'), findsOneWidget);
      // Still empty: + Add is offered, the suggestion is NOT the value.
      expect(_add(DirectionHorizon.month), findsOneWidget);
      expect(_statement(DirectionHorizon.month), findsNothing);

      await tester.tap(_keep(DirectionHorizon.month));
      await tester.pump();
      expect(repo.writes, ['2026-09=Get ready for launch']);
      expect(_statement(DirectionHorizon.month), findsOneWidget);
      expect(find.text('Last month: Get ready for launch'), findsNothing);
    });

    testWidgets('inside an open editor, typing hides the suggestion',
        (tester) async {
      final aug = DirectionPeriods.previous(
        DirectionPeriods.current(DirectionHorizon.month, _now),
      );
      final repo = _FakeDirectionRepository([
        DirectionEntry.forPeriod(aug, text: 'Old focus', nowMs: 1),
      ]);
      await tester.pumpWidget(_wrap(const DirectionScreen(), repo));
      await tester.pump();
      await tester.tap(_add(DirectionHorizon.month));
      await tester.pump();
      expect(find.text('Last month: Old focus'), findsOneWidget);
      await tester.enterText(_field(DirectionHorizon.month), 'New focus');
      await tester.pump();
      expect(find.text('Last month: Old focus'), findsNothing);
    });
  });

  group('DirectionStrip', () {
    testWidgets('empty → "Set your direction →", tap opens the page',
        (tester) async {
      final repo = _FakeDirectionRepository();
      await tester.pumpWidget(
        _wrap(const Scaffold(body: DirectionStrip()), repo),
      );
      await tester.pump();
      expect(find.text('Set your direction →'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('direction_strip')));
      await tester.pumpAndSettle();
      expect(find.byType(DirectionScreen), findsOneWidget);
    });

    testWidgets('falls back month → quarter → year', (tester) async {
      final repo = _FakeDirectionRepository([
        _seed(DirectionHorizon.year, _now, 'Year focus'),
        _seed(DirectionHorizon.quarter, _now, 'Quarter focus'),
      ]);
      await tester.pumpWidget(
        _wrap(const Scaffold(body: DirectionStrip()), repo),
      );
      await tester.pump();
      expect(find.text('This quarter: Quarter focus'), findsOneWidget);
    });

    testWidgets('a previous month is never shown as current', (tester) async {
      final aug = DirectionPeriods.previous(
        DirectionPeriods.current(DirectionHorizon.month, _now),
      );
      final repo = _FakeDirectionRepository([
        DirectionEntry.forPeriod(aug, text: 'August focus', nowMs: 1),
      ]);
      await tester.pumpWidget(
        _wrap(const Scaffold(body: DirectionStrip()), repo),
      );
      await tester.pump();
      expect(find.text('Set your direction →'), findsOneWidget);
    });
  });
}
