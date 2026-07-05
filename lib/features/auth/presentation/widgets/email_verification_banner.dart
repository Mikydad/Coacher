import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../application/auth_providers.dart';

import '../../../../core/presentation/app_colors.dart';

const String _kDismissedUntilKey = 'email_verification_banner_dismissed_until_ms';

/// Non-blocking banner shown at the top of the screen when the signed-in user
/// has an unverified email address.
///
/// Wrap any full-screen scaffold body with this widget. It overlays nothing
/// when hidden, so there is zero layout cost.
///
/// Dismissible for 24 hours (stored in [SharedPreferences]).
class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner> {
  bool _dismissed = false;
  bool _resendLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDismissState();
  }

  Future<void> _loadDismissState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedUntilMs =
        prefs.getInt(_kDismissedUntilKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (mounted) setState(() => _dismissed = now < dismissedUntilMs);
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    final until = DateTime.now()
        .add(const Duration(hours: 24))
        .millisecondsSinceEpoch;
    await prefs.setInt(_kDismissedUntilKey, until);
    if (mounted) setState(() => _dismissed = true);
  }

  Future<void> _resend(User user) async {
    if (_resendLoading) return;
    setState(() => _resendLoading = true);
    try {
      await user.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification email sent. Check your inbox.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await _dismiss();
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not send verification email. Try again later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _resendLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final showBanner = !_dismissed &&
        user != null &&
        !(user.isAnonymous) &&
        !(user.emailVerified);

    if (!showBanner) return widget.child;

    // showBanner is only true when user != null — use a promoted local binding.
    final nonNullUser = user;

    // Overlay the banner at the top using a Stack so the child (MainTabShell)
    // keeps its full-screen layout and StackFit.expand constraints intact.
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SafeArea(
            bottom: false,
            child: _Banner(
              onDismiss: _dismiss,
              onResend: _resendLoading ? null : () => _resend(nonNullUser),
              isLoading: _resendLoading,
            ),
          ),
        ),
      ],
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.onDismiss,
    required this.onResend,
    required this.isLoading,
  });

  final VoidCallback onDismiss;
  final VoidCallback? onResend;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.limeInkDeep,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.mark_email_unread_outlined,
              color: AppColors.accentDim, size: 16),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Verify your email to unlock all features.',
              style: TextStyle(
                  color: AppColors.limeSoft, fontSize: 12, height: 1.4),
            ),
          ),
          if (isLoading)
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  color: AppColors.accentDim, strokeWidth: 1.5),
            )
          else
            TextButton(
              onPressed: onResend,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Resend',
                style: TextStyle(
                    color: AppColors.accentDim,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          GestureDetector(
            onTap: onDismiss,
            child: const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.close, color: AppColors.gray55, size: 14),
            ),
          ),
        ],
      ),
    );
  }
}
