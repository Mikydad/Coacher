import 'isar_ai_summary.dart';
import 'isar_analytics_event.dart';
import 'isar_analytics_stats.dart';
import 'isar_behavior_feature_cache.dart';
import 'isar_block.dart';
import 'isar_coaching_focus.dart';
import 'isar_delivery_decision_snapshot.dart';
import 'isar_delivery_history_entry.dart';
import 'isar_generated_insight.dart';
import 'isar_goal.dart';
import 'isar_reminder.dart';
import 'isar_routine.dart';
import 'isar_task.dart';

/// All Isar collection schemas for [OfflineStore].
const isarSchemaList = [
  IsarRoutineSchema,
  IsarBlockSchema,
  IsarTaskSchema,
  IsarAnalyticsEventSchema,
  IsarAnalyticsStatsSchema,
  IsarAiSummarySchema,
  IsarBehaviorFeatureCacheSchema,
  IsarCoachingFocusSchema,
  IsarDeliveryDecisionSnapshotSchema,
  IsarDeliveryHistoryEntrySchema,
  IsarGeneratedInsightSchema,
  IsarReminderSchema,
  IsarGoalSchema,
];
