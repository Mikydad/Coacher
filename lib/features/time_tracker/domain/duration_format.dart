/// Compact durations for the timeline: `6m`, `45m`, `1h 05m`, `3h 51m`.
/// Sub-minute rounds down; zero reads `0m`.
String formatActivityDuration(Duration d) {
  final totalMinutes = d.inMinutes;
  if (totalMinutes < 60) return '${totalMinutes}m';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
}
