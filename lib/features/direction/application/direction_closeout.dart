import 'package:flutter/foundation.dart';

import '../../context_override/domain/models/interruption_level.dart';
import '../domain/direction_periods.dart';
import '../domain/models/direction_entry.dart';

/// The end-of-period close-out (Miko, 2026-09-19): when a period with a
/// written direction ends, one quiet local notification asks how it went
/// — Achieved / Partly / Not yet — and a tap opens the Direction page,
/// where the same three chips wait until answered. Month, quarter and
/// year alike. Supersedes the 2026-09-11 "no notification" decision for
/// this one moment; the rollover card stays as it was.
///
/// Pure timing here; the port does the scheduling so tests need no plugin.
abstract final class DirectionCloseout {
  /// Local hour on the period's LAST day. Evening: the day is mostly done,
  /// the answer is honest, and the new period has not started yet.
  static const int hourOfDay = 19;

  static const String payloadPrefix = 'direction:';

  static DateTime fireTimeFor(DirectionPeriod period) {
    final lastInstant = DateTime.fromMillisecondsSinceEpoch(period.endMs - 1);
    return DateTime(
      lastInstant.year,
      lastInstant.month,
      lastInstant.day,
      hourOfDay,
    );
  }

  /// Stable per entry id, in its own namespace.
  static int notificationId(String entryId) =>
      ('direction:$entryId').hashCode.abs() % 2147483647;

  static String payloadFor(String entryId) => '$payloadPrefix$entryId';

  /// Worth arming: written, unanswered, and its moment is still ahead.
  static bool shouldSchedule(DirectionEntry e, DateTime now) {
    if (e.isEmpty || e.outcome != null) return false;
    final period = e.period;
    if (period == null) return false;
    return fireTimeFor(period).isAfter(now);
  }

  static String titleFor(DirectionEntry e) => switch (e.horizon) {
    DirectionHorizon.month => 'Your month is ending',
    DirectionHorizon.quarter => 'Your quarter is ending',
    DirectionHorizon.year => 'Your year is ending',
  };

  static String bodyFor(DirectionEntry e) {
    final label = e.period?.label ?? e.periodKey;
    final text = e.text.length > 60 ? '${e.text.substring(0, 57)}…' : e.text;
    return '$label: "$text" — did you get there? Achieved, partly, or not '
        'yet. Tap to answer.';
  }
}

typedef CloseoutSchedule =
    Future<void> Function({
      required int id,
      required String title,
      required String body,
      required DateTime when,
      required String payload,
      required InterruptionLevel level,
    });

/// Keeps the OS in step with the entries: one notification per written,
/// unanswered direction whose period end is ahead; nothing for the rest.
/// Called on bootstrap and after every Direction write on this device.
class DirectionCloseoutScheduler {
  DirectionCloseoutScheduler({
    required CloseoutSchedule schedule,
    required Future<void> Function(int id) cancel,
    DateTime Function()? now,
  }) : _schedule = schedule,
       _cancel = cancel,
       _now = now ?? DateTime.now;

  final CloseoutSchedule _schedule;
  final Future<void> Function(int id) _cancel;
  final DateTime Function() _now;

  Future<void> rearm(Iterable<DirectionEntry> entries) async {
    final now = _now();
    for (final e in entries) {
      final id = DirectionCloseout.notificationId(e.id);
      try {
        if (DirectionCloseout.shouldSchedule(e, now)) {
          await _schedule(
            id: id,
            title: DirectionCloseout.titleFor(e),
            body: DirectionCloseout.bodyFor(e),
            when: DirectionCloseout.fireTimeFor(e.period!),
            payload: DirectionCloseout.payloadFor(e.id),
            level: InterruptionLevel.low,
          );
        } else {
          // Answered, cleared, or already past: nothing may stay armed.
          await _cancel(id);
        }
      } catch (err) {
        debugPrint('[DirectionCloseout] rearm ${e.id} failed: $err');
      }
    }
  }
}
