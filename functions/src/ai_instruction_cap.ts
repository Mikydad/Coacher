/**
 * Daily instruction cap — pure logic (no firebase imports; unit-tested).
 *
 * AI chat fix plan Phase 0.1 (decision D8, 2026-09-26). Before this module
 * the cap read from `tier_limits_v1.freeAiInstructionsPerDay` applied to
 * EVERY uid (Pro included) and counted EVERY charged turn (questions
 * included) — see documentation/AI_CHAT_AUDIT_REVIEW_2026-09-26.md §2.1 #1.
 *
 * Fail-safe rules (full "server classifies actionable" arrives with
 * monetization):
 *  - the cap applies only when the account is KNOWN to be free: the
 *    entitlement doc was read and is not active. An unreadable doc means
 *    "unknown" → no cap (never punish a paying user for a Firestore blip);
 *  - only tool-bearing first rounds count as instructions. Answer-only
 *    turns (the streaming endpoints, tool-less calls) and agent-loop
 *    follow-ups (loopIndex > 0) never count.
 */

/** Shape of `users/{uid}/entitlements/pro` (written by the RevenueCat
 *  webhook; owner-read, client-write denied). */
export interface ProEntitlementData {
  active?: unknown;
  expiresAtMs?: unknown;
}

/** True when the entitlement doc says Pro and it has not expired. Mirrors
 *  the circles cap (`maxCirclesFor`). */
export function proEntitlementActive(
  data: ProEntitlementData | undefined,
  now: number = Date.now(),
): boolean {
  if (data === undefined) return false;
  const active = data.active === true;
  const expiresAtMs = data.expiresAtMs;
  const unexpired = typeof expiresAtMs !== "number" || expiresAtMs > now;
  return active && unexpired;
}

/** What the caller learned about the account's tier. `unknown` = the
 *  entitlement read failed. */
export type TierKnowledge = "free" | "pro" | "unknown";

export function tierFromEntitlement(
  read: { ok: true; data: ProEntitlementData | undefined } | { ok: false },
  now: number = Date.now(),
): TierKnowledge {
  if (!read.ok) return "unknown";
  return proEntitlementActive(read.data, now) ? "pro" : "free";
}

/** The cap to enforce for this account, or undefined for "no cap". */
export function instructionCapFor(args: {
  configuredCap: number;
  tier: TierKnowledge;
}): number | undefined {
  if (args.tier !== "free") return undefined;
  if (!Number.isFinite(args.configuredCap) || args.configuredCap <= 0) return undefined;
  return Math.floor(args.configuredCap);
}

/** Whether this request is an "instruction" for the daily cap: a first
 *  round that carries tools. Everything else is a question or a follow-up. */
export function countsAsInstruction(args: {
  hasTools: boolean;
  loopIndex: number;
}): boolean {
  return args.hasTools && args.loopIndex === 0;
}
