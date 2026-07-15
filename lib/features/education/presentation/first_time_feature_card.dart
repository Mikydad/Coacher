import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/application/main_tab_navigation.dart';
import '../../../core/presentation/app_colors.dart';
import '../../add_task/presentation/add_task_screen.dart';
import '../application/education_providers.dart';
import '../domain/feature_guide.dart';
import '../domain/feature_guides.dart';

/// Once-only explainer shown the first time a user visits a feature screen.
/// Renders nothing while prefs load (no flash) and forever after "Got it".
class FirstTimeFeatureCard extends ConsumerStatefulWidget {
  const FirstTimeFeatureCard({super.key, required this.guideId});

  final String guideId;

  @override
  ConsumerState<FirstTimeFeatureCard> createState() =>
      _FirstTimeFeatureCardState();
}

class _FirstTimeFeatureCardState extends ConsumerState<FirstTimeFeatureCard> {
  bool _expanded = false;

  void _dismiss() {
    ref.read(educationSeenCardsProvider.notifier).markSeen(widget.guideId);
  }

  void _tryIt(FeatureGuide guide) {
    _dismiss();
    if (guide.tryItRoute == AddTaskScreen.routeName) {
      // Add Task is a bottom sheet, not a pushed route.
      showAddTaskSheet(context);
    } else if (guide.tryItRoute != null) {
      Navigator.pushNamed(context, guide.tryItRoute!);
    } else if (guide.tryItTabIndex != null) {
      navigateToMainTab(context, ref, index: guide.tryItTabIndex!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(showFeatureCardProvider(widget.guideId))) {
      return const SizedBox.shrink();
    }
    final guide = FeatureGuides.byId(widget.guideId);
    if (guide == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.inkWarm,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(color: AppColors.accentDim, width: 3),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(14, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(guide.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    guide.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fg,
                    ),
                  ),
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _dismiss,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: AppColors.textSoft,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              guide.oneLiner,
              style: TextStyle(fontSize: 12, color: AppColors.textSoft),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 200),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guide.what,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.fg,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < guide.howSteps.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${i + 1}.  ${guide.howSteps[i]}',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: AppColors.textSoft,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!_expanded)
                  TextButton(
                    onPressed: () => setState(() => _expanded = true),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 32),
                    ),
                    child: Text(
                      'More',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSoft,
                      ),
                    ),
                  ),
                const Spacer(),
                TextButton(
                  onPressed: _dismiss,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 32),
                  ),
                  child: Text(
                    'Got it',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fg,
                    ),
                  ),
                ),
                if (guide.hasTryIt) ...[
                  const SizedBox(width: 4),
                  FilledButton(
                    onPressed: () => _tryIt(guide),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.onAccent,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      minimumSize: const Size(0, 32),
                    ),
                    child: const Text(
                      'Try it',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
