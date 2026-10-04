/**
 * Pre-dispatch quota gating — pure logic (no firebase imports; unit-tested).
 *
 * Pre-launch audit H9/H10 (2026-09-15). The interactive AI endpoints run
 * the Firestore quota transaction CONCURRENTLY with the OpenAI request for
 * latency, so a rejected caller has already started one upstream request.
 * The per-instance markers below bound that to one aborted request per
 * instance per window — but only if EVERY rejection reason sets a marker
 * (daily cap, token budget and follow-up cap never did), and only if the
 * marker is consulted for every request shape (the `loopIndex > 0` escape
 * hatch let a client with a junk turnId dispatch on every call).
 */

/** uid → epoch ms until which the uid is known to be over quota. */
export class OverQuotaRegistry {
  private readonly untilByKey = new Map<string, number>();

  constructor(private readonly maxEntries = 1000) {}

  exhaustedUntil(key: string, now: number = Date.now()): number | undefined {
    const until = this.untilByKey.get(key);
    if (until !== undefined && now < until) return until;
    this.untilByKey.delete(key);
    return undefined;
  }

  mark(key: string, untilMs: number, now: number = Date.now()): void {
    if (this.untilByKey.size > this.maxEntries) {
      for (const [k, until] of this.untilByKey) {
        if (until <= now) this.untilByKey.delete(k);
      }
    }
    this.untilByKey.set(key, untilMs);
  }

  /** Test hook. */
  clear(): void {
    this.untilByKey.clear();
  }
}

/**
 * Turns this instance has CHARGED (turn registered in the quota doc). A
 * follow-up (`loopIndex > 0`) for one of these is a known-legitimate agent
 * loop and keeps the concurrent fast path even while the uid is over
 * quota; a follow-up for an unknown turn must clear the quota transaction
 * BEFORE anything is dispatched upstream.
 */
export class ChargedTurnRegistry {
  private readonly keys = new Set<string>();

  constructor(private readonly maxEntries = 5000) {}

  static key(uid: string, turnKey: string): string {
    return `${uid}:${turnKey}`;
  }

  add(uid: string, turnKey: string): void {
    if (this.keys.size >= this.maxEntries) {
      // Drop the oldest half; insertion order is iteration order.
      let n = 0;
      for (const k of this.keys) {
        this.keys.delete(k);
        if (++n >= this.maxEntries / 2) break;
      }
    }
    this.keys.add(ChargedTurnRegistry.key(uid, turnKey));
  }

  has(uid: string, turnKey: string): boolean {
    return this.keys.has(ChargedTurnRegistry.key(uid, turnKey));
  }

  clear(): void {
    this.keys.clear();
  }
}

export type DispatchGate = 'reject' | 'fast_path' | 'quota_first';

/**
 * How to run the quota check relative to the upstream request.
 *  - reject:      known over quota and this is not a follow-up of a turn
 *                 this instance charged — no upstream call at all;
 *  - fast_path:   first turn while not over quota, or a follow-up of a
 *                 turn charged here — quota and upstream run concurrently;
 *  - quota_first: a follow-up for a turn this instance did not charge —
 *                 either another instance's legitimate loop (costs ~0.5 s
 *                 once) or a forged turnId (costs nothing upstream).
 */
export function gateBeforeDispatch(args: {
  loopIndex: number;
  overQuota: boolean;
  turnChargedHere: boolean;
}): DispatchGate {
  if (args.loopIndex > 0 && args.turnChargedHere) return 'fast_path';
  if (args.overQuota) return 'reject';
  if (args.loopIndex > 0) return 'quota_first';
  return 'fast_path';
}

export type QuotaRejectReason =
  | 'user_quota'
  | 'daily_cap'
  | 'token_budget'
  | 'turn_follow_up_cap';

/** Until when a rejection of [reason] keeps the uid marked over quota. */
export function overQuotaUntilFor(
  reason: QuotaRejectReason,
  args: { now: number; windowEndMs?: number; midnightMs?: number; turnWindowMs?: number },
): number {
  switch (reason) {
    case 'user_quota':
      return args.windowEndMs ?? args.now;
    case 'daily_cap':
    case 'token_budget':
      return args.midnightMs ?? args.now;
    case 'turn_follow_up_cap':
      // Only this turn is capped; a new turn is fine. Mark for the turn
      // window so the same turnId cannot keep dispatching.
      return args.now + (args.turnWindowMs ?? 0);
  }
}

/**
 * Audit H10 — per-uid quotas are replenishable by minting throwaway
 * password accounts. When [require] is on (Remote Config), password
 * accounts must have a verified email; social providers verify on their
 * own. Returns a rejection message or null.
 */
export function verifiedAccountRejection(args: {
  signInProvider: string | undefined;
  emailVerified: boolean | undefined;
  require: boolean;
}): string | null {
  if (args.signInProvider === 'anonymous') {
    return 'Sign in with an account to use Coach AI.';
  }
  if (!args.require) return null;
  if (args.signInProvider === 'password' && args.emailVerified !== true) {
    return 'Verify your email address to use Coach AI.';
  }
  return null;
}
