import '../data/circle_repository.dart';
import '../domain/models/accountability_circle.dart';
import '../domain/models/circle_enums.dart';

const int _kMaxMembers = AccountabilityCircle.kMaxMembers;

/// A circle scored by relevance to the current user's profile.
class ScoredCircle {
  const ScoredCircle({
    required this.circle,
    required this.score,
    required this.matchReason,
  });

  final AccountabilityCircle circle;

  /// Relevance score 0.0–1.0.
  final double score;

  /// Human-readable explanation, e.g. "Matches your Learning goal".
  final String matchReason;
}

/// Scores and ranks public circles by relevance to a user's goals, timezone,
/// and coaching style.
///
/// Pure scoring logic — no network calls except loading circles from the repo.
class CircleRecommendationService {
  const CircleRecommendationService({
    required CircleRepository circleRepo,
  }) : _circleRepo = circleRepo;

  final CircleRepository _circleRepo;

  /// Returns circles scored by relevance, sorted descending.
  ///
  /// Excludes full circles (`memberCount == kMaxMembers`) and
  /// circles already joined by the user.
  Future<List<ScoredCircle>> getRecommendations({
    required String userId,
    required List<String> activeGoalCategories,
    required String userTimezone,
    required List<String> alreadyJoinedIds,
  }) async {
    final all = await _circleRepo.searchCircles();
    final eligible = all.where((c) {
      if (c.memberCount >= _kMaxMembers) return false;
      if (alreadyJoinedIds.contains(c.id)) return false;
      return true;
    }).toList();

    final scored = eligible
        .map((c) => _score(
              circle: c,
              activeGoalCategories: activeGoalCategories,
              userTimezone: userTimezone,
            ))
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return scored;
  }

  // ── Scoring formula ────────────────────────────────────────────────────────

  ScoredCircle _score({
    required AccountabilityCircle circle,
    required List<String> activeGoalCategories,
    required String userTimezone,
  }) {
    // Category match (0.0 or 1.0)
    final categoryMatch = activeGoalCategories.any(
      (cat) => _normalise(cat) == _normalise(circle.category),
    )
        ? 1.0
        : 0.0;

    // Timezone proximity (0.0, 0.5, 1.0)
    final tzOffset = _tzOffsetHours(userTimezone, circle.timezone).abs();
    final timezoneMatch = tzOffset <= 2.0
        ? 1.0
        : tzOffset <= 4.0
            ? 0.5
            : 0.0;

    // Activity level: memberCount / kMaxMembers
    final activityLevel = circle.memberCount / _kMaxMembers;

    // Open join policy
    final openPolicy = circle.joinPolicy == JoinPolicy.open
        ? 1.0
        : circle.joinPolicy == JoinPolicy.requestApproval
            ? 0.5
            : 0.0;

    final score = categoryMatch * 0.4 +
        timezoneMatch * 0.3 +
        activityLevel * 0.2 +
        openPolicy * 0.1;

    final reason = _buildReason(
      circle: circle,
      categoryMatch: categoryMatch > 0,
      timezoneMatch: timezoneMatch > 0,
    );

    return ScoredCircle(circle: circle, score: score, matchReason: reason);
  }

  static String _buildReason({
    required AccountabilityCircle circle,
    required bool categoryMatch,
    required bool timezoneMatch,
  }) {
    if (categoryMatch) {
      return 'Matches your ${circle.category} goal';
    }
    if (timezoneMatch) {
      return 'Active in your timezone';
    }
    return 'Open to new members';
  }

  static String _normalise(String s) => s.toLowerCase().trim();

  /// Approximate offset in hours between two IANA timezone names.
  /// Falls back to 0 if parsing fails (treat as same timezone).
  static double _tzOffsetHours(String tz1, String tz2) {
    if (tz1 == tz2) return 0.0;
    // Simple heuristic: parse known UTC offsets from well-known tz names.
    final offset1 = _knownOffset(tz1);
    final offset2 = _knownOffset(tz2);
    return (offset1 - offset2).abs().toDouble();
  }

  static int _knownOffset(String tz) {
    // Sparse lookup for common zones. Defaults to 0.
    const offsets = <String, int>{
      'UTC': 0,
      'Etc/UTC': 0,
      'America/New_York': -5,
      'America/Chicago': -6,
      'America/Denver': -7,
      'America/Los_Angeles': -8,
      'America/Vancouver': -8,
      'America/Toronto': -5,
      'America/Sao_Paulo': -3,
      'Europe/London': 0,
      'Europe/Paris': 1,
      'Europe/Berlin': 1,
      'Europe/Moscow': 3,
      'Africa/Cairo': 2,
      'Africa/Nairobi': 3,
      'Africa/Lagos': 1,
      'Asia/Dubai': 4,
      'Asia/Kolkata': 5,
      'Asia/Dhaka': 6,
      'Asia/Bangkok': 7,
      'Asia/Shanghai': 8,
      'Asia/Tokyo': 9,
      'Australia/Sydney': 11,
      'Pacific/Auckland': 13,
    };
    return offsets[tz] ?? 0;
  }
}
