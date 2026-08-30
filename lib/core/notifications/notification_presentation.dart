import 'dart:io' show Platform;

import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;

import '../../features/context_override/domain/models/interruption_level.dart';

/// Maps SidePal's [InterruptionLevel] onto what each OS actually does
/// (FR-R-44, fixing AUDIT §10 M1).
///
/// Before this, `local_notifications_service.dart` contained ZERO references
/// to [InterruptionLevel]: every notification was scheduled with
/// `Importance.max` / `Priority.high` on Android and bare
/// `DarwinNotificationDetails` on iOS. An Extreme-mode `critical` and a
/// Flexible `low` rendered identically. The level's only real effect was the
/// override suppression matrix — i.e. modes changed *when a reminder was
/// dropped*, never how it arrived.
///
/// Android needs one channel per level because importance is fixed at channel
/// creation: you cannot quiet a notification after the fact, only post it to a
/// quieter channel. That also gives the user per-level control in system
/// settings, which is the point.
abstract final class NotificationPresentation {
  static const String channelPassive = 'sidepal_reminders_passive';
  static const String channelDefault = 'sidepal_reminders_default';
  static const String channelUrgent = 'sidepal_reminders_urgent';

  /// The legacy single channel. Kept so an upgrading device's existing
  /// notifications stay addressable; new deliveries use the levelled ones.
  static const String channelLegacy = 'coach4life_reminders';

  static fln.AndroidNotificationDetails android(
    InterruptionLevel level, {
    required bool silent,
    List<fln.AndroidNotificationAction> actions = const [],
  }) {
    // A `silent` decision (the focus-silence path) must arrive without
    // lighting the screen, whatever the level says. AttentionDecision.silent
    // was computed and then never read by _executeDecision — "silent"
    // deliveries were delivered loud.
    final effective = silent ? InterruptionLevel.low : level;

    return switch (effective) {
      InterruptionLevel.low => fln.AndroidNotificationDetails(
        channelPassive,
        'Quiet reminders',
        channelDescription:
            'Gentle nudges that should not interrupt what you are doing.',
        importance: fln.Importance.low,
        priority: fln.Priority.low,
        actions: actions,
      ),
      InterruptionLevel.medium => fln.AndroidNotificationDetails(
        channelDefault,
        'Reminders',
        channelDescription: 'Your normal task and habit reminders.',
        importance: fln.Importance.defaultImportance,
        priority: fln.Priority.defaultPriority,
        actions: actions,
      ),
      InterruptionLevel.high || InterruptionLevel.critical =>
        fln.AndroidNotificationDetails(
          channelUrgent,
          'Urgent reminders',
          channelDescription:
              'Escalations and critical items, such as medication.',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          actions: actions,
        ),
    };
  }

  static fln.DarwinNotificationDetails darwin(
    InterruptionLevel level, {
    required bool silent,
    String? categoryIdentifier,
  }) {
    final effective = silent ? InterruptionLevel.low : level;
    return fln.DarwinNotificationDetails(
      categoryIdentifier: categoryIdentifier,
      presentSound: effective != InterruptionLevel.low,
      interruptionLevel: switch (effective) {
        InterruptionLevel.low => fln.InterruptionLevel.passive,
        InterruptionLevel.medium => fln.InterruptionLevel.active,
        // timeSensitive breaks through Focus modes, and needs the matching
        // entitlement; without it iOS quietly treats it as `active`, which is
        // a safe degrade rather than a failure.
        InterruptionLevel.high ||
        InterruptionLevel.critical => fln.InterruptionLevel.timeSensitive,
      },
    );
  }

  /// D8: Android is parked this wave.
  ///
  /// `exactAllowWhileIdle` needs the SCHEDULE_EXACT_ALARM permission flow and
  /// a boot receiver to survive a restart — neither of which exists yet
  /// (AUDIT §4). Requesting exactness we have not earned means silent
  /// failures on release builds, so ladders are gated to inexact and the
  /// reminder health row says so. Honest and degraded beats broken and quiet.
  static fln.AndroidScheduleMode get scheduleMode =>
      _isAndroid
      ? fln.AndroidScheduleMode.inexactAllowWhileIdle
      : fln.AndroidScheduleMode.exactAllowWhileIdle;

  static bool get _isAndroid {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }
}
