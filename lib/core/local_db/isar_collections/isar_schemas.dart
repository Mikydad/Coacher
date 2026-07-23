import 'isar_activity_feed_cache.dart';
import 'isar_ai_action_batch.dart';
import 'isar_ai_interaction_history.dart';
import 'isar_dismissed_suggestion_log.dart';
import 'isar_ai_pulse_cache.dart';
import 'isar_ai_summary.dart';
import 'isar_analytics_event.dart';
import 'isar_analytics_stats.dart';
import 'isar_behavior_feature_cache.dart';
import 'isar_block.dart';
import 'isar_blocked_user.dart';
import 'isar_coaching_focus.dart';
import 'isar_delivery_decision_snapshot.dart';
import 'isar_delivery_history_entry.dart';
import 'isar_generated_insight.dart';
import 'isar_goal.dart';
import 'isar_goal_action.dart';
import 'isar_goal_check_in.dart';
import 'isar_goal_milestone.dart';
import 'isar_intention.dart';
import 'isar_notification_ledger_entry.dart';
import 'isar_opportunity_plan.dart';
import 'isar_onboarding_profile.dart';
import 'isar_points.dart';
import 'isar_reminder.dart';
import 'isar_routine.dart';
import 'isar_scheduled_time_block.dart';
import 'isar_stake_challenge.dart';
import 'isar_stake_evidence.dart';
import 'isar_task.dart';
import 'isar_user_attention_state.dart';
import 'isar_user_coaching_profile.dart';
import 'isar_user_profile_preference.dart';

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
  IsarGoalActionSchema,
  IsarGoalMilestoneSchema,
  IsarGoalCheckInSchema,
  IsarScheduledTimeBlockSchema,
  IsarUserAttentionStateSchema,
  IsarUserCoachingProfileSchema,
  IsarUserProfilePreferenceSchema,
  IsarOnboardingProfileSchema,
  IsarActivityFeedCacheSchema,
  IsarAiPulseCacheSchema,
  IsarAiInteractionHistorySchema,
  IsarDismissedSuggestionLogSchema,
  IsarNotificationLedgerEntrySchema,
  IsarAiActionBatchSchema,
  IsarStakeChallengeSchema,
  IsarStakeEvidenceSchema,
  IsarBlockedUserSchema,
  IsarPointsTxnSchema,
  IsarPointsBalanceSchema,
  IsarCharitySchema,
  IsarIntentionSchema,
  IsarOpportunityPlanSchema,
];
