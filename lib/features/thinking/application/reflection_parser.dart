import 'dart:convert';

/// Pure, defensive parsing of `reflect` responses (humanizing Phase 7).
///
/// The reflection's output is NEVER an action — only labeled proposals,
/// each of which must survive validation here before touching anything:
///
/// - **grounding-or-drop**: every proposal must cite `basedOn` ids that
///   exist in the snapshot we sent (the reflection sibling of extraction's
///   quote verification — the model may connect dots, but only OUR dots);
/// - **caps**: ≤3 dormant intentions, ≤5 hint updates, exactly ≤1
///   observation per pass (quiet-app principle);
/// - **shape**: bounded lengths, known enum values, ids resolved against
///   the live records — malformed entries are dropped, never repaired.
class ReflectionDormantCandidate {
  const ReflectionDormantCandidate({
    required this.title,
    required this.estimatedMinutes,
    required this.basedOn,
  });

  final String title;
  final int estimatedMinutes;
  final List<String> basedOn;
}

class ReflectionHintUpdate {
  const ReflectionHintUpdate({
    required this.intentionId,
    required this.preferredTimeBlock,
    this.basedOn = const [],
  });

  final String intentionId;
  final String preferredTimeBlock;

  /// Grounding refs (fact/person/intention ids from the snapshot). Kept on
  /// the hint so the intention's `aiHintsJson` can carry provenance — the
  /// confirm-at-delivery loop uses it to contradict the sourcing facts
  /// when the user says "wrong time".
  final List<String> basedOn;
}

class ReflectionObservation {
  const ReflectionObservation({required this.message, required this.basedOn});

  final String message;
  final List<String> basedOn;
}

class ParsedReflection {
  const ParsedReflection({
    this.dormantIntentions = const [],
    this.hintUpdates = const [],
    this.observation,
  });

  final List<ReflectionDormantCandidate> dormantIntentions;
  final List<ReflectionHintUpdate> hintUpdates;
  final ReflectionObservation? observation;

  bool get isEmpty =>
      dormantIntentions.isEmpty && hintUpdates.isEmpty && observation == null;
}

class ReflectionParser {
  static const maxDormant = 3;
  static const maxHints = 5;
  static const timeBlocks = {'morning', 'afternoon', 'evening'};

  /// [knownIds] is the grounding universe (snapshot fact/person/intention
  /// ids); [openIntentionIds] gates hint targets; [existingTitleKeys] are
  /// normalized titles of ALL live intentions, for dormant dedupe.
  static ParsedReflection parse(
    String content, {
    required Set<String> knownIds,
    required Set<String> openIntentionIds,
    required Set<String> existingTitleKeys,
  }) {
    final decoded = _decode(content);
    if (decoded == null) return const ParsedReflection();

    final seenTitles = {...existingTitleKeys};
    final dormant = <ReflectionDormantCandidate>[];
    for (final raw in _list(decoded['dormantIntentions'])) {
      if (dormant.length >= maxDormant) break;
      if (raw is! Map) continue;
      final title = _string(raw['title']);
      if (title == null || title.length < 3 || title.length > 80) continue;
      final key = titleKey(title);
      if (seenTitles.contains(key)) continue;
      final basedOn = _groundedRefs(raw['basedOn'], knownIds);
      if (basedOn == null) continue;
      seenTitles.add(key);
      dormant.add(
        ReflectionDormantCandidate(
          title: title,
          estimatedMinutes: _minutes(raw['estimatedMinutes']),
          basedOn: basedOn,
        ),
      );
    }

    final seenIntentions = <String>{};
    final hints = <ReflectionHintUpdate>[];
    for (final raw in _list(decoded['hintUpdates'])) {
      if (hints.length >= maxHints) break;
      if (raw is! Map) continue;
      final intentionId = _string(raw['intentionId']);
      final block = _string(raw['preferredTimeBlock']);
      if (intentionId == null || !openIntentionIds.contains(intentionId)) {
        continue;
      }
      if (block == null || !timeBlocks.contains(block)) continue;
      // Grounding-or-drop applies to hints too (P1-09): an ungrounded
      // model response must not steer real planner scoring through
      // `preferredTimeBlock`. Same rule as dormant/observation proposals.
      final basedOn = _groundedRefs(raw['basedOn'], knownIds);
      if (basedOn == null) continue;
      if (!seenIntentions.add(intentionId)) continue;
      hints.add(
        ReflectionHintUpdate(
          intentionId: intentionId,
          preferredTimeBlock: block,
          basedOn: basedOn,
        ),
      );
    }

    ReflectionObservation? observation;
    for (final raw in _list(decoded['observations'])) {
      if (raw is! Map) continue;
      final message = _string(raw['message']);
      if (message == null || message.length < 10 || message.length > 200) {
        continue;
      }
      final basedOn = _groundedRefs(raw['basedOn'], knownIds);
      if (basedOn == null) continue;
      observation = ReflectionObservation(message: message, basedOn: basedOn);
      break; // At most ONE observation per pass — quiet-app principle.
    }

    return ParsedReflection(
      dormantIntentions: dormant,
      hintUpdates: hints,
      observation: observation,
    );
  }

  /// Title identity for dedupe: lowercase, punctuation-stripped,
  /// whitespace-collapsed — "Call Mom!" and "call mom" are one wish.
  static String titleKey(String title) => title
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Non-empty refs, every one inside the grounding universe — otherwise
  /// the whole proposal drops. Never repaired, never partially accepted.
  static List<String>? _groundedRefs(Object? raw, Set<String> knownIds) {
    if (raw is! List || raw.isEmpty) return null;
    final refs = <String>[];
    for (final entry in raw) {
      if (entry is! String || !knownIds.contains(entry)) return null;
      refs.add(entry);
    }
    return refs;
  }

  static Map<String, dynamic>? _decode(String content) {
    var text = content.trim();
    final fence = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$');
    final match = fence.firstMatch(text);
    if (match != null) text = match.group(1)!.trim();
    try {
      final decoded = jsonDecode(text);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static List<Object?> _list(Object? raw) =>
      raw is List ? raw : const <Object?>[];

  static String? _string(Object? raw) {
    if (raw is! String) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static int _minutes(Object? raw) {
    if (raw is num) return raw.toInt().clamp(5, 120);
    return 20;
  }
}
