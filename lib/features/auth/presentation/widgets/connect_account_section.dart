import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../profile/application/profile_providers.dart';
import '../../application/auth_providers.dart';
import '../../domain/auth_failure.dart';
import 'auth_apple_sign_in_button.dart' show isAppleSignInSupported;

enum _ConnectProvider { google, apple }

/// The full guest → connected flow, callable from anywhere with a context
/// (Profile's Connect button, the guest log-out dialog):
///
///   provider sheet (Google/Apple) → link with blocking progress →
///   success snackbar, or the reinstall-conflict dialog
///   (use existing account / try another / cancel).
///
/// Linking upgrades the anonymous session in place (same uid) so all data
/// survives phone changes and reinstalls from then on.
Future<void> showConnectAccountFlow(BuildContext context, WidgetRef ref) async {
  final provider = await _showProviderSheet(context);
  if (provider == null || !context.mounted) return;
  await _connect(context, ref, provider);
}

Future<_ConnectProvider?> _showProviderSheet(BuildContext context) {
  return showModalBottomSheet<_ConnectProvider>(
    context: context,
    backgroundColor: AppColors.inkCard,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 4),
            child: Text(
              'Connect an account',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.fg,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Text(
              'Your data stays safe across devices and reinstalls.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textSoft),
            ),
          ),
          _ProviderRow(
            icon: Icons.g_mobiledata_rounded,
            label: 'Continue with Google',
            onTap: () => Navigator.pop(ctx, _ConnectProvider.google),
          ),
          if (isAppleSignInSupported)
            _ProviderRow(
              icon: Icons.apple_rounded,
              label: 'Continue with Apple',
              onTap: () => Navigator.pop(ctx, _ConnectProvider.apple),
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

Future<void> _connect(
  BuildContext context,
  WidgetRef ref,
  _ConnectProvider provider, {
  bool forceAccountPicker = false,
}) async {
  final repo = ref.read(authRepositoryProvider);

  final (failure, _) = await _withBlockingProgress(context, () async {
    return switch (provider) {
      _ConnectProvider.google => repo.signInWithGoogle(
        forceAccountPicker: forceAccountPicker,
      ),
      _ConnectProvider.apple => repo.signInWithApple(),
    };
  });
  if (!context.mounted) return;

  if (failure == null) {
    // Profile UI reads from Isar — seed name from the linked identity.
    final name = repo.currentUser?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      await ref
          .read(profilePreferenceServiceProvider)
          .syncDisplayNameFromAuthIfEmpty(name);
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Account connected — your data is now safe across devices.',
        ),
      ),
    );
    return;
  }

  if (failure is AuthSignInCanceled) return;

  if (failure is CredentialAlreadyLinked) {
    await _showConflictDialog(context, ref, provider, failure);
    return;
  }

  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(failure.toUserMessage())));
}

/// The reinstall / phone-change recovery moment: the picked identity already
/// owns a PathPal account.
Future<void> _showConflictDialog(
  BuildContext context,
  WidgetRef ref,
  _ConnectProvider provider,
  CredentialAlreadyLinked conflict,
) async {
  final label = conflict.providerLabel ?? 'sign-in';
  final email = conflict.email;
  final choice = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('You already have an account'),
      content: Text(
        'This $label account${email != null ? ' ($email)' : ''} is already '
        'connected to an existing PathPal account.\n\n'
        'Switch to it and your progress from that account is restored on '
        'this phone. Anything you did here as a guest will be replaced.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, 'retry'),
          child: const Text('Try another account'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, 'use'),
          child: const Text('Use that account'),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null) return;

  if (choice == 'retry') {
    await _connect(context, ref, provider, forceAccountPicker: true);
    return;
  }

  // Switch to the existing account.
  final (failure, _) = await _withBlockingProgress(
    context,
    () => ref.read(authRepositoryProvider).signInWithPendingLinkConflict(),
  );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        failure == null
            ? 'Welcome back — your data is being restored.'
            : failure.toUserMessage(),
      ),
    ),
  );
}

/// Non-dismissible spinner over the app while [op] runs (the native
/// Google/Apple sheets present above it; it covers the network link phase).
Future<T> _withBlockingProgress<T>(
  BuildContext context,
  Future<T> Function() op,
) async {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(
      child: SizedBox(
        height: 32,
        width: 32,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      ),
    ),
  );
  try {
    return await op();
  } finally {
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

/// Profile "Account" section — guests only.
///
/// One "Connect account" button; tapping runs [showConnectAccountFlow].
/// Registered users see nothing here — their connected identity lives in
/// Account settings ([ConnectedIdentityCard]).
class ConnectAccountSection extends ConsumerWidget {
  const ConnectAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    // Registered users manage their identity in Account settings.
    if (user == null || !user.isAnonymous) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: FilledButton(
        onPressed: () => showConnectAccountFlow(context, ref),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link_rounded, size: 20),
            SizedBox(width: 8),
            Text(
              'Connect account',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}

/// One provider option row in the connect sheet.
class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.fg, size: 26),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.fg,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Account connected · <provider> · <email>" — lives in Account settings
/// (registered users); the guest connect flow lives on the Profile page.
class ConnectedIdentityCard extends StatelessWidget {
  const ConnectedIdentityCard({super.key, required this.user});

  final dynamic user; // firebase User; dynamic keeps this file test-friendly

  (IconData, String) get _providerBadge {
    final ids = <String>[
      for (final p in (user.providerData as List)) p.providerId as String,
    ];
    if (ids.contains('google.com')) {
      return (Icons.g_mobiledata_rounded, 'Google');
    }
    if (ids.contains('apple.com')) return (Icons.apple_rounded, 'Apple');
    return (Icons.email_outlined, 'Email');
  }

  @override
  Widget build(BuildContext context) {
    final (icon, label) = _providerBadge;
    final email = (user.email as String?)?.trim();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.whiteBorder8),
      ),
      child: Row(
        children: [
          Icon(Icons.verified_user_outlined, size: 20, color: AppColors.cyan),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account connected',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.fg,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email == null || email.isEmpty ? label : '$label · $email',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.textSoft),
                ),
              ],
            ),
          ),
          Icon(icon, size: 22, color: AppColors.textSoft),
        ],
      ),
    );
  }
}
