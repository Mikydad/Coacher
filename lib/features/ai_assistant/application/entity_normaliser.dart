/// Maps raw user-provided entity names to canonical category keys,
/// and scores how well a raw entity matches a candidate task title.
class EntityNormaliser {
  const EntityNormaliser();

  // ─── V2 dictionary ────────────────────────────────────────────────────────

  static const Map<String, List<String>> _dictionary = {
    'fitness': [
      'workout',
      'gym',
      'exercise',
      'run',
      'push day',
      'pull day',
      'leg day',
      'cardio',
      'swim',
      'bike',
      'jog',
      'lift',
      'training',
    ],
    'study': [
      'study',
      'reading',
      'review',
      'homework',
      'revision',
      'research',
      'learn',
      'read',
      'practice',
    ],
    'work': [
      'meeting',
      'standup',
      'sync',
      'call',
      'interview',
      'presentation',
      'deep work',
      'sprint',
      'review',
      'planning',
      'retro',
    ],
    'sleep': ['sleep', 'nap', 'rest', 'bedtime', 'wind down'],
    'meal': [
      'breakfast',
      'lunch',
      'dinner',
      'meal prep',
      'cook',
      'eat',
      'snack',
    ],
    'mindfulness': [
      'meditation',
      'yoga',
      'breathwork',
      'journaling',
      'journal',
      'journal entry',
      'mindfulness',
      'stretch',
    ],
  };

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Normalises [rawEntity] to a canonical category key.
  ///
  /// Returns the category key if a dictionary match is found,
  /// otherwise returns the lowercased + punctuation-stripped input.
  String normalise(String rawEntity) {
    final cleaned = _clean(rawEntity);
    for (final entry in _dictionary.entries) {
      // Exact keyword match
      if (entry.value.contains(cleaned)) return entry.key;
      // Word-boundary keyword match within a multi-word entity
      final words = cleaned.split(RegExp(r'\s+'));
      for (final keyword in entry.value) {
        final keyWords = keyword.split(RegExp(r'\s+'));
        // All words of keyword must appear in cleaned (in any order)
        if (keyWords.every((kw) => words.contains(kw))) {
          return entry.key;
        }
        // Single-word keywords: exact word match only (no substring)
        if (keyWords.length == 1 && words.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return cleaned;
  }

  /// Scores how well [rawEntity] matches [candidateTitle].
  ///
  /// Scoring:
  /// - 1.0 — exact category match (both normalise to the same key).
  /// - 0.9 — same category (one is a known keyword in the same bucket).
  /// - 0.7 — partial string overlap (one contains the other as a substring).
  /// - 0.0 — no relationship found.
  double similarityScore(String rawEntity, String candidateTitle) {
    final cleanedEntity = _clean(rawEntity);
    final cleanedCandidate = _clean(candidateTitle);

    // Exact cleaned string match
    if (cleanedEntity == cleanedCandidate) return 1.0;

    final normEntity = normalise(rawEntity);
    final normCandidate = normalise(candidateTitle);

    // Both inputs normalise to the exact same category key
    if (normEntity == normCandidate) return 0.9;

    // Both map to a known dictionary category (same bucket via indirect path)
    final catEntity = _categoryFor(normEntity);
    final catCandidate = _categoryFor(normCandidate);
    if (catEntity != null && catEntity == catCandidate) return 0.9;

    // Partial word overlap on cleaned strings (word boundary match)
    final entityWords = cleanedEntity
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toSet();
    final candidateWords = cleanedCandidate
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 2)
        .toSet();
    if (entityWords.isNotEmpty &&
        candidateWords.isNotEmpty &&
        entityWords.intersection(candidateWords).isNotEmpty) {
      return 0.7;
    }

    return 0.0;
  }

  // ─── Private helpers ──────────────────────────────────────────────────────

  /// Lowercases and strips all non-alphanumeric/space characters.
  static String _clean(String raw) {
    return raw.toLowerCase().replaceAll(RegExp(r"[^\w\s]"), '').trim();
  }

  /// Returns the dictionary category for a (possibly already-normalised) string.
  String? _categoryFor(String cleaned) {
    if (_dictionary.containsKey(cleaned)) return cleaned;
    for (final entry in _dictionary.entries) {
      if (entry.value.contains(cleaned)) return entry.key;
    }
    return null;
  }
}
