import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { getRemoteConfig, ServerTemplate } from "firebase-admin/remote-config";

import { openAiApiKey } from "./secrets";
import {
  SPEECH_MODEL,
  SPEECH_RATE_LIMIT_PER_HOUR,
  resolveSpeechVoice,
  validateSpeechText,
} from "./speech_rules";

// TTS proxy for Voice Mode (OpenAI TTS, Level 1 — plan of 2026-08-07).
//
// The client sends one sanitized Coach reply (or a sentence slice of one)
// and receives mp3 bytes, base64-encoded inside the callable JSON envelope.
// The API key lives only in Secret Manager; the voice is pinned server-side
// via Remote Config so taste changes never need an app release. Failures are
// non-events for the user: the client degrades to the on-device system
// voice and the conversation continues.

const OPENAI_SPEECH_URL = "https://api.openai.com/v1/audio/speech";

const RC_DEFAULTS = {
  ai_speech_enabled: true,
  ai_speech_voice: "coral",
};
const RC_TTL_MS = 5 * 60 * 1000;

let rcTemplate: ServerTemplate | undefined;
let rcLoadedAtMs = 0;

async function speechConfig(): Promise<{ enabled: boolean; voice: string }> {
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
/// versa). Same transaction shape as aiChat's enforceRateLimit.
async function enforceSpeechRateLimit(uid: string): Promise<void> {
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

async function recordSpeechUsage(uid: string, chars: number): Promise<void> {
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

interface AiSpeechData {
  text?: unknown;
}

export const aiSpeech = onCall(
  {
    secrets: [openAiApiKey],
    region: "us-central1",
    timeoutSeconds: 30,
    memory: "256MiB",
    maxInstances: 10,
    // Warm instance: TTS sits on the spoken-turn critical path too.
    minInstances: 1,
  },
  async (request: CallableRequest<AiSpeechData>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    // Same spend-control stance as aiChat: anonymous uids are free to mint,
    // so per-uid quotas don't bound cost for them.
    const signInProvider = (request.auth.token as Record<string, any>)?.firebase
      ?.sign_in_provider;
    if (signInProvider === "anonymous") {
      throw new HttpsError(
        "permission-denied",
        "Sign in with an account to use Coach AI.",
      );
    }
    const uid = request.auth.uid;

    const validated = validateSpeechText(request.data?.text);
    if (!validated.ok) {
      throw new HttpsError("invalid-argument", validated.reason);
    }
    const text = validated.text;

    const { enabled, voice } = await speechConfig();
    if (!enabled) {
      // Kill switch: the client falls back to the on-device voice.
      throw new HttpsError("failed-precondition", "Speech synthesis is disabled.");
    }

    await enforceSpeechRateLimit(uid);

    let response: Response;
    try {
      response = await fetch(OPENAI_SPEECH_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openAiApiKey.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: SPEECH_MODEL,
          voice,
          input: text,
          response_format: "mp3",
        }),
        signal: AbortSignal.timeout(25_000),
      });
    } catch (error) {
      logger.error("OpenAI speech request failed", { uid, error: `${error}` });
      throw new HttpsError("unavailable", "Speech service unreachable.");
    }

    if (response.status === 429) {
      logger.warn("OpenAI speech rate limited", { uid });
      throw new HttpsError("resource-exhausted", "Speech service is busy.");
    }
    if (!response.ok) {
      const body = await response.text().catch(() => "");
      logger.error("OpenAI speech non-200", {
        uid,
        status: response.status,
        body: body.slice(0, 500),
      });
      throw new HttpsError(
        response.status >= 500 ? "unavailable" : "internal",
        "Speech request failed.",
      );
    }

    const audio = Buffer.from(await response.arrayBuffer());
    if (audio.length === 0) {
      logger.error("OpenAI speech empty audio", { uid });
      throw new HttpsError("internal", "Speech returned no audio.");
    }

    logger.info("aiSpeech ok", { uid, voice, chars: text.length, bytes: audio.length });
    await recordSpeechUsage(uid, text.length);
    return { audioB64: audio.toString("base64"), mime: "audio/mpeg" };
  },
);
