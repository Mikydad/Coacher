import '../../education/presentation/first_time_feature_card.dart';
import '../../education/presentation/help_dot.dart';
import '../../../core/firebase/firestore_paths.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/circle_providers.dart';
import '../domain/models/accountability_circle.dart';
import 'circle_create_screen.dart';
import 'circle_detail_screen.dart';
import 'circle_discovery_screen.dart';

import '../../../core/presentation/app_colors.dart';
import '../../../core/presentation/async_value_ui.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  static const routeName = '/community';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idsAsync = ref.watch(myCircleIdsProvider);
    final circlesAsync = ref.watch(myCirclesProvider);

    return Scaffold(
      backgroundColor: AppColors.surfaceDeep,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimary,
        title: Text(
          'My Circles',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        elevation: 0,
        actions: [
          const HelpAppBarButton('circles'),
          IconButton(
            icon: Icon(Icons.explore_rounded, color: AppColors.textMuted),
            tooltip: 'Discover circles',
            onPressed: () =>
                Navigator.pushNamed(context, CircleDiscoveryScreen.routeName),
          ),
        ],
      ),
      body: (idsAsync.isLoading && !idsAsync.hasValue)
          ? Center(child: CircularProgressIndicator(color: AppColors.accent))
          : circlesAsync.when(
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
              error: (e, _) => swallowedAsyncError(
                'community_screen',
                e,
                Center(
                  child: Text(
                    'Could not load circles.',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              ),
              data: (circles) {
                if (circles.isEmpty) {
                  // Discovery-first: instead of a bare empty state, surface
                  // existing public circles to browse and join immediately.
                  // Creating a circle stays available via the '+ Circle' FAB.
                  return const _DiscoverCirclesState();
                }
                return RefreshIndicator(
                  color: AppColors.accent,
                  backgroundColor: AppColors.surfaceDark,
                  onRefresh: () async => invalidateCircleScopedProviders(ref),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    // Index 0 is the once-only intro card.
                    itemCount: circles.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => i == 0
                        ? const FirstTimeFeatureCard(guideId: 'circles')
                        : _MyCircleCard(
                            circle: circles[i - 1],
                            onTap: () => Navigator.pushNamed(
                              context,
                              CircleDetailScreen.routeName,
                              arguments: circles[i - 1].id,
                            ),
                          ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'community_tab_fab',
        onPressed: () => _showCreateOrDiscover(context),
        backgroundColor: AppColors.accent,
        foregroundColor: AppColors.onAccent,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Circle',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  void _showCreateOrDiscover(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.fg.withOpacity(0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceCard,
                child: Icon(Icons.add_rounded, color: AppColors.accent),
              ),
              title: Text(
                'Create a circle',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Start a new accountability circle',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, CircleCreateScreen.routeName);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceCard,
                child: Icon(Icons.explore_rounded, color: AppColors.cyanDeep),
              ),
              title: Text(
                'Discover circles',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                'Browse and join existing circles',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pushNamed(context, CircleDiscoveryScreen.routeName);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Zero-circles state: discover-first ──────────────────────────────────────
//
// Shown when the user hasn't joined or created any circles yet. Rather than a
// bare empty state, it surfaces the same public-circle list & join action as
// CircleDiscoveryScreen (via `discoverCirclesProvider` / `joinOrRequestCircle`
// / `CircleCard`, all defined in circle_discovery_screen.dart) so discovery is
// the default. Creating a circle stays reachable through the '+ Circle' FAB.

class _DiscoverCirclesState extends ConsumerWidget {
  const _DiscoverCirclesState();

  static const String? _category = null; // all categories

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoverAsync = ref.watch(discoverCirclesProvider(_category));
    final joinedIds = ref.watch(myCircleIdsProvider).valueOrNull?.toSet() ?? {};
    // FirestorePaths guards the no-Firebase case (VM/widget tests) — a raw
    // FirebaseAuth.instance here throws before any provider can swallow it.
    final currentUid = FirestorePaths.activeUid;

    return RefreshIndicator(
      color: AppColors.accent,
      backgroundColor: AppColors.surfaceDark,
      onRefresh: () async => ref.invalidate(discoverCirclesProvider(_category)),
      child: discoverAsync.when(
        loading: () => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            const FirstTimeFeatureCard(guideId: 'circles'),
            const SizedBox(height: 24),
            const _DiscoverHeader(),
            const SizedBox(height: 40),
            Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            ),
          ],
        ),
        error: (e, _) => swallowedAsyncError(
          'community_screen_discover',
          e,
          ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              const FirstTimeFeatureCard(guideId: 'circles'),
              const SizedBox(height: 24),
              const _DiscoverHeader(),
              const SizedBox(height: 40),
              Text(
                'Could not load circles to discover.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
        data: (circles) {
          final itemCount = circles.isEmpty ? 3 : circles.length + 2;
          return ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: itemCount,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              if (i == 0) {
                return const FirstTimeFeatureCard(guideId: 'circles');
              }
              if (i == 1) return const _DiscoverHeader();
              if (circles.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(
                    'No public circles yet. Be the first to create one!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 14),
                  ),
                );
              }
              final circle = circles[i - 2];
              final isJoined =
                  joinedIds.contains(circle.id) ||
                  (currentUid.isNotEmpty && circle.creatorId == currentUid);
              return CircleCard(
                circle: circle,
                joined: isJoined,
                onJoin: (c) =>
                    joinOrRequestCircle(context: context, ref: ref, circle: c),
              );
            },
          );
        },
      ),
    );
  }
}

class _DiscoverHeader extends StatelessWidget {
  const _DiscoverHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Discover circles',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Join an existing circle or create your own.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
      ],
    );
  }
}

// ── Circle card ───────────────────────────────────────────────────────────────

class _MyCircleCard extends StatelessWidget {
  const _MyCircleCard({required this.circle, required this.onTap});

  final AccountabilityCircle circle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fg.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            // Category icon/initial
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  circle.category.isNotEmpty
                      ? circle.category[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    circle.name,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.group_rounded,
                        size: 13,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${circle.memberCount}/${AccountabilityCircle.kMaxMembers}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _CategoryBadge(circle.category),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (circle.currentStreak > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🔥', style: TextStyle(fontSize: 13)),
                      const SizedBox(width: 2),
                      Text(
                        '${circle.currentStreak}',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge(this.category);
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category[0].toUpperCase() + category.substring(1),
        style: TextStyle(color: AppColors.textMuted, fontSize: 11),
      ),
    );
  }
}
