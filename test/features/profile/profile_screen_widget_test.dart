import 'package:coach_for_life/features/coaching/application/coaching_style_providers.dart';
import 'package:coach_for_life/features/coaching/domain/models/coaching_style.dart';
import 'package:coach_for_life/features/coaching/domain/models/enforcement_mode.dart';
import 'package:coach_for_life/features/coaching/domain/models/user_coaching_profile.dart';
import 'package:coach_for_life/features/context_override/application/context_override_providers.dart';
import 'package:coach_for_life/features/context_override/domain/models/user_attention_state.dart';
import 'package:coach_for_life/features/goals/application/goals_providers.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:coach_for_life/features/analytics/application/discipline_score.dart';
import 'package:coach_for_life/features/feedback/application/tester_mode_controller.dart';
import 'package:coach_for_life/features/profile/application/profile_providers.dart';
import 'package:coach_for_life/features/profile/domain/models/user_profile_preference.dart';
import 'package:coach_for_life/features/profile/presentation/profile_screen.dart';
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
    ],
    child: const MaterialApp(home: ProfileScreen()),
  );
}

// ─────────────────────────────────────────────────────────────────────────────

void main() {
  group('ProfileScreen', () {
    testWidgets('renders the Profile app bar', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('displays the display name', (tester) async {
      await tester.pumpWidget(_buildScreen(displayName: 'Miko'));
      await tester.pump();
      expect(find.text('Miko'), findsOneWidget);
    });

    testWidgets('falls back to "You" when display name is empty', (tester) async {
      await tester.pumpWidget(_buildScreen(displayName: ''));
      await tester.pump();
      expect(find.text('You'), findsOneWidget);
    });

    testWidgets('renders Discipline Modes section header', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      expect(find.text('DISCIPLINE MODES'), findsOneWidget);
    });

    testWidgets('shows the active coaching style in the hero badge',
        (tester) async {
      await tester.pumpWidget(
        _buildScreen(style: CoachingStyle.supportive),
      );
      await tester.pump();
      expect(
        find.text(CoachingStyle.supportive.displayName.toUpperCase()),
        findsOneWidget,
      );
    });

    testWidgets('shows all enforcement mode tiles', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      for (final mode in EnforcementMode.values) {
        expect(find.text(mode.displayName), findsWidgets);
      }
      // The active mode carries the ACTIVE badge.
      expect(find.text('ACTIVE'), findsOneWidget);
    });

    testWidgets('renders streak card', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      expect(find.text('DAY STREAK'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
    });

    testWidgets('renders Coach Tone section with all styles', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('COACH TONE'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('COACH TONE'), findsOneWidget);
    });

    testWidgets('shows Core Optimization settings rows', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Account Settings'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Account Settings'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Reminder Settings'), findsOneWidget);
    });

    testWidgets('shows the Send Feedback row', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.scrollUntilVisible(
        find.text('Send Feedback'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Send Feedback'), findsOneWidget);
      expect(find.text('Report a bug or suggest an idea'), findsOneWidget);
    });

    testWidgets('7 taps on the version footer toggle tester mode',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      final footer = find.textContaining('PATHPAL');
      await tester.scrollUntilVisible(
        footer,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.ensureVisible(footer);
      await tester.pumpAndSettle();

      final container = ProviderScope.containerOf(
        tester.element(find.byType(ProfileScreen)),
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

    testWidgets('avatar initial uses first letter of display name',
        (tester) async {
      await tester.pumpWidget(_buildScreen(displayName: 'Alice'));
      await tester.pump();
      expect(find.text('A'), findsOneWidget);
    });
  });
}
