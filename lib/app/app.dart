import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_navigator.dart';
import 'application/main_tab_navigation.dart';
import 'presentation/main_tab_shell.dart';
import '../features/auth/presentation/auth_landing_screen.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/forgot_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/sign_up_screen.dart';
import '../features/add_task/presentation/add_task_screen.dart';
import '../features/analytics/presentation/analytics_progress_screen.dart';
import '../features/focus/presentation/focus_selection_screen.dart';
import '../features/goals/presentation/goal_detail_screen.dart';
import '../features/goals/presentation/goal_editor_screen.dart';
import '../features/goals/presentation/goal_template_picker_screen.dart';
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
import '../features/feedback/application/feedback_route_tracker.dart';
import '../features/feedback/presentation/feedback_screen.dart';
import '../features/feedback/presentation/tester_bug_bubble.dart';
import '../features/profile/presentation/default_enforcement_mode_selection_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/settings/presentation/account_settings_screen.dart';
import '../features/settings/presentation/notification_settings_screen.dart';
import '../features/settings/presentation/reminder_settings_screen.dart';
import '../features/tasks_hub/presentation/task_detail_screen.dart';
import '../features/tasks_hub/presentation/tasks_hub_screen.dart';
import '../features/timer/presentation/timer_session_screen.dart';

import '../core/presentation/app_colors.dart';
import '../core/presentation/theme_brightness_controller.dart';

class CoachForLifeApp extends ConsumerWidget {
  const CoachForLifeApp({super.key});

  static ThemeData _theme(Brightness brightness) {
    // Rectangular button language (Obsidian Pulse Light DESIGN.md: small
    // radii, no pills) — applied to BOTH modes so the app stays consistent.
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: AppColors.scaffold,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brightness == Brightness.dark
            ? const Color(0xFFB7FF00)
            : const Color(0xFF4C6700),
        brightness: brightness,
      ),
      useMaterial3: true,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.scaffold,
        foregroundColor: AppColors.textPrimary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(shape: buttonShape),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(shape: buttonShape),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(themeBrightnessProvider);
    // Point the static token table at the right palette BEFORE any child
    // builds; the ValueKey rebuilds the entire tree on toggle so every
    // AppColors read repaints. (Navigation stack resets on toggle — accepted.)
    AppColors.palette = brightness == Brightness.light
        ? AppPalette.light
        : AppPalette.dark;

    return MaterialApp(
      key: ValueKey(brightness),
      navigatorKey: appNavigatorKey,
      title: 'Coach for Life',
      debugShowCheckedModeBanner: false,
      theme: _theme(brightness),
      navigatorObservers: [FeedbackRouteTracker()],
      // Overlay above every route: the tester-mode bug-report bubble.
      builder: (context, child) => Stack(
        textDirection: TextDirection.ltr,
        children: [?child, const TesterBugBubbleLayer()],
      ),
      initialRoute: MainTabShell.routeName,
      routes: {
        // ── Auth ──────────────────────────────────────────────────────────
        AuthLandingScreen.routeName: (_) => const AuthLandingScreen(),
        LoginScreen.routeName: (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return LoginScreen(prefillEmail: email);
        },
        SignUpScreen.routeName: (_) => const SignUpScreen(),
        ForgotPasswordScreen.routeName: (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return ForgotPasswordScreen(prefillEmail: email);
        },
        ChangePasswordScreen.routeName: (_) => const ChangePasswordScreen(),
        MainTabShell.routeName: (_) => const MainTabShell(),
        GoalSelectionScreen.routeName: (_) => const GoalSelectionScreen(),
        GoalTemplatePickerScreen.routeName: (_) =>
            const GoalTemplatePickerScreen(),
        GoalEditorScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is GoalEditorArgs) {
            return GoalEditorScreen(
              goalId: args.goalId,
              template: args.template,
            );
          }
          return const GoalEditorScreen();
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
        TaskDetailScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is TaskDetailArgs) {
            return TaskDetailScreen(args: args);
          }
          // Opened without arguments (should not happen) — land on the hub.
          return const TasksHubScreen();
        },
        AnalyticsProgressScreen.routeName: (_) =>
            const AnalyticsProgressScreen(),
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
        AccountSettingsScreen.routeName: (_) => const AccountSettingsScreen(),
        NotificationSettingsScreen.routeName: (_) =>
            const NotificationSettingsScreen(),
        ReminderSettingsScreen.routeName: (_) => const ReminderSettingsScreen(),
        FeedbackScreen.routeName: (_) => const FeedbackScreen(),
        ProfileScreen.routeName: (_) => const ProfileScreen(),
        DefaultEnforcementModeSelectionScreen.routeName: (_) =>
            const DefaultEnforcementModeSelectionScreen(),
        CoachingStyleSelectionScreen.routeName: (_) =>
            const CoachingStyleSelectionScreen(),
        // ── Coach AI ──────────────────────────────────────────────────────
        AiAssistantScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return _CoachTabRedirect(args: args is CoachRouteArgs ? args : null);
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
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: SizedBox.shrink(),
    );
  }
}
