/**
 * Reminder V2's [L-PUSH] policy (PRD §5, task 13.0) — pure rules, no I/O.
 *
 * The local pre-scheduled ladder is the correctness floor: local
 * notifications fire whether or not the app is running, so the server never
 * doubles a slot the client armed. What the floor cannot do is anything
 * BEYOND the compiled ladder while the app stays closed, because extending
 * the ladder needs an [L-ALIVE] recompile. That gap is exactly two cases:
 *
 * 1. **The Extreme tail** (FR-R-30): an Extreme-mode occurrence that went
 *    past its window unresolved keeps deserving pressure — hourly, three
 *    times — but those slots were never armed locally (the ladder stops at
 *    windowEnd by design).
 * 2. **The criticality-3 in-window net**: medication on a device that has
 *    been dark since before the occurrence was due, so its ladder may not
 *    exist at all (Android after a restart — D8 deferred the boot
 *    receiver). Inside the window only: D5's "stops hard at windowEnd"
 *    binds the server too.
 *
 * Everything else is a skip, and says why.
 */

export interface ReminderOccurrenceSnapshot {
  id: string;
  entityId: string;
  entityTitle: string;
  state: string; // upcoming | due | active | overdue | resolved
  scheduledAtMs: number;
  windowMinutes: number;
  criticality: number;
  modeRefId: string | null;
}

export interface ReminderRescueState {
  /** How many tail pushes this occurrence has received. */
  tailCount: number;
  lastPushAtMs: number;
  /** Set when the one crit-3 in-window rescue went out. */
  critRescued?: boolean;
}

export type ReminderRescueAction =
  | { kind: 'skip'; reason: string }
  | { kind: 'tail'; tailIndex: number; title: string; body: string }
  | { kind: 'critWindow'; title: string; body: string };

/** Device seen more recently than this → the local engine owns delivery. */
export const CHECKED_IN_WINDOW_MS = 30 * 60 * 1000;

/** Extreme tail cadence and depth (FR-R-30's table). */
export const TAIL_INTERVAL_MS = 60 * 60 * 1000;
export const MAX_TAIL_PUSHES = 3;

export function reminderRescueAction(args: {
  occ: ReminderOccurrenceSnapshot;
  lastSeenMs: number | null;
  state: ReminderRescueState | null;
  nowMs: number;
}): ReminderRescueAction {
  const { occ, lastSeenMs, state, nowMs } = args;

  if (occ.state === 'resolved') return { kind: 'skip', reason: 'resolved' };

  const isExtreme = (occ.modeRefId ?? '').toLowerCase() === 'extreme';
  const isCrit = occ.criticality >= 3;
  if (!isExtreme && !isCrit) {
    return { kind: 'skip', reason: 'not_covered' };
  }

  if (lastSeenMs === null) return { kind: 'skip', reason: 'no_devices' };
  if (nowMs - lastSeenMs < CHECKED_IN_WINDOW_MS) {
    // Fresh heartbeat = the app ran recently = the ladder is armed and the
    // Recovery Card is doing its job. This gate IS the idempotency between
    // [L-PUSH] and the local slots (task 13.3).
    return { kind: 'skip', reason: 'device_fresh' };
  }

  const windowEndMs = occ.scheduledAtMs + occ.windowMinutes * 60 * 1000;

  // ── Case 2: criticality-3, still inside the window ──────────────────────
  if (isCrit && nowMs >= occ.scheduledAtMs && nowMs < windowEndMs) {
    if (state?.critRescued === true) {
      return { kind: 'skip', reason: 'already_rescued' };
    }
    // A heartbeat AFTER scheduling means the ladder was compiled and its
    // slots will fire on their own — pushing would double them.
    if (lastSeenMs >= occ.scheduledAtMs) {
      return { kind: 'skip', reason: 'ladder_assumed_armed' };
    }
    return {
      kind: 'critWindow',
      title: occ.entityTitle || 'SidePal',
      body: `Time for ${occ.entityTitle || 'your task'}.`,
    };
  }

  // D5: criticality 3 stops hard at windowEnd — no tail, server included.
  if (!isExtreme) return { kind: 'skip', reason: 'crit_window_closed' };

  // ── Case 1: the Extreme tail, hourly ×3 past the window ────────────────
  if (nowMs < windowEndMs) return { kind: 'skip', reason: 'window_open' };

  const tailCount = state?.tailCount ?? 0;
  if (tailCount >= MAX_TAIL_PUSHES) {
    return { kind: 'skip', reason: 'tail_exhausted' };
  }
  const dueForNext = windowEndMs + (tailCount + 1) * TAIL_INTERVAL_MS;
  if (nowMs < dueForNext) return { kind: 'skip', reason: 'tail_not_due' };

  const name = occ.entityTitle || 'your task';
  return {
    kind: 'tail',
    tailIndex: tailCount + 1,
    title: occ.entityTitle || 'SidePal',
    // Mirrors the copy bank's Extreme voice: blunter, never louder.
    body: tailCount + 1 >= MAX_TAIL_PUSHES
      ? `Final call for ${name}. Do it now, or say why you're not.`
      : `${name} is still open. Start it, or reschedule with a reason.`,
  };
}
