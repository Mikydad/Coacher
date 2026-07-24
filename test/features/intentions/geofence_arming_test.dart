import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/core/context/geofence_signal.dart';
import 'package:sidepal/features/intentions/application/geofence_arming.dart';
import 'package:sidepal/features/intentions/domain/models/intention.dart';

/// Phase 6b — per-intention home-exit arming. All tests are pure Dart:
/// the channel is faked, prefs are mocked; the native side is exercised
/// by `flutter build ios` only.

class _FakeChannel extends GeofenceSignalChannel {
  String status = 'notDetermined';
  String requestOutcome = 'always';
  bool homeSet = false;
  HomeLocation? location = const HomeLocation(latitude: 1, longitude: 2);
  List<Map<String, dynamic>>? lastArmed;
  int armWrites = 0;

  @override
  Future<String> getAuthorizationStatus() async => status;

  @override
  Future<String> requestAccess() async {
    status = requestOutcome;
    return status;
  }

  @override
  Future<HomeLocation?> getCurrentLocation() async => location;

  @override
  Future<bool> setHome(HomeLocation home) async {
    homeSet = true;
    return true;
  }

  @override
  Future<void> clearHome() async {
    homeSet = false;
  }

  @override
  Future<bool> hasHome() async => homeSet;

  @override
  Future<void> setArmedIntents(List<Map<String, dynamic>> intents) async {
    lastArmed = intents;
    armWrites++;
  }
}

Intention _intention(
  String id, {
  IntentionStatus status = IntentionStatus.open,
  int windowStartMs = 1000,
  int windowEndMs = 100000,
  String title = 'Buy flowers',
}) {
  return Intention(
    id: id,
    title: title,
    rawUtterance: title,
    windowStartMs: windowStartMs,
    windowEndMs: windowEndMs,
    estimatedMinutes: 15,
    status: status,
    createdAtMs: 1,
    updatedAtMs: 1,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeChannel channel;
  late GeofenceArmingService service;
  DateTime now = DateTime.fromMillisecondsSinceEpoch(50000);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    channel = _FakeChannel();
    service = GeofenceArmingService(channel: channel, now: () => now);
  });

  Future<void> makeLive() async {
    channel.status = 'always';
    channel.homeSet = true;
    await GeofenceSignalSettings().setChoice(GeofenceSignalChoice.enabled);
  }

  group('geofenceNudgeCopy', () {
    test('is a question about the errand, never a POI claim', () {
      final copy = geofenceNudgeCopy('buy flowers');
      expect(copy['title'], 'Heading out?');
      expect(copy['body'], 'Buy flowers on the way?');
    });

    test('falls back for a blank title', () {
      expect(geofenceNudgeCopy('  ')['body'], 'Your promise on the way?');
    });
  });

  group('armedIntentPayload', () {
    test('carries id, prerendered copy, window and polite hours', () {
      final payload = armedIntentPayload(
        _intention('i1', windowStartMs: 5, windowEndMs: 99),
      );
      expect(payload['intentionId'], 'i1');
      expect(payload['title'], 'Heading out?');
      expect(payload['body'], 'Buy flowers on the way?');
      expect(payload['windowStartMs'], 5);
      expect(payload['windowEndMs'], 99);
      expect(payload['politeStartHour'], kGeofencePoliteStartHour);
      expect(payload['politeEndHour'], kGeofencePoliteEndHour);
    });
  });

  group('enable / decline', () {
    test('enable runs the OS ladder and remembers the grant', () {
      channel.requestOutcome = 'always';
      expect(service.enable(), completion(isTrue));
    });

    test('enable remembers a denial as declined', () async {
      channel.requestOutcome = 'denied';
      expect(await service.enable(), isFalse);
      expect(await service.getChoice(), GeofenceSignalChoice.declined);
    });

    test('decline clears home and the native armed list — off means off',
        () async {
      await makeLive();
      await service.decline();
      expect(channel.homeSet, isFalse);
      expect(channel.lastArmed, isEmpty);
      expect(await service.getChoice(), GeofenceSignalChoice.declined);
    });
  });

  group('isLive', () {
    test('requires choice + OS grant + home, in that order', () async {
      expect(await service.isLive(), isFalse); // undecided
      await GeofenceSignalSettings().setChoice(GeofenceSignalChoice.enabled);
      expect(await service.isLive(), isFalse); // no grant
      channel.status = 'always';
      expect(await service.isLive(), isFalse); // no home
      channel.homeSet = true;
      expect(await service.isLive(), isTrue);
    });
  });

  group('setHomeToCurrentLocation', () {
    test('reads one-shot location and anchors home', () async {
      channel.status = 'always';
      expect(await service.setHomeToCurrentLocation(), isTrue);
      expect(channel.homeSet, isTrue);
    });

    test('degrades to false when no location is available', () async {
      channel.status = 'always';
      channel.location = null;
      expect(await service.setHomeToCurrentLocation(), isFalse);
      expect(channel.homeSet, isFalse);
    });
  });

  group('syncArmed', () {
    test('arms only opted-in, open, unexpired intentions', () async {
      await makeLive();
      await service.optIn('opted');
      await service.optIn('done');
      await service.optIn('expired');
      await service.syncArmed([
        _intention('opted'),
        _intention('done', status: IntentionStatus.done),
        _intention('expired', windowEndMs: 40000), // now = 50000
        _intention('not-opted'),
      ]);
      expect(channel.lastArmed, hasLength(1));
      expect(channel.lastArmed!.single['intentionId'], 'opted');
    });

    test('prunes opt-ins for promises that closed or vanished', () async {
      await makeLive();
      await service.optIn('opted');
      await service.optIn('gone');
      await service.syncArmed([_intention('opted')]);
      expect(await service.optedInIds(), {'opted'});
    });

    test('does nothing while the signal is not live', () async {
      await service.optIn('opted');
      await service.syncArmed([_intention('opted')]);
      expect(channel.armWrites, 0);
      // The opt-in survives — arming starts once enable + home complete.
      expect(await service.optedInIds(), {'opted'});
    });

    test('optOut disarms on the next sync', () async {
      await makeLive();
      await service.optIn('opted');
      await service.syncArmed([_intention('opted')]);
      expect(channel.lastArmed, hasLength(1));
      await service.optOut('opted');
      await service.syncArmed([_intention('opted')]);
      expect(channel.lastArmed, isEmpty);
    });
  });
}
