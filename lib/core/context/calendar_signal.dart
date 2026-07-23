import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Ephemeral device-calendar signal (humanizing Phase 4b, PRD §9 Tier 1).
///
/// Privacy contract, enforced by construction: the native channel
/// (ios/Runner/CalendarSignal.swift) returns ONLY busy intervals —
/// start/end/allDay. No titles, no locations, no identifiers. Intervals
/// live in memory for the duration of one computation and are never
/// written to Isar, Firestore, or anywhere else.
///
/// The user's choice is device-local by design (a device permission must
/// not sync to other devices) and tri-state: undecided → the one-time ask
/// may show; declined → remembered, never re-asked (Profile toggle can
/// re-enable); enabled → signal flows when the OS grant allows.

/// One busy span from the device calendar. All times are epoch ms.
@immutable
class CalendarBusyInterval {
  const CalendarBusyInterval({
    required this.startMs,
    required this.endMs,
    this.allDay = false,
  });

  final int startMs;
  final int endMs;
  final bool allDay;

  static CalendarBusyInterval? fromMap(Map<Object?, Object?> map) {
    final start = map['startMs'];
    final end = map['endMs'];
    if (start is! int || end is! int || end <= start) return null;
    return CalendarBusyInterval(
      startMs: start,
      endMs: end,
      allDay: map['allDay'] == true,
    );
  }

  @override
  String toString() => 'CalendarBusyInterval($startMs–$endMs'
      '${allDay ? ', allDay' : ''})';
}

enum CalendarSignalChoice { undecided, enabled, declined }

/// Device-local persistence of the user's calendar decision.
class CalendarSignalSettings {
  static const prefsKey = 'calendar_signal_choice_v1';

  Future<CalendarSignalChoice> getChoice() async {
    final prefs = await SharedPreferences.getInstance();
    return switch (prefs.getString(prefsKey)) {
      'enabled' => CalendarSignalChoice.enabled,
      'declined' => CalendarSignalChoice.declined,
      _ => CalendarSignalChoice.undecided,
    };
  }

  Future<void> setChoice(CalendarSignalChoice choice) async {
    final prefs = await SharedPreferences.getInstance();
    if (choice == CalendarSignalChoice.undecided) {
      await prefs.remove(prefsKey);
    } else {
      await prefs.setString(prefsKey, choice.name);
    }
  }
}

/// Thin wrapper over the native channel. Every call degrades to "signal
/// unavailable" on platforms without the channel (Android, tests).
class CalendarSignalChannel {
  static const _channel = MethodChannel('sidepal/calendar_signal');

  /// 'notDetermined' | 'denied' | 'authorized' | 'unavailable'.
  Future<String> getAuthorizationStatus() async {
    try {
      return await _channel.invokeMethod<String>('getAuthorizationStatus') ??
          'unavailable';
    } catch (_) {
      return 'unavailable';
    }
  }

  Future<bool> requestAccess() async {
    try {
      return await _channel.invokeMethod<bool>('requestAccess') ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<List<CalendarBusyInterval>> getBusyIntervals(
    DateTime start,
    DateTime end,
  ) async {
    try {
      final raw = await _channel.invokeListMethod<Map<Object?, Object?>>(
        'getBusyIntervals',
        {
          'startMs': start.millisecondsSinceEpoch,
          'endMs': end.millisecondsSinceEpoch,
        },
      );
      if (raw == null) return const [];
      return [for (final map in raw) ?CalendarBusyInterval.fromMap(map)];
    } catch (e) {
      debugPrint('[CalendarSignal] busy fetch failed: $e');
      return const [];
    }
  }
}

/// The one consumer-facing API: choice + OS grant + fetch, with nullable
/// degradation — `null` means "the signal doesn't exist right now" and
/// callers plan without it (scripted copy, no claims).
class CalendarSignalService {
  CalendarSignalService({
    CalendarSignalSettings? settings,
    CalendarSignalChannel? channel,
  }) : _settings = settings ?? CalendarSignalSettings(),
       _channel = channel ?? CalendarSignalChannel();

  final CalendarSignalSettings _settings;
  final CalendarSignalChannel _channel;

  Future<CalendarSignalChoice> getChoice() => _settings.getChoice();

  /// Whether the ask card may show: user undecided AND the OS could still
  /// grant (not already denied at system level).
  Future<bool> shouldOfferAsk() async {
    if (await _settings.getChoice() != CalendarSignalChoice.undecided) {
      return false;
    }
    final status = await _channel.getAuthorizationStatus();
    return status == 'notDetermined' || status == 'authorized';
  }

  /// User said yes: request the OS grant, remember the outcome.
  /// Returns true when the signal is now live.
  Future<bool> enable() async {
    final status = await _channel.getAuthorizationStatus();
    var granted = status == 'authorized';
    if (status == 'notDetermined') {
      granted = await _channel.requestAccess();
    }
    await _settings.setChoice(
      granted ? CalendarSignalChoice.enabled : CalendarSignalChoice.declined,
    );
    return granted;
  }

  /// User said no (card "Not now" or Profile toggle off) — remembered,
  /// never re-asked.
  Future<void> decline() =>
      _settings.setChoice(CalendarSignalChoice.declined);

  /// Busy intervals for [start, end), or **null when the signal is
  /// unavailable** (declined, undecided, OS-denied, non-iOS). All-day
  /// events are dropped — a birthday doesn't occupy time slots.
  Future<List<CalendarBusyInterval>?> busyIntervals(
    DateTime start,
    DateTime end,
  ) async {
    if (await _settings.getChoice() != CalendarSignalChoice.enabled) {
      return null;
    }
    if (await _channel.getAuthorizationStatus() != 'authorized') return null;
    final intervals = await _channel.getBusyIntervals(start, end);
    return intervals.where((i) => !i.allDay).toList(growable: false);
  }
}
