import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp } from "firebase-admin/firestore";

initializeApp();

const openAiApiKey = defineSecret("OPENAI_API_KEY");

// Model is pinned server-side; clients cannot request a different one.
const MODEL = "gpt-4o-mini";
const OPENAI_URL = "https://api.openai.com/v1/chat/completions";

const MAX_TOKENS_CAP = 800;
const MAX_MESSAGES = 40;
const MAX_TOTAL_CHARS = 120_000;

// Per-user quota: sliding hourly window stored in Firestore.
// The `aiUsage` collection has no client rules, so only the Admin SDK
// (this function) can read or reset counters.
const RATE_LIMIT_PER_HOUR = 40;
const RATE_WINDOW_MS = 60 * 60 * 1000;

interface ChatMessage {
  role: string;
  content: string;
}

interface AiChatData {
  messages?: unknown;
  temperature?: unknown;
  maxTokens?: unknown;
  purpose?: unknown;
}

function validateMessages(raw: unknown): ChatMessage[] {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new HttpsError("invalid-argument", "messages must be a non-empty array.");
  }
  if (raw.length > MAX_MESSAGES) {
    throw new HttpsError("invalid-argument", "Too many messages.");
  }
  const allowedRoles = new Set(["system", "user", "assistant"]);
  let totalChars = 0;
  const messages: ChatMessage[] = [];
  for (const entry of raw) {
    if (typeof entry !== "object" || entry === null) {
      throw new HttpsError("invalid-argument", "Each message must be an object.");
    }
    const role = (entry as Record<string, unknown>).role;
    const content = (entry as Record<string, unknown>).content;
    if (typeof role !== "string" || !allowedRoles.has(role)) {
      throw new HttpsError("invalid-argument", "Invalid message role.");
    }
    if (typeof content !== "string" || content.length === 0) {
      throw new HttpsError("invalid-argument", "Message content must be a non-empty string.");
    }
    totalChars += content.length;
    messages.push({ role, content });
  }
  if (totalChars > MAX_TOTAL_CHARS) {
    throw new HttpsError("invalid-argument", "Prompt too large.");
  }
  return messages;
}

function clampTemperature(raw: unknown): number {
  const value = typeof raw === "number" && Number.isFinite(raw) ? raw : 0.2;
  return Math.min(Math.max(value, 0), 1);
}

function clampMaxTokens(raw: unknown): number {
  const value =
    typeof raw === "number" && Number.isFinite(raw) ? Math.floor(raw) : MAX_TOKENS_CAP;
  return Math.min(Math.max(value, 1), MAX_TOKENS_CAP);
}

async function enforceRateLimit(uid: string): Promise<void> {
  const db = getFirestore();
  const ref = db.collection("aiUsage").doc(uid);
  const now = Date.now();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    const windowStartMs: number =
      data?.windowStart instanceof Timestamp ? data.windowStart.toMillis() : 0;
    const count: number = typeof data?.count === "number" ? data.count : 0;

    if (now - windowStartMs >= RATE_WINDOW_MS) {
      tx.set(ref, {
        windowStart: Timestamp.fromMillis(now),
        count: 1,
        totalCount: (typeof data?.totalCount === "number" ? data.totalCount : 0) + 1,
      });
      return;
    }
    if (count >= RATE_LIMIT_PER_HOUR) {
      throw new HttpsError(
        "resource-exhausted",
        "AI request limit reached. Try again later.",
      );
    }
    tx.update(ref, { count: count + 1, totalCount: (data?.totalCount ?? 0) + 1 });
  });
}

export const aiChat = onCall(
  {
    secrets: [openAiApiKey],
    region: "us-central1",
    timeoutSeconds: 60,
    memory: "256MiB",
    maxInstances: 10,
  },
  async (request: CallableRequest<AiChatData>) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const uid = request.auth.uid;

    const messages = validateMessages(request.data?.messages);
    const temperature = clampTemperature(request.data?.temperature);
    const maxTokens = clampMaxTokens(request.data?.maxTokens);
    const purpose =
      typeof request.data?.purpose === "string" ? request.data.purpose.slice(0, 64) : "unknown";

    await enforceRateLimit(uid);

    let response: Response;
    try {
      response = await fetch(OPENAI_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openAiApiKey.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: MODEL,
          temperature,
          max_tokens: maxTokens,
          response_format: { type: "json_object" },
          messages,
        }),
        signal: AbortSignal.timeout(45_000),
      });
    } catch (error) {
      logger.error("OpenAI request failed", { uid, purpose, error: `${error}` });
      throw new HttpsError("unavailable", "AI service unreachable. Try again.");
    }

    if (response.status === 429) {
      logger.warn("OpenAI rate limited", { uid, purpose });
      throw new HttpsError("resource-exhausted", "AI service is busy. Try again shortly.");
    }
    if (!response.ok) {
      const body = await response.text().catch(() => "");
      logger.error("OpenAI non-200", { uid, purpose, status: response.status, body: body.slice(0, 500) });
      throw new HttpsError(
        response.status >= 500 ? "unavailable" : "internal",
        "AI request failed.",
      );
    }

    const json = (await response.json()) as {
      choices?: Array<{ message?: { content?: string } }>;
      usage?: { total_tokens?: number };
    };
    const content = json.choices?.[0]?.message?.content;
    if (typeof content !== "string" || content.length === 0) {
      logger.error("OpenAI empty content", { uid, purpose });
      throw new HttpsError("internal", "AI returned an empty response.");
    }

    logger.info("aiChat ok", { uid, purpose, totalTokens: json.usage?.total_tokens ?? -1 });
    return { content };
  },
);
