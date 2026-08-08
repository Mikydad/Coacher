import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../context_override/application/context_override_providers.dart';
import '../../context_override/domain/models/context_override.dart';
import '../../planning/domain/models/task_item.dart';
import '../../planning/domain/sleep_task.dart';
import '../../planning/presentation/sleep_task_ios_guidance.dart';

/// Post-save Sleep-category effects: update the daily sleep window and, when
/// opted in, activate the quiet-mode override (iOS shows the Focus guidance
/// sheet instead of auto-activating). No-op for non-sleep or reminder-less
/// tasks.
Future<void> applyAddTaskSleepSideEffects(
  BuildContext context,
  WidgetRef ref, {
  required PlannedTask task,
  required bool syncSleepWindowAndQuietMode,
  required String inAppQuietMode,
}) async {
  if (!isSleepTask(task)) return;
  if (!task.reminderEnabled || task.reminderTimeIso == null) return;

  final start = DateTime.tryParse(task.reminderTimeIso!)?.toLocal();
  if (start == null) return;
  final end = start.add(Duration(minutes: task.durationMinutes));

  final overrideService = ref.read(contextOverrideServiceProvider);
  await overrideService.setSleepWindow(
    start: formatSleepWindowHHmm(start),
    end: formatSleepWindowHHmm(end),
  );

  if (!syncSleepWindowAndQuietMode) return;

  if (Platform.isIOS && context.mounted) {
    await showSleepTaskIosFocusGuidance(
      context,
      onUseInAppSleep: () async {
        await overrideService.activateOverride(
          type: ContextOverride.sleep,
          expiresAt: end,
        );
      },
      onUseInAppDnd: () async {
        await overrideService.activateOverride(
          type: ContextOverride.doNotDisturb,
          expiresAt: end,
        );
      },
    );
    return;
  }

  final type = inAppQuietMode == 'dnd'
      ? ContextOverride.doNotDisturb
      : ContextOverride.sleep;
  await overrideService.activateOverride(type: type, expiresAt: end);
}
