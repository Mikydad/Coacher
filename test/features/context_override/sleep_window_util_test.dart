import 'package:sidepal/features/context_override/application/sleep_window_util.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/context_override/domain/models/context_override.dart';
import 'package:sidepal/features/context_override/domain/models/user_attention_state.dart';

void main() {
  group('isWithinSleepWindow', () {
    // ─── Null / empty guards ─────────────────────────────────────────────
    test('returns false when both fields are null', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 2, 0), null, null),
        isFalse,
      );
    });
    test('returns false when start is null', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 2, 0), null, '07:00'),
        isFalse,
      );
    });
    test('returns false when end is null', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 2, 0), '23:00', null),
        isFalse,
      );
    });
    test('returns false for empty strings', () {
      expect(isWithinSleepWindow(DateTime(2026, 5, 18, 2, 0), '', ''), isFalse);
    });

    // ─── Same-day window: 01:00–07:00 ────────────────────────────────────
    test('inside same-day window', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 3, 30), '01:00', '07:00'),
        isTrue,
      );
    });
    test('at start boundary of same-day window', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 1, 0), '01:00', '07:00'),
        isTrue,
      );
    });
    test('just before same-day window', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 0, 59), '01:00', '07:00'),
        isFalse,
      );
    });
    test('at end boundary of same-day window (exclusive)', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 7, 0), '01:00', '07:00'),
        isFalse,
      );
    });
    test('after same-day window', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 9, 0), '01:00', '07:00'),
        isFalse,
      );
    });

    // ─── Midnight crossover: 23:00–07:00 ─────────────────────────────────
    test('inside crossover window — evening before midnight', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 23, 30), '23:00', '07:00'),
        isTrue,
      );
    });
    test('inside crossover window — after midnight', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 3, 0), '23:00', '07:00'),
        isTrue,
      );
    });
    test('at start of crossover window', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 23, 0), '23:00', '07:00'),
        isTrue,
      );
    });
    test('just before start of crossover window', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 22, 59), '23:00', '07:00'),
        isFalse,
      );
    });
    test('at end of crossover window (exclusive)', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 7, 0), '23:00', '07:00'),
        isFalse,
      );
    });
    test('outside crossover window — midday', () {
      expect(
        isWithinSleepWindow(DateTime(2026, 5, 18, 12, 0), '23:00', '07:00'),
        isFalse,
      );
    });
  });

  group('vacationWindowContains', () {
    // These are tested in context_override_service_test.dart via the full
    // service. This file focuses on the utility function in isolation
    // through the streak engine tests.
  });

  group('nextMorningAfter', () {
    test('late night rolls to the configured wake time tomorrow', () {
      expect(
        nextMorningAfter(DateTime(2026, 5, 18, 23, 30), '07:00'),
        DateTime(2026, 5, 19, 7, 0),
      );
    });
    test('early morning before wake time stays same day', () {
      expect(
        nextMorningAfter(DateTime(2026, 5, 18, 2, 0), '07:00'),
        DateTime(2026, 5, 18, 7, 0),
      );
    });
    test('exactly at wake time rolls to tomorrow (strictly after)', () {
      expect(
        nextMorningAfter(DateTime(2026, 5, 18, 7, 0), '07:00'),
        DateTime(2026, 5, 19, 7, 0),
      );
    });
    test('no configured window falls back to 07:00', () {
      expect(
        nextMorningAfter(DateTime(2026, 5, 18, 22, 0), null),
        DateTime(2026, 5, 19, 7, 0),
      );
    });
  });

  group('effectiveOverride honours a paused sleep window (2026-09-15)', () {
    UserAttentionState state({int? pausedUntilMs}) => UserAttentionState(
      id: kUserAttentionStateId,
      activeOverride: ContextOverride.none,
      manuallyMuted: false,
      updatedAtMs: 0,
      sleepWindowStart: '23:00',
      sleepWindowEnd: '07:00',
      sleepWindowPausedUntilMs: pausedUntilMs,
    );
    final night = DateTime(2026, 9, 15, 2, 0);
    final wake = DateTime(2026, 9, 15, 7, 0).millisecondsSinceEpoch;

    test('inside the window and not paused → sleep', () {
      expect(effectiveOverride(state(), night), ContextOverride.sleep);
    });
    test('inside the window but paused until wake → none', () {
      expect(
        effectiveOverride(state(pausedUntilMs: wake), night),
        ContextOverride.none,
      );
    });
    test('the pause lapses: next night is sleep again', () {
      expect(
        effectiveOverride(
          state(pausedUntilMs: wake),
          DateTime(2026, 9, 15, 23, 30),
        ),
        ContextOverride.sleep,
      );
    });
    test('a manual override still wins over the pause', () {
      final manual = UserAttentionState(
        id: kUserAttentionStateId,
        activeOverride: ContextOverride.focus,
        manuallyMuted: false,
        updatedAtMs: 0,
        sleepWindowStart: '23:00',
        sleepWindowEnd: '07:00',
        sleepWindowPausedUntilMs: wake,
      );
      expect(effectiveOverride(manual, night), ContextOverride.focus);
    });
  });
}
