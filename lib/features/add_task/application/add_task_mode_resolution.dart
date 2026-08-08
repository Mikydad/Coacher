import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../coaching/application/default_mode_resolver.dart';
import '../../planning/application/effective_task_mode.dart';
import '../../planning/domain/models/routine.dart';
import '../../planning/domain/models/task_item.dart';
import '../../profile/application/profile_providers.dart';

/// Execution-mode choices offered by the Add Task form, in display order.
const kAddTaskModeChoiceIds = ['flexible', 'disciplined', 'extreme'];
const kAddTaskModeLabels = ['Flexible', 'Disciplined', 'Extreme'];
const kAddTaskModeDescriptions = [
  'Reminders are gentle. Missing a day is okay.',
  'Hold me accountable. Streaks matter.',
  'No excuses. Follow up until I act.',
];

/// Plan day for the form: the reminder's calendar day when a reminder is set,
/// else the preset slot/edit day (e.g. from Plan Tomorrow), else today.
String addTaskPlanDateKey({
  required bool reminderEnabled,
  required DateTime reminderTime,
  String? presetDateKey,
}) {
  if (!reminderEnabled) {
    return presetDateKey ?? DateKeys.todayKey();
  }
  final rd = DateTime(reminderTime.year, reminderTime.month, reminderTime.day);
  return DateKeys.yyyymmdd(rd);
}

/// A resolved mode seed for the form: the mode id plus where it was inherited
/// from (`profile` | `routine`) for the accountability subtitle.
class AddTaskModeSeed {
  const AddTaskModeSeed({required this.modeRefId, required this.inheritSource});

  final String modeRefId;
  final String inheritSource;
}

/// Routine-level mode for a Plan-Tomorrow slot. Null when the routine is
/// unknown or carries no known choice id — keep the profile-scaled seed then.
Future<AddTaskModeSeed?> resolveRoutineSlotModeSeed(
  WidgetRef ref, {
  required String slotDateKey,
  required String slotRoutineId,
}) async {
  try {
    final planning = ref.read(planningRepositoryProvider);
    final routines = await planning.getRoutinesForDate(slotDateKey);
    for (final r in routines) {
      if (r.id == slotRoutineId) {
        final id = r.modeId.trim().toLowerCase();
        if (kAddTaskModeChoiceIds.contains(id)) {
          return AddTaskModeSeed(modeRefId: id, inheritSource: 'routine');
        }
        return null;
      }
    }
  } catch (e) {
    debugPrint('add_task_mode_resolution: swallowed error: $e');
  }
  return null;
}

/// Seed from the profile-level Discipline Mode, scaled by the target block's
/// urgency when the slot is known ("how strict is the app overall" — see
/// [DefaultModeResolver]).
Future<AddTaskModeSeed> resolveProfileDefaultModeSeed(
  WidgetRef ref, {
  String? slotRoutineId,
  String? slotBlockId,
}) async {
  final profileDefault = ref.read(defaultEnforcementModeProvider);
  final urgency = await _blockUrgencyForSlot(
    ref,
    routineId: slotRoutineId,
    blockId: slotBlockId,
  );
  return AddTaskModeSeed(
    modeRefId: DefaultModeResolver.resolveModeRefId(
      profileDefault: profileDefault,
      blockUrgencyScore: urgency,
    ),
    inheritSource: 'profile',
  );
}

Future<int?> _blockUrgencyForSlot(
  WidgetRef ref, {
  String? routineId,
  String? blockId,
}) async {
  if (routineId == null || blockId == null) return null;
  try {
    final planning = ref.read(planningRepositoryProvider);
    final blocks = await planning.getBlocks(routineId);
    for (final b in blocks) {
      if (b.id == blockId) return b.urgencyScore;
    }
  } catch (e) {
    debugPrint('add_task_mode_resolution: swallowed error: $e');
  }
  return null;
}

/// The mode id persisted at save time: an explicit user/task mode wins, else
/// the routine's mode, else the profile default scaled by block urgency.
/// [explicitModeRefId] is null while the mode is still inherited (create mode,
/// user never picked); [fallbackPriority] is the edited task's priority or 3.
Future<String> resolveEffectiveModeRefIdForSave(
  WidgetRef ref, {
  required String routineId,
  required String blockId,
  required String planDateKey,
  required String? explicitModeRefId,
  required int fallbackPriority,
}) async {
  final planning = ref.read(planningRepositoryProvider);
  Routine? routine;
  var blockUrgency = 50;
  try {
    final routines = await planning.getRoutinesForDate(planDateKey);
    for (final r in routines) {
      if (r.id == routineId) {
        routine = r;
        break;
      }
    }
    final blocks = await planning.getBlocks(routineId);
    for (final b in blocks) {
      if (b.id == blockId) {
        blockUrgency = b.urgencyScore;
        break;
      }
    }
  } catch (e) {
    debugPrint('add_task_mode_resolution: swallowed error: $e');
  }

  final task = PlannedTask(
    id: '',
    routineId: routineId,
    blockId: blockId,
    title: '',
    durationMinutes: 1,
    priority: 3,
    orderIndex: 0,
    reminderEnabled: false,
    reminderTimeIso: null,
    status: TaskStatus.notStarted,
    createdAtMs: 0,
    updatedAtMs: 0,
    modeRefId: explicitModeRefId,
  );
  final fallback = DefaultModeResolver.resolveModeRefId(
    profileDefault: ref.read(defaultEnforcementModeProvider),
    priority: fallbackPriority,
    blockUrgencyScore: blockUrgency,
  );
  return EffectiveTaskMode.effectiveModeRefId(
    task: task,
    routine: routine,
    fallbackModeRefId: fallback,
  );
}
