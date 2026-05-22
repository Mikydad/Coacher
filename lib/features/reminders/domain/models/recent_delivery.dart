import '../../../context_override/domain/models/interruption_level.dart';

/// Lightweight record of a notification that was successfully delivered.
/// Kept in-memory (Riverpod StateProvider) for the last 30 minutes
/// to enable collision management in [AttentionOrchestrator].
class RecentDelivery {
  const RecentDelivery({
    required this.entityId,
    required this.deliveredAtMs,
    required this.interruptionLevel,
  });

  final String entityId;

  /// Epoch milliseconds when the notification was scheduled/delivered.
  final int deliveredAtMs;

  final InterruptionLevel interruptionLevel;

  DateTime get deliveredAt =>
      DateTime.fromMillisecondsSinceEpoch(deliveredAtMs);
}
