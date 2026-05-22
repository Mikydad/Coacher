import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/date_keys.dart';
import '../../../../core/utils/stable_id.dart';
import '../../application/weekly_commitment_providers.dart';
import '../../domain/models/weekly_commitment.dart';

class WeeklyCommitmentsView extends ConsumerWidget {
  const WeeklyCommitmentsView({super.key, required this.circleId});

  final String circleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final commitmentsAsync =
        ref.watch(circleWeeklyCommitmentsProvider(circleId));

    return commitmentsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: Color(0xFFB7FF00)),
      ),
      error: (_, __) => const Center(
        child: Text(
          'Could not load commitments.',
          style: TextStyle(color: Color(0xFF8A8FA8)),
        ),
      ),
      data: (all) {
        final mine = all.where((c) => c.userId == uid).toList();
        final others = all.where((c) => c.userId != uid).toList();
        final weekKey = DateKeys.isoWeekKey(DateTime.now());
        final isEndOfWeek = _isEndOfWeek();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── End-of-week banner ─────────────────────────────────────────
            if (isEndOfWeek && mine.isNotEmpty)
              _EndOfWeekBanner(commitments: mine),

            // ── My commitments ─────────────────────────────────────────────
            _SectionHeader(
              'My commitments this week',
              trailing: TextButton.icon(
                onPressed: () => _showEditSheet(context, ref, uid, weekKey, mine),
                icon: const Icon(Icons.edit_rounded, size: 14,
                    color: Color(0xFFB7FF00)),
                label: const Text(
                  'Edit',
                  style: TextStyle(
                    color: Color(0xFFB7FF00),
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (mine.isEmpty)
              _EmptyMyCommitments(
                onAdd: () =>
                    _showEditSheet(context, ref, uid, weekKey, mine),
              )
            else
              ...mine.map(
                (c) => _CommitmentRow(
                  commitment: c,
                  isOwn: true,
                  onMarkProgress: () => ref
                      .read(weeklyCommitmentRepositoryProvider)
                      .markProgress(circleId, c.id),
                ),
              ),

            const SizedBox(height: 24),

            // ── Circle commitments ─────────────────────────────────────────
            if (others.isNotEmpty) ...[
              const _SectionHeader('Circle commitments'),
              const SizedBox(height: 8),
              ..._groupByUser(others).entries.map(
                (entry) => _MemberCommitmentsGroup(
                  userId: entry.key,
                  displayName: entry.value.first.userId == entry.key
                      ? entry.key
                      : entry.value.first.userId,
                  commitments: entry.value,
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Map<String, List<WeeklyCommitment>> _groupByUser(
      List<WeeklyCommitment> commitments) {
    final map = <String, List<WeeklyCommitment>>{};
    for (final c in commitments) {
      map.putIfAbsent(c.userId, () => []).add(c);
    }
    return map;
  }

  bool _isEndOfWeek() {
    final now = DateTime.now();
    // ISO weekday: 1=Mon ... 7=Sun; show banner on Thu(4), Fri(5), Sat(6), Sun(7)
    return now.weekday >= DateTime.thursday;
  }

  Future<void> _showEditSheet(
    BuildContext context,
    WidgetRef ref,
    String uid,
    String weekKey,
    List<WeeklyCommitment> existing,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF14171C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditCommitmentsSheet(
        circleId: circleId,
        uid: uid,
        weekKey: weekKey,
        existing: existing,
        ref: ref,
      ),
    );
  }
}

// ── Edit sheet ────────────────────────────────────────────────────────────────

class _EditCommitmentsSheet extends StatefulWidget {
  const _EditCommitmentsSheet({
    required this.circleId,
    required this.uid,
    required this.weekKey,
    required this.existing,
    required this.ref,
  });

  final String circleId;
  final String uid;
  final String weekKey;
  final List<WeeklyCommitment> existing;
  final WidgetRef ref;

  @override
  State<_EditCommitmentsSheet> createState() => _EditCommitmentsSheetState();
}

class _EditCommitmentsSheetState extends State<_EditCommitmentsSheet> {
  late List<_DraftCommitment> _drafts;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _drafts = widget.existing
        .map((c) => _DraftCommitment(
              id: c.id,
              titleController: TextEditingController(text: c.title),
              target: c.targetCount,
            ))
        .toList();
    if (_drafts.isEmpty) _addRow();
  }

  @override
  void dispose() {
    for (final d in _drafts) {
      d.titleController.dispose();
    }
    super.dispose();
  }

  void _addRow() {
    if (_drafts.length >= 3) return;
    setState(() {
      _drafts.add(_DraftCommitment(
        id: StableId.generate('wc'),
        titleController: TextEditingController(),
        target: 3,
      ));
    });
  }

  void _removeRow(int i) {
    _drafts[i].titleController.dispose();
    setState(() => _drafts.removeAt(i));
  }

  Future<void> _save() async {
    final valid = _drafts.where((d) => d.titleController.text.trim().isNotEmpty);
    if (valid.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      final commitments = valid
          .map((d) => WeeklyCommitment(
                id: d.id,
                circleId: widget.circleId,
                userId: widget.uid,
                title: d.titleController.text.trim(),
                targetCount: d.target,
                completedCount: widget.existing
                    .where((e) => e.id == d.id)
                    .map((e) => e.completedCount)
                    .firstOrNull ?? 0,
                weekKey: widget.weekKey,
                updatedAtMs: now,
              ))
          .toList();

      await widget.ref.read(weeklyCommitmentRepositoryProvider).setCommitments(
            circleId: widget.circleId,
            userId: widget.uid,
            weekKey: widget.weekKey,
            commitments: commitments,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'My commitments this week',
              style: TextStyle(
                color: Color(0xFFF0F4FF),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _drafts.length,
                itemBuilder: (_, i) => _DraftRow(
                  draft: _drafts[i],
                  canRemove: _drafts.length > 1,
                  onRemove: () => _removeRow(i),
                  onTargetChanged: (v) =>
                      setState(() => _drafts[i].target = v),
                ),
              ),
            ),
            if (_drafts.length < 3)
              TextButton.icon(
                onPressed: _addRow,
                icon: const Icon(Icons.add_rounded,
                    color: Color(0xFFB7FF00)),
                label: const Text(
                  'Add commitment',
                  style: TextStyle(color: Color(0xFFB7FF00)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFB7FF00),
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftCommitment {
  _DraftCommitment({
    required this.id,
    required this.titleController,
    required this.target,
  });
  final String id;
  final TextEditingController titleController;
  int target;
}

class _DraftRow extends StatelessWidget {
  const _DraftRow({
    required this.draft,
    required this.canRemove,
    required this.onRemove,
    required this.onTargetChanged,
  });

  final _DraftCommitment draft;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<int> onTargetChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: draft.titleController,
              style: const TextStyle(color: Color(0xFFF0F4FF)),
              decoration: InputDecoration(
                hintText: 'e.g. Workout ×3',
                hintStyle: const TextStyle(color: Color(0xFF8A8FA8)),
                filled: true,
                fillColor: const Color(0xFF1C2029),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: draft.target,
            dropdownColor: const Color(0xFF1C2029),
            style: const TextStyle(color: Color(0xFFF0F4FF)),
            underline: const SizedBox.shrink(),
            items: List.generate(
              7,
              (i) => DropdownMenuItem(
                value: i + 1,
                child: Text('×${i + 1}'),
              ),
            ),
            onChanged: (v) => onTargetChanged(v ?? 1),
          ),
          if (canRemove)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline_rounded,
                  color: Color(0xFFFF4D4D), size: 20),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

// ── Commitment row ────────────────────────────────────────────────────────────

class _CommitmentRow extends StatelessWidget {
  const _CommitmentRow({
    required this.commitment,
    required this.isOwn,
    this.onMarkProgress,
  });

  final WeeklyCommitment commitment;
  final bool isOwn;
  final VoidCallback? onMarkProgress;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF14171C),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  commitment.title,
                  style: const TextStyle(
                    color: Color(0xFFF0F4FF),
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                _ProgressTicks(
                  completed: commitment.completedCount,
                  target: commitment.targetCount,
                ),
              ],
            ),
          ),
          if (isOwn &&
              commitment.completedCount < commitment.targetCount &&
              onMarkProgress != null)
            IconButton(
              onPressed: onMarkProgress,
              icon: const Icon(
                Icons.add_circle_rounded,
                color: Color(0xFFB7FF00),
                size: 24,
              ),
              tooltip: 'Mark progress',
            ),
        ],
      ),
    );
  }
}

class _ProgressTicks extends StatelessWidget {
  const _ProgressTicks({required this.completed, required this.target});
  final int completed;
  final int target;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(target, (i) {
        final done = i < completed;
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: done
                  ? const Color(0xFFB7FF00)
                  : const Color(0xFF1C2029),
              shape: BoxShape.circle,
              border: Border.all(
                color: done
                    ? const Color(0xFFB7FF00)
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: done
                ? const Icon(Icons.check_rounded,
                    size: 9, color: Colors.black)
                : null,
          ),
        );
      }),
    );
  }
}

// ── Member group ──────────────────────────────────────────────────────────────

class _MemberCommitmentsGroup extends StatelessWidget {
  const _MemberCommitmentsGroup({
    required this.userId,
    required this.displayName,
    required this.commitments,
  });

  final String userId;
  final String displayName;
  final List<WeeklyCommitment> commitments;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6, top: 8),
          child: Text(
            commitments.first.userId,
            style: const TextStyle(
              color: Color(0xFF8A8FA8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...commitments.map(
          (c) => _CommitmentRow(commitment: c, isOwn: false),
        ),
      ],
    );
  }
}

// ── End-of-week banner ────────────────────────────────────────────────────────

class _EndOfWeekBanner extends StatelessWidget {
  const _EndOfWeekBanner({required this.commitments});
  final List<WeeklyCommitment> commitments;

  @override
  Widget build(BuildContext context) {
    final total = commitments.length;
    final done = commitments.where((c) => c.completedCount >= c.targetCount).length;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFB7FF00).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFB7FF00).withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          const Text('🏆', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You completed $done/$total commitments this week',
              style: const TextStyle(
                color: Color(0xFFB7FF00),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, {this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF8A8FA8),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
        const Spacer(),
        if (trailing != null) trailing!,
      ],
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyMyCommitments extends StatelessWidget {
  const _EmptyMyCommitments({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF14171C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFB7FF00).withValues(alpha: 0.2),
            style: BorderStyle.none,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFFB7FF00)),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Set your commitments for this week',
                style: TextStyle(
                  color: Color(0xFF8A8FA8),
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
