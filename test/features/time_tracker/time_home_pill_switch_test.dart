import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';
import 'package:sidepal/features/profile/application/profile_preference_service.dart';
import 'package:sidepal/features/profile/application/profile_providers.dart';
import 'package:sidepal/features/profile/data/profile_preference_repository.dart';
import 'package:sidepal/features/profile/domain/models/user_profile_preference.dart';
import 'package:sidepal/features/time_tracker/application/activity_reminder_service.dart';
import 'package:sidepal/features/time_tracker/application/time_tracker_providers.dart';
import 'package:sidepal/features/time_tracker/data/activity_event_repository.dart';
import 'package:sidepal/features/time_tracker/domain/models/activity_event.dart';
import 'package:sidepal/features/time_tracker/presentation/time_screen.dart';
import 'package:sidepal/features/time_tracker/presentation/track_pill.dart';

/// The Time page's footer switch decides one thing — whether Home shows the
/// tracking pill (Miko, 2026-09-18) — and it is a plain local write.

class _MemoryPrefs implements ProfilePreferenceRepository {
  UserProfilePreference? stored;

  @override
  Future<UserProfilePreference?> getPreference() async => stored;

  @override
  Future<void> upsertPreference(UserProfilePreference pref) async =>
      stored = pref;

  @override
  Stream<UserProfilePreference?> watchPreference() => Stream.value(stored);
}

/// Just enough of the repository for an empty Time page — no Isar.
class _EmptyEvents extends ActivityEventRepository {
  @override
  Stream<List<ActivityEvent>> watchDay(String dateKey) =>
      Stream.value(const []);
  @override
  Future<List<ActivityEvent>> fetchDayOnce(String dateKey) async => const [];
  @override
  Stream<List<ActivityEvent>> watchRecentSince(int sinceMs) =>
      Stream.value(const []);
  @override
  Stream<List<ActivityEvent>> watchRange(int fromMs, int toMs) =>
      Stream.value(const []);
  @override
  Future<List<ActivityEvent>> fetchRangeOnce(int fromMs, int toMs) async =>
      const [];
  @override
  Stream<ActivityEvent?> watchLatest() => Stream.value(null);
  @override
  Future<ActivityEvent?> fetchLatestOnce() async => null;
  @override
  Future<ActivityEvent?> getById(String id) async => null;
}

UserProfilePreference _pref({required bool pill}) => UserProfilePreference(
  id: kUserProfilePreferenceId,
  displayName: '',
  defaultEnforcementMode: EnforcementMode.disciplined,
  updatedAtMs: 1,
  homeTrackPillEnabled: pill,
);

Widget _app(Widget home, _MemoryPrefs prefs) => ProviderScope(
  overrides: [
    profilePreferenceRepositoryProvider.overrideWithValue(prefs),
    activityEventRepositoryProvider.overrideWithValue(_EmptyEvents()),
    activityReminderServiceProvider.overrideWithValue(
      ActivityReminderService(evaluate: (_) async {}, cancel: (_) async {}),
    ),
  ],
  child: MaterialApp(home: home),
);

Finder get _switch => find.byKey(const ValueKey('time_home_pill_switch'));

void main() {
  testWidgets('the footer switch reflects the stored preference', (
    tester,
  ) async {
    final prefs = _MemoryPrefs()..stored = _pref(pill: false);
    await tester.pumpWidget(_app(const TimeScreen(), prefs));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(_switch, 200);
    expect(tester.widget<SwitchListTile>(_switch).value, isFalse);
  });

  testWidgets('flipping it writes the preference locally', (tester) async {
    final prefs = _MemoryPrefs()..stored = _pref(pill: true);
    await tester.pumpWidget(_app(const TimeScreen(), prefs));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(_switch, 200);
    await tester.tap(_switch);
    await tester.pumpAndSettle();

    expect(prefs.stored?.homeTrackPillEnabled, isFalse);
  });

  test('the service round-trips through the repository', () async {
    final prefs = _MemoryPrefs();
    final service = ProfilePreferenceService(repository: prefs);

    await service.setHomeTrackPillEnabled(false);
    expect(prefs.stored?.homeTrackPillEnabled, isFalse);

    await service.setHomeTrackPillEnabled(true);
    expect(prefs.stored?.homeTrackPillEnabled, isTrue);
  });

  testWidgets('the Home pill provider defaults to shown', (tester) async {
    final prefs = _MemoryPrefs(); // nothing stored yet
    await tester.pumpWidget(
      _app(
        Consumer(
          builder: (context, ref, _) => ref.watch(homeTrackPillEnabledProvider)
              ? const Scaffold(body: TrackPill())
              : const Scaffold(body: Text('hidden')),
        ),
        prefs,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TrackPill), findsOneWidget);
  });
}
