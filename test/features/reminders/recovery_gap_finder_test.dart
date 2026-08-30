import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/reminders/application/ladder_compiler.dart';
import 'package:sidepal/features/reminders/application/recovery_gap_finder.dart';

/// FR-R-53 / §3.6. The recovery summary is the only push the recovery system
/// gets, so where it lands matters: a summary 30 seconds before a meeting is
/// just another interruption.
void main() {
  final dayEnd = DateTime(2026, 8, 30, 21, 0);

  DateTime? find({
    required DateTime now,
    List<DateTime> upcomingStarts = const [],
    List<ShieldWindow> shields = const [],
    DateTime? end,
  }) => RecoveryGapFinder.find(
    now: now,
    dayEnd: end ?? dayEnd,
    upcomingStarts: upcomingStarts,
    shields: shields,
  );

  group('placement', () {
    test('lands ahead of now, never instantly', () {
      final now = DateTime(2026, 8, 30, 14, 0);
      final at = find(now: now)!;

      expect(at.isAfter(now.add(const Duration(minutes: 15))), isTrue);
      expect(at, DateTime(2026, 8, 30, 14, 30));
    });

    test('rounds to a tidy time rather than an arbitrary second', () {
      final at = find(now: DateTime(2026, 8, 30, 14, 3, 27))!;
      expect(at.minute % 15, 0);
      expect(at.second, 0);
    });
  });

  group('it respects the same boundary the ladder does', () {
    test('it will not land in the run-up to a scheduled item', () {
      // A 14:30 item makes 14:10 through 14:30 quiet — the start moment
      // included, because arriving exactly as something begins is the
      // interruption this rule exists to prevent.
      final at = find(
        now: DateTime(2026, 8, 30, 14, 0),
        upcomingStarts: [DateTime(2026, 8, 30, 14, 30)],
      )!;

      expect(at.isAfter(DateTime(2026, 8, 30, 14, 30)), isTrue);
      expect(at, DateTime(2026, 8, 30, 14, 45));
    });

    test('the start moment itself is not a free gap', () {
      final at = find(
        now: DateTime(2026, 8, 30, 14, 0),
        upcomingStarts: [DateTime(2026, 8, 30, 14, 30)],
      );
      expect(at, isNot(DateTime(2026, 8, 30, 14, 30)));
    });

    test('it skips past several packed items', () {
      final at = find(
        now: DateTime(2026, 8, 30, 14, 0),
        upcomingStarts: [
          DateTime(2026, 8, 30, 14, 30),
          DateTime(2026, 8, 30, 15, 0),
          DateTime(2026, 8, 30, 15, 30),
        ],
      );
      expect(at, isNotNull);
      for (final start in [
        DateTime(2026, 8, 30, 14, 30),
        DateTime(2026, 8, 30, 15, 0),
        DateTime(2026, 8, 30, 15, 30),
      ]) {
        final quietFrom = start.subtract(const Duration(minutes: 20));
        expect(
          !at!.isBefore(quietFrom) && !at.isAfter(start),
          isFalse,
          reason: 'landed inside the run-up to $start',
        );
      }
    });
  });

  group('shields', () {
    test('it will not land inside a sleep window', () {
      final at = find(
        now: DateTime(2026, 8, 30, 14, 0),
        shields: [
          ShieldWindow(
            start: DateTime(2026, 8, 30, 14, 10),
            end: DateTime(2026, 8, 30, 16, 0),
            reason: 'sleep',
          ),
        ],
      )!;
      expect(at, DateTime(2026, 8, 30, 16, 0));
    });
  });

  group('the day can simply have no room', () {
    test('too close to the end of the day yields nothing', () {
      expect(find(now: DateTime(2026, 8, 30, 20, 50)), isNull);
    });

    test('a wall-to-wall shield yields nothing', () {
      expect(
        find(
          now: DateTime(2026, 8, 30, 14, 0),
          shields: [
            ShieldWindow(
              start: DateTime(2026, 8, 30, 0, 0),
              end: DateTime(2026, 8, 31, 0, 0),
              reason: 'sleep',
            ),
          ],
        ),
        isNull,
      );
    });

    test('after the day has ended, nothing', () {
      expect(find(now: DateTime(2026, 8, 30, 22, 0)), isNull);
    });

    test('the search terminates on a pathological plan', () {
      // Every 15 minutes blocked, all day. Must return null, not hang.
      final starts = <DateTime>[
        for (var m = 0; m < 24 * 60; m += 15)
          DateTime(2026, 8, 30).add(Duration(minutes: m + 20)),
      ];
      expect(find(now: DateTime(2026, 8, 30, 8, 0), upcomingStarts: starts),
          isNull);
    });
  });
}
