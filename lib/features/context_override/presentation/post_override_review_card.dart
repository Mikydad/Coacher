import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../application/context_override_providers.dart';
import '../domain/models/context_override.dart';
import '../domain/models/post_override_review.dart';
import '../domain/models/suppressed_item.dart';

const String _kPendingReviewKey = 'pending_override_review';

/// Writes a flag to SharedPreferences when a review is pending.
/// Called by [ContextOverrideService.endOverride] via the poller/service.
Future<void> persistPendingReviewFlag(bool hasPending) async {
  final prefs = await SharedPreferences.getInstance();
  if (hasPending) {
    await prefs.setBool(_kPendingReviewKey, true);
  } else {
    await prefs.remove(_kPendingReviewKey);
  }
}

/// Returns true if there was a pending review flag saved across restarts.
Future<bool> loadPendingReviewFlag() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kPendingReviewKey) ?? false;
}

// ─── Card widget ──────────────────────────────────────────────────────────────

/// Dismissible home screen card shown after an override ends.
///
/// Shows up to 5 suppressed items with action chips.
/// In Phase B, `suppressedItems` is empty (stub) — Phase C will populate it.
class PostOverrideReviewCard extends ConsumerWidget {
  const PostOverrideReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(pendingRecoveryReviewProvider);
    if (review == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white.withAlpha(12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Text(
                  review.overrideType.icon,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'While you were in ${review.overrideType.displayName}${review.hasSuppressedItems ? ', ${review.suppressedItems.length} item${review.suppressedItems.length == 1 ? '' : 's'} were held back' : ''}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                // Dismiss all
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _dismissAll(ref),
                ),
              ],
            ),

            if (!review.hasSuppressedItems) ...[
              const SizedBox(height: 4),
              const Text(
                'No items were held back. You\'re all caught up.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],

            if (review.hasSuppressedItems) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: Colors.white12),
              const SizedBox(height: 8),

              // Items list (max 5 + "show more")
              for (final item in review.suppressedItems.take(5)) ...[
                _SuppressedItemRow(
                  item: item,
                  onAction: (action) =>
                      _handleAction(ref, review, item, action),
                ),
                const SizedBox(height: 6),
              ],

              if (review.suppressedItems.length > 5)
                Text(
                  '+${review.suppressedItems.length - 5} more items',
                  style: const TextStyle(fontSize: 12, color: Colors.white38),
                ),
            ],

            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _dismissAll(ref),
                child: const Text(
                  'Dismiss all',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _dismissAll(WidgetRef ref) {
    ref.read(pendingRecoveryReviewProvider.notifier).state = null;
    persistPendingReviewFlag(false);
  }

  void _handleAction(
    WidgetRef ref,
    PostOverrideReview review,
    SuppressedItem item,
    SuggestedAction action,
  ) {
    // Phase B: action chips are stubs — just remove the item from the review.
    // Phase C will wire real schedule mutations here.
    final updated = review.withItemActioned(item.entityId);
    if (updated.suppressedItems.isEmpty) {
      ref.read(pendingRecoveryReviewProvider.notifier).state = null;
      persistPendingReviewFlag(false);
    } else {
      ref.read(pendingRecoveryReviewProvider.notifier).state = updated;
    }
  }
}

// ─── Suppressed item row ──────────────────────────────────────────────────────

class _SuppressedItemRow extends StatelessWidget {
  const _SuppressedItemRow({required this.item, required this.onAction});

  final SuppressedItem item;
  final void Function(SuggestedAction) onAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.entityTitle,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: SuggestedAction.values
                .map(
                  (action) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        action.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => onAction(action),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}
