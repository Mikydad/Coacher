/// Maps minutes back to the closest Add Task chip label.
String durationLabelFromMinutes(int minutes) {
  if (minutes <= 15) return '15 MIN';
  if (minutes <= 25) return '25 MIN';
  if (minutes <= 45) return '45 MIN';
  if (minutes <= 60) return '1 HOUR';
  return '1 HOUR';
}

/// Maps Add Task screen duration chip labels to minutes.
int addTaskDurationMinutes(String label) {
  switch (label.trim().toUpperCase()) {
    case '15 MIN':
      return 15;
    case '25 MIN':
      return 25;
    case '45 MIN':
      return 45;
    case '1 HOUR':
      return 60;
    default:
      return 25;
  }
}
