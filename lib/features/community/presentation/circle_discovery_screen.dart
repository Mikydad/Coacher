import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/presentation/keyboard_dismiss.dart';
import '../application/circle_providers.dart';
import '../application/circle_recommendation_service.dart';
import '../application/user_circle_membership_service.dart';
import '../domain/models/accountability_circle.dart';
import '../domain/models/circle_enums.dart';
import 'circle_detail_screen.dart';

const _kAllCategories = [
  'all',
  'fitness',
  'learning',
  'business',
  'reading',
  'productivity',
  'other',
];

class CircleDiscoveryScreen extends ConsumerStatefulWidget {
  const CircleDiscoveryScreen({super.key});

  static const routeName = '/community/discover';

  @override
  ConsumerState<CircleDiscoveryScreen> createState() =>
      _CircleDiscoveryScreenState();
}

class _CircleDiscoveryScreenState
    extends ConsumerState<CircleDiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();

  String _selectedCategory = 'all';
  List<AccountabilityCircle>? _browseCircles;
  List<AccountabilityCircle> _searchResults = [];
  List<ScoredCircle> _recommendations = [];
  bool _loadingBrowse = false;
  bool _loadingSearch = false;
  Timer? _debounce;
  bool _recommendationsFetched = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      if (_tabController.indexIsChanging) {
        dismissKeyboard(context);
      }
    });
    _fetchBrowse();
  }

  Future<void> _fetchRecommendations(List<String> joinedIds) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isEmpty) return;

      final svc = CircleRecommendationService(
        circleRepo: ref.read(circleRepositoryProvider),
      );
      final recs = await svc.getRecommendations(
        userId: uid,
        activeGoalCategories: const [],
        userTimezone: DateTime.now().timeZoneName,
        alreadyJoinedIds: joinedIds,
      );
      if (mounted) setState(() => _recommendations = recs.take(5).toList());
    } catch (_) {}
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _fetchBrowse({String? category}) async {
    setState(() => _loadingBrowse = true);
    try {
      final results = await ref.read(circleRepositoryProvider).searchCircles(
            category: (category == null || category == 'all') ? null : category,
          );
      if (mounted) setState(() => _browseCircles = results);
    } catch (_) {
      if (mounted) setState(() => _browseCircles = []);
    } finally {
      if (mounted) setState(() => _loadingBrowse = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() => _loadingSearch = true);
      try {
        final results =
            await ref.read(circleRepositoryProvider).searchCircles(query: query.trim());
        if (mounted) setState(() => _searchResults = results);
      } catch (_) {
        if (mounted) setState(() => _searchResults = []);
      } finally {
        if (mounted) setState(() => _loadingSearch = false);
      }
    });
  }

  Future<void> _joinOrRequest(AccountabilityCircle circle) async {
    // Read the live joined-IDs set straight from the provider
    final joinedIds = ref.read(myCircleIdsProvider).valueOrNull?.toSet() ?? {};

    // Already a member — navigate directly instead of joining again
    if (joinedIds.contains(circle.id)) {
      if (mounted) {
        Navigator.pushNamed(
          context,
          CircleDetailScreen.routeName,
          arguments: circle.id,
        );
      }
      return;
    }

    final service = ref.read(userCircleMembershipServiceProvider);
    try {
      if (circle.joinPolicy == JoinPolicy.open) {
        await service.joinCircle(circle.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Joined ${circle.name}!')),
          );
          Navigator.pushNamed(
            context,
            CircleDetailScreen.routeName,
            arguments: circle.id,
          );
        }
      } else {
        await service.requestJoin(circle.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request sent to ${circle.name}.')),
          );
        }
      }
    } on CircleLimitException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } on CircleFullException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Something went wrong. Try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always read live from Riverpod — no local copy needed.
    final joinedIds =
        ref.watch(myCircleIdsProvider).valueOrNull?.toSet() ?? {};

    // Fetch recommendations once we have the joined-IDs list.
    if (!_recommendationsFetched && joinedIds.isNotEmpty) {
      _recommendationsFetched = true;
      WidgetsBinding.instance.addPostFrameCallback(
          (_) => _fetchRecommendations(joinedIds.toList()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFF15171B),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E2126),
        foregroundColor: const Color(0xFFF0F4FF),
        title: const Text(
          'Discover circles',
          style: TextStyle(
            color: Color(0xFFF0F4FF),
            fontWeight: FontWeight.w600,
          ),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFB7FF00),
          unselectedLabelColor: const Color(0xFF8A8FA8),
          indicatorColor: const Color(0xFFB7FF00),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'Browse'),
            Tab(text: 'Search'),
          ],
        ),
      ),
      body: KeyboardDismissOnTap(
        child: TabBarView(
        controller: _tabController,
        children: [
          _BrowseTab(
            circles: _browseCircles,
            recommendations: _recommendations,
            loading: _loadingBrowse,
            selectedCategory: _selectedCategory,
            joinedIds: joinedIds,
            onCategoryChanged: (cat) {
              setState(() => _selectedCategory = cat);
              _fetchBrowse(category: cat);
            },
            onJoin: _joinOrRequest,
          ),
          _SearchTab(
            controller: _searchController,
            results: _searchResults,
            loading: _loadingSearch,
            joinedIds: joinedIds,
            onChanged: _onSearchChanged,
            onJoin: _joinOrRequest,
          ),
        ],
      ),
      ),
    );
  }
}

// ── Browse tab ────────────────────────────────────────────────────────────────

class _BrowseTab extends StatelessWidget {
  const _BrowseTab({
    required this.circles,
    required this.recommendations,
    required this.loading,
    required this.selectedCategory,
    required this.joinedIds,
    required this.onCategoryChanged,
    required this.onJoin,
  });

  final List<AccountabilityCircle>? circles;
  final List<ScoredCircle> recommendations;
  final bool loading;
  final String selectedCategory;
  final Set<String> joinedIds;
  final ValueChanged<String> onCategoryChanged;
  final Future<void> Function(AccountabilityCircle) onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CategoryChipRow(
          selected: selectedCategory,
          onChanged: onCategoryChanged,
        ),
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFB7FF00),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Recommendations section
                    if (recommendations.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.only(bottom: 10),
                        child: Text(
                          'RECOMMENDED FOR YOU',
                          style: TextStyle(
                            color: Color(0xFF8A8FA8),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: recommendations.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (_, i) =>
                              _RecommendedCircleCard(
                            scored: recommendations[i],
                            onJoin: onJoin,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'ALL CIRCLES',
                        style: TextStyle(
                          color: Color(0xFF8A8FA8),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    // All circles list
                    if (circles == null || circles!.isEmpty)
                      _EmptyState(
                        message: selectedCategory == 'all'
                            ? 'No circles yet. Create the first one!'
                            : 'No $selectedCategory circles yet.',
                      )
                    else
                      ...circles!.map(
                        (c) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _CircleCard(
                            circle: c,
                            joined: joinedIds.contains(c.id),
                            onJoin: onJoin,
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RecommendedCircleCard extends StatelessWidget {
  const _RecommendedCircleCard({
    required this.scored,
    required this.onJoin,
  });

  final ScoredCircle scored;
  final Future<void> Function(AccountabilityCircle) onJoin;

  @override
  Widget build(BuildContext context) {
    final circle = scored.circle;
    return GestureDetector(
      onTap: () => Navigator.pushNamed(
        context,
        CircleDetailScreen.routeName,
        arguments: circle.id,
      ),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF1E2126),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB7FF00).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    circle.name,
                    style: const TextStyle(
                      color: Color(0xFFF0F4FF),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              scored.matchReason,
              style: const TextStyle(
                color: Color(0xFFB7FF00),
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Row(
              children: [
                const Icon(Icons.people_outline,
                    color: Color(0xFF8A8FA8), size: 12),
                const SizedBox(width: 4),
                Text(
                  '${circle.memberCount}/${AccountabilityCircle.kMaxMembers}',
                  style: const TextStyle(
                    color: Color(0xFF8A8FA8),
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => onJoin(circle),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB7FF00),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'Join',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChipRow extends StatelessWidget {
  const _CategoryChipRow({
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _kAllCategories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _kAllCategories[i];
          final isSelected = cat == selected;
          return ChoiceChip(
            label: Text(
              cat[0].toUpperCase() + cat.substring(1),
              style: TextStyle(
                color: isSelected ? Colors.black : const Color(0xFF8A8FA8),
                fontSize: 13,
              ),
            ),
            selected: isSelected,
            selectedColor: const Color(0xFFB7FF00),
            backgroundColor: const Color(0xFF1F232A),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFFB7FF00)
                  : Colors.white.withOpacity(0.06),
            ),
            onSelected: (_) => onChanged(cat),
          );
        },
      ),
    );
  }
}

// ── Search tab ────────────────────────────────────────────────────────────────

class _SearchTab extends StatelessWidget {
  const _SearchTab({
    required this.controller,
    required this.results,
    required this.loading,
    required this.joinedIds,
    required this.onChanged,
    required this.onJoin,
  });

  final TextEditingController controller;
  final List<AccountabilityCircle> results;
  final bool loading;
  final Set<String> joinedIds;
  final ValueChanged<String> onChanged;
  final Future<void> Function(AccountabilityCircle) onJoin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: controller,
            onChanged: onChanged,
            onTapOutside: (_) => dismissKeyboard(context),
            style: const TextStyle(color: Color(0xFFF0F4FF)),
            decoration: InputDecoration(
              hintText: 'Search circles…',
              hintStyle: const TextStyle(color: Color(0xFF8A8FA8)),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: Color(0xFF8A8FA8)),
              filled: true,
              fillColor: const Color(0xFF1E2126),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    BorderSide(color: Colors.white.withOpacity(0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFB7FF00)),
              ),
            ),
          ),
        ),
        Expanded(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFB7FF00),
                  ),
                )
              : controller.text.isEmpty
                  ? const _EmptyState(message: 'Start typing to search…')
                  : results.isEmpty
                      ? _EmptyState(
                          message:
                              'No circles found for "${controller.text}"',
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: results.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _CircleCard(
                            circle: results[i],
                            joined: joinedIds.contains(results[i].id),
                            onJoin: onJoin,
                          ),
                        ),
        ),
      ],
    );
  }
}

// ── Shared circle card ────────────────────────────────────────────────────────

class _CircleCard extends StatefulWidget {
  const _CircleCard({
    required this.circle,
    required this.onJoin,
    this.joined = false,
  });

  final AccountabilityCircle circle;
  final Future<void> Function(AccountabilityCircle) onJoin;
  final bool joined;

  @override
  State<_CircleCard> createState() => _CircleCardState();
}

class _CircleCardState extends State<_CircleCard> {
  bool _joining = false;

  @override
  Widget build(BuildContext context) {
    final circle = widget.circle;
    final isFull =
        circle.memberCount >= AccountabilityCircle.kMaxMembers;
    final isJoined = widget.joined;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2126),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  circle.name,
                  style: const TextStyle(
                    color: Color(0xFFF0F4FF),
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              _CategoryBadge(circle.category),
            ],
          ),
          if (circle.description != null && circle.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              circle.description!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8A8FA8),
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.group_rounded,
                  size: 14, color: Color(0xFF8A8FA8)),
              const SizedBox(width: 4),
              Text(
                '${circle.memberCount}/${AccountabilityCircle.kMaxMembers}',
                style: const TextStyle(
                  color: Color(0xFF8A8FA8),
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.schedule_rounded,
                  size: 14, color: Color(0xFF8A8FA8)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  circle.timezone,
                  style: const TextStyle(
                    color: Color(0xFF8A8FA8),
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _PolicyBadge(circle.joinPolicy),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (isFull && !isJoined) || _joining
                  ? null
                  : () async {
                      if (isJoined) {
                        // Already a member — navigate straight in
                        Navigator.pushNamed(
                          context,
                          CircleDetailScreen.routeName,
                          arguments: circle.id,
                        );
                        return;
                      }
                      setState(() => _joining = true);
                      await widget.onJoin(circle);
                      if (mounted) setState(() => _joining = false);
                    },
              style: FilledButton.styleFrom(
                backgroundColor: isJoined
                    ? const Color(0xFF1F232A)
                    : isFull
                        ? const Color(0xFF1F232A)
                        : const Color(0xFFB7FF00),
                foregroundColor: isJoined
                    ? const Color(0xFF8A8FA8)
                    : isFull
                        ? const Color(0xFF8A8FA8)
                        : Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: const Size.fromHeight(40),
              ),
              child: _joining
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black),
                    )
                  : Text(
                      isJoined
                          ? 'Open'
                          : isFull
                              ? 'Full'
                              : circle.joinPolicy == JoinPolicy.open
                                  ? 'Join'
                                  : 'Request to join',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
            ),
          ),
        ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFB7FF00).withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        category[0].toUpperCase() + category.substring(1),
        style: const TextStyle(
          color: Color(0xFFB7FF00),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PolicyBadge extends StatelessWidget {
  const _PolicyBadge(this.policy);
  final JoinPolicy policy;

  @override
  Widget build(BuildContext context) {
    final isOpen = policy == JoinPolicy.open;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF1F232A),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
            size: 11,
            color: const Color(0xFF8A8FA8),
          ),
          const SizedBox(width: 4),
          Text(
            isOpen ? 'Open' : 'Approval',
            style: const TextStyle(
              color: Color(0xFF8A8FA8),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF8A8FA8),
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
