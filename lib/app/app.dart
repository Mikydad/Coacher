import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_navigator.dart';
import 'application/main_tab_navigation.dart';
import 'presentation/main_tab_shell.dart';
import '../features/add_task/presentation/add_task_screen.dart';
import '../features/analytics/presentation/analytics_progress_screen.dart';
import '../features/firebase_test/presentation/firebase_test_screen.dart';
import '../features/focus/presentation/focus_selection_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/goals/presentation/goal_editor_screen.dart';
import '../features/goals/presentation/goal_selection_screen.dart';
import '../features/goals/presentation/goals_archive_screen.dart';
import '../features/plan_tomorrow/presentation/plan_tomorrow_screen.dart';
import '../features/planning/presentation/accountability_history_screen.dart';
import '../features/coaching/presentation/coaching_style_selection_screen.dart';
import '../features/community/presentation/circle_create_screen.dart';
import '../features/community/presentation/circle_detail_screen.dart';
import '../features/community/presentation/circle_discovery_screen.dart';
import '../features/ai_assistant/presentation/ai_assistant_screen.dart';
import '../features/community/presentation/community_screen.dart';
import '../features/profile/presentation/default_enforcement_mode_selection_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tasks_hub/presentation/tasks_hub_screen.dart';
import '../features/timer/presentation/timer_session_screen.dart';

class CoachForLifeApp extends StatelessWidget {
  const CoachForLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Coach for Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050806),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB7FF00),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: MainTabShell.routeName,
      routes: {
        MainTabShell.routeName: (_) => const MainTabShell(),
        GoalSelectionScreen.routeName: (_) => const GoalSelectionScreen(),
        GoalEditorScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final id = args is GoalEditorArgs ? args.goalId : null;
          return GoalEditorScreen(goalId: id);
        },
        GoalDetailScreen.routeName: (context) {
          final id =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return GoalDetailScreen(goalId: id);
        },
        GoalsArchiveScreen.routeName: (_) => const GoalsArchiveScreen(),
        PlanTomorrowScreen.routeName: (_) => const PlanTomorrowScreen(),
        AccountabilityHistoryScreen.routeName: (_) =>
            const AccountabilityHistoryScreen(),
        AddTaskScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return AddTaskScreen(
            editArgs: args is AddTaskEditArgs ? args : null,
            slotArgs: args is AddTaskSlotArgs ? args : null,
          );
        },
        TasksHubScreen.routeName: (_) => const TasksHubScreen(),
        AnalyticsProgressScreen.routeName: (_) =>
            const AnalyticsProgressScreen(),
        FirebaseTestScreen.routeName: (_) => const FirebaseTestScreen(),
        FocusSelectionScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return FocusSelectionScreen(
            launchArgs: args is FocusLaunchArgs ? args : null,
          );
        },
        TimerSessionScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return TimerSessionScreen(
            launchArgs: args is TimerLaunchArgs ? args : null,
          );
        },
        SettingsScreen.routeName: (_) => const SettingsScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        DefaultEnforcementModeSelectionScreen.routeName: (_) =>
            const DefaultEnforcementModeSelectionScreen(),
        CoachingStyleSelectionScreen.routeName: (_) =>
            const CoachingStyleSelectionScreen(),
        // ── Coach AI ──────────────────────────────────────────────────────
        AiAssistantScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return _CoachTabRedirect(
            args: args is CoachRouteArgs ? args : null,
          );
        },
        // ── Community / Accountability Circles ────────────────────────────
        CommunityScreen.routeName: (_) => const CommunityScreen(),
        CircleCreateScreen.routeName: (_) => const CircleCreateScreen(),
        CircleDiscoveryScreen.routeName: (_) => const CircleDiscoveryScreen(),
        CircleDetailScreen.routeName: (context) {
          final id =
              ModalRoute.of(context)?.settings.arguments as String? ?? '';
          return CircleDetailScreen(circleId: id);
        },
      },
    );
  }
}

/// Deep links to `/coach` switch the shell tab instead of stacking a second Coach.
class _CoachTabRedirect extends ConsumerWidget {
  const _CoachTabRedirect({this.args});

  final CoachRouteArgs? args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      navigateToMainTab(
        context,
        ref,
        index: MainTabIndex.coach,
        coachArgs: args,
      );
      Navigator.of(context).popUntil((route) => route.isFirst);
    });
    return const Scaffold(
      backgroundColor: Color(0xFF050806),
      body: SizedBox.shrink(),
    );
  }
}
