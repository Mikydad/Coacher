import 'context_override.dart';
import 'suppressed_item.dart';

/// Represents the review surfaced to the user after an override ends.
///
/// In Phase B this is in-memory only (not persisted to Isar).
/// In Phase C, `AttentionOrchestrator` will populate `suppressedItems` from
/// its real suppressed intent queue.
class PostOverrideReview {
  const PostOverrideReview({
    required this.overrideType,
    required this.activeFromMs,
    required this.activeUntilMs,
    required this.suppressedItems,
  });

  /// Which override just ended.
  final ContextOverride overrideType;

  /// Epoch ms when the override started.
  final int activeFromMs;

  /// Epoch ms when the override ended (expiry or manual end).
  final int activeUntilMs;

  /// Items that were held back during the window.
  /// Empty in Phase B (stub) — populated by Phase C.
  final List<SuppressedItem> suppressedItems;

  /// Duration that the override was active.
  Duration get activeDuration =>
      Duration(milliseconds: activeUntilMs - activeFromMs);

  bool get hasSuppressedItems => suppressedItems.isNotEmpty;

  /// Returns a copy with [suppressedItems] filtered to exclude [entityId].
  PostOverrideReview withItemActioned(String entityId) {
    return PostOverrideReview(
      overrideType: overrideType,
      activeFromMs: activeFromMs,
      activeUntilMs: activeUntilMs,
      suppressedItems:
          suppressedItems.where((i) => i.entityId != entityId).toList(),
    );
  }
}
