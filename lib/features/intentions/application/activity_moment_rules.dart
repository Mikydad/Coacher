import '../../../core/context/activity_signal.dart';

/// Decision-time motion rules for seize-the-moment (humanizing Phase 6a,
/// PRD §9 Tier 2). Pure — fully unit-testable.
///
/// Semantics, from the PRD's worked example ("You're walking home with
/// ~20 free minutes — good moment to call your cousin"):
/// - **null** (no signal): neutral — behavior identical to pre-Phase-6.
///   Provenance honesty: no reading, no claims, no filtering.
/// - **still**: neutral — the user can act on anything.
/// - **walking**: only hands-free-compatible intentions (calls) are
///   suggested; a "write the report" nudge mid-walk is a suggestion the
///   user cannot act on — better silent than wrong.
/// - **driving / cycling / running**: suppress the card entirely. Never
///   suggest acting on anything mid-drive.

/// Tags a walking user can act on immediately.
const handsFreeCompatibleTags = {'call', 'handsFree'};

/// Whether the seize card may suggest an intention with [tags] given the
/// current motion state.
bool seizeAllowedFor(ActivityKind? activity, List<String> tags) {
  switch (activity) {
    case null:
    case ActivityKind.still:
    case ActivityKind.unknown:
      return true;
    case ActivityKind.walking:
      return tags.any(handsFreeCompatibleTags.contains);
    case ActivityKind.driving:
    case ActivityKind.cycling:
    case ActivityKind.running:
      return false;
  }
}

/// The provenance-honest phrase for the card copy, or null when we have
/// no reading (copy then makes no motion claim at all).
String? activityMomentPhrase(ActivityKind? activity) => switch (activity) {
  ActivityKind.walking => "you're walking",
  _ => null,
};
