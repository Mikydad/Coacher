import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/first_launch_gate.dart' show kIsarSeededV1PrefsKey;
import '../../auth/application/auth_session_policy.dart'
    show kLastSignedInUidPrefsKey;
import 'onboarding_flow_screen.dart';
import 'onboarding_ui.dart';

/// Set once the flow finishes (completed OR skipped). Device-level on
/// purpose — logout must NOT replay a marketing flow, so
/// [AuthSessionPolicy.clearLocalSession] leaves this key alone.
const String kOnboardingCompletedPrefsKey = 'onboarding_completed_v1';

/// First-launch onboarding gate — sits ABOVE [AuthGate] in the widget tree.
///
/// While the flow shows, [AuthGate] is not mounted, so nobody is signed in
/// yet; registering mid-flow just creates the Firebase account quietly.
/// When the flow finishes (or Skip), the gate falls through and [AuthGate]
/// does what it already does: show the app for a signed-in user, or silent
/// anonymous sign-in — which IS the Skip path, no extra auth code.
class OnboardingGate extends StatefulWidget {
  const OnboardingGate({super.key, required this.child});

  final Widget child;

  @override
  State<OnboardingGate> createState() => _OnboardingGateState();
}

class _OnboardingGateState extends State<OnboardingGate> {
  bool? _showOnboarding; // null = prefs not read yet

  @override
  void initState() {
    super.initState();
    unawaited(_decide());
  }

  Future<void> _decide() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    if (prefs.getBool(kOnboardingCompletedPrefsKey) == true) {
      setState(() => _showOnboarding = false);
      return;
    }

    // Existing install upgrading to a build that has onboarding: anyone who
    // ever signed in or seeded Isar is not a new user — never show them a
    // marketing flow.
    final isExistingInstall =
        prefs.getString(kLastSignedInUidPrefsKey) != null ||
        prefs.getBool(kIsarSeededV1PrefsKey) == true;
    if (isExistingInstall) {
      await prefs.setBool(kOnboardingCompletedPrefsKey, true);
      if (!mounted) return;
      setState(() => _showOnboarding = false);
      return;
    }

    setState(() => _showOnboarding = true);
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingCompletedPrefsKey, true);
    if (!mounted) return;
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    final show = _showOnboarding;
    if (show == null) {
      // Local prefs read — resolves in milliseconds; match the flow's
      // background so a first launch never flashes a wrong-colored frame.
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Material(color: OnboardingColors.background),
      );
    }
    if (show) {
      return OnboardingFlowApp(onFinished: _finish);
    }
    return widget.child;
  }
}
