import 'package:flutter/material.dart';

import '../../../../core/tier/pro_locked.dart';

/// Pro gate for Progress history (Week and beyond; decision 2026-09-12) —
/// the shared [ProLocked] with Progress's pill label.
class ProgressProGate extends StatelessWidget {
  const ProgressProGate({
    super.key,
    required this.blocked,
    required this.onUnlock,
    required this.child,
  });

  final bool blocked;
  final VoidCallback onUnlock;
  final Widget child;

  @override
  Widget build(BuildContext context) => ProLocked(
    blocked: blocked,
    label: 'Unlock Progress',
    onUnlock: onUnlock,
    child: child,
  );
}
