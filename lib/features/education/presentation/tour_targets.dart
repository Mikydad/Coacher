import 'package:flutter/widgets.dart';

/// GlobalKeys the guided tour points its spotlight at. Screens attach them
/// to the real widgets; the overlay measures their rects each frame it is
/// visible. A key with no mounted context simply renders no spotlight, which
/// is what makes off-script navigation safe.
abstract final class TourTargets {
  /// The ADD TASK action tile on Home.
  static final addTaskTile = GlobalKey(debugLabel: 'tour_addTaskTile');

  /// The title field on the Add Task screen.
  static final addTaskTitleField = GlobalKey(
    debugLabel: 'tour_addTaskTitleField',
  );

  /// The save button on the Add Task screen.
  static final addTaskSaveButton = GlobalKey(
    debugLabel: 'tour_addTaskSaveButton',
  );

  /// The completion circle of the FIRST task row on Home.
  static final firstTaskCheckbox = GlobalKey(
    debugLabel: 'tour_firstTaskCheckbox',
  );

  /// The analytics/progress hero card on Home.
  static final progressCard = GlobalKey(debugLabel: 'tour_progressCard');

  /// Global rect of a target, or null when it isn't on screen.
  static Rect? rectOf(GlobalKey key) {
    final context = key.currentContext;
    if (context == null || !context.mounted) return null;
    final render = context.findRenderObject();
    if (render is! RenderBox || !render.attached || !render.hasSize) {
      return null;
    }
    final origin = render.localToGlobal(Offset.zero);
    return origin & render.size;
  }
}
