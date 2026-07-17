import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/presentation/app_colors.dart';
import '../../ai_assistant/presentation/ai_assistant_screen.dart';
import '../domain/feature_guide.dart';
import '../domain/feature_guides.dart';

/// Opens the styled help sheet for any page guide or element topic.
/// Unknown ids are a silent no-op so a stale HelpDot can never crash.
Future<void> showHelpSheet(BuildContext context, String guideId) {
  final guide = FeatureGuides.byId(guideId);
  if (guide == null) return Future.value();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfacePanel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => HelpSheet(guide: guide),
  );
}

class HelpSheet extends ConsumerWidget {
  const HelpSheet({super.key, required this.guide});

  final FeatureGuide guide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fg24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '${guide.emoji}  ${guide.title}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.fg,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            guide.oneLiner,
            style: TextStyle(fontSize: 13, color: AppColors.textSoft),
          ),
          const SizedBox(height: 18),
          Text(
            guide.what,
            style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.fg),
          ),
          const SizedBox(height: 16),
          _caption('WHY IT MATTERS'),
          const SizedBox(height: 6),
          Text(
            guide.why,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.textSoft,
            ),
          ),
          if (guide.howSteps.isNotEmpty) ...[
            const SizedBox(height: 16),
            _caption('HOW TO USE IT'),
            const SizedBox(height: 6),
            for (var i = 0; i < guide.howSteps.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accentDim,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        guide.howSteps[i],
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: AppColors.fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (guide.tips.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final tip in guide.tips)
              Text(
                '💡 $tip',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSoft,
                ),
              ),
          ],
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () {
              // Capture the ROOT navigator before popping — this sheet's
              // own context is defunct right after the pop.
              final rootNavigator = Navigator.of(context, rootNavigator: true);
              Navigator.of(context).pop();
              // Prefill only — autoSendMessage would prepend "Help me with:"
              // and break the education phrasing the AI pipeline matches on.
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!rootNavigator.context.mounted) return;
                showCoachAiSheet(
                  rootNavigator.context,
                  args: CoachRouteArgs(
                    preDraftedText: 'Tell me about ${guide.title}',
                  ),
                );
              });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.accent,
              side: BorderSide(color: AppColors.accentDim),
              minimumSize: const Size.fromHeight(44),
            ),
            icon: const Icon(Icons.auto_awesome, size: 16),
            label: const Text(
              'Ask Coach about this',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _caption(String text) => Text(
    text,
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 2,
      color: AppColors.accentDim,
    ),
  );
}
