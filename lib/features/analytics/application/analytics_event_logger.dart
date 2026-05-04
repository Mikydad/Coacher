import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../../core/utils/date_keys.dart';
import '../../../core/utils/stable_id.dart';
import '../domain/models/analytics_event.dart';

Future<void> logAnalyticsEvent(
  WidgetRef ref, {
  required AnalyticsEventType type,
  required String entityId,
  required String entityKind,
  required String sourceSurface,
  required String idempotencyKey,
  String? modeRefId,
  String? reason,
  DateTime? now,
}) async {
  final ts = now ?? DateTime.now();
  final event = AnalyticsEvent(
    id: StableId.generate('an_evt'),
    type: type,
    entityId: entityId,
    entityKind: entityKind,
    dateKey: DateKeys.todayKey(ts),
    timestampLocalIso: ts.toIso8601String(),
    sourceSurface: sourceSurface,
    idempotencyKey: idempotencyKey,
    modeRefId: modeRefId,
    reason: reason,
    createdAtMs: ts.millisecondsSinceEpoch,
    updatedAtMs: ts.millisecondsSinceEpoch,
  );
  await ref.read(analyticsRepositoryProvider).logEvent(event);
}

void fireAndForgetAnalyticsEvent(
  WidgetRef ref, {
  required AnalyticsEventType type,
  required String entityId,
  required String entityKind,
  required String sourceSurface,
  required String idempotencyKey,
  String? modeRefId,
  String? reason,
}) {
  unawaited(
    logAnalyticsEvent(
      ref,
      type: type,
      entityId: entityId,
      entityKind: entityKind,
      sourceSurface: sourceSurface,
      idempotencyKey: idempotencyKey,
      modeRefId: modeRefId,
      reason: reason,
    ),
  );
}
