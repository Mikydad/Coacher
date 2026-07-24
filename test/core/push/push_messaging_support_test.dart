import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/push/push_messaging_support.dart';

void main() {
  group('dayKey', () {
    test('zero-pads to yyyy-mm-dd', () {
      expect(dayKey(DateTime(2026, 7, 4, 23, 59)), '2026-07-04');
      expect(dayKey(DateTime(2026, 12, 31)), '2026-12-31');
    });

    test('same day across times, different across midnight', () {
      expect(dayKey(DateTime(2026, 7, 4, 1)), dayKey(DateTime(2026, 7, 4, 22)));
      expect(
        dayKey(DateTime(2026, 7, 4, 23, 59)),
        isNot(dayKey(DateTime(2026, 7, 5, 0, 1))),
      );
    });
  });

  group('payloads', () {
    test('deviceTokenPayload seeds lastSeenMs so the device is seen today', () {
      final p = deviceTokenPayload(
        token: 'abc',
        platform: 'ios',
        nowMs: 42,
        tzOffsetMinutes: 180,
      );
      expect(p, {
        'token': 'abc',
        'platform': 'ios',
        'lastSeenMs': 42,
        'tzOffsetMinutes': 180,
        'updatedAtMs': 42,
      });
    });

    test('heartbeatPayload carries no token (merge-only) but refreshes tz', () {
      final p = heartbeatPayload(nowMs: 7, tzOffsetMinutes: -300);
      expect(p.containsKey('token'), isFalse);
      expect(p['lastSeenMs'], 7);
      expect(p['tzOffsetMinutes'], -300);
      expect(p['updatedAtMs'], 7);
    });
  });

  group('rescue payload tags', () {
    test('isRescueReplan true only for the tagged data push', () {
      expect(isRescueReplan({'type': 'intention_replan'}), isTrue);
      expect(isRescueReplan({'type': 'intention_rescue'}), isFalse);
    });

    test('isRescueNotification true only for the days-absent rescue', () {
      expect(isRescueNotification({'type': 'intention_rescue'}), isTrue);
      expect(isRescueNotification({'type': 'intention_replan'}), isFalse);
    });

    test('false for other/empty payloads', () {
      expect(isRescueReplan({'type': 'chat'}), isFalse);
      expect(isRescueReplan(const {}), isFalse);
      expect(isRescueNotification(const {}), isFalse);
    });
  });
}
