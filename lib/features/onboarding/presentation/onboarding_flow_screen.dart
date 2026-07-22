import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/forgot_password_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/sign_up_screen.dart';
import '../application/onboarding_flow_controller.dart';
import 'onboarding_ui.dart';
import 'steps/ai_demo_step.dart';
import 'steps/community_step.dart';
import 'steps/day_one_step.dart';
import 'steps/goals_step.dart';
import 'steps/journey_step.dart';
import 'steps/meet_sidepal_step.dart';
import 'steps/personalizing_step.dart';
import 'steps/premium_step.dart';
import 'steps/problem_step.dart';
import 'steps/register_step.dart';
import 'steps/science_step.dart';
import 'steps/struggles_step.dart';
import 'steps/welcome_step.dart';
import 'steps/why_step.dart';
import 'steps/your_sidepal_step.dart';

/// Self-contained [MaterialApp] for the first-launch onboarding flow.
///
/// Lives ABOVE the main app's [MaterialApp] (same pattern as the auth flow's
/// `_AuthFlowApp`), so it supplies its own Navigator/theme. Dark-only by
/// design (DESIGN.md) — it never follows the device theme.
class OnboardingFlowApp extends StatelessWidget {
  const OnboardingFlowApp({super.key, required this.onFinished});

  /// Called on BOTH exits — "Start My Journey" and the flow-level Skip.
  /// The [OnboardingGate] then falls through to [AuthGate].
  final VoidCallback onFinished;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SidePal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: OnboardingColors.background,
        colorScheme: ColorScheme.fromSeed(
          seedColor: OnboardingColors.primary,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: OnboardingFlowScreen(onFinished: onFinished),
      // Existing auth screens reachable from the flow ("Log in" on Welcome).
      routes: {
        LoginScreen.routeName: (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return LoginScreen(prefillEmail: email);
        },
        SignUpScreen.routeName: (_) => const SignUpScreen(),
        ForgotPasswordScreen.routeName: (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;
          return ForgotPasswordScreen(prefillEmail: email);
        },
      },
    );
  }
}

class OnboardingFlowScreen extends ConsumerStatefulWidget {
  const OnboardingFlowScreen({super.key, required this.onFinished});

  final VoidCallback onFinished;

  @override
  ConsumerState<OnboardingFlowScreen> createState() =>
      _OnboardingFlowScreenState();
}

class _OnboardingFlowScreenState extends ConsumerState<OnboardingFlowScreen> {
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    // A real (non-anonymous) sign-in is the one cross-cutting event:
    //  * from the "Log in" path — existing account, finish the flow now;
    //  * on the register step — account created (email or social), advance.
    ref.listenManual(authStateProvider, (_, next) {
      final user = next.valueOrNull;
      if (user == null || (user.isAnonymous)) return;
      final flow = ref.read(onboardingFlowControllerProvider);
      final controller = ref.read(onboardingFlowControllerProvider.notifier);
      if (flow.authIntent == OnboardingAuthIntent.login) {
        _finish();
      } else if (flow.step == OnboardingStep.register) {
        // Dismiss any pushed auth routes before advancing the step behind.
        Navigator.of(context).popUntil((r) => r.isFirst);
        controller.markRegistered();
        controller.next();
      }
    });
  }

  void _finish() {
    if (_finished) return; // auth stream can re-emit — fire the exit once
    _finished = true;
    widget.onFinished();
  }

  /// Flow-level Skip — straight to the anonymous account (AuthGate signs in
  /// anonymously once the gate falls through; no auth code here).
  void _skip() => _finish();

  void _completeJourney() {
    ref.read(onboardingFlowControllerProvider.notifier).complete();
    _finish();
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(onboardingFlowControllerProvider);
    final controller = ref.read(onboardingFlowControllerProvider.notifier);

    return PopScope(
      canPop: flow.step == OnboardingStep.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.back();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.04, 0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        ),
        child: KeyedSubtree(
          key: ValueKey(flow.step),
          child: _buildStep(flow.step),
        ),
      ),
    );
  }

  Widget _buildStep(OnboardingStep step) {
    switch (step) {
      case OnboardingStep.welcome:
        return WelcomeStep(onSkip: _skip);
      case OnboardingStep.register:
        return RegisterStep(onSkip: _skip);
      case OnboardingStep.struggles:
        return StrugglesStep(onSkip: _skip);
      case OnboardingStep.whyThisHappens:
        return WhyStep(onSkip: _skip);
      case OnboardingStep.meetSidePal:
        return MeetSidePalStep(onSkip: _skip);
      case OnboardingStep.community:
        return CommunityStep(onSkip: _skip);
      case OnboardingStep.aiDemo:
        return AiDemoStep(onSkip: _skip);
      case OnboardingStep.theProblem:
        return ProblemStep(onSkip: _skip);
      case OnboardingStep.dayOnePhoto:
        return DayOneStep(onSkip: _skip);
      case OnboardingStep.science:
        return ScienceStep(onSkip: _skip);
      case OnboardingStep.chooseGoals:
        return GoalsStep(onSkip: _skip);
      case OnboardingStep.personalizing:
        return const PersonalizingStep();
      case OnboardingStep.yourSidePal:
        return YourSidePalStep(onSkip: _skip);
      case OnboardingStep.premium:
        return PremiumStep(onSkip: _skip);
      case OnboardingStep.journey:
        return JourneyStep(onStart: _completeJourney);
    }
  }
}
