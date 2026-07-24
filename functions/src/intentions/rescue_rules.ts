/**
 * Pure decision rules for the intention rescue-net (humanizing Phase 5b,
 * PRD §8). NO server LLM, no I/O — every input arrives as an argument so
 * the whole policy is unit-tested and every sweep pass is reproducible.
 *
 * The rule, verbatim from the PRD: "open intention, window closing, no
 * client-scheduled slot covers it, user hasn't checked in today" → push.
 * Platform honesty picks the transport: a recently-seen device gets a
 * silent data push (the app replans locally through the attention
 * orchestrator — the double-gate); a days-absent device gets ONE polite
 * notification-type push per window with a server-composed deterministic
 * title, because iOS never delivers data-only pushes to force-quit apps.
 */

/** How close to the deadline "window closing" means. */
export const CLOSING_HORIZON_MS = 24 * 3_600_000;

/** "Checked in today": an app-open heartbeat within this window. */
export const CHECKED_IN_WINDOW_MS = 24 * 3_600_000;

/** Silent replan nudges repeat at most this often per intention. */
export const DATA_PUSH_MIN_INTERVAL_MS = 6 * 3_600_000;

/** Notification pushes only land inside polite local hours. */
export const POLITE_HOUR_START = 9;
export const POLITE_HOUR_END = 21; // exclusive

/** The intention fields the sweep reads (subset of the synced doc). */
export interface IntentionSnapshot {
  id: string;
  title: string;
  status: string;
  active: boolean;
  windowEndMs: number;
}

/** The client-mirrored coarse projection (Phase 5a), or null when the
 * client never mirrored one. */
export interface ProjectionSnapshot {
  covered: boolean;
  nextSlotMs: number | null;
}

/** Server-owned per-intention rescue bookkeeping (never client-written,
 * so client outbox upserts can't clobber it). */
export interface RescueState {
  lastRescueAtMs?: number;
  rescuedWindowEndMs?: number;
  lastDataPushAtMs?: number;
}

export type RescueAction =
  | { kind: 'skip'; reason: string }
  | { kind: 'data' }
  | { kind: 'notification'; title: string; body: string };

/** Local hour for a device at `tzOffsetMinutes` east of UTC. Unknown
 * offsets fall back to UTC — new clients always report one. */
export function localHour(nowMs: number, tzOffsetMinutes: number): number {
  const shifted = nowMs + tzOffsetMinutes * 60_000;
  return Math.floor((shifted / 3_600_000) % 24 + 24) % 24;
}

export function isPoliteHour(nowMs: number, tzOffsetMinutes: number): boolean {
  const hour = localHour(nowMs, tzOffsetMinutes);
  return hour >= POLITE_HOUR_START && hour < POLITE_HOUR_END;
}

/** "Call cousin Sara" → "call cousin Sara" for mid-sentence use — the
 * exact mirror of the client's OpportunityPlanner._asAction, so a server
 * rescue reads identically to a local deadline nudge. */
export function asAction(title: string): string {
  if (title.length < 2) return title;
  const first = title[0];
  const second = title[1];
  if (first.toUpperCase() === first && second.toLowerCase() === second) {
    return first.toLowerCase() + title.slice(1);
  }
  return title;
}

/** Deterministic rescue copy — suggestion-as-question, never a command
 * (settled decision, 2026-07-23). Matches the client's deadline template. */
export function composeRescue(title: string): { title: string; body: string } {
  return {
    title: 'A promise is closing',
    body: `Your window to ${asAction(title)} is closing — is now a good moment?`,
  };
}

/**
 * The whole policy in one pure call. The caller resolves the inputs
 * (projection doc, device heartbeats, rescue state) and executes the
 * returned action.
 */
export function rescueAction(args: {
  intention: IntentionSnapshot;
  projection: ProjectionSnapshot | null;
  /** Max lastSeenMs across the user's devices; null = no devices. */
  lastSeenMs: number | null;
  /** tz offset of the most recently seen device (minutes east of UTC). */
  tzOffsetMinutes: number;
  state: RescueState | null;
  nowMs: number;
}): RescueAction {
  const { intention, projection, lastSeenMs, tzOffsetMinutes, state, nowMs } =
    args;

  // Terminal / tombstoned intentions are the client's to display, never
  // the server's to rescue.
  if (intention.status !== 'open' || !intention.active) {
    return { kind: 'skip', reason: 'not_open' };
  }
  if (intention.windowEndMs <= nowMs) {
    return { kind: 'skip', reason: 'expired' };
  }
  if (intention.windowEndMs - nowMs > CLOSING_HORIZON_MS) {
    return { kind: 'skip', reason: 'not_closing' };
  }

  // A client slot that still lies ahead and inside the window covers the
  // promise — local multi-slot alarms are the correctness floor and the
  // server never doubles them.
  const next = projection?.nextSlotMs ?? null;
  if (
    projection?.covered === true &&
    next !== null &&
    next > nowMs &&
    next <= intention.windowEndMs
  ) {
    return { kind: 'skip', reason: 'covered' };
  }

  if (lastSeenMs === null) {
    return { kind: 'skip', reason: 'no_devices' };
  }

  const checkedIn = nowMs - lastSeenMs < CHECKED_IN_WINDOW_MS;
  if (checkedIn) {
    // The device was here today: a silent data push lets the app replan
    // through the attention orchestrator. Invisible, so no polite-hours
    // gate — but throttled so sweeps don't spam radios.
    const lastData = state?.lastDataPushAtMs ?? 0;
    if (nowMs - lastData < DATA_PUSH_MIN_INTERVAL_MS) {
      return { kind: 'skip', reason: 'data_throttled' };
    }
    return { kind: 'data' };
  }

  // Days-absent: the one polite save. Once per window, never at night —
  // a skipped pass retries on the next 15-minute sweep once hours are
  // polite again.
  if (
    state?.lastRescueAtMs !== undefined &&
    state.rescuedWindowEndMs === intention.windowEndMs
  ) {
    return { kind: 'skip', reason: 'already_rescued' };
  }
  if (!isPoliteHour(nowMs, tzOffsetMinutes)) {
    return { kind: 'skip', reason: 'impolite_hour' };
  }
  return { kind: 'notification', ...composeRescue(intention.title) };
}
