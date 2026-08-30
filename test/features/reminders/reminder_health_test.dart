import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/reminders/domain/models/reminder_health.dart';

/// FR-R-80. The health snapshot is a pure value type, so what counts as a
/// fault — and therefore what raises the quiet Home hint — is testable
/// without touching the OS.
void main() {
  ReminderHealth health({
    bool? permitted = true,
    int? pendingCount = 10,
    bool timeZoneResolved = true,
    bool isAndroid = false,
  }) => ReminderHealth(
    permitted: permitted,
    pendingCount: pendingCount,
    pendingCap: 56,
    timeZoneResolved: timeZoneResolved,
    timeZoneName: timeZoneResolved ? 'Africa/Addis_Ababa' : null,
    timeZoneFailureReason: timeZoneResolved ? null : 'channel unavailable',
    isAndroid: isAndroid,
  );

  group('a healthy install says nothing', () {
    test('no faults, no issues', () {
      final h = health();
      expect(h.isHealthy, isTrue);
      expect(h.faults, isEmpty);
      expect(h.issues, isEmpty);
      expect(h.summaryLine, 'All good');
    });
  });

  group('faults raise the Home hint', () {
    test('blocked permission is blocking', () {
      final h = health(permitted: false);
      expect(h.isHealthy, isFalse);
      expect(h.faults.first.severity, ReminderHealthSeverity.blocking);
      expect(h.summaryLine, 'Not allowed to notify');
    });

    test('an unresolved timezone is degraded, and names the reason', () {
      final h = health(timeZoneResolved: false);
      expect(h.isHealthy, isFalse);
      expect(h.faults.first.severity, ReminderHealthSeverity.degraded);
      expect(h.faults.first.detail, contains('channel unavailable'));
      expect(h.summaryLine, 'Timezone unresolved');
    });

    test('a full pending queue is degraded', () {
      final h = health(pendingCount: 56);
      expect(h.pendingNearCap, isTrue);
      expect(h.isHealthy, isFalse);
      expect(h.summaryLine, 'Queue full');
    });

    test('a queue under the cap is fine', () {
      expect(health(pendingCount: 55).pendingNearCap, isFalse);
      expect(health(pendingCount: 55).isHealthy, isTrue);
    });

    test('the worst fault leads', () {
      final h = health(permitted: false, timeZoneResolved: false);
      expect(h.faults.first.severity, ReminderHealthSeverity.blocking);
      expect(h.faults, hasLength(2));
    });
  });

  group('unknowns are not faults', () {
    test('an unreadable permission state does not cry wolf', () {
      final h = health(permitted: null);
      expect(h.isHealthy, isTrue);
      expect(h.summaryLine, 'Unknown');
    });

    test('an unreadable pending queue does not cry wolf', () {
      final h = health(pendingCount: null);
      expect(h.pendingNearCap, isFalse);
      expect(h.isHealthy, isTrue);
    });
  });

  group("Android's timing note is context, not a fault (D8)", () {
    test('it appears in issues but never in faults', () {
      final h = health(isAndroid: true);

      expect(h.issues, hasLength(1));
      expect(h.issues.single.severity, ReminderHealthSeverity.note);
      // The Home hint must stay silent for it.
      expect(h.faults, isEmpty);
      expect(h.isHealthy, isTrue);
      expect(h.summaryLine, 'All good');
    });

    test('it sits alongside a real fault without hiding it', () {
      final h = health(isAndroid: true, permitted: false);
      expect(h.issues, hasLength(2));
      expect(h.faults, hasLength(1));
      expect(h.faults.single.severity, ReminderHealthSeverity.blocking);
    });
  });

  group('summary line reports the worst thing first', () {
    test('permission outranks timezone outranks queue', () {
      expect(
        health(permitted: false, timeZoneResolved: false, pendingCount: 56)
            .summaryLine,
        'Not allowed to notify',
      );
      expect(
        health(timeZoneResolved: false, pendingCount: 56).summaryLine,
        'Timezone unresolved',
      );
      expect(health(pendingCount: 56).summaryLine, 'Queue full');
    });
  });
}
