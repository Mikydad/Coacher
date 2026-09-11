import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/features/direction/application/direction_providers.dart';
import 'package:sidepal/features/direction/application/new_month_prompt.dart';
import 'package:sidepal/features/direction/data/direction_repository.dart';
import 'package:sidepal/features/direction/domain/direction_periods.dart';
import 'package:sidepal/features/direction/domain/models/direction_entry.dart';
import 'package:sidepal/features/direction/presentation/direction_screen.dart';
import 'package:sidepal/features/direction/presentation/new_month_direction_card.dart';

class _MemoryRepo extends DirectionRepository {
  _MemoryRepo([Iterable<DirectionEntry> seed = const []]) {
    for (final e in seed) {
      rows[e.id] = e;
    }
  }
  final Map<String, DirectionEntry> rows = {};
  final controller = StreamController<List<DirectionEntry>>.broadcast();

  @override
  Stream<List<DirectionEntry>> watchAll() async* {
    yield rows.values.toList();
    yield* controller.stream;
  }

  @override
  Future<DirectionEntry?> setText(DirectionPeriod period, String text) async {
    final e = DirectionEntry.forPeriod(period, text: text, nowMs: 1);
    rows[e.id] = e;
    controller.add(rows.values.toList());
    return e;
  }
}

final _sept = DateTime(2026, 9, 11, 9);

Widget _wrap(_MemoryRepo repo, DateTime now) {
  return ProviderScope(
    overrides: [
      directionRepositoryProvider.overrideWithValue(repo),
      directionClockProvider.overrideWith((ref) => now),
      newMonthPromptControllerProvider.overrideWith(
        (ref) => NewMonthPromptController(now: () => now),
      ),
    ],
    child: MaterialApp(
      home: const Scaffold(body: NewMonthDirectionCard()),
      routes: {DirectionScreen.routeName: (_) => const DirectionScreen()},
    ),
  );
}

void main() {
  group('decideNewMonthPrompt', () {
    test('table', () {
      NewMonthPromptDecision d({
        bool loaded = true,
        String? handled,
        String current = '2026-09',
        bool hasText = false,
      }) => decideNewMonthPrompt(
        loaded: loaded,
        handledMonthKey: handled,
        currentMonthKey: current,
        monthHasText: hasText,
      );

      expect(d(loaded: false), NewMonthPromptDecision.hide);
      expect(d(handled: null), NewMonthPromptDecision.seed);
      expect(d(handled: '2026-09'), NewMonthPromptDecision.hide);
      expect(d(handled: '2026-08'), NewMonthPromptDecision.show);
      expect(d(handled: '2026-08', hasText: true), NewMonthPromptDecision.hide);
      // Next month after a dismissal → shows again.
      expect(
        d(handled: '2026-09', current: '2026-10'),
        NewMonthPromptDecision.show,
      );
    });
  });

  group('NewMonthPromptController', () {
    test('fresh install seeds the current month and persists it', () async {
      SharedPreferences.setMockInitialValues({});
      final c = NewMonthPromptController(now: () => _sept);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.loaded, isTrue);
      expect(c.state.handledMonthKey, '2026-09');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kDirectionMonthCardHandledPrefsKey), '2026-09');
      c.dispose();
    });

    test('markHandled persists', () async {
      SharedPreferences.setMockInitialValues({
        kDirectionMonthCardHandledPrefsKey: '2026-08',
      });
      final c = NewMonthPromptController(now: () => _sept);
      await Future<void>.delayed(Duration.zero);
      expect(c.state.handledMonthKey, '2026-08');
      await c.markHandled('2026-09');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kDirectionMonthCardHandledPrefsKey), '2026-09');
      c.dispose();
    });
  });

  group('NewMonthDirectionCard', () {
    testWidgets('fresh install: nothing on day one', (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_wrap(_MemoryRepo(), _sept));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('new_month_direction_card')),
          findsNothing);
    });

    testWidgets('new month + empty → shows with the month name; × dismisses',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        kDirectionMonthCardHandledPrefsKey: '2026-08',
      });
      await tester.pumpWidget(_wrap(_MemoryRepo(), _sept));
      await tester.pump();
      await tester.pump();
      expect(find.text("What's your focus for September?"), findsOneWidget);
      expect(find.text('+ Add your direction'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('new_month_direction_dismiss')));
      await tester.pump();
      expect(find.byKey(const ValueKey('new_month_direction_card')),
          findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kDirectionMonthCardHandledPrefsKey), '2026-09');
    });

    testWidgets('CTA opens the Direction page and handles the month',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        kDirectionMonthCardHandledPrefsKey: '2026-08',
      });
      await tester.pumpWidget(_wrap(_MemoryRepo(), _sept));
      await tester.pump();
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('new_month_direction_cta')));
      await tester.pumpAndSettle();
      expect(find.byType(DirectionScreen), findsOneWidget);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kDirectionMonthCardHandledPrefsKey), '2026-09');
    });

    testWidgets('month already has a direction → hidden and handled',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        kDirectionMonthCardHandledPrefsKey: '2026-08',
      });
      final sep = DirectionPeriods.current(DirectionHorizon.month, _sept);
      final repo = _MemoryRepo([
        DirectionEntry.forPeriod(sep, text: 'Launch', nowMs: 1),
      ]);
      await tester.pumpWidget(_wrap(repo, _sept));
      await tester.pump();
      await tester.pump();
      expect(find.byKey(const ValueKey('new_month_direction_card')),
          findsNothing);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(kDirectionMonthCardHandledPrefsKey), '2026-09');
    });

    testWidgets('January reads "for January" — no new-year variant',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        kDirectionMonthCardHandledPrefsKey: '2026-12',
      });
      await tester.pumpWidget(_wrap(_MemoryRepo(), DateTime(2027, 1, 1, 8)));
      await tester.pump();
      await tester.pump();
      expect(find.text("What's your focus for January?"), findsOneWidget);
    });
  });
}
