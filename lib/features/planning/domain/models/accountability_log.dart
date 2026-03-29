import '../../../../core/validation/model_validators.dart';
import 'flow_transition_event.dart';

enum AccountabilityAction {
  reshuffle,
  defer,
  skip,
}

extension AccountabilityActionStorage on AccountabilityAction {
  String get storageValue => name;
}

class AccountabilityLog {
  const AccountabilityLog({
    required this.id,
    required this.taskId,
    required this.action,
    required this.reasonCategory,
    required this.reasonNote,
    this.modeRefId,
    this.taskPriority,
    required this.createdAtMs,
  });

  final String id;
  final String taskId;
  final AccountabilityAction action;
  final OverrideReasonCategory reasonCategory;
  final String reasonNote;
  final String? modeRefId;
  final int? taskPriority;
  final int createdAtMs;

  void validate() {
    ModelValidators.requireNotBlank(id, 'accountabilityLog.id');
    ModelValidators.requireNotBlank(taskId, 'accountabilityLog.taskId');
    FlowTransitionEvent.validateReasonNote(reasonNote);
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'taskId': taskId,
    'action': action.storageValue,
    'reasonCategory': reasonCategory.storageValue,
    'reasonNote': reasonNote,
    if (modeRefId != null) 'modeRefId': modeRefId,
    if (taskPriority != null) 'taskPriority': taskPriority,
    'createdAtMs': createdAtMs,
  };

  static AccountabilityLog fromMap(Map<String, dynamic> map) {
    final rawAction = (map['action'] as String?) ?? AccountabilityAction.defer.storageValue;
    final action = AccountabilityAction.values.firstWhere(
      (a) => a.storageValue == rawAction,
      orElse: () => AccountabilityAction.defer,
    );
    return AccountabilityLog(
      id: map['id'] as String? ?? '',
      taskId: map['taskId'] as String? ?? '',
      action: action,
      reasonCategory: OverrideReasonCategoryStorage.fromStorage(map['reasonCategory'] as String?),
      reasonNote: map['reasonNote'] as String? ?? '',
      modeRefId: map['modeRefId'] as String?,
      taskPriority: (map['taskPriority'] as num?)?.toInt(),
      createdAtMs: (map['createdAtMs'] as num?)?.toInt() ?? 0,
    );
  }
}
