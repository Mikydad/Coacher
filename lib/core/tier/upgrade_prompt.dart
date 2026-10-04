import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/widgets/connect_account_section.dart';
import '../presentation/app_colors.dart';
import '../presentation/page_headers.dart';
import 'pro_plan_screen.dart';

/// The one line every guest prompt leads with (decision 2026-09-27): an
/// account is sold as keeping your data, never as "more" — guest and Free
/// caps are the same numbers.
const String kGuestDataLine =
    'Your plan lives only on this phone. Sign in so you don\'t lose it.';

/// Opens the Pro plan page (the paywall once RevenueCat ships).
Future<void> openProPlan(BuildContext context) =>
    Navigator.of(context).pushNamed(ProPlanScreen.routeName);

/// Bottom sheet shown when a free limit blocks something (PRD monetization
/// §8). Who's asking decides the door:
///  - a **guest** is asked to sign in first, framed as keeping their data
///    ([kGuestDataLine]); once linked they land on the Pro plan page;
///  - a **signed-in free** user gets "See Pro" → the Pro plan page.
///
/// Unreachable in production while `kPaywallAvailable` is false — no gate
/// blocks with enforcement off.
Future<void> showTierLimitSheet(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfacePanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _TierLimitSheet(title: title, message: message),
  );
}

class _TierLimitSheet extends ConsumerStatefulWidget {
  const _TierLimitSheet({required this.title, required this.message});

  final String title;
  final String message;

  @override
  ConsumerState<_TierLimitSheet> createState() => _TierLimitSheetState();
}

class _TierLimitSheetState extends ConsumerState<_TierLimitSheet> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    // The sheet stays mounted while the connect flow runs so its ref is
    // alive for the flow's post-link work.
    await _runSignIn(context, ref);
    if (!mounted) return;
    final navigator = Navigator.of(context);
    final linked = ref.read(isRegisteredProvider);
    navigator.pop();
    if (linked) await navigator.pushNamed(ProPlanScreen.routeName);
  }

  void _seePro() {
    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.pushNamed(ProPlanScreen.routeName);
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = isGuestSession(ref.watch(authStateProvider));
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(widget.title),
            const SizedBox(height: 10),
            Text(widget.message, style: _bodyStyle),
            if (isGuest) ...[
              const SizedBox(height: 10),
              Text(
                '$kGuestDataLine Then you can unlock more with Pro.',
                key: const ValueKey('tier_sheet_guest_line'),
                style: _bodyStyle,
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: ValueKey(
                  isGuest ? 'tier_sheet_sign_in' : 'tier_sheet_see_pro',
                ),
                onPressed: _busy ? null : (isGuest ? _signIn : _seePro),
                child: Text(isGuest ? 'Sign in' : 'See Pro'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Not now',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Gate for account-only features (Coach AI, groups, stakes — PRD
/// monetization §4.1). Returns true when the user has an account and may
/// proceed. A guest gets a polite sheet ("Sign in to use {feature}") that
/// runs the guest → account link (same uid, all local data kept) and
/// returns true only if the link succeeded, so the caller continues
/// straight into the feature.
Future<bool> ensureAccountFor(
  BuildContext context, {
  required String feature,
}) async {
  final container = ProviderScope.containerOf(context, listen: false);
  // Await the auth state rather than peek: a not-yet-loaded stream must not
  // read as "has an account". Unreadable (VM tests, no auth backend) →
  // don't block; server rules still guard every account-only call. A
  // signed-out session can't link, so it takes the sheet's log-in path.
  final User? user;
  try {
    user = await container
        .read(authStateProvider.future)
        .timeout(const Duration(seconds: 3));
  } catch (_) {
    return true;
  }
  if (user != null && !user.isAnonymous) return true;
  if (!context.mounted) return false;
  final proceed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: AppColors.surfacePanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _AccountRequiredSheet(feature: feature),
  );
  return proceed == true;
}

class _AccountRequiredSheet extends ConsumerStatefulWidget {
  const _AccountRequiredSheet({required this.feature});

  final String feature;

  @override
  ConsumerState<_AccountRequiredSheet> createState() =>
      _AccountRequiredSheetState();
}

class _AccountRequiredSheetState extends ConsumerState<_AccountRequiredSheet> {
  bool _busy = false;

  Future<void> _signIn() async {
    setState(() => _busy = true);
    await _runSignIn(context, ref);
    if (!mounted) return;
    Navigator.of(context).pop(ref.read(isRegisteredProvider));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader('Sign in to use ${widget.feature}'),
            const SizedBox(height: 10),
            Text(
              'You need an account for ${widget.feature}. Signing in also '
              'keeps your data safe if you lose or switch phones — '
              'everything you\'ve added stays.',
              style: _bodyStyle,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const ValueKey('account_sheet_sign_in'),
                onPressed: _busy ? null : _signIn,
                child: const Text('Sign in'),
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => Navigator.of(context).pop(false),
                child: Text(
                  'Not now',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A guest is a signed-in **anonymous** session — the same test the Coach
/// service uses. Signed out entirely can't reach in-app surfaces (AuthGate
/// shows the landing screen), and an unreadable auth state (VM tests)
/// reads as not-a-guest; server rules still guard every account-only call.
bool isGuestSession(AsyncValue<User?> auth) {
  final user = auth.valueOrNull;
  return user != null && user.isAnonymous;
}

/// Guest (anonymous uid) → the existing link flow, which keeps the uid and
/// every local row. Signed out entirely (no uid to link) → plain log in.
Future<void> _runSignIn(BuildContext context, WidgetRef ref) async {
  final user = ref.read(authStateProvider).valueOrNull;
  if (user == null) {
    await Navigator.of(context).pushNamed(LoginScreen.routeName);
    return;
  }
  await showConnectAccountFlow(context, ref);
}

TextStyle get _bodyStyle =>
    TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.45);
