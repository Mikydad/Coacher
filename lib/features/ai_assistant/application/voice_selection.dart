/// Pure voice-picking logic for Voice Mode TTS (no plugin imports, so the
/// ranking is unit-testable like the rest of the voice stack).
///
/// iOS ships one compact ("default" quality) voice per locale plus, on
/// modern devices, several "enhanced" ones; users can download "premium"
/// neural voices in Settings → Accessibility → Spoken Content. The default
/// compact voice is the robotic one — if anything better is installed we
/// should be using it.
library;

/// Ranks the platform voice list and returns the voice to pass to
/// `FlutterTts.setVoice`, or null to keep the system default.
///
/// Rules:
/// - only voices matching [localeTag]'s language are considered (an
///   Italian premium voice is no upgrade for an English conversation);
/// - only enhanced/premium quality — if just compact voices are installed
///   the system default is already the best we have;
/// - exact locale match (accent) beats quality: an enhanced en-GB voice
///   fits a British user better than a premium en-US one;
/// - deterministic tie-break by name so the pick is stable across runs.
Map<String, String>? pickPreferredIosVoice(
  List<dynamic> voices,
  String localeTag,
) {
  final language = localeTag.split(RegExp('[-_]')).first.toLowerCase();
  if (language.isEmpty) return null;
  final normalizedTag = localeTag.replaceAll('_', '-').toLowerCase();

  var best = <String, String>{};
  var bestRank = 0;
  for (final raw in voices) {
    if (raw is! Map) continue;
    final name = raw['name']?.toString() ?? '';
    final locale = raw['locale']?.toString() ?? '';
    if (name.isEmpty || locale.isEmpty) continue;
    final voiceTag = locale.replaceAll('_', '-').toLowerCase();
    if (voiceTag.split('-').first != language) continue;

    final quality = switch (raw['quality']?.toString()) {
      'premium' => 2,
      'enhanced' => 1,
      _ => 0,
    };
    if (quality == 0) continue;

    final exactLocale = voiceTag == normalizedTag ? 1 : 0;
    // Locale outranks quality; quality outranks nothing else.
    final rank = exactLocale * 10 + quality;
    final better =
        rank > bestRank || (rank == bestRank && name.compareTo(best['name'] ?? '') < 0);
    if (!better) continue;
    bestRank = rank;
    best = {
      'name': name,
      'locale': locale,
      if (raw['identifier'] != null) 'identifier': raw['identifier'].toString(),
    };
  }
  return bestRank > 0 ? best : null;
}
