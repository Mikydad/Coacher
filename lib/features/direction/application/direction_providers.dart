import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/direction_repository.dart';
import '../domain/direction_context_lines.dart';
import '../domain/direction_periods.dart';
import '../domain/models/direction_entry.dart';

/// Direction providers. Everything derives from ONE Isar watch stream and
/// ONE clock; the local write IS the update (no invalidate-and-refetch).
///
/// Direction is not something SidePal asks the user to accomplish. It is
/// something SidePal remembers while helping them.

final directionRepositoryProvider = Provider<DirectionRepository>(
  (ref) => DirectionRepository(),
);

/// Every row (history included). Watches Isar, so a remote merge and a local
/// write both flow through the same path.
final directionEntriesStreamProvider = StreamProvider<List<DirectionEntry>>((
  ref,
) {
  return ref.watch(directionRepositoryProvider).watchAll();
});

/// "Now" for period resolution. Re-stamped by `AppLifecycleTaskRefresh` on
/// day change and resume so the slots roll over into a new month without a
/// restart; tests pin it.
final directionClockProvider = StateProvider<DateTime>((ref) => DateTime.now());

/// The three current-period slots (year / quarter / month) resolved against
/// the clock. A slot's `current` is null when never written — that is the
/// normal empty state. Its `suggestion` is the previous period's text for
/// the page's "Keep" row and NOTHING else (history ≠ current direction).
final currentDirectionProvider = Provider<Map<DirectionHorizon, DirectionSlot>>(
  (ref) {
    final entries =
        ref.watch(directionEntriesStreamProvider).valueOrNull ?? const [];
    final now = ref.watch(directionClockProvider);
    return resolveDirectionSlots(entries, now);
  },
);

/// Compact lines for the AI readers. Empty when nothing is set — callers
/// omit the block entirely. Current period only, never a previous one.
final directionContextLinesProvider = Provider<List<String>>((ref) {
  final entries =
      ref.watch(directionEntriesStreamProvider).valueOrNull ?? const [];
  final now = ref.watch(directionClockProvider);
  return buildDirectionContextLines(entries, now);
});

/// True once the user has written any direction, ever (history counts).
final hasAnyDirectionProvider = Provider<bool>((ref) {
  final entries =
      ref.watch(directionEntriesStreamProvider).valueOrNull ?? const [];
  return entries.any((e) => e.isNotEmpty);
});
