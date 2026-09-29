import 'dart:convert';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/page_headers.dart';
import '../../../core/tier/upgrade_prompt.dart';
import '../../accountability/presentation/accountability_create_flow.dart';
import '../../community/presentation/circle_create_screen.dart';
import '../domain/page_explainers.dart';
import 'explainer_scenes.dart';
import 'help_sheet.dart';

/// Remote Config key: JSON map of explainer id → video URL, e.g.
/// `{"accountability": "https://youtu.be/…"}`. An id with no URL shows no
/// video row, so videos can be added (or swapped) without a release.
const kRemoteConfigExplainerVideos = 'explainer_videos_v1';

/// The video link for [explainerId], or null. Synchronous on purpose: reads
/// whatever Remote Config already activated this session and never waits
/// on the network — no video row is better than a slow sheet.
Uri? explainerVideoUrl(String explainerId) {
  try {
    final raw = FirebaseRemoteConfig.instance.getString(
      kRemoteConfigExplainerVideos,
    );
    if (raw.isEmpty) return null;
    final url = (jsonDecode(raw) as Map<String, dynamic>)[explainerId];
    if (url is! String || url.isEmpty) return null;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme ? uri : null;
  } catch (_) {
    // No Firebase (tests), unfetched, or malformed console value.
    return null;
  }
}

/// Presents [explainer]. [fromHelp] is the `?` path: the quiet link under
/// the button becomes "More details" (the long guide) instead of
/// "Maybe later", since the user asked for help rather than being shown it.
Future<void> showPageExplainer(
  BuildContext context,
  PageExplainer explainer, {
  bool fromHelp = false,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: AppColors.surfacePanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => PageExplainerSheet(
      explainer: explainer,
      fromHelp: fromHelp,
      videoUrl: explainerVideoUrl(explainer.id),
    ),
  );
}

class PageExplainerSheet extends StatelessWidget {
  const PageExplainerSheet({
    super.key,
    required this.explainer,
    this.fromHelp = false,
    this.videoUrl,
  });

  final PageExplainer explainer;
  final bool fromHelp;
  final Uri? videoUrl;

  @override
  Widget build(BuildContext context) {
    final e = explainer;
    final showMoreDetails = fromHelp && e.guideId != null;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          16 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.fg24,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            ExplainerSceneView(scene: e.scene),
            const SizedBox(height: 18),
            SectionHeader(e.title),
            const SizedBox(height: 6),
            Text(
              e.body,
              style: TextStyle(fontSize: 15, height: 1.45, color: AppColors.fg),
            ),
            const SizedBox(height: 14),
            _ExampleQuote(e.example),
            const SizedBox(height: 18),
            _StepsRow(e.steps),
            const SizedBox(height: 16),
            Text(
              e.why,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                fontStyle: FontStyle.italic,
                color: AppColors.textSoft,
              ),
            ),
            if (videoUrl != null) ...[
              const SizedBox(height: 14),
              _VideoRow(url: videoUrl!),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => _onPrimary(context),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                e.primaryLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => showMoreDetails
                  ? _openDetails(context, e.guideId!)
                  : Navigator.of(context).pop(),
              child: Text(
                showMoreDetails ? 'More details' : 'Maybe later',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSoft,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onPrimary(BuildContext context) {
    // Capture the ROOT navigator before popping — this sheet's own context
    // is defunct right after the pop.
    final root = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop();
    final action = explainer.action;
    if (action == ExplainerAction.dismiss) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final ctx = root.context;
      if (!ctx.mounted) return;
      switch (action) {
        case ExplainerAction.createStake:
          await openAccountabilityCreateFlow(ctx);
        case ExplainerAction.createGroup:
          // Same gate as the Group FAB: creating needs a real identity.
          if (await ensureAccountFor(ctx, feature: 'groups') && ctx.mounted) {
            await Navigator.of(ctx).pushNamed(CircleCreateScreen.routeName);
          }
        case ExplainerAction.dismiss:
          break;
      }
    });
  }

  void _openDetails(BuildContext context, String guideId) {
    final root = Navigator.of(context, rootNavigator: true);
    Navigator.of(context).pop();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (root.context.mounted) showGuideSheet(root.context, guideId);
    });
  }
}

class _ExampleQuote extends StatelessWidget {
  const _ExampleQuote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EXAMPLE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.6,
              color: AppColors.accentDim,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.fg),
          ),
        ],
      ),
    );
  }
}

class _StepsRow extends StatelessWidget {
  const _StepsRow(this.steps);

  final List<ExplainerStep> steps;

  static final _tints = [
    () => AppColors.violet,
    () => AppColors.cyan,
    () => AppColors.coral,
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (i, step) in steps.indexed) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: AppColors.fg38,
              ),
            ),
          Expanded(
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _tints[i % 3]().withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(step.icon),
                    size: 20,
                    color: _tints[i % 3](),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  step.label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.3,
                    color: AppColors.textSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _VideoRow extends StatelessWidget {
  const _VideoRow({required this.url});

  final Uri url;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => launchUrl(url, mode: LaunchMode.externalApplication),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.fg12),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.play_arrow_rounded,
                color: AppColors.danger,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'See how it works',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fg,
                    ),
                  ),
                  Text(
                    'Short video',
                    style: TextStyle(fontSize: 12, color: AppColors.textSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.open_in_new_rounded, size: 16, color: AppColors.fg38),
          ],
        ),
      ),
    );
  }
}

IconData _iconFor(ExplainerIcon icon) => switch (icon) {
  ExplainerIcon.target => Icons.track_changes_rounded,
  ExplainerIcon.camera => Icons.photo_camera_rounded,
  ExplainerIcon.lock => Icons.lock_rounded,
  ExplainerIcon.groupAdd => Icons.group_add_rounded,
  ExplainerIcon.checklist => Icons.checklist_rounded,
  ExplainerIcon.eye => Icons.visibility_rounded,
  ExplainerIcon.flag => Icons.flag_rounded,
  ExplainerIcon.route => Icons.route_rounded,
  ExplainerIcon.calendar => Icons.calendar_month_rounded,
  ExplainerIcon.moveOn => Icons.update_rounded,
  ExplainerIcon.question => Icons.help_outline_rounded,
  ExplainerIcon.shield => Icons.shield_rounded,
  ExplainerIcon.chat => Icons.chat_bubble_rounded,
  ExplainerIcon.sparkle => Icons.auto_awesome_rounded,
  ExplainerIcon.undo => Icons.undo_rounded,
};
