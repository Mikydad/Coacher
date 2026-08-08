import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";

import { openAiApiKey } from "./secrets";
import { SPEECH_MODEL, validateSpeechText } from "./speech_rules";
import {
  enforceSpeechRateLimit,
  recordSpeechUsage,
  speechConfig,
} from "./speech_shared";

// TTS proxy for Voice Mode (OpenAI TTS, Level 1 — plan of 2026-08-07).
//
// The client sends one sanitized Coach reply (or a sentence slice of one)
// and receives mp3 bytes, base64-encoded inside the callable JSON envelope.
// The API key lives only in Secret Manager; the voice is pinned server-side
// via Remote Config so taste changes never need an app release. Failures are
// non-events for the user: the client degrades to the on-device system
// voice and the conversation continues.

const OPENAI_SPEECH_URL = "https://api.openai.com/v1/audio/speech";

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
    // No warm instance here anymore: the streaming endpoint took over the
    // spoken-turn critical path (Phase 1, 2026-08-08) and carries the
    // minInstances budget. This callable stays as the buffered fallback
    // path for older builds and the _kStreamingTts=false A/B setting.
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
