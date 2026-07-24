import '../../../core/utils/date_keys.dart';
import '../domain/models/opportunity_slot.dart';

/// Daily politeness ceilings for intention nudges (P1-06, decision log).
///
/// The slot ladder alone bounds a single plan (≤3 slots), but nothing
/// bounded a DAY: several intentions replanning into the same afternoon
/// could legally stack 6+ nudges. These caps are the promise the PRD's
/// "politeness" language makes concrete:
///
/// - an intention may claim at most [kMaxNudgesPerIntentionPerDay] nudges
///   per local calendar day;
/// - all intentions together at most [kMaxIntentionNudgesPerDay].
///
/// Counting basis is "delivery claims" from the notification ledger —
/// slots still pending plus slots that actually reached the user (even if
/// later replaced). Cancelled-before-delivery rows are free, so replans
/// never starve their own budget.
const int kMaxNudgesPerIntentionPerDay = 2;
const int kMaxIntentionNudgesPerDay = 4;

/// Pure filter: walks [slots] in ladder order and keeps a slot only while
/// its local-day counts stay under both ceilings. [intentionCountByDay]
/// and [globalCountByDay] are existing claim counts keyed by
/// `DateKeys.yyyymmdd` day; the maps are not mutated.
List<OpportunitySlot> applyIntentionDailyCaps({
  required List<OpportunitySlot> slots,
  required Map<String, int> intentionCountByDay,
  required Map<String, int> globalCountByDay,
}) {
  final own = Map<String, int>.from(intentionCountByDay);
  final global = Map<String, int>.from(globalCountByDay);
  final allowed = <OpportunitySlot>[];
  for (final slot in slots) {
    final day = DateKeys.yyyymmdd(
      DateTime.fromMillisecondsSinceEpoch(slot.deliverAtMs),
    );
    if ((own[day] ?? 0) >= kMaxNudgesPerIntentionPerDay) continue;
    if ((global[day] ?? 0) >= kMaxIntentionNudgesPerDay) continue;
    own[day] = (own[day] ?? 0) + 1;
    global[day] = (global[day] ?? 0) + 1;
    allowed.add(slot);
  }
  return allowed;
}
