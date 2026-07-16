import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../accountability/application/blocked_users.dart';
import '../../application/circle_providers.dart';
import '../../../accountability/presentation/stake_reveal_viewer_screen.dart';
import '../../domain/models/activity_feed_item.dart';
import '../../domain/models/circle_enums.dart';
import '../widgets/ai_pulse_banner.dart';

import '../../../../core/presentation/app_colors.dart';
import '../../../../core/presentation/async_value_ui.dart';

// Filter categories shown in the chip row.
enum _FeedFilter { all, goals, habits, tasks }

class CircleActivityView extends ConsumerStatefulWidget {
  const CircleActivityView({super.key, required this.circleId});

  final String circleId;

  @override
  ConsumerState<CircleActivityView> createState() => _CircleActivityViewState();
}

class _CircleActivityViewState extends ConsumerState<CircleActivityView> {
  _FeedFilter _filter = _FeedFilter.all;

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(circleActivityFeedProvider(widget.circleId));
    final circleAsync = ref.watch(circleDetailProvider(widget.circleId));
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isModerator =
        circleAsync.valueOrNull?.moderatorIds.contains(uid) ?? false;

    return Column(
      children: [
        _FilterChipRow(
          selected: _filter,
          onChanged: (f) => setState(() => _filter = f),
        ),
        Expanded(
          child: feedAsync.when(
            loading: () => Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
            error: (e, _) => swallowedAsyncError(
              'circle_activity_view',
              e,
              Center(
                child: Text(
                  'Could not load activity.',
                  style: TextStyle(color: AppColors.textMuted),
                ),
              ),
            ),
            data: (items) {
              final blocked =
                  ref.watch(blockedUidsProvider).valueOrNull ?? const <String>{};
              final visible = blocked.isEmpty
                  ? items
                  : items.where((i) => !blocked.contains(i.userId)).toList();
              final filtered = _applyFilter(visible);

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length + 1,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return AiPulseBanner(
                      circleId: widget.circleId,
                      isModerator: isModerator,
                    );
                  }
                  final item = filtered[i - 1];
                  if (item.eventType == ActivityEventType.memberJoined ||
                      item.eventType == ActivityEventType.memberLeft) {
                    return _SystemActivityPill(item: item);
                  }
                  return _ActivityCard(item: item);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  List<ActivityFeedItem> _applyFilter(List<ActivityFeedItem> items) {
    switch (_filter) {
      case _FeedFilter.all:
        return items;
      case _FeedFilter.goals:
        return items
            .where(
              (i) =>
                  i.eventType == ActivityEventType.goalCompleted ||
                  i.eventType == ActivityEventType.milestoneReached ||
                  i.eventType == ActivityEventType.weeklyCommitmentMet,
            )
            .toList();
      case _FeedFilter.habits:
        return items
            .where((i) => i.eventType == ActivityEventType.habitStreakReached)
            .toList();
      case _FeedFilter.tasks:
        return items
            .where((i) => i.eventType == ActivityEventType.taskFinished)
            .toList();
    }
  }
}

// ── Filter chip row ───────────────────────────────────────────────────────────

class _FilterChipRow extends StatelessWidget {
  const _FilterChipRow({required this.selected, required this.onChanged});

  final _FeedFilter selected;
  final ValueChanged<_FeedFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: _FeedFilter.values.map((f) {
          final isSelected = f == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(
                _filterLabel(f),
                style: TextStyle(
                  color: isSelected ? Colors.black : AppColors.textMuted,
                  fontSize: 13,
                ),
              ),
              selected: isSelected,
              selectedColor: AppColors.accent,
              backgroundColor: AppColors.surfaceCard,
              side: BorderSide(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.fg.withValues(alpha: 0.06),
              ),
              onSelected: (_) => onChanged(f),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _filterLabel(_FeedFilter f) {
    switch (f) {
      case _FeedFilter.all:
        return 'All';
      case _FeedFilter.goals:
        return 'Goals';
      case _FeedFilter.habits:
        return 'Habits';
      case _FeedFilter.tasks:
        return 'Tasks';
    }
  }
}

// ── Activity card ─────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.item});
  final ActivityFeedItem item;

  @override
  Widget build(BuildContext context) {
    // Reveal posts open the secure viewer while the window lasts.
    final revealId = item.eventType == ActivityEventType.stakePhotoRevealed
        ? item.entityId
        : null;
    return GestureDetector(
      onTap: revealId == null
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      StakeRevealViewerScreen(challengeId: revealId),
                ),
              ),
      child: _cardBody(context),
    );
  }

  Widget _cardBody(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fg.withValues(alpha: 0.06)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AvatarInitial(name: item.displayName, userId: item.userId),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                    children: [
                      TextSpan(
                        text: '${item.displayName} ',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      TextSpan(text: _activityCopy(item)),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _relativeTime(item.createdAtMs),
                  style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _EventIcon(item.eventType),
        ],
      ),
    );
  }
}

class _SystemActivityPill extends StatelessWidget {
  const _SystemActivityPill({required this.item});
  final ActivityFeedItem item;

  @override
  Widget build(BuildContext context) {
    final copy = item.eventType == ActivityEventType.memberJoined
        ? '${item.displayName} joined the circle 👋'
        : '${item.displayName} left the circle';

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceCard,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          copy,
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ),
    );
  }
}

// ── Event icon ────────────────────────────────────────────────────────────────

class _EventIcon extends StatelessWidget {
  const _EventIcon(this.eventType);
  final ActivityEventType eventType;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconFor(eventType);
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16, color: color),
    );
  }

  (IconData, Color) _iconFor(ActivityEventType t) {
    switch (t) {
      case ActivityEventType.goalCompleted:
        return (Icons.flag_rounded, AppColors.accent);
      case ActivityEventType.habitStreakReached:
        return (Icons.local_fire_department_rounded, AppColors.orange);
      case ActivityEventType.taskFinished:
        return (Icons.check_circle_rounded, AppColors.cyanDeep);
      case ActivityEventType.milestoneReached:
        return (Icons.emoji_events_rounded, AppColors.yellow);
      case ActivityEventType.weeklyCommitmentMet:
        return (Icons.calendar_today_rounded, AppColors.violet);
      case ActivityEventType.challengeProgressUpdated:
        return (Icons.bar_chart_rounded, AppColors.mint);
      case ActivityEventType.memberJoined:
      case ActivityEventType.memberLeft:
        return (Icons.group_rounded, AppColors.textMuted);
      case ActivityEventType.stakePhotoRevealed:
        return (Icons.local_fire_department_rounded, AppColors.danger);
      case ActivityEventType.screenshotStrike:
        return (Icons.no_photography_rounded, AppColors.danger);
    }
  }
}

// ── Avatar ────────────────────────────────────────────────────────────────────

class _AvatarInitial extends StatelessWidget {
  _AvatarInitial({required this.name, required this.userId});
  final String name;
  final String userId;

  static final _colors = [
    AppColors.accent,
    AppColors.cyanDeep,
    AppColors.orange,
    AppColors.pink,
    AppColors.violet,
    AppColors.mint,
    AppColors.yellow,
    AppColors.danger,
  ];

  Color get _color => _colors[userId.hashCode.abs() % _colors.length];

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 18,
      backgroundColor: _color.withValues(alpha: 0.2),
      child: Text(
        initial,
        style: TextStyle(
          color: _color,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No activity yet.\nComplete a goal or task to see progress here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _activityCopy(ActivityFeedItem item) {
  switch (item.eventType) {
    case ActivityEventType.goalCompleted:
      return 'completed ${item.entityTitle ?? 'a goal'} ✅';
    case ActivityEventType.habitStreakReached:
      return 'reached a ${item.value ?? '?'}-day streak 🔥';
    case ActivityEventType.taskFinished:
      return 'finished ${item.entityTitle ?? 'a task'} 💪';
    case ActivityEventType.milestoneReached:
      return 'hit a milestone: ${item.entityTitle ?? 'unknown'} 🎯';
    case ActivityEventType.weeklyCommitmentMet:
      return 'met their weekly commitment 🏆';
    case ActivityEventType.challengeProgressUpdated:
      return 'updated challenge progress';
    case ActivityEventType.memberJoined:
      return 'joined the circle 👋';
    case ActivityEventType.memberLeft:
      return 'left the circle';
    case ActivityEventType.stakePhotoRevealed:
      return 'broke their promise "${item.entityTitle ?? 'a staked goal'}" — '
          'their stake photo is live. Tap to see it before it\'s gone. 💥';
    case ActivityEventType.screenshotStrike:
      return 'screenshotted a stake photo and is banned from challenges '
          'for ${_banLabel(item.value)} 🚫';
  }
}

String _banLabel(String? banMsRaw) {
  final ms = int.tryParse(banMsRaw ?? '') ?? 0;
  final hours = ms ~/ 3600000;
  if (hours >= 24) return '${hours ~/ 24} day${hours >= 48 ? 's' : ''}';
  return '$hours hours';
}

String _relativeTime(int ms) {
  final dt = DateTime.fromMillisecondsSinceEpoch(ms);
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays == 1) return 'yesterday';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}
