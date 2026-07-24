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
/// `tzOffsetMinutes` (east of UTC) lets the sweep clamp notification-type
/// rescues into polite LOCAL hours without ever knowing the timezone name.
/// `morningBriefEnabled` rides here because the preference is device-local
/// (it never synced between devices) — the server briefs only devices that
/// opted in, and this doc is the only synced surface that knows.
Map<String, dynamic> deviceTokenPayload({
  required String token,
  required String platform,
  required int nowMs,
  required int tzOffsetMinutes,
  required bool morningBriefEnabled,
}) => {
  'token': token,
  'platform': platform,
  'lastSeenMs': nowMs,
  'tzOffsetMinutes': tzOffsetMinutes,
  'morningBriefEnabled': morningBriefEnabled,
  'updatedAtMs': nowMs,
};

/// Heartbeat-only merge payload (no token churn — token writes carry their
/// own lastSeenMs). Refreshes tz + the brief flag too: both drift.
Map<String, dynamic> heartbeatPayload({
  required int nowMs,
  required int tzOffsetMinutes,
  required bool morningBriefEnabled,
}) => {
  'lastSeenMs': nowMs,
  'tzOffsetMinutes': tzOffsetMinutes,
  'morningBriefEnabled': morningBriefEnabled,
  'updatedAtMs': nowMs,
};

/// Immediate merge write when the Profile toggle flips — without it the
/// flag would wait for tomorrow's heartbeat, and a user who enables the
/// brief then doesn't open the app would never get one.
Map<String, dynamic> morningBriefFlagPayload({
  required bool enabled,
  required int nowMs,
}) => {'morningBriefEnabled': enabled, 'updatedAtMs': nowMs};

/// True when a foreground push is one of our rescue-net replan signals.
/// The server tags these `{"type": "intention_replan"}`; anything else is
/// left for other handlers (or ignored).
bool isRescueReplan(Map<String, dynamic> data) =>
    data['type'] == 'intention_replan';

/// True for the days-absent rescue (notification-type). When one reaches a
/// LIVE app — foreground arrival or tap — the honest response is the same
/// as a replan signal: recompute locally so the ladder covers the window;
/// the local plan, not the push, is the source of truth (client-side
/// dedupe, PRD §8).
bool isRescueNotification(Map<String, dynamic> data) =>
    data['type'] == 'intention_rescue';

/// True for the morning-brief push (Phase 5c). Tapping it opens the Coach
/// with the suggestions panel — the same destination as the in-app
/// snackbar it replaces for users who didn't open the app.
bool isMorningBrief(Map<String, dynamic> data) =>
    data['type'] == 'morning_brief';
