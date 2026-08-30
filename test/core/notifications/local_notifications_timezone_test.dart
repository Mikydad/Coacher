import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/notifications/local_notifications_service.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;

/// FR-R-06 / AUDIT §10 T3.
///
/// When `FlutterTimezone` fails, `tz.local` stays UTC and every
/// `zonedSchedule` interprets its wall-clock time as UTC — on a UTC+3 device
/// every reminder fires three hours late, for the whole session, behind
/// nothing but a debugPrint. The service must now record the failure so the
/// health row can show it, and retry on the next resume.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_timezone');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(() => tz_data.initializeTimeZones());
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  // One narrative test: the service is a singleton, so the phases share state
  // deliberately — that IS the behaviour under test (a failed session that
  // later recovers on resume).
  test(
    'timezone resolution fails loudly, recovers on retry, then stays resolved',
    () async {
      final service = LocalNotificationsService.instance;

      // ── Phase 1: the platform can't answer ──────────────────────────────
      messenger.setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'UNAVAILABLE', message: 'no tz');
      });

      expect(await service.ensureTimeZoneResolved(), isFalse);
      expect(service.isTimeZoneResolved, isFalse);
      expect(service.resolvedTimeZoneName, isNull);
      // The failure is recorded rather than swallowed — this is what the
      // reminder health row reads.
      expect(service.timeZoneFailureReason, isNotNull);

      // ── Phase 2: the next resume retries and succeeds ───────────────────
      messenger.setMockMethodCallHandler(
        channel,
        (call) async => 'Africa/Addis_Ababa',
      );

      expect(await service.ensureTimeZoneResolved(), isTrue);
      expect(service.isTimeZoneResolved, isTrue);
      expect(service.resolvedTimeZoneName, 'Africa/Addis_Ababa');
      expect(service.timeZoneFailureReason, isNull);

      // ── Phase 3: further resumes are a cheap no-op ──────────────────────
      // The channel breaks again; the resolved state must stand, and no
      // further platform call is made.
      var calls = 0;
      messenger.setMockMethodCallHandler(channel, (call) async {
        calls++;
        throw PlatformException(code: 'UNAVAILABLE');
      });

      expect(await service.ensureTimeZoneResolved(), isTrue);
      expect(calls, 0);
      expect(service.isTimeZoneResolved, isTrue);
    },
  );
}
