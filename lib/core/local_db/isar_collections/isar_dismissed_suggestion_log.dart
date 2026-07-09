import 'package:isar_community/isar.dart';

part 'isar_dismissed_suggestion_log.g.dart';

/// Records each time the user taps "Not now" on a proactive suggestion.
///
/// Used by [ProactiveSuggestionEngine] to suppress suggestion types that
/// have been dismissed 3+ times in the last 7 days.
@Collection()
class IsarDismissedSuggestionLog {
  IsarDismissedSuggestionLog();

  /// Isar auto-id.
  Id isarId = Isar.autoIncrement;

  /// The [ProactiveSuggestionType.name] that was dismissed.
  @Index()
  late String suggestionType;

  /// Epoch ms when the user tapped "Not now".
  @Index()
  late int dismissedAtMs;
}
