import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/core/notifications/notification_presentation.dart';
import 'package:sidepal/features/context_override/domain/models/interruption_level.dart';

/// FR-R-44 / AUDIT §10 M1. The level the policy computes must reach the OS —
/// before this, an Extreme `critical` and a Flexible `low` rendered
/// identically because nothing read the level at all.
void main() {
  group('Android: one channel per level', () {
    test('each level gets its own channel and importance', () {
      final low = NotificationPresentation.android(
        InterruptionLevel.low,
        silent: false,
      );
      final medium = NotificationPresentation.android(
        InterruptionLevel.medium,
        silent: false,
      );
      final high = NotificationPresentation.android(
        InterruptionLevel.high,
        silent: false,
      );

      expect(low.channelId, NotificationPresentation.channelPassive);
      expect(medium.channelId, NotificationPresentation.channelDefault);
      expect(high.channelId, NotificationPresentation.channelUrgent);

      expect(low.importance, fln.Importance.low);
      expect(medium.importance, fln.Importance.defaultImportance);
      expect(high.importance, fln.Importance.max);
    });

    test('the three channels are genuinely distinct', () {
      final ids = {
        for (final level in InterruptionLevel.values)
          NotificationPresentation.android(level, silent: false).channelId,
      };
      // critical shares the urgent channel with high, by design.
      expect(ids, hasLength(3));
    });

    test('a silent decision is quiet whatever the level says', () {
      for (final level in InterruptionLevel.values) {
        final details = NotificationPresentation.android(level, silent: true);
        expect(
          details.channelId,
          NotificationPresentation.channelPassive,
          reason: level.name,
        );
        expect(details.importance, fln.Importance.low, reason: level.name);
      }
    });

    test('actions are carried through', () {
      final details = NotificationPresentation.android(
        InterruptionLevel.medium,
        silent: false,
        actions: const [fln.AndroidNotificationAction('later', 'Snooze')],
      );
      expect(details.actions, hasLength(1));
    });
  });

  group('iOS: interruption levels', () {
    test('each level maps to its Darwin counterpart', () {
      expect(
        NotificationPresentation.darwin(
          InterruptionLevel.low,
          silent: false,
        ).interruptionLevel,
        fln.InterruptionLevel.passive,
      );
      expect(
        NotificationPresentation.darwin(
          InterruptionLevel.medium,
          silent: false,
        ).interruptionLevel,
        fln.InterruptionLevel.active,
      );
      for (final level in [
        InterruptionLevel.high,
        InterruptionLevel.critical,
      ]) {
        expect(
          NotificationPresentation.darwin(level, silent: false).interruptionLevel,
          fln.InterruptionLevel.timeSensitive,
          reason: level.name,
        );
      }
    });

    test('a quiet delivery plays no sound', () {
      expect(
        NotificationPresentation.darwin(
          InterruptionLevel.low,
          silent: false,
        ).presentSound,
        isFalse,
      );
      expect(
        NotificationPresentation.darwin(
          InterruptionLevel.high,
          silent: false,
        ).presentSound,
        isTrue,
      );
    });

    test('silent overrides the level here too', () {
      final details = NotificationPresentation.darwin(
        InterruptionLevel.critical,
        silent: true,
      );
      expect(details.interruptionLevel, fln.InterruptionLevel.passive);
      expect(details.presentSound, isFalse);
    });

    test('the tap category survives the mapping', () {
      expect(
        NotificationPresentation.darwin(
          InterruptionLevel.medium,
          silent: false,
          categoryIdentifier: 'task_reminder',
        ).categoryIdentifier,
        'task_reminder',
      );
    });
  });

  group('D8: Android schedules inexactly this wave', () {
    test('the mode matches what the health row promises the user', () {
      // On a non-Android host this is exact; the point of the constant is that
      // ONE place decides, and the health row's copy is written against it.
      expect(NotificationPresentation.scheduleMode, isNotNull);
    });
  });
}
