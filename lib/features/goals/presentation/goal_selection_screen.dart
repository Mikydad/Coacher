import 'package:flutter/material.dart';

import 'goals_home_screen.dart';

/// Route **`/goals`** — Home footer “Goals” tab (`prd-goals.md`).
class GoalSelectionScreen extends StatelessWidget {
  const GoalSelectionScreen({super.key});

  static const routeName = '/goals';

  @override
  Widget build(BuildContext context) {
    return const GoalsHomeScreen();
  }
}
