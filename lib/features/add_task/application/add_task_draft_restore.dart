import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/application/analytics_event_logger.dart';
import '../../analytics/domain/models/analytics_event.dart';
import '../../planning/application/form_draft_providers.dart';
import '../../planning/domain/models/add_task_form_draft.dart';

/// Loads a saved Add Task draft, silently discards expired / empty / identical
/// ones, and otherwise offers the "Restore draft?" dialog. [applyDraft] must
/// run the caller State's setState-based apply (and cancel its autosave) so
/// draft-dirtiness bookkeeping stays inside the State; the once-per-open guard
/// also stays with the caller.
Future<void> offerAddTaskDraftRestoreIfNeeded(
  BuildContext context,
  WidgetRef ref, {
  required String draftKey,
  required bool isEdit,
  required AddTaskFormDraft Function() captureCurrent,
  required void Function(AddTaskFormDraft draft) applyDraft,
}) async {
  final repo = ref.read(formDraftRepositoryProvider);
  final raw = await repo.load(draftKey);
  if (!context.mounted || raw == null) return;

  final draft = AddTaskFormDraft.fromJson(raw);
  if (repo.isExpired(draft.savedAtMs)) {
    await repo.delete(draftKey);
    return;
  }
  if (!draft.hasMeaningfulContent) {
    await repo.delete(draftKey);
    return;
  }

  final current = captureCurrent();
  if (current.contentEquals(draft)) {
    await repo.delete(draftKey);
    return;
  }

  final restore = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Restore draft?'),
      content: const Text(
        'You have unsaved changes from earlier. Restore them or start fresh?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Start fresh'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Restore'),
        ),
      ],
    ),
  );
  if (!context.mounted) return;
  if (restore == true) {
    applyDraft(draft);
    await repo.delete(draftKey);
    fireAndForgetAnalyticsEvent(
      ref,
      type: AnalyticsEventType.formDraftRestored,
      entityId: draftKey,
      entityKind: 'form_draft',
      sourceSurface: isEdit ? 'add_task_edit' : 'add_task_create',
      idempotencyKey: 'form_draft_restored_$draftKey',
    );
  } else {
    await repo.delete(draftKey);
    fireAndForgetAnalyticsEvent(
      ref,
      type: AnalyticsEventType.formDraftDiscarded,
      entityId: draftKey,
      entityKind: 'form_draft',
      sourceSurface: isEdit ? 'add_task_edit' : 'add_task_create',
      idempotencyKey: 'form_draft_discarded_$draftKey',
    );
  }
}
