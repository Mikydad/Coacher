/// Coach AI capability boundaries — what the assistant can read, mutate, or not do yet.
abstract final class AiCapabilityRegistry {
  static const supportedRead = [
    'today_schedule',
    'tomorrow_schedule',
    'goals_summary',
    'goal_progress',
    'focus_state',
    'activity_patterns',
  ];

  static const supportedMutate = [
    'tasks_create_edit_move_delete',
    'goals_create_modify_delete',
    'reminders_add_remove_reschedule',
    'context_overrides_focus_sleep_dnd',
  ];

  /// Keywords grouped by unsupported domain (v1).
  static const _unsupportedDomains = <_UnsupportedDomain>[
    _UnsupportedDomain(
      id: 'community',
      keywords: [
        'circle',
        'circles',
        'community',
        'group chat',
        'teammate',
        'accountability partner',
      ],
      message:
          'Community and Circles are not available in Coach AI yet — coming later. '
          'You can open Circles from the app to manage those features.',
      suggestedPrompts: ['What\'s my plan for tomorrow?'],
    ),
    _UnsupportedDomain(
      id: 'billing',
      keywords: [
        'subscription',
        'billing',
        'payment',
        'premium',
        'upgrade plan',
        'cancel subscription',
      ],
      message:
          'I can\'t change subscription or billing settings from Coach AI. '
          'Please use Settings in the app for account and billing.',
    ),
    _UnsupportedDomain(
      id: 'account',
      keywords: [
        'change password',
        'delete account',
        'email address',
        'sign out',
        'log out of',
      ],
      message:
          'I can\'t change account or sign-in settings from here. '
          'Open Settings in the app for profile and account options.',
    ),
    _UnsupportedDomain(
      id: 'sync',
      keywords: [
        'sync status',
        'cloud backup',
        'firebase sync',
        'backup my data',
      ],
      message:
          'Sync and backup status are not available in Coach AI yet — coming later.',
    ),
  ];

  /// JSON section injected into every AI payload.
  static Map<String, dynamic> buildPayloadSection() => {
        'read': supportedRead,
        'mutate': supportedMutate,
        'unsupported': _unsupportedDomains.map((d) => d.id).toList(),
      };

  /// Human-readable block for the LLM user prompt.
  static String formatForPrompt() {
    final buffer = StringBuffer()
      ..writeln('Coach AI capabilities:')
      ..writeln('  Read: ${supportedRead.join(', ')}')
      ..writeln('  Mutate: ${supportedMutate.join(', ')}')
      ..writeln('  Not available yet: ${_unsupportedDomains.map((d) => d.id).join(', ')}')
      ..writeln(
        'If the user asks for an unsupported domain, respond with responseType '
        '"unsupported" only — do not invent data or actions.',
      );
    return buffer.toString();
  }

  /// Fast client-side guard before calling the LLM.
  static AiUnsupportedMatch? detectUnsupported(String userInput) {
    final lower = userInput.toLowerCase();
    for (final domain in _unsupportedDomains) {
      for (final keyword in domain.keywords) {
        if (lower.contains(keyword)) {
          return AiUnsupportedMatch(
            domainId: domain.id,
            message: domain.message,
            suggestedPrompts: domain.suggestedPrompts,
          );
        }
      }
    }
    return null;
  }
}

class AiUnsupportedMatch {
  const AiUnsupportedMatch({
    required this.domainId,
    required this.message,
    this.suggestedPrompts = const [],
  });

  final String domainId;
  final String message;
  final List<String> suggestedPrompts;
}

class _UnsupportedDomain {
  const _UnsupportedDomain({
    required this.id,
    required this.keywords,
    required this.message,
    this.suggestedPrompts = const [],
  });

  final String id;
  final List<String> keywords;
  final String message;
  final List<String> suggestedPrompts;
}
