import 'dart:io' show Platform;

/// One thing wrong with reminder delivery, in the user's terms.
///
/// Severity is what decides whether the quiet Home hint appears: `blocking`
/// means reminders cannot reach the user at all, `degraded` means they will
/// arrive but wrong or incomplete, `note` is honest platform context that is
/// not a fault.
enum ReminderHealthSeverity { blocking, degraded, note }

class ReminderHealthIssue {
  const ReminderHealthIssue({
    required this.severity,
    required this.title,
    required this.detail,
  });

  final ReminderHealthSeverity severity;
  final String title;
  final String detail;
}

/// A snapshot of whether reminders can actually fire (FR-R-80).
///
/// Every field here was previously a `debugPrint` and nothing else — the
/// audit's L5, "zero user-facing health signals". A user whose notification
/// permission was revoked, or whose timezone failed to resolve, had no way to
/// learn why SidePal went quiet.
class ReminderHealth {
  const ReminderHealth({
    this.permitted,
    this.pendingCount,
    required this.pendingCap,
    required this.timeZoneResolved,
    this.timeZoneName,
    this.timeZoneFailureReason,
    this.lastReconciliationAtMs,
    this.lastReconciliationSummary,
    this.pushRegistered = false,
    this.isAndroid = false,
  });

  /// Null when the OS could not be asked — not the same as denied.
  final bool? permitted;

  /// Armed notifications in the OS pending queue; null when unreadable.
  final int? pendingCount;

  /// The safety margin under iOS's hard cap of 64.
  final int pendingCap;

  final bool timeZoneResolved;
  final String? timeZoneName;
  final String? timeZoneFailureReason;

  final int? lastReconciliationAtMs;
  final String? lastReconciliationSummary;

  /// Whether the [L-PUSH] server rescue net has this device registered.
  final bool pushRegistered;

  final bool isAndroid;

  static bool get platformIsAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false; // tests / web
    }
  }

  bool get pendingNearCap =>
      pendingCount != null && pendingCount! >= pendingCap;

  /// Everything currently wrong, worst first.
  List<ReminderHealthIssue> get issues {
    final out = <ReminderHealthIssue>[];

    if (permitted == false) {
      out.add(
        const ReminderHealthIssue(
          severity: ReminderHealthSeverity.blocking,
          title: 'Reminders are switched off in system settings',
          detail:
              'SidePal can still track what you miss, but nothing will '
              'appear on your screen until you re-enable notifications.',
        ),
      );
    }

    if (!timeZoneResolved) {
      out.add(
        ReminderHealthIssue(
          severity: ReminderHealthSeverity.degraded,
          title: 'Reminder times may be off',
          detail:
              "Your device's timezone could not be read, so reminders are "
              'being scheduled in UTC. SidePal retries each time you open '
              'it.${timeZoneFailureReason == null ? '' : ' ($timeZoneFailureReason)'}',
        ),
      );
    }

    if (pendingNearCap) {
      out.add(
        ReminderHealthIssue(
          severity: ReminderHealthSeverity.degraded,
          title: 'Too many reminders scheduled at once',
          detail:
              'iOS allows 64 pending reminders. Some of the furthest-out '
              'ones are being skipped until earlier ones fire.',
        ),
      );
    }

    // D8: Android is parked this wave. Gated to inexact scheduling — honest,
    // not silent.
    if (isAndroid) {
      out.add(
        const ReminderHealthIssue(
          severity: ReminderHealthSeverity.note,
          title: 'Reminders may arrive a few minutes late',
          detail:
              'On Android, SidePal schedules reminders inexactly so they '
              'survive battery optimisation. Exact timing is coming.',
        ),
      );
    }

    return out;
  }

  /// What the quiet Home hint reacts to: real faults only, never the
  /// platform note.
  List<ReminderHealthIssue> get faults => issues
      .where((i) => i.severity != ReminderHealthSeverity.note)
      .toList(growable: false);

  bool get isHealthy => faults.isEmpty;

  /// One-line summary for the Settings row's trailing text.
  String get summaryLine {
    if (permitted == false) return 'Not allowed to notify';
    if (!timeZoneResolved) return 'Timezone unresolved';
    if (pendingNearCap) return 'Queue full';
    if (permitted == null) return 'Unknown';
    return 'All good';
  }
}
