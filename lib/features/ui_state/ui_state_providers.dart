import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedTaskProvider = StateProvider<String>((ref) => 'Deep Work: UI Architecture');
final timerRunningProvider = StateProvider<bool>((ref) => false);
final timerDisplayProvider = StateProvider<String>((ref) => '25:00');
