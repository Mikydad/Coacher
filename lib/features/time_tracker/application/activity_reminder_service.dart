import 'package:flutter/foundation.dart';

import '../../../core/utils/stable_id.dart';
import '../../context_override/domain/models/interruption_level.dart';
import '../../reminders/application/notification_route_resolver.dart';
import '../../reminders/domain/models/reminder_intent.dart';
import '../domain/models/activity_event.dart';

/// The intended-duration reminder (PRD/Time_Tracker §6, decisions 10–13):
/// "30m are up. What are you doing now?" — its purpose is to CONTINUE THE
/// TIMELINE, never to enforce. It rides the attention orchestrator through
/// the injected callbacks, so focus/sleep suppression, collisions and the
/// ledger apply exactly as for every other notification. The event itself
/// is always recorded; only the reminder can be suppressed.
///
/// One reminder per event, never re-armed after firing. Timer-sourced
/// events get none — the timer already owns that moment.
class ActivityReminderService {
  ActivityReminderService({
    required Future<void> Function(ReminderIntent intent) evaluate,
    required Future<void> Function(String entityId) cancel,
    DateTime Function()? now,
  }) : _evaluate = evaluate,
       _cancel = cancel,
       _now = now ?? DateTime.now;

  final Future<void> Function(ReminderIntent) _evaluate;
  final Future<void> Function(String) _cancel;
  final DateTime Function() _now;

  static const int importance = 45;

  static String bodyFor(ActivityEvent event) {
    final m = event.intendedMinutes ?? 0;
    final label = m % 60 == 0 && m >= 60
        ? '${m ~/ 60}h'
        : '${m}m';
    return "$label are up. What are you doing now?";
  }

  /// Returns true when a reminder was handed to the orchestrator.
  Future<bool> scheduleFor(ActivityEvent event) async {
    final intended = event.intendedMinutes;
    if (intended == null || !event.active) return false;
    if (event.isTimerSourced) return false;
    if (event.hasExplicitEnd) return false;
    final proposedAt = DateTime.fromMillisecondsSinceEpoch(
      event.startedAtMs,
    ).add(Duration(minutes: intended));
    if (!proposedAt.isAfter(_now())) return false; // backdated past its end
    final intent = ReminderIntent(
      id: StableId.generate('ri_activity'),
      entityId: event.id,
      entityKind: ReminderEntityKinds.activity,
      entityTitle: event.text,
      proposedAt: proposedAt,
      importance: importance,
      interruptionLevel: InterruptionLevel.low,
      enforcementMode: 'flexible',
      sourceReason: 'activity_intended_duration',
      bodyOverride: bodyFor(event),
      createdAtMs: _now().millisecondsSinceEpoch,
    );
    try {
      await _evaluate(intent);
      return true;
    } catch (e) {
      debugPrint('[ActivityReminder] schedule failed: $e');
      return false;
    }
  }

  Future<void> cancelFor(String eventId) async {
    try {
      await _cancel(eventId);
    } catch (e) {
      debugPrint('[ActivityReminder] cancel failed: $e');
    }
  }
}
