import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../application/circle_invite_functions.dart';
import '../circle_auth_guard.dart';
import '../circle_detail_screen.dart';

/// "Join with a key" (2026-08-26): enter the invite key someone shared and
/// land straight in the circle — works for private and approval-required
/// circles too, because the key is verified (and the membership written)
/// server-side. [prefillCode] comes from a tapped sidepal://join/KEY link.
Future<void> showJoinWithCodeSheet(
  BuildContext context,
  WidgetRef ref, {
  String? prefillCode,
}) async {
  // Joining needs a real identity — same guard as every circle action.
  if (!await ensureRegisteredForCircleAction(
    context,
    ref,
    actionLabel: 'join a circle',
  )) {
    return;
  }
  if (!context.mounted) return;
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _JoinWithCodeSheet(prefillCode: prefillCode),
  );
}

/// Deep-link entry (sidepal://join/KEY): opens the sheet prefilled,
/// WITHOUT the pre-flight guest guard — there's no WidgetRef on the link
/// path, and the server rejects guests with its own clear message anyway.
Future<void> showJoinWithCodeSheetForLink(BuildContext context, String code) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _JoinWithCodeSheet(prefillCode: code),
  );
}

class _JoinWithCodeSheet extends ConsumerStatefulWidget {
  const _JoinWithCodeSheet({this.prefillCode});

  final String? prefillCode;

  @override
  ConsumerState<_JoinWithCodeSheet> createState() => _JoinWithCodeSheetState();
}

class _JoinWithCodeSheetState extends ConsumerState<_JoinWithCodeSheet> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.prefillCode ?? '',
  );
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _join() async {
    final code = _controller.text.trim();
    if (code.isEmpty || _busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(circleInviteFunctionsProvider)
          .joinWithInvite(code);
      if (!mounted) return;
      Navigator.pop(context);
      final messenger = ScaffoldMessenger.maybeOf(context);
      messenger?.showSnackBar(
        SnackBar(
          content: Text(
            result.alreadyMember
                ? 'You\'re already in ${result.name}.'
                : 'Joined ${result.name}!',
          ),
        ),
      );
      Navigator.pushNamed(
        context,
        CircleDetailScreen.routeName,
        arguments: result.circleId,
      );
    } on CircleInviteException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.isRetryable
            ? 'Could not reach the server — check your connection and try '
                  'again.'
            : e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Something went wrong. Try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.viewInsetsOf(context).bottom;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom + insets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fg.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Join with a key',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Enter the invite key a circle member shared with you.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            enabled: !_busy,
            autofocus: widget.prefillCode == null,
            textCapitalization: TextCapitalization.characters,
            autocorrect: false,
            enableSuggestions: false,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
            decoration: InputDecoration(
              hintText: 'XXXX-XXXX',
              hintStyle: TextStyle(color: AppColors.textFaint),
              filled: true,
              fillColor: AppColors.surfaceCard,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (_) => _join(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(
              _error!,
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _busy ? null : _join,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
            child: _busy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Join circle'),
          ),
        ],
      ),
    );
  }
}
