import { HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { getRemoteConfig, ServerTemplate } from "firebase-admin/remote-config";

import {
  SPEECH_MAX_CLIPS_PER_TURN,
  SPEECH_RATE_LIMIT_PER_HOUR,
  resolveSpeechVoice,
} from "./speech_rules";

// Shared IO helpers for the two TTS transports (speech.ts callable,
// speech_stream.ts streaming endpoint). One Remote Config surface, ONE
// hourly quota pool — a voice turn costs the same no matter which wire
// carried it, so the transports must never have separate budgets.

const RC_DEFAULTS = {
  ai_speech_enabled: true,
  ai_speech_voice: "coral",
};
const RC_TTL_MS = 5 * 60 * 1000;

let rcTemplate: ServerTemplate | undefined;
let rcLoadedAtMs = 0;
let rcFailedAtMs = 0;

export async function speechConfig(): Promise<{
  enabled: boolean;
  voice: string;
}> {
  const now = Date.now();
  const defaults = {
    enabled: RC_DEFAULTS.ai_speech_enabled,
    voice: resolveSpeechVoice(RC_DEFAULTS.ai_speech_voice),
  };
  // Failure caching (2026-08-19 stage ledgers) applies in BOTH states: a
  // failed refresh must not be retried on every call (~100-250ms tax), and
  // — critically — an RC outage must serve the LAST-KNOWN template, never
  // the compiled defaults: defaults say enabled=true, so falling back to
  // them would silently revive a kill-switched feature mid-outage.
  const stale = rcTemplate === undefined || now - rcLoadedAtMs > RC_TTL_MS;
  const inFailureCooldown = now - rcFailedAtMs < RC_TTL_MS;
  if (stale && !inFailureCooldown) {
    try {
      rcTemplate = await getRemoteConfig().getServerTemplate({
        defaultConfig: RC_DEFAULTS,
      });
      rcLoadedAtMs = now;
    } catch (error) {
      rcFailedAtMs = now;
      logger.warn("Remote Config refresh failed; serving last-known speech config", {
        error: `${error}`,
      });
    }
  }
  if (rcTemplate === undefined) return defaults;
  try {
    const config = rcTemplate.evaluate();
    return {
      enabled: config.getBoolean("ai_speech_enabled"),
      voice: resolveSpeechVoice(config.getString("ai_speech_voice")),
    };
  } catch (error) {
    logger.warn("Remote Config evaluate failed; using default speech config", {
      error: `${error}`,
    });
    return defaults;
  }
}

// ── Over-quota short-circuit ─────────────────────────────────────────────────
// The quota transaction runs CONCURRENTLY with the OpenAI call on the
// streaming path (latency win), which means a 429'd request has already
// paid for one synthesis. This per-instance marker stops the bleeding: once
// a uid is known to be over quota, callers must not fire OpenAI at all
// until the sliding window can have rolled. Best-effort by design (one
// wasted call per instance per window, bounded by maxInstances).
const speechOverQuotaUntilByUid = new Map<string, number>();

export function speechQuotaExhaustedUntil(uid: string): number | undefined {
  const until = speechOverQuotaUntilByUid.get(uid);
  if (until !== undefined && Date.now() < until) return until;
  speechOverQuotaUntilByUid.delete(uid);
  return undefined;
}

function markSpeechOverQuota(uid: string, untilMs: number): void {
  if (speechOverQuotaUntilByUid.size > 1000) {
    const now = Date.now();
    for (const [key, until] of speechOverQuotaUntilByUid) {
      if (until <= now) speechOverQuotaUntilByUid.delete(key);
    }
  }
  speechOverQuotaUntilByUid.set(uid, untilMs);
}

/// Sliding-hour quota on the shared per-user aiUsage doc, in speech-scoped
/// fields so a voice conversation can never eat the chat quota (or vice
/// versa). Counted per spoken TURN: clips sharing [turnId] consume one
/// quota unit total (sentence pipelining synthesizes one clip per
/// sentence), bounded by SPEECH_MAX_CLIPS_PER_TURN. Same transaction shape
/// as aiChat's enforceRateLimit. Throws HttpsError(resource-exhausted) —
/// the HTTP endpoint maps it to 429.
export async function enforceSpeechRateLimit(
  uid: string,
  turnId?: string,
): Promise<void> {
  const db = getFirestore();
  const ref = db.collection("aiUsage").doc(uid);
  const now = Date.now();
  const windowMs = 60 * 60 * 1000;

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    const windowStartMs: number =
      data?.speechWindowStart instanceof Timestamp
        ? data.speechWindowStart.toMillis()
        : 0;
    const count: number =
      typeof data?.speechCount === "number" ? data.speechCount : 0;

    // Follow-up clip of an already-charged spoken reply: free, but the
    // clip ladder is bounded so a stuck client can't loop one turn forever.
    if (
      turnId !== undefined &&
      turnId === data?.lastSpeechTurnId &&
      now - windowStartMs < windowMs
    ) {
      const clips: number =
        typeof data?.speechTurnClips === "number" ? data.speechTurnClips : 0;
      if (clips >= SPEECH_MAX_CLIPS_PER_TURN) {
        throw new HttpsError(
          "resource-exhausted",
          "Speech clip limit reached for this reply.",
        );
      }
      tx.set(ref, { speechTurnClips: clips + 1 }, { merge: true });
      return;
    }

    const turnFields = {
      lastSpeechTurnId: turnId ?? null,
      speechTurnClips: 1,
    };
    if (now - windowStartMs >= windowMs) {
      tx.set(
        ref,
        {
          speechWindowStart: Timestamp.fromMillis(now),
          speechCount: 1,
          ...turnFields,
        },
        { merge: true },
      );
      return;
    }
    if (count >= SPEECH_RATE_LIMIT_PER_HOUR) {
      // Remember when the window can roll so subsequent requests are
      // rejected BEFORE an OpenAI call is fired (see marker above).
      markSpeechOverQuota(uid, windowStartMs + windowMs);
      throw new HttpsError(
        "resource-exhausted",
        "Speech request limit reached. Try again later.",
      );
    }
    tx.set(ref, { speechCount: count + 1, ...turnFields }, { merge: true });
  });
}

export async function recordSpeechUsage(
  uid: string,
  chars: number,
): Promise<void> {
  try {
    await getFirestore()
      .collection("aiUsage")
      .doc(uid)
      .set(
        {
          byPurpose: {
            speak: {
              count: FieldValue.increment(1),
              chars: FieldValue.increment(chars),
            },
          },
        },
        { merge: true },
      );
  } catch (error) {
    // Telemetry must never fail a successful synthesis.
    logger.warn("speech telemetry write failed", { uid, error: `${error}` });
  }
}
