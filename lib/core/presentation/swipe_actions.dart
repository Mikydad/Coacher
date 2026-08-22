import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'app_colors.dart';

/// Right-to-left swipe on a list row revealing Edit / Delete (2026-08-22).
/// One shared wrapper so goals, tasks, and future lists behave and look the
/// same. The delete callback runs the surface's existing confirm-and-delete
/// flow; the row leaves the tree via the local watch stream, so no
/// dismiss animation state is kept here.
class SwipeActionsRow extends StatelessWidget {
  const SwipeActionsRow({
    super.key,
    required this.id,
    required this.child,
    this.onEdit,
    required this.onDelete,
    this.groupTag = 'swipe-actions',
  });

  /// Stable row identity (entity id) — keeps the pane attached to the right
  /// row across list updates.
  final String id;
  final Widget child;
  final VoidCallback? onEdit;
  final VoidCallback onDelete;

  /// Rows sharing a tag auto-close each other's open panes.
  final Object groupTag;

  @override
  Widget build(BuildContext context) {
    return Slidable(
      key: ValueKey('swipe_$id'),
      groupTag: groupTag,
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: onEdit == null ? 0.28 : 0.5,
        children: [
          if (onEdit != null)
            CustomSlidableAction(
              onPressed: (_) => onEdit!(),
              backgroundColor: AppColors.fg12,
              foregroundColor: AppColors.textPrimary,
              child: const _SwipeActionLabel(
                icon: Icons.edit_rounded,
                label: 'Edit',
              ),
            ),
          CustomSlidableAction(
            onPressed: (_) => onDelete(),
            backgroundColor: AppColors.danger.withValues(alpha: 0.85),
            foregroundColor: Colors.white,
            child: const _SwipeActionLabel(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SwipeActionLabel extends StatelessWidget {
  const _SwipeActionLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
