import '../domain/models/task_item.dart';

const String kSleepTaskCategory = 'Sleep';

const List<String> sleepDurationChipKeys = ['6 HOURS', '7 HOURS', '8 HOURS'];

const List<String> sleepDurationChipLabels = ['6h', '7h', '8h'];

bool isSleepCategory(String? category) =>
    category?.trim().toLowerCase() == kSleepTaskCategory.toLowerCase();

bool isSleepTask(PlannedTask task) => isSleepCategory(task.category);

/// 24-hour `HH:mm` for sleep window storage.
String formatSleepWindowHHmm(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
