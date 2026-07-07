import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/keyboard_dismiss.dart';
import '../../auth/application/auth_providers.dart';
import '../application/circle_providers.dart';
import '../domain/models/circle_enums.dart';
import '../domain/models/circle_member.dart';
import 'views/circle_activity_view.dart';
import 'views/circle_chat_view.dart';
import 'views/circle_members_view.dart';
import 'views/circle_challenges_view.dart';
import 'views/circle_info_view.dart';
import 'views/weekly_commitments_view.dart';

import '../../../core/presentation/app_colors.dart';

class CircleDetailScreen extends ConsumerStatefulWidget {
  const CircleDetailScreen({super.key, required this.circleId});

  final String circleId;

  static const routeName = '/community/circle';

  @override
  ConsumerState<CircleDetailScreen> createState() => _CircleDetailScreenState();
}

class _CircleDetailScreenState extends ConsumerState<CircleDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    'Chat',
    'Activity',
    'Commitments',
    'Challenges',
    'Members',
    'Info',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging) {
        dismissKeyboard(context);
      } else {
        ref.read(circleActiveTabProvider(widget.circleId).notifier).state =
            _tabController.index;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(userCircleMembershipServiceProvider)
          .ensureCircleIndex(widget.circleId);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(authStateProvider);
    final circleAsync = ref.watch(circleDetailProvider(widget.circleId));
    final membersAsync = ref.watch(circleMembersProvider(widget.circleId));

    if (authAsync.isLoading && !authAsync.hasValue) {
      return const Scaffold(
        backgroundColor: AppColors.surfaceDeep,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent)),
      );
    }

    // When the circle document is deleted (stream emits null), go back
    // immediately instead of showing a "not found" placeholder.
    ref.listen<AsyncValue<dynamic>>(circleDetailProvider(widget.circleId), (
      _,
      next,
    ) {
      if (next is AsyncData && next.value == null) {
        if (context.mounted) {
          Navigator.of(context).popUntil((r) {
            return r.settings.name == '/community' || r.isFirst;
          });
        }
      }
    });

    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      body: circleAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              kDebugMode
                  ? 'Could not load circle.\n$e'
                  : 'Could not load circle.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
        ),
        data: (circle) {
          if (circle == null) {
            // Navigation is handled by the listener above; show a brief
            // loading indicator while the pop animation plays.
            return const Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            );
          }

          final activeMembers =
              membersAsync.valueOrNull
                  ?.where((m) => m.status == CircleMemberStatus.active)
                  .toList() ??
              [];

          return KeyboardDismissOnTap(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverAppBar(
                  backgroundColor: AppColors.surfaceDark,
                  foregroundColor: AppColors.textPrimary,
                  expandedHeight: 200,
                  pinned: true,
                  floating: false,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _CircleHeader(
                      circleName: circle.name,
                      streak: circle.currentStreak,
                      memberCount: circle.memberCount,
                      members: activeMembers,
                    ),
                  ),
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(48),
                    child: TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelColor: AppColors.accent,
                      unselectedLabelColor: AppColors.textMuted,
                      indicatorColor: AppColors.accent,
                      indicatorSize: TabBarIndicatorSize.label,
                      tabAlignment: TabAlignment.start,
                      tabs: _tabs.map((t) => Tab(text: t)).toList(),
                    ),
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Chat
                  CircleChatView(circleId: widget.circleId),
                  // Activity
                  CircleActivityView(circleId: widget.circleId),
                  // Commitments
                  WeeklyCommitmentsView(circleId: widget.circleId),
                  // Challenges
                  CircleChallengesView(circleId: widget.circleId),
                  // Members
                  CircleMembersView(circleId: widget.circleId),
                  // Info
                  CircleInfoView(circleId: widget.circleId),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _CircleHeader extends StatelessWidget {
  const _CircleHeader({
    required this.circleName,
    required this.streak,
    required this.memberCount,
    required this.members,
  });

  final String circleName;
  final int streak;
  final int memberCount;
  final List<CircleMember> members;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Dark background
        Container(color: AppColors.surfaceDeep),
        // Glass card
        Positioned.fill(
          child: ClipRRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(color: Colors.white.withOpacity(0.05)),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        circleName,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (streak > 0) _StreakBadge(streak),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  '$memberCount / ${AccountabilityCircleConst.kMaxMembers} members',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                if (members.isNotEmpty) _MemberAvatarRow(members: members),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StreakBadge extends StatelessWidget {
  const _StreakBadge(this.streak);
  final int streak;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 4),
          Text(
            '$streak day${streak == 1 ? '' : 's'}',
            style: const TextStyle(
              color: AppColors.accent,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberAvatarRow extends StatelessWidget {
  const _MemberAvatarRow({required this.members});
  final List<CircleMember> members;

  static const _colors = [
    AppColors.accent,
    AppColors.cyanDeep,
    AppColors.orange,
    AppColors.pink,
    AppColors.violet,
    AppColors.mint,
    AppColors.yellow,
    AppColors.danger,
  ];

  Color _colorFor(String userId) =>
      _colors[userId.hashCode.abs() % _colors.length];

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    // Show at most 8 avatars
    final visible = members.take(8).toList();

    return Row(
      children: visible.map((m) {
        final initial = m.displayName.isNotEmpty
            ? m.displayName[0].toUpperCase()
            : '?';
        final color = _colorFor(m.userId);
        final isMe = m.userId == uid;

        return Padding(
          padding: const EdgeInsets.only(right: 6),
          child: Tooltip(
            message: m.displayName,
            child: CircleAvatar(
              radius: 18,
              backgroundColor: color.withOpacity(isMe ? 1.0 : 0.2),
              child: Text(
                initial,
                style: TextStyle(
                  color: isMe ? Colors.black : color,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Placeholder tab ───────────────────────────────────────────────────────────

class _PlaceholderTab extends StatelessWidget {
  const _PlaceholderTab(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        message,
        style: const TextStyle(color: AppColors.textMuted, fontSize: 15),
      ),
    );
  }
}

// Helper constant to avoid importing the full model just for kMaxMembers
class AccountabilityCircleConst {
  static const int kMaxMembers = 8;
}
