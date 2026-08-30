import '../domain/models/reminder_occurrence_enums.dart';

/// What the classifier decided, and which rule decided it.
///
/// [rule] is not decoration: it is what makes a misclassification
/// diagnosable ("why is my gym session time-sensitive?") and what the golden
/// set asserts on, so a rule change that produces the right answer for the
/// wrong reason still fails the test.
class ReminderClassification {
  const ReminderClassification({
    required this.taxonomy,
    required this.criticality,
    required this.rule,
  });

  final ReminderTaxonomy taxonomy;
  final int criticality;
  final String rule;

  @override
  String toString() =>
      'ReminderClassification($taxonomy, crit $criticality, via $rule)';

  @override
  bool operator ==(Object other) =>
      other is ReminderClassification &&
      other.taxonomy == taxonomy &&
      other.criticality == criticality &&
      other.rule == rule;

  @override
  int get hashCode => Object.hash(taxonomy, criticality, rule);
}

/// The local, rule-based classifier (FR-R-20) — **pure**, synchronous, and
/// offline. It is not a stopgap: it is the permanent floor the AI classifier
/// (FR-R-22) degrades to whenever the network, the token budget or the
/// response schema fails. Every task gets a usable class at creation time
/// with no round trip.
///
/// ## Rules, in priority order
///
/// 1. **Keyword → `timeSensitive`, criticality 2.** Meetings, calls,
///    appointments and medication are less useful (or useless) later.
/// 2. **Habit anchor → `routine`, criticality 0.** The user ticked "this
///    recurs", so one missed day is low-stakes and aggregates into the daily
///    digest rather than demanding disposition.
/// 3. **Scheduled short work block → `timeSensitive`, criticality 1.** An
///    explicit time plus a duration under half an hour plus the Work category
///    is the shape of a slot, not a chore.
/// 4. **Everything else → `flexible`, criticality 1.** Still worth doing
///    later; becomes Overdue and surfaces at a recovery moment.
///
/// Keywords outrank the habit anchor deliberately: "take meds" ticked as a
/// habit is still medication, and aggregating those misses into a digest line
/// would be exactly the wrong call.
///
/// ## Why criticality stops at 2
///
/// Criticality 3 is the only thing in the system allowed to pierce the
/// interruption boundary, the Focus Shield *and* the configured sleep window
/// (D5). No substring match earns that: "social media catch-up" contains
/// "med", and the cost of being wrong is waking someone at 3 a.m. The
/// heuristic goes to 2 and the user grants 3 with the editor's Critical
/// toggle — a decision worth one deliberate tap. (Settled with Miko
/// 2026-08-30, superseding FR-R-20's `meds: 3`.)
abstract final class ReminderClassifier {
  /// Bumped whenever the rules change, so a later pass can re-classify only
  /// what an older build decided (FR-R-22's `classifierVersion` gate).
  static const int version = 1;

  /// Titles containing one of these words are time-sensitive. Matched on
  /// whole words, never substrings — "recall" is not a call, and "immediate"
  /// is not medication.
  static const Set<String> timeSensitiveWords = {
    // Commitments with another party, or a fixed slot.
    //
    // Deliberately excluded, because they read as ordinary work far more
    // often than as appointments: 'session' ("gym session", "study
    // session"), 'train' ("train legs"), 'bus'. A word earns a place here
    // only if being late to it costs something.
    'meeting', 'meet', 'appointment', 'appt', 'call', 'interview',
    'standup', 'sync', 'webinar', 'lecture', 'class',
    'flight', 'deadline', 'due', 'submit',
    'doctor', 'dentist', 'clinic', 'hospital', 'therapy',
    // Medication. Capped at criticality 2 — see the class doc.
    'meds', 'medication', 'medicine', 'pill', 'pills', 'insulin',
    'dose', 'vitamin', 'vitamins', 'antibiotic', 'antibiotics', 'inhaler',
  };

  /// Category whose scheduled short blocks read as slots (rule 3). The PRD
  /// says "work/meeting"; this app's category vocabulary has only `Work`,
  /// and "meeting" is covered by [timeSensitiveWords].
  static const String scheduledSlotCategory = 'Work';

  /// A "short" block for rule 3.
  static const int shortBlockMaxMinutes = 30;

  static ReminderClassification classify({
    required String title,
    bool hasReminderTime = false,
    int? durationMinutes,
    String? category,
    bool isHabitAnchor = false,
  }) {
    if (_hasTimeSensitiveWord(title)) {
      return const ReminderClassification(
        taxonomy: ReminderTaxonomy.timeSensitive,
        criticality: 2,
        rule: 'keyword',
      );
    }

    if (isHabitAnchor) {
      return const ReminderClassification(
        taxonomy: ReminderTaxonomy.routine,
        criticality: 0,
        rule: 'habitAnchor',
      );
    }

    if (hasReminderTime &&
        durationMinutes != null &&
        durationMinutes <= shortBlockMaxMinutes &&
        (category?.trim().toLowerCase() ==
            scheduledSlotCategory.toLowerCase())) {
      return const ReminderClassification(
        taxonomy: ReminderTaxonomy.timeSensitive,
        criticality: 1,
        rule: 'scheduledShortWorkBlock',
      );
    }

    return const ReminderClassification(
      taxonomy: ReminderTaxonomy.flexible,
      criticality: 1,
      rule: 'default',
    );
  }

  /// Whole-word match. Splits on anything that is not a letter or digit, so
  /// "Dr. appointment @ 3pm" and "1:1 sync" both tokenise sensibly, and
  /// "social media" cannot match "meds".
  static bool _hasTimeSensitiveWord(String title) {
    for (final token in tokenize(title)) {
      if (timeSensitiveWords.contains(token)) return true;
    }
    return false;
  }

  /// Lowercased word tokens of [title]. Exposed for the golden-set test.
  static List<String> tokenize(String title) => title
      .toLowerCase()
      .split(RegExp(r'[^a-z0-9]+'))
      .where((t) => t.isNotEmpty)
      .toList(growable: false);
}
