import { onRequest, HttpsError } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { getAuth } from "firebase-admin/auth";
import { Readable } from "node:stream";

import { openAiApiKey } from "./secrets";
import {
  SPEECH_MODEL,
  bearerTokenFrom,
  validateSpeechText,
} from "./speech_rules";
import {
  enforceSpeechRateLimit,
  recordSpeechUsage,
  speechConfig,
} from "./speech_shared";

// Streaming TTS proxy for Voice Mode (latency batch 2, 2026-08-08).
//
// Unlike the aiSpeech callable (which buffers the whole clip into a base64
// JSON envelope), this endpoint pipes OpenAI's mp3 bytes through AS THEY
// ARRIVE, so the client's player can start speaking before synthesis
// finishes. POST with the text in the JSON body — reply text must never
// appear in a URL (request paths land in Cloud Run logs).
//
// Production-hardened after the spike gate passed on device: shares the
// hourly quota pool, Remote Config voice pin and kill switch, and usage
// telemetry with the callable (speech_shared.ts), and carries the warm
// instance for the spoken-turn critical path.

const OPENAI_SPEECH_URL = "https://api.openai.com/v1/audio/speech";

export const aiSpeechStream = onRequest(
  {
    secrets: [openAiApiKey],
    region: "us-central1",
    timeoutSeconds: 60,
    memory: "256MiB",
    maxInstances: 10,
    // The warm instance moved here from aiSpeech (Phase 1): this is the
    // spoken-turn critical path now, and we only pay for one.
    minInstances: 1,
  },
  async (req, res) => {
    if (req.method !== "POST") {
      res.status(405).json({ error: "POST only." });
      return;
    }

    const tStart = Date.now();

    const token = bearerTokenFrom(req.headers.authorization);
    if (token === null) {
      res.status(401).json({ error: "Missing bearer token." });
      return;
    }

    let uid: string;
    try {
      const decoded = await getAuth().verifyIdToken(token);
      // Same spend-control stance as the callable: anonymous uids are free
      // to mint, so per-uid quotas don't bound cost for them.
      const provider = (decoded as Record<string, any>)?.firebase?.sign_in_provider;
      if (provider === "anonymous") {
        res.status(403).json({ error: "Sign in with an account to use Coach AI." });
        return;
      }
      uid = decoded.uid;
    } catch (error) {
      logger.warn("aiSpeechStream token rejected", { error: `${error}` });
      res.status(401).json({ error: "Invalid token." });
      return;
    }

    const tAuth = Date.now();

    const validated = validateSpeechText(req.body?.text);
    if (!validated.ok) {
      res.status(400).json({ error: validated.reason });
      return;
    }
    const text = validated.text;

    const { enabled, voice } = await speechConfig();
    if (!enabled) {
      // Kill switch: the client falls back to the on-device voice.
      res.status(503).json({ error: "Speech synthesis is disabled." });
      return;
    }
    const tConfig = Date.now();

    // Tap-to-interrupt closes the client connection; abort the upstream
    // OpenAI request instead of synthesizing to the end for nobody.
    const upstreamAbort = new AbortController();
    res.on("close", () => upstreamAbort.abort());

    // The quota transaction (~0.5s of Firestore, 2026-08-19 ledgers) runs
    // CONCURRENTLY with the OpenAI connect instead of in front of it. An
    // over-quota caller pays OpenAI for one aborted synthesis — that only
    // happens at the 91st request of the hour, and latency is paid by
    // every legitimate turn.
    const quotaPromise = enforceSpeechRateLimit(uid);
    const fetchPromise = fetch(OPENAI_SPEECH_URL, {
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
      signal: upstreamAbort.signal,
    });

    try {
      await quotaPromise;
    } catch (error) {
      upstreamAbort.abort();
      fetchPromise.catch(() => {});
      if (error instanceof HttpsError && error.code === "resource-exhausted") {
        res.status(429).json({ error: "Speech request limit reached." });
        return;
      }
      logger.error("aiSpeechStream quota check failed", { uid, error: `${error}` });
      res.status(500).json({ error: "Quota check failed." });
      return;
    }
    const tQuota = Date.now();

    let response: Response;
    try {
      response = await fetchPromise;
    } catch (error) {
      if (upstreamAbort.signal.aborted) return; // client hung up — not an error
      logger.error("aiSpeechStream OpenAI request failed", { uid, error: `${error}` });
      res.status(503).json({ error: "Speech service unreachable." });
      return;
    }

    if (!response.ok || response.body === null) {
      const body = await response.text().catch(() => "");
      logger.error("aiSpeechStream OpenAI non-200", {
        uid,
        status: response.status,
        body: body.slice(0, 500),
      });
      res
        .status(response.status === 429 ? 429 : 502)
        .json({ error: "Speech request failed." });
      return;
    }

    // Stage ledger (latency batch 3): read next to the client's
    // [voice-timing] headClip — client total minus this function's total
    // ≈ phone↔server network, which decides the region question. Since
    // batch 4 the quota and OpenAI legs OVERLAP (both measured from
    // tConfig); totalToFirstPipeMs stays the honest wall-clock sum.
    const tOpenAi = Date.now();
    logger.info("aiSpeechStream stages", {
      uid,
      authMs: tAuth - tStart,
      configMs: tConfig - tAuth,
      quotaMs: tQuota - tConfig,
      openaiHeadersMs: tOpenAi - tConfig,
      totalToFirstPipeMs: tOpenAi - tStart,
    });

    res.status(200);
    res.setHeader("Content-Type", "audio/mpeg");
    res.setHeader("Cache-Control", "no-store");

    const started = Date.now();
    const upstream = Readable.fromWeb(response.body as any);
    upstream.pipe(res);
    upstream.on("error", (error) => {
      // Mid-stream failure: headers are gone, so just end the response —
      // the client's player treats a short stream as a failed clip and the
      // resilient adapter falls back.
      if (!upstreamAbort.signal.aborted) {
        logger.error("aiSpeechStream upstream error mid-pipe", {
          uid,
          error: `${error}`,
        });
      }
      res.end();
    });
    upstream.on("end", () => {
      logger.info("aiSpeechStream ok", {
        uid,
        voice,
        chars: text.length,
        pipeMs: Date.now() - started,
      });
      void recordSpeechUsage(uid, text.length);
    });
  },
);
