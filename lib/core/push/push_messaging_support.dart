/// Pure, plugin-free helpers for `PushMessagingService` (humanizing
/// Phase 5) — split out so payload shapes, the heartbeat day key, and
/// rescue-payload detection are unit-testable without FCM or Firebase.
library;

/// Local calendar day key (yyyy-mm-dd) for the once-per-day heartbeat gate.
String dayKey(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';

/// Device-token registration payload. `lastSeenMs` doubles as the initial
/// heartbeat so a freshly registered device is immediately "seen today".
Map<String, dynamic> deviceTokenPayload({
  required String token,
  required String platform,
  required int nowMs,
}) => {
  'token': token,
  'platform': platform,
  'lastSeenMs': nowMs,
  'updatedAtMs': nowMs,
};

/// Heartbeat-only merge payload (no token churn — token writes carry their
/// own lastSeenMs).
Map<String, dynamic> heartbeatPayload({required int nowMs}) => {
  'lastSeenMs': nowMs,
  'updatedAtMs': nowMs,
};

/// True when a foreground push is one of our rescue-net replan signals.
/// The server tags these `{"type": "intention_replan"}`; anything else is
/// left for other handlers (or ignored).
bool isRescueReplan(Map<String, dynamic> data) =>
    data['type'] == 'intention_replan';
