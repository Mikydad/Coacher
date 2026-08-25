import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../application/circle_invite_functions.dart';

/// The "share this circle" sheet (2026-08-26): shows the circle's invite
/// key, minted server-side on demand. Any active member can copy/share it;
/// moderators can regenerate (which revokes the old key). The key IS the
/// approval — whoever holds it joins straight in, including into private
/// circles, which have no other door.
Future<void> showCircleInviteSheet(
  BuildContext context, {
  required String circleId,
  required String circleName,
  required bool isModerator,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceDark,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CircleInviteSheet(
      circleId: circleId,
      circleName: circleName,
      isModerator: isModerator,
    ),
  );
}

class _CircleInviteSheet extends ConsumerStatefulWidget {
  const _CircleInviteSheet({
    required this.circleId,
    required this.circleName,
    required this.isModerator,
  });

  final String circleId;
  final String circleName;
  final bool isModerator;

  @override
  ConsumerState<_CircleInviteSheet> createState() => _CircleInviteSheetState();
}

class _CircleInviteSheetState extends ConsumerState<_CircleInviteSheet> {
  String? _code;
  String? _error;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch({bool regenerate = false}) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final code = await ref
          .read(circleInviteFunctionsProvider)
          .inviteCode(widget.circleId, regenerate: regenerate);
      if (!mounted) return;
      setState(() {
        _code = code;
        _busy = false;
      });
    } on CircleInviteException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not reach the server. Check your connection.';
        _busy = false;
      });
    }
  }

  String get _shareText =>
      'Join my circle "${widget.circleName}" on SidePal!\n'
      'Open SidePal → Community → Join with a key, and enter: $_code\n'
      'Or tap: sidepal://join/$_code';

  Future<void> _regenerate() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: Text(
          'Regenerate the key?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        content: Text(
          'The current key stops working immediately — anyone you already '
          'sent it to will need the new one.',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _fetch(regenerate: true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
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
            'Invite members',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Anyone with this key joins "${widget.circleName}" directly — '
            'share it only with people you want in.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 18),
          if (_busy)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: CircularProgressIndicator(),
              ),
            )
          else if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: AppColors.danger, fontSize: 13),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => _fetch(),
              child: const Text('Try again'),
            ),
          ] else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.4),
                ),
              ),
              child: Text(
                _code ?? '',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: _code!));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Key copied.')),
                        );
                      }
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(text: _shareText),
                    ),
                    icon: const Icon(Icons.ios_share_rounded, size: 18),
                    label: const Text('Share'),
                  ),
                ),
              ],
            ),
            if (widget.isModerator) ...[
              const SizedBox(height: 6),
              TextButton(
                onPressed: _regenerate,
                child: Text(
                  'Regenerate key (revokes the current one)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
