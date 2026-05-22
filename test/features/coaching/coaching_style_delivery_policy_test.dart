import 'package:coach_for_life/features/coaching/application/coaching_style_delivery_policy.dart';
import 'package:coach_for_life/features/coaching/domain/models/coaching_style.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // ─── shouldBackOff ────────────────────────────────────────────────────────

  group('CoachingStyleDeliveryPolicy.shouldBackOff', () {
    group('supportive', () {
      test('does not back off at 0 ignored', () {
        expect(
          CoachingStyleDeliveryPolicy.shouldBackOff(CoachingStyle.supportive, 0),
          isFalse,
        );
      });

      test('does not back off at 1 ignored', () {
        expect(
          CoachingStyleDeliveryPolicy.shouldBackOff(CoachingStyle.supportive, 1),
          isFalse,
        );
      });

      test('backs off at exactly 2 ignored', () {
        expect(
          CoachingStyleDeliveryPolicy.shouldBackOff(CoachingStyle.supportive, 2),
          isTrue,
        );
      });

      test('backs off at 5 ignored', () {
        expect(
          CoachingStyleDeliveryPolicy.shouldBackOff(CoachingStyle.supportive, 5),
          isTrue,
        );
      });
    });

    group('balanced', () {
      test('never backs off at 0 ignored', () {
        expect(
          CoachingStyleDeliveryPolicy.shouldBackOff(CoachingStyle.balanced, 0),
          isFalse,
        );
      });

      test('never backs off at 10 ignored', () {
        expect(
          CoachingStyleDeliveryPolicy.shouldBackOff(CoachingStyle.balanced, 10),
          isFalse,
        );
      });
    });

    group('disciplined', () {
      test('never backs off', () {
        expect(
          CoachingStyleDeliveryPolicy.shouldBackOff(CoachingStyle.disciplined, 3),
          isFalse,
        );
      });
    });

    group('intense', () {
      test('never backs off even at high ignored count', () {
        expect(
          CoachingStyleDeliveryPolicy.shouldBackOff(CoachingStyle.intense, 99),
          isFalse,
        );
      });
    });
  });

  // ─── backOffDurationMinutes ────────────────────────────────────────────────

  group('CoachingStyleDeliveryPolicy.backOffDurationMinutes', () {
    test('supportive → 240 min (4 h)', () {
      expect(
        CoachingStyleDeliveryPolicy.backOffDurationMinutes(CoachingStyle.supportive),
        240,
      );
    });

    test('balanced → 0', () {
      expect(
        CoachingStyleDeliveryPolicy.backOffDurationMinutes(CoachingStyle.balanced),
        0,
      );
    });

    test('disciplined → 0', () {
      expect(
        CoachingStyleDeliveryPolicy.backOffDurationMinutes(CoachingStyle.disciplined),
        0,
      );
    });

    test('intense → 0', () {
      expect(
        CoachingStyleDeliveryPolicy.backOffDurationMinutes(CoachingStyle.intense),
        0,
      );
    });
  });

  // ─── continuesAtTailAfterFullEscalation ────────────────────────────────────

  group('CoachingStyleDeliveryPolicy.continuesAtTailAfterFullEscalation', () {
    test('supportive → false', () {
      expect(
        CoachingStyleDeliveryPolicy.continuesAtTailAfterFullEscalation(
          CoachingStyle.supportive,
        ),
        isFalse,
      );
    });

    test('balanced → false', () {
      expect(
        CoachingStyleDeliveryPolicy.continuesAtTailAfterFullEscalation(
          CoachingStyle.balanced,
        ),
        isFalse,
      );
    });

    test('disciplined → true', () {
      expect(
        CoachingStyleDeliveryPolicy.continuesAtTailAfterFullEscalation(
          CoachingStyle.disciplined,
        ),
        isTrue,
      );
    });

    test('intense → true', () {
      expect(
        CoachingStyleDeliveryPolicy.continuesAtTailAfterFullEscalation(
          CoachingStyle.intense,
        ),
        isTrue,
      );
    });
  });

  // ─── maxIgnoredBeforeGivingUp ─────────────────────────────────────────────

  group('CoachingStyleDeliveryPolicy.maxIgnoredBeforeGivingUp', () {
    test('supportive → 2', () {
      expect(
        CoachingStyleDeliveryPolicy.maxIgnoredBeforeGivingUp(
          CoachingStyle.supportive,
        ),
        2,
      );
    });

    test('balanced → null (never)', () {
      expect(
        CoachingStyleDeliveryPolicy.maxIgnoredBeforeGivingUp(
          CoachingStyle.balanced,
        ),
        isNull,
      );
    });

    test('disciplined → null', () {
      expect(
        CoachingStyleDeliveryPolicy.maxIgnoredBeforeGivingUp(
          CoachingStyle.disciplined,
        ),
        isNull,
      );
    });

    test('intense → null', () {
      expect(
        CoachingStyleDeliveryPolicy.maxIgnoredBeforeGivingUp(
          CoachingStyle.intense,
        ),
        isNull,
      );
    });
  });
}
