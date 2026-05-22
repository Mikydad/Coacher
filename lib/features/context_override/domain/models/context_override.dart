/// The type of context override currently active.
enum ContextOverride {
  none,
  meeting,
  focus,
  sleep,
  vacation,
  doNotDisturb,
}

ContextOverride contextOverrideFromStorage(String? raw) {
  for (final v in ContextOverride.values) {
    if (v.name == raw) return v;
  }
  return ContextOverride.none;
}

/// Display label shown in UI.
extension ContextOverrideLabel on ContextOverride {
  String get displayName {
    switch (this) {
      case ContextOverride.none:
        return 'None';
      case ContextOverride.meeting:
        return 'Meeting';
      case ContextOverride.focus:
        return 'Focus';
      case ContextOverride.sleep:
        return 'Sleep';
      case ContextOverride.vacation:
        return 'Vacation';
      case ContextOverride.doNotDisturb:
        return 'Do Not Disturb';
    }
  }

  /// Icon character shown alongside the override name.
  String get icon {
    switch (this) {
      case ContextOverride.none:
        return '';
      case ContextOverride.meeting:
        return '📅';
      case ContextOverride.focus:
        return '🎯';
      case ContextOverride.sleep:
        return '🌙';
      case ContextOverride.vacation:
        return '🏖';
      case ContextOverride.doNotDisturb:
        return '🔕';
    }
  }
}
