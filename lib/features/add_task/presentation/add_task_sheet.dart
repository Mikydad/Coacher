import 'package:flutter/material.dart';

import 'add_task_args.dart';
import 'add_task_screen.dart';
import 'add_task_ui.dart';

/// Opens Add Task as a modal bottom sheet — the one way to reach the form
/// (create, edit, and Plan Tomorrow slots all come through here).
///
/// The sheet slides up over the caller, dismisses by swipe-down / tapping the
/// scrim / save, and keeps the caller's context underneath. Dismissing
/// mid-entry is safe: the form's draft autosave offers a restore next open.
/// The route is still named [AddTaskScreen.routeName] so the guided tour and
/// the feedback route tracker see the same signal as the old pushed page.
Future<void> showAddTaskSheet(
  BuildContext context, {
  AddTaskEditArgs? editArgs,
  AddTaskSlotArgs? slotArgs,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: AddTaskColors.surface,
    clipBehavior: Clip.antiAlias,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    routeSettings: const RouteSettings(name: AddTaskScreen.routeName),
    builder: (_) => FractionallySizedBox(
      // Tall overlay: a sliver of the caller stays visible so the sheet
      // reads as "on top of" the screen, not a new page.
      heightFactor: 0.93,
      child: AddTaskScreen(editArgs: editArgs, slotArgs: slotArgs),
    ),
  );
}
