import 'isar_block.dart';
import 'isar_goal.dart';
import 'isar_reminder.dart';
import 'isar_routine.dart';
import 'isar_task.dart';

/// All Isar collection schemas for [OfflineStore].
const isarSchemaList = [
  IsarRoutineSchema,
  IsarBlockSchema,
  IsarTaskSchema,
  IsarReminderSchema,
  IsarGoalSchema,
];
