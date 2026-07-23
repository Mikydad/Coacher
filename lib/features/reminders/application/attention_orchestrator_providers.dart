import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/notifications/notification_ledger_repository.dart';
import '../../../core/offline/offline_store.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../../analytics/application/feature_builder_recompute_service.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../coaching/application/coaching_style_providers.dart';
import '../../context_override/application/context_override_providers.dart';
import '../domain/models/recent_delivery.dart';
import '../domain/models/reminder_intent.dart';
import 'attention_orchestrator_service.dart';

// ─── Suppressed intent queue ──────────────────────────────────────────────────

/// Intents suppressed with retryAllowed = true, held in memory.
/// Populated by [AttentionOrchestratorService] and flushed on override end.
final suppressedIntentQueueProvider = StateProvider<List<ReminderIntent>>(
  (ref) => const [],
);

// ─── Recent deliveries ────────────────────────────────────────────────────────

/// Notifications delivered in the last 30 minutes.
/// Used by [AttentionOrchestrator] for collision gap management.
final recentDeliveriesProvider = StateProvider<List<RecentDelivery>>(
  (ref) => const [],
);

// ─── AttentionOrchestratorService ─────────────────────────────────────────────

/// The Riverpod-wired execution wrapper for [AttentionOrchestrator].
///
/// Injects all required dependencies, including a bound [logEvent] callback
/// that writes to the analytics repository and triggers feature-builder
/// recompute — keeping [AttentionOrchestratorService] free of Riverpod.
final attentionOrchestratorServiceProvider =
    Provider<AttentionOrchestratorService>((ref) {
      final analyticsRepo = ref.read(analyticsRepositoryProvider);
      final featureBuilderRecompute = ref.read(
        featureBuilderRecomputeServiceProvider,
      );

      Future<void> logEvent({
        required AnalyticsEventType type,
        required String entityId,
        required String entityKind,
        required String sourceSurface,
        required String idempotencyKey,
        String? reason,
      }) async {
        final ts = DateTime.now();
        final event = AnalyticsEvent(
          id: StableId.generate('an_evt'),
          type: type,
          entityId: entityId,
          entityKind: entityKind,
          dateKey: DateKeys.todayKey(ts),
          timestampLocalIso: ts.toIso8601String(),
          sourceSurface: sourceSurface,
          idempotencyKey: idempotencyKey,
          reason: reason,
          createdAtMs: ts.millisecondsSinceEpoch,
          updatedAtMs: ts.millisecondsSinceEpoch,
        );
        await analyticsRepo.logEvent(event);
        featureBuilderRecompute.onAnalyticsEventLogged(event);
      }

      return AttentionOrchestratorService(
        contextOverrideRepository: ref.read(contextOverrideRepositoryProvider),
        focusRepository: ref.read(focusRepositoryProvider),
        reminderRepository: ref.read(reminderRepositoryProvider),
        notifications: ref.read(localNotificationsServiceProvider),
        ledger: NotificationLedgerRepository(OfflineStore.instance.isar!),
        logEvent: logEvent,
        // Synchronous getter — reads cached Riverpod state without suspending.
        getCoachingStyle: () => ref.read(activeCoachingStyleProvider),
        budget: ref.read(notificationBudgetProvider),
      );
    });
