import 'package:coach_for_life/features/coaching/application/coaching_style_providers.dart';
import 'package:coach_for_life/features/coaching/domain/models/coaching_style.dart';
import 'package:coach_for_life/features/coaching/domain/models/enforcement_mode.dart';
import 'package:coach_for_life/features/coaching/domain/models/user_coaching_profile.dart';
import 'package:coach_for_life/features/context_override/application/context_override_providers.dart';
import 'package:coach_for_life/features/context_override/domain/models/user_attention_state.dart';
import 'package:coach_for_life/features/goals/application/goals_providers.dart';
import 'package:coach_for_life/features/goals/domain/models/user_goal.dart';
import 'package:coach_for_life/features/profile/application/profile_providers.dart';
import 'package:coach_for_life/features/profile/domain/models/user_profile_preference.dart';
import 'package:coach_for_life/features/profile/presentation/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
      // Total completions
      totalCompletionsCountProvider.overrideWith((ref) async => 42),
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

    testWidgets('renders Coaching Contract section header', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      expect(find.text('YOUR COACHING CONTRACT'), findsOneWidget);
    });

    testWidgets('shows Coaching Style tile with current style name',
        (tester) async {
      // Use supportive so "Supportive" is unique (not also used for enforcement).
      await tester.pumpWidget(
        _buildScreen(style: CoachingStyle.supportive),
      );
      await tester.pump();
      expect(find.text('Coaching Style'), findsOneWidget);
      expect(find.text(CoachingStyle.supportive.displayName), findsOneWidget);
    });

    testWidgets('shows Enforcement Mode tile', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      expect(find.text('Enforcement Mode'), findsOneWidget);
      // "Disciplined" appears for both coaching style subtitle and enforcement
      // mode subtitle — use findsWidgets (≥1) rather than findsOneWidget.
      expect(
        find.text(EnforcementMode.disciplined.displayName),
        findsWidgets,
      );
    });

    testWidgets('renders Progress section header', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      expect(find.text('PROGRESS'), findsOneWidget);
    });

    testWidgets('renders Account section header', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      // Scroll to the bottom to ensure off-screen widgets are built.
      await tester.dragUntilVisible(
        find.text('ACCOUNT'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('ACCOUNT'), findsOneWidget);
    });

    testWidgets('shows Sign Out and Export Data tiles', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.dragUntilVisible(
        find.text('Sign Out'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('Sign Out'), findsOneWidget);
      expect(find.text('Export Data'), findsOneWidget);
    });

    testWidgets('shows Delete Account tile', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.dragUntilVisible(
        find.text('Delete Account'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('shows app name footer', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.dragUntilVisible(
        find.text('Coach for Life'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      expect(find.text('Coach for Life'), findsOneWidget);
    });

    testWidgets('Export Data tap shows snackbar', (tester) async {
      await tester.pumpWidget(_buildScreen());
      await tester.pump();
      await tester.dragUntilVisible(
        find.text('Export Data'),
        find.byType(ListView),
        const Offset(0, -200),
      );
      await tester.tap(find.text('Export Data'));
      await tester.pump();
      expect(find.text('Export coming soon.'), findsOneWidget);
    });

    testWidgets('avatar initial uses first letter of display name',
        (tester) async {
      await tester.pumpWidget(_buildScreen(displayName: 'Alice'));
      await tester.pump();
      expect(find.text('A'), findsOneWidget);
    });
  });
}
