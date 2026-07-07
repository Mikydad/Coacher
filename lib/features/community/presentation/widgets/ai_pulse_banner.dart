import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/ai_pulse_providers.dart';
import '../sheets/challenge_create_sheet.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';

class AiPulseBanner extends ConsumerStatefulWidget {
  const AiPulseBanner({
    super.key,
    required this.circleId,
    required this.isModerator,
  });

  final String circleId;
  final bool isModerator;

  @override
  ConsumerState<AiPulseBanner> createState() => _AiPulseBannerState();
}

class _AiPulseBannerState extends ConsumerState<AiPulseBanner> {
  bool _expanded = false;
  bool _generating = false;
  String? _updatedLabel;

  Future<void> _generate() async {
    setState(() {
      _generating = true;
      _updatedLabel = null;
    });
    try {
      final pulse = await ref
          .read(circleAiPulseServiceProvider)
          .generateDailyPulse(widget.circleId);
      if (mounted) {
        setState(() {
          _updatedLabel = pulse != null
              ? 'Updated just now'
              : 'Nothing new yet';
        });
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pulseAsync = ref.watch(latestDailyPulseProvider(widget.circleId));

    return pulseAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (e, _) =>
          swallowedAsyncError('ai_pulse_banner', e, const SizedBox.shrink()),
      data: (pulse) {
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.dark1A2535, AppColors.surfaceDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Collapsed header ─────────────────────────────────────────
              GestureDetector(
                onTap: pulse != null
                    ? () => setState(() => _expanded = !_expanded)
                    : null,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      _PulsingDot(),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          pulse?.summary ?? 'No pulse yet — generate one below',
                          style: TextStyle(
                            color: pulse != null
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                            fontSize: 13,
                            fontWeight: pulse != null
                                ? FontWeight.w500
                                : FontWeight.normal,
                          ),
                          maxLines: _expanded ? null : 1,
                          overflow: _expanded
                              ? TextOverflow.visible
                              : TextOverflow.ellipsis,
                        ),
                      ),
                      if (pulse != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          _expanded ? '↑ Pulse' : '↓ Pulse',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Expanded content ──────────────────────────────────────────
              if (_expanded && pulse != null) ...[
                const Divider(height: 1, color: AppColors.surfaceSlate),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Member lines
                      ...pulse.memberLines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _MemberAvatar(
                                name: line.displayName,
                                userId: line.userId,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.displayName,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      line.insight,
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Suggested challenge
                      if (pulse.suggestedChallenge != null) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.lightbulb_outline,
                                color: AppColors.accent,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Suggested: ${pulse.suggestedChallenge}',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ChallengeCreateSheet(
                                    circleId: widget.circleId,
                                  ),
                                ),
                                child: const Text(
                                  'Start',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: AppColors.accent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ── Moderator generate button ─────────────────────────────────
              if (widget.isModerator)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                  child: Row(
                    children: [
                      if (_updatedLabel != null)
                        Text(
                          _updatedLabel!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      const Spacer(),
                      _generating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accent,
                              ),
                            )
                          : TextButton.icon(
                              onPressed: _generate,
                              icon: const Icon(
                                Icons.auto_awesome,
                                size: 14,
                                color: AppColors.accent,
                              ),
                              label: const Text(
                                'Generate now',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 12,
                                ),
                              ),
                              style: TextButton.styleFrom(
                                minimumSize: Size.zero,
                                padding: EdgeInsets.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: Color.fromRGBO(183, 255, 0, _anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({required this.name, required this.userId});
  final String name;
  final String userId;

  static const _colors = [
    AppColors.accent,
    AppColors.cyanDeep,
    AppColors.orange,
    AppColors.pink,
    AppColors.violet,
  ];

  Color get _color => _colors[userId.hashCode.abs() % _colors.length];

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: _color.withValues(alpha: 0.2),
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
