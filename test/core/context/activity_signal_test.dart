import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidepal/core/context/activity_signal.dart';
import 'package:sidepal/core/context/calendar_signal.dart';
import 'package:sidepal/core/context/context_snapshot.dart';
import 'package:sidepal/core/context/context_snapshot_service.dart';
import 'package:sidepal/features/intentions/application/activity_moment_rules.dart';

/// Scripted channel fake — no platform, fully deterministic.
class FakeActivityChannel extends ActivitySignalChannel {
  FakeActivityChannel({
    this.status = 'notDetermined',
    this.grantOnRequest = true,
    this.reading,
  });

  String status;
  bool grantOnRequest;
  ActivityReading? reading;
  int requestCount = 0;

  @override
  Future<String> getAuthorizationStatus() async => status;

  @override
  Future<bool> requestAccess() async {
    requestCount++;
    if (grantOnRequest) status = 'authorized';
    return grantOnRequest;
  }

  @override
  Future<ActivityReading?> getCurrentActivity({
    Duration lookback = const Duration(minutes: 10),
  }) async => reading;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final now = DateTime(2026, 7, 24, 12);
  final nowMs = now.millisecondsSinceEpoch;

  ActivityReading walking({String confidence = 'high', int? capturedAtMs}) =>
      ActivityReading(
        kind: ActivityKind.walking,
        confidence: confidence,
        capturedAtMs: capturedAtMs ?? nowMs,
      );

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ActivityReading.fromMap', () {
    test('parses valid maps and rejects malformed ones', () {
      final ok = ActivityReading.fromMap({
        'kind': 'driving',
        'confidence': 'medium',
        'capturedAtMs': 123,
      });
      expect(ok, isNotNull);
      expect(ok!.kind, ActivityKind.driving);
      expect(ok.confidence, 'medium');

      expect(ActivityReading.fromMap({'kind': 'teleporting'}), isNull);
      expect(ActivityReading.fromMap({'capturedAtMs': 5}), isNull);
    });
  });

  group('ActivitySignalService', () {
    test('currentActivity is null until the user enables the signal',
        () async {
      final channel = FakeActivityChannel(
        status: 'authorized',
        reading: walking(),
      );
      final service = ActivitySignalService(channel: channel);
      expect(await service.currentActivity(now: now), isNull);
    });

    test('enable requests the OS grant and remembers the outcome', () async {
      final channel = FakeActivityChannel(
        grantOnRequest: true,
        reading: walking(),
      );
      final service = ActivitySignalService(channel: channel);
      expect(await service.enable(), isTrue);
      expect(channel.requestCount, 1);
      expect(await service.getChoice(), ActivitySignalChoice.enabled);
      final reading = await service.currentActivity(now: now);
      expect(reading?.kind, ActivityKind.walking);
    });

    test('OS denial is remembered as declined', () async {
      final channel = FakeActivityChannel(grantOnRequest: false);
      final service = ActivitySignalService(channel: channel);
      expect(await service.enable(), isFalse);
      expect(await service.getChoice(), ActivitySignalChoice.declined);
    });

    test('declined choice silences the ask forever', () async {
      final channel = FakeActivityChannel();
      final service = ActivitySignalService(channel: channel);
      await service.decline();
      expect(await service.shouldOfferAsk(), isFalse);
    });

    test('ask is not offered when the OS already denied', () async {
      final channel = FakeActivityChannel(status: 'denied');
      final service = ActivitySignalService(channel: channel);
      expect(await service.shouldOfferAsk(), isFalse);
    });

    test('low-confidence, unknown, and stale readings degrade to null '
        '(a wrong claim is worse than silence)', () async {
      final channel = FakeActivityChannel(grantOnRequest: true);
      final service = ActivitySignalService(channel: channel);
      await service.enable();

      channel.reading = walking(confidence: 'low');
      expect(await service.currentActivity(now: now), isNull);

      channel.reading = ActivityReading(
        kind: ActivityKind.unknown,
        confidence: 'high',
        capturedAtMs: nowMs,
      );
      expect(await service.currentActivity(now: now), isNull);

      channel.reading = walking(
        capturedAtMs: nowMs -
            ActivitySignalService.staleAfter.inMilliseconds -
            1,
      );
      expect(await service.currentActivity(now: now), isNull);

      channel.reading = walking(confidence: 'medium');
      expect(
        (await service.currentActivity(now: now))?.kind,
        ActivityKind.walking,
      );
    });
  });

  group('ContextSnapshot activity', () {
    test('coarse label appears only when the signal exists', () {
      final without = ContextSnapshot(capturedAtMs: nowMs);
      expect(without.hasActivitySignal, isFalse);
      expect(without.coarseLabels().where((l) => l.startsWith('activity_')),
          isEmpty);

      final with_ = ContextSnapshot(
        capturedAtMs: nowMs,
        activity: ActivityKind.walking,
      );
      expect(with_.hasActivitySignal, isTrue);
      expect(with_.coarseLabels(), contains('activity_walking'));
    });

    test('ContextSnapshotService captures the reading (nullable path)',
        () async {
      final channel = FakeActivityChannel(
        grantOnRequest: true,
        reading: walking(),
      );
      final activityService = ActivitySignalService(channel: channel);
      await activityService.enable();

      final service = ContextSnapshotService(
        scheduleMapsForDay: (_) async => const [],
        overrideMode: () async => null,
        isOnline: () async => true,
        calendarSignal: CalendarSignalService(),
        activitySignal: activityService,
        now: () => now,
      );
      final snapshot = await service.capture();
      expect(snapshot.activity, ActivityKind.walking);

      // No injected signal → field stays null (pre-Phase-6 shape).
      final bare = ContextSnapshotService(
        scheduleMapsForDay: (_) async => const [],
        overrideMode: () async => null,
        isOnline: () async => true,
        calendarSignal: CalendarSignalService(),
        now: () => now,
      );
      expect((await bare.capture()).activity, isNull);
    });
  });

  group('activity_moment_rules', () {
    test('no signal or still → everything allowed (pre-Phase-6 behavior)',
        () {
      expect(seizeAllowedFor(null, const []), isTrue);
      expect(seizeAllowedFor(ActivityKind.still, const ['errand']), isTrue);
    });

    test('walking allows only hands-free-compatible intentions', () {
      expect(seizeAllowedFor(ActivityKind.walking, const ['call']), isTrue);
      expect(
        seizeAllowedFor(ActivityKind.walking, const ['handsFree']),
        isTrue,
      );
      expect(
        seizeAllowedFor(ActivityKind.walking, const ['errand']),
        isFalse,
      );
      expect(seizeAllowedFor(ActivityKind.walking, const []), isFalse);
    });

    test('driving/cycling/running suppress every suggestion', () {
      for (final kind in [
        ActivityKind.driving,
        ActivityKind.cycling,
        ActivityKind.running,
      ]) {
        expect(seizeAllowedFor(kind, const ['call']), isFalse);
      }
    });

    test('motion phrase exists only for walking (provenance honesty)', () {
      expect(activityMomentPhrase(ActivityKind.walking), "you're walking");
      expect(activityMomentPhrase(ActivityKind.still), isNull);
      expect(activityMomentPhrase(null), isNull);
      expect(activityMomentPhrase(ActivityKind.driving), isNull);
    });
  });
}
