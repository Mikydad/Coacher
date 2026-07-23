/// Pure text transforms for Voice Mode (humanizing Phase 3) — what the
/// Coach's written reply must become before a TTS engine may speak it.
///
/// Two jobs:
///  1. [sanitizeForSpeech] — strip everything that is chat chrome, not
///     speech: `[mem:…]` grounding markers, markdown-lite (`**bold**`,
///     list markers), and collapsed whitespace.
///  2. [splitIntoSentences] — sentence-chunk the reply so TTS playback
///     starts immediately and tap-to-interrupt lands between sentences,
///     masking the non-streaming `aiChat` round-trip (PRD §6 L2).
library;

final RegExp _kMemMarker = RegExp(r'\s*\[mem:[A-Za-z0-9_-]+(?:\|[^\]]*)?\]');
final RegExp _kBold = RegExp(r'\*\*(.+?)\*\*');
final RegExp _kListMarker = RegExp(r'^\s*(?:[-*]|\d+\.)\s+', multiLine: true);
final RegExp _kSpaces = RegExp(r'[ \t]+');
final RegExp _kBlankLines = RegExp(r'\n{2,}');

/// Chat text → speakable text. Deterministic, no I/O.
String sanitizeForSpeech(String content) {
  var text = content.replaceAll(_kMemMarker, '');
  text = text.replaceAllMapped(_kBold, (m) => m.group(1)!);
  text = text.replaceAll(_kListMarker, '');
  text = text.replaceAll(_kSpaces, ' ');
  text = text.replaceAll(_kBlankLines, '\n');
  return text.trim();
}

/// Sentence terminators we chunk on. A newline is also a boundary — the
/// Coach's list-style replies read naturally line by line.
final RegExp _kSentenceEnd = RegExp(r'(?<=[.!?…])\s+|\n');

/// Splits [text] into speakable chunks, dropping empties. Very short
/// fragments (≤2 chars, e.g. a stray "OK") merge into the previous chunk
/// so the TTS engine doesn't stutter.
List<String> splitIntoSentences(String text) {
  final raw = text.split(_kSentenceEnd);
  final chunks = <String>[];
  for (final part in raw) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.length <= 2 && chunks.isNotEmpty) {
      chunks[chunks.length - 1] = '${chunks.last} $trimmed';
    } else {
      chunks.add(trimmed);
    }
  }
  return chunks;
}

/// Convenience: sanitize then chunk.
List<String> speechChunksFor(String content) =>
    splitIntoSentences(sanitizeForSpeech(content));
