import { HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { getRemoteConfig, ServerTemplate } from "firebase-admin/remote-config";

import {
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

export async function speechConfig(): Promise<{
  enabled: boolean;
  voice: string;
}> {
  const now = Date.now();
  try {
    if (rcTemplate === undefined || now - rcLoadedAtMs > RC_TTL_MS) {
      rcTemplate = await getRemoteConfig().getServerTemplate({
        defaultConfig: RC_DEFAULTS,
      });
      rcLoadedAtMs = now;
    }
    const config = rcTemplate.evaluate();
    return {
      enabled: config.getBoolean("ai_speech_enabled"),
      voice: resolveSpeechVoice(config.getString("ai_speech_voice")),
    };
  } catch (error) {
    logger.warn("Remote Config unavailable; using default speech config", {
      error: `${error}`,
    });
    return {
      enabled: RC_DEFAULTS.ai_speech_enabled,
      voice: resolveSpeechVoice(RC_DEFAULTS.ai_speech_voice),
    };
  }
}

/// Sliding-hour quota on the shared per-user aiUsage doc, in speech-scoped
/// fields so a voice conversation can never eat the chat quota (or vice
/// versa). Same transaction shape as aiChat's enforceRateLimit. Throws
/// HttpsError(resource-exhausted) — the HTTP endpoint maps it to 429.
export async function enforceSpeechRateLimit(uid: string): Promise<void> {
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

    if (now - windowStartMs >= windowMs) {
      tx.set(
        ref,
        { speechWindowStart: Timestamp.fromMillis(now), speechCount: 1 },
        { merge: true },
      );
      return;
    }
    if (count >= SPEECH_RATE_LIMIT_PER_HOUR) {
      throw new HttpsError(
        "resource-exhausted",
        "Speech request limit reached. Try again later.",
      );
    }
    tx.set(ref, { speechCount: count + 1 }, { merge: true });
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
