import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/form_draft_repository.dart';

/// Drafts older than this are discarded on load.
const kFormDraftTtlMinutes = 60;

final formDraftRepositoryProvider = Provider<FormDraftRepository>(
  (ref) => FormDraftRepository(),
);

String addTaskCreateDraftKey() => 'add_task_create';

String addTaskEditDraftKey(String taskId) => 'add_task_edit:$taskId';

String goalCreateDraftKey() => 'goal_create';

String goalEditDraftKey(String goalId) => 'goal_edit:$goalId';
