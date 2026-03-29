/// Base routine execution modes for V2 structured flow.
enum RoutineMode {
  flexible,
  disciplined,
  extreme,
}

extension RoutineModeStorage on RoutineMode {
  String get storageValue => name;

  static RoutineMode fromStorage(String? raw) {
    return RoutineMode.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => RoutineMode.flexible,
    );
  }
}

/// Immutable policy contract derived from mode + context.
///
/// Future extension points:
/// - user-defined modes can map into this policy shape;
/// - AI-assisted tuning can write these values safely without schema changes.
class RoutineModePolicy {
  const RoutineModePolicy({
    required this.mode,
    required this.requireTimerForCompletion,
    required this.allowHardGate,
    required this.baseSnoozeMinutes,
    required this.maxExtensionMinutes,
    required this.requireReasonForDeferral,
  });

  final RoutineMode mode;
  final bool requireTimerForCompletion;
  final bool allowHardGate;
  final int baseSnoozeMinutes;
  final int maxExtensionMinutes;
  final bool requireReasonForDeferral;

  RoutineModePolicy copyWith({
    RoutineMode? mode,
    bool? requireTimerForCompletion,
    bool? allowHardGate,
    int? baseSnoozeMinutes,
    int? maxExtensionMinutes,
    bool? requireReasonForDeferral,
  }) {
    return RoutineModePolicy(
      mode: mode ?? this.mode,
      requireTimerForCompletion:
          requireTimerForCompletion ?? this.requireTimerForCompletion,
      allowHardGate: allowHardGate ?? this.allowHardGate,
      baseSnoozeMinutes: baseSnoozeMinutes ?? this.baseSnoozeMinutes,
      maxExtensionMinutes: maxExtensionMinutes ?? this.maxExtensionMinutes,
      requireReasonForDeferral:
          requireReasonForDeferral ?? this.requireReasonForDeferral,
    );
  }

  Map<String, dynamic> toMap() => {
    'mode': mode.storageValue,
    'requireTimerForCompletion': requireTimerForCompletion,
    'allowHardGate': allowHardGate,
    'baseSnoozeMinutes': baseSnoozeMinutes,
    'maxExtensionMinutes': maxExtensionMinutes,
    'requireReasonForDeferral': requireReasonForDeferral,
  };

  static RoutineModePolicy fromMap(Map<String, dynamic> map) {
    return RoutineModePolicy(
      mode: RoutineModeStorage.fromStorage(map['mode'] as String?),
      requireTimerForCompletion: map['requireTimerForCompletion'] as bool? ?? false,
      allowHardGate: map['allowHardGate'] as bool? ?? false,
      baseSnoozeMinutes: (map['baseSnoozeMinutes'] as num?)?.toInt() ?? 10,
      maxExtensionMinutes: (map['maxExtensionMinutes'] as num?)?.toInt() ?? 60,
      requireReasonForDeferral: map['requireReasonForDeferral'] as bool? ?? true,
    );
  }
}

/// Persisted/selected mode descriptor.
///
/// `id` allows custom modes in the future while preserving built-ins:
/// - built-ins: `flexible`, `disciplined`, `extreme`
/// - custom: stable generated ids
class RoutineModeConfig {
  const RoutineModeConfig({
    required this.id,
    required this.label,
    required this.baseMode,
    required this.policy,
    this.isUserDefined = false,
  });

  final String id;
  final String label;
  final RoutineMode baseMode;
  final RoutineModePolicy policy;
  final bool isUserDefined;

  Map<String, dynamic> toMap() => {
    'id': id,
    'label': label,
    'baseMode': baseMode.storageValue,
    'isUserDefined': isUserDefined,
    'policy': policy.toMap(),
  };

  static RoutineModeConfig fromMap(Map<String, dynamic> map) {
    return RoutineModeConfig(
      id: map['id'] as String? ?? 'flexible',
      label: map['label'] as String? ?? 'Flexible',
      baseMode: RoutineModeStorage.fromStorage(map['baseMode'] as String?),
      isUserDefined: map['isUserDefined'] as bool? ?? false,
      policy: map['policy'] is Map<String, dynamic>
          ? RoutineModePolicy.fromMap(map['policy'] as Map<String, dynamic>)
          : defaultPolicyFor(RoutineModeStorage.fromStorage(map['baseMode'] as String?)),
    );
  }

  static RoutineModePolicy defaultPolicyFor(RoutineMode mode) {
    switch (mode) {
      case RoutineMode.flexible:
        return const RoutineModePolicy(
          mode: RoutineMode.flexible,
          requireTimerForCompletion: false,
          allowHardGate: false,
          baseSnoozeMinutes: 15,
          maxExtensionMinutes: 60,
          requireReasonForDeferral: true,
        );
      case RoutineMode.disciplined:
        return const RoutineModePolicy(
          mode: RoutineMode.disciplined,
          requireTimerForCompletion: true,
          allowHardGate: false,
          baseSnoozeMinutes: 10,
          maxExtensionMinutes: 45,
          requireReasonForDeferral: true,
        );
      case RoutineMode.extreme:
        return const RoutineModePolicy(
          mode: RoutineMode.extreme,
          requireTimerForCompletion: true,
          allowHardGate: true,
          baseSnoozeMinutes: 5,
          maxExtensionMinutes: 30,
          requireReasonForDeferral: true,
        );
    }
  }

  static List<RoutineModeConfig> defaults() {
    return [
      RoutineModeConfig(
        id: 'flexible',
        label: 'Flexible',
        baseMode: RoutineMode.flexible,
        policy: defaultPolicyFor(RoutineMode.flexible),
      ),
      RoutineModeConfig(
        id: 'disciplined',
        label: 'Disciplined',
        baseMode: RoutineMode.disciplined,
        policy: defaultPolicyFor(RoutineMode.disciplined),
      ),
      RoutineModeConfig(
        id: 'extreme',
        label: 'Extreme',
        baseMode: RoutineMode.extreme,
        policy: defaultPolicyFor(RoutineMode.extreme),
      ),
    ];
  }
}
