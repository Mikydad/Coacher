/// Tone guard for AI time observations (V1.2 decision 12). Enforced by the
/// parser, not just the prompt: a message that trips this is DROPPED, and
/// silence is the answer. Observational only — never a verdict, never a
/// "correct amount of time".
///
/// Don't tell people how to live. Help them see how they're living.
final List<RegExp> kBannedObservationPatterns = [
  for (final phrase in const [
    'wasted',
    'waste of',
    'should',
    'failed',
    'failure',
    'bad',
    'lazy',
    'you need to',
    'you ought to',
    'unproductive',
    'too much',
    'too little',
    'too long',
    'not enough',
    'excessive',
    'only ',
    'at least you',
    'better than',
    'worse than',
    'more than you',
    'less than you',
    'ideal',
    'supposed to',
    'must ',
    'try to',
    'make sure',
    'discipline',
    'productive',
    'guilty',
    'procrastinat',
  ])
    RegExp('\\b${RegExp.escape(phrase.trim())}', caseSensitive: false),
];

/// True when [message] contains judgment language. Word-boundary,
/// case-insensitive, prefix-tolerant ("procrastinat" catches all forms).
bool violatesObservationTone(String message) {
  final m = message.toLowerCase();
  for (final p in kBannedObservationPatterns) {
    if (p.hasMatch(m)) return true;
  }
  return false;
}
