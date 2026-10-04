import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_providers.dart';
import '../../auth/presentation/forgot_password_screen.dart';
import '../../auth/presentation/login_screen.dart';
import '../../auth/presentation/sign_up_screen.dart';
import '../application/onboarding_flow_controller.dart';
import 'onboarding_ui.dart';
import 'steps/ai_demo_step.dart';
import 'steps/goals_step.dart';
import 'steps/personalizing_step.dart';
import 'steps/ready_step.dart';
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

  /// Called on every exit — Ready, "Turn this into your first goal", a
  /// real log-in, and the flow-level Skip.
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
    // A real (non-anonymous) sign-in is the one cross-cutting event: the
    // only auth surface left in the flow is Welcome's "Log in", so a real
    // user means an existing account — finish, never replay the tour.
    ref.listenManual(authStateProvider, (_, next) {
      final user = next.valueOrNull;
      if (user == null || user.isAnonymous) return;
      _finish();
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

  /// Ready's "Go to Home" — profile saved; the bridge replicates it once
  /// the anonymous account exists.
  void _completeJourney() {
    ref
        .read(onboardingFlowControllerProvider.notifier)
        .complete(wantsFirstGoal: false);
    _finish();
  }

  /// Your SidePal's "Turn this into your first goal" — a real goal needs a
  /// uid, so the flow ends here and `OnboardingHandoffBridge` opens the
  /// picker (then the created-variant Ready) right after sign-in.
  void _completeWithFirstGoal() {
    ref
        .read(onboardingFlowControllerProvider.notifier)
        .complete(wantsFirstGoal: true);
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
      case OnboardingStep.struggles:
        return StrugglesStep(onSkip: _skip);
      case OnboardingStep.chooseGoals:
        return GoalsStep(onSkip: _skip);
      case OnboardingStep.whyThisHappens:
        return WhyStep(onSkip: _skip);
      case OnboardingStep.aiDemo:
        return AiDemoStep(onSkip: _skip);
      case OnboardingStep.personalizing:
        return const PersonalizingStep();
      case OnboardingStep.yourSidePal:
        return YourSidePalStep(
          onSkip: _skip,
          onFirstGoal: _completeWithFirstGoal,
        );
      case OnboardingStep.ready:
        return ReadyStep(goalCreated: false, onStart: _completeJourney);
    }
  }
}
