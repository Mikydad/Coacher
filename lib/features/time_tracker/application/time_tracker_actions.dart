import '../data/activity_event_repository.dart';
import '../domain/models/activity_event.dart';
import 'activity_reminder_service.dart';

/// The write-side use cases the sheet and the page call, so reminder
/// bookkeeping (§6) can never be forgotten at a call site:
///
/// - log     → save, cancel the previous ongoing event's reminder, arm this
///             one's if it has an intended duration;
/// - update  → save, cancel + re-arm (still relevant only while the event
///             has no explicit end);
/// - delete  → tombstone + cancel;
/// - end     → explicit end + cancel.
///
/// All writes are Isar-then-outbox; nothing here awaits the network.
class TimeTrackerActions {
  const TimeTrackerActions({required this.repository, required this.reminders});

  final ActivityEventRepository repository;
  final ActivityReminderService reminders;

  Future<ActivityEvent> log(ActivityEvent event) async {
    final previous = await repository.fetchLatestOnce();
    final saved = await repository.upsert(event);
    if (previous != null && previous.id != saved.id) {
      // The next log ends the previous activity — its "are up" reminder
      // has nothing left to ask.
      await reminders.cancelFor(previous.id);
    }
    await reminders.scheduleFor(saved);
    return saved;
  }

  Future<ActivityEvent> update(ActivityEvent event) async {
    final saved = await repository.upsert(event);
    await reminders.cancelFor(saved.id);
    await reminders.scheduleFor(saved);
    return saved;
  }

  Future<void> delete(String id) async {
    await repository.softDelete(id);
    await reminders.cancelFor(id);
  }

  Future<ActivityEvent?> end(String id, int endedAtMs) async {
    final saved = await repository.setEnd(id, endedAtMs);
    await reminders.cancelFor(id);
    return saved;
  }
}
