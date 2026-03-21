import 'package:flutter/material.dart';

import '../features/add_task/presentation/add_task_screen.dart';
import '../features/firebase_test/presentation/firebase_test_screen.dart';
import '../features/focus/presentation/focus_selection_screen.dart';
import '../features/goals/presentation/goal_selection_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/plan_tomorrow/presentation/plan_tomorrow_screen.dart';
import '../features/tasks_hub/presentation/tasks_hub_screen.dart';
import '../features/timer/presentation/timer_session_screen.dart';

class CoachForLifeApp extends StatelessWidget {
  const CoachForLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coach for Life',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050806),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFB7FF00),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      initialRoute: HomeScreen.routeName,
      routes: {
        HomeScreen.routeName: (_) => const HomeScreen(),
        GoalSelectionScreen.routeName: (_) => const GoalSelectionScreen(),
        PlanTomorrowScreen.routeName: (_) => const PlanTomorrowScreen(),
        AddTaskScreen.routeName: (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          return AddTaskScreen(
            editArgs: args is AddTaskEditArgs ? args : null,
            slotArgs: args is AddTaskSlotArgs ? args : null,
          );
        },
        TasksHubScreen.routeName: (_) => const TasksHubScreen(),
        FirebaseTestScreen.routeName: (_) => const FirebaseTestScreen(),
        FocusSelectionScreen.routeName: (_) => const FocusSelectionScreen(),
        TimerSessionScreen.routeName: (_) => const TimerSessionScreen(),
      },
    );
  }
}
