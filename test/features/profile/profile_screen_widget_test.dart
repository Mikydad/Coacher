import 'package:sidepal/features/coaching/application/coaching_style_providers.dart';
import 'package:sidepal/features/coaching/domain/models/coaching_style.dart';
import 'package:sidepal/features/coaching/domain/models/enforcement_mode.dart';
import 'package:sidepal/features/coaching/domain/models/user_coaching_profile.dart';
import 'package:sidepal/features/auth/application/auth_providers.dart';
import 'package:sidepal/features/context_override/application/context_override_providers.dart';
import 'package:sidepal/features/context_override/domain/models/user_attention_state.dart';
import 'package:sidepal/features/goals/application/goals_providers.dart';
import 'package:sidepal/features/goals/domain/models/user_goal.dart';
import 'package:sidepal/features/analytics/application/discipline_score.dart';
import 'package:sidepal/features/feedback/application/tester_mode_controller.dart';
import 'package:sidepal/features/profile/application/profile_providers.dart';
import 'package:sidepal/features/profile/domain/models/user_profile_preference.dart';
import 'package:sidepal/features/profile/presentation/profile_screen.dart';
import 'package:sidepal/features/settings/presentation/about_support_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Stub data ────────────────────────────────────────────────────────────────

final _stubProfile = UserCoachingProfile(
  id: kUserCoachingProfileId,
  coachingStyle: CoachingStyle.balanced,
  lastChangedAtMs: 0,
  updatedAtMs: 0,
);

final _stubPreference = UserProfilePreference(
  id: kUserProfilePreferenceId,
  displayName: 'Test User',
  defaultEnforcementMode: EnforcementMode.disciplined,
  updatedAtMs: 0,
);

final _emptyAttentionState = UserAttentionState.empty();

// ─── Helpers ──────────────────────────────────────────────────────────────────

Widget _buildScreen({
  String displayName = 'Test User',
  CoachingStyle style = CoachingStyle.balanced,
  List<UserGoal> activeGoals = const [],
}) {
  final preference = _stubPreference.copyWith(displayName: displayName);
  return ProviderScope(
    overrides: [
      // Coaching profile
      coachingProfileStreamProvider.overrideWith(
        (ref) => Stream.value(_stubProfile.copyWith(coachingStyle: style)),
      ),
      // Active coaching style
      activeCoachingStyleProvider.overrideWithValue(style),
      // Profile preference stream
      userProfilePreferenceStreamProvider.overrideWith(
        (ref) => Stream.value(preference),
      ),
      // Derived display name
      displayNameProvider.overrideWithValue(displayName),
      // Default enforcement mode
      defaultEnforcementModeProvider.overrideWithValue(
        EnforcementMode.disciplined,
      ),
      // Attention state (no quiet hours)
      attentionStateProvider.overrideWith(
        (ref) => Stream.value(_emptyAttentionState),
      ),
      // Active goals
      goalsStreamProvider.overrideWith((ref) => Stream.value(activeGoals)),
      homeDisplayStreakDaysProvider.overrideWithValue(12),
      // Signed-in registered account — tester mode requires one, and this
      // keeps the auth providers off real Firebase in tests.
      authUidProvider.overrideWithValue('test-uid'),
      isRegisteredProvider.overrideWithValue(true),
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

/// The default 800x600 test surface is shorter than any real phone, so the
/// Coach Tone section falls outside it once Progress sits above the knobs —
/// and unbuilt slivers can't be asserted on. Give those tests a phone-shaped
/// viewport instead of scrolling past the frosted top bar.
void _useTallViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1200, 3000);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
}

Widget _buildAboutScreen() {
  return ProviderScope(
    overrides: [
      authUidProvider.overrideWithValue('test-uid'),
      isRegisteredProvider.overrideWithValue(true),
    ],
    child: const MaterialApp(home: AboutSupportScreen()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ProfileScreen', () {
    testWidgets('renders the Profile app bar', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      // PageTitle renders app-bar titles as small caps.
      expect(find.text('PROFILE'), findsOneWidget);
    });

    testWidgets('displays the display name', (tester) async {
      await tester.pumpWidget(_buildScreen(displayName: 'Miko'));
      await tester.pump();
      expect(find.text('Miko'), findsOneWidget);
    });

    testWidgets('falls back to "You" when display name is empty', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(displayName: ''));
      await tester.pump();
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('renders the grouped settings hub', (tester) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      // Discipline Mode and Coach Tone sit above the list, not inside it.
      expect(find.text('DISCIPLINE MODE'), findsOneWidget);
      expect(find.text('COACH TONE'), findsOneWidget);
      // Progress sits above the knobs, not inside the settings list.
      expect(find.text('Progress'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('SETTINGS'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('SETTINGS'), findsOneWidget);
      expect(find.text('Coaching'), findsNothing);
    });

    testWidgets('shows the active coaching style in the hero badge', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(style: CoachingStyle.supportive));
      await tester.pump();
      expect(
        find.text(CoachingStyle.supportive.displayName.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets(
      'Discipline Mode collapses to the active value and expands in place',
      (tester) async {
        _useTallViewport(tester);
        await tester.pumpWidget(_buildScreen());
        await tester.pumpAndSettle();
        // Collapsed: only the active mode and active tone show.
        expect(
          find.text(EnforcementMode.disciplined.displayName),
          findsOneWidget,
        );
        expect(find.text(EnforcementMode.extreme.displayName), findsNothing);
        expect(find.text('ACTIVE'), findsNWidgets(2));

        // Expand discipline: the other modes appear.
        await tester.tap(find.text(EnforcementMode.disciplined.displayName));
        await tester.pumpAndSettle();
        for (final mode in EnforcementMode.values) {
          expect(find.text(mode.displayName), findsOneWidget);
        }
      },
    );

    testWidgets('renders streak card', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      expect(find.text('DAY STREAK'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('Coach Tone shows only the active style until expanded', (
      tester,
    ) async {
      _useTallViewport(tester);
      await tester.pumpWidget(_buildScreen());
      await tester.pumpAndSettle();
      expect(find.text(CoachingStyle.balanced.displayName), findsOneWidget);
      expect(find.text(CoachingStyle.intense.displayName), findsNothing);
    });

    testWidgets('shows the hub navigation rows', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Account & Privacy'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Account & Privacy'), findsOneWidget);
      expect(find.text('Notifications & Reminders'), findsOneWidget);
      expect(find.text('Smart Timing'), findsOneWidget);
      expect(find.text('Coach & AI'), findsOneWidget);
      expect(find.text('Appearance'), findsOneWidget);
      expect(find.text('About & Support'), findsOneWidget);
    });

    testWidgets('About & Support page shows the Send Feedback row', (
      tester,
    ) async {
      await tester.pumpWidget(_buildAboutScreen());
      await tester.pump();
      expect(find.text('Send Feedback'), findsOneWidget);
      expect(find.text('Report a bug or suggest an idea'), findsOneWidget);
    });

    testWidgets('7 taps on the version footer toggle tester mode', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_buildAboutScreen());
      await tester.pump();
      final footer = find.textContaining('SIDEPAL');
      await tester.ensureVisible(footer);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(AboutSupportScreen)),
      );
      expect(container.read(testerModeProvider), isFalse);

      for (var i = 0; i < 7; i++) {
        await tester.tap(footer, warnIfMissed: false);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(container.read(testerModeProvider), isTrue);
      expect(
        find.text('Tester mode enabled — bug bubble is on'),
        findsOneWidget,
      );
    });

    testWidgets('shows Log Out button', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Log Out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('Log Out tap shows confirmation dialog', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Log Out'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      // The row can land half-clipped at the viewport edge (the settings list
      // grew an Appearance row); align it fully into view before tapping.
      await tester.ensureVisible(find.text('Log Out'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();
      expect(find.text('Log Out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('avatar initial uses first letter of display name', (
      tester,
    ) async {
      await tester.pumpWidget(_buildScreen(displayName: 'Alice'));
      await tester.pump();
      expect(find.text('A'), findsOneWidget);
    });
  });
}
