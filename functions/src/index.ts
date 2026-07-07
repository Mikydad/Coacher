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
  content?: string | null;
  tool_calls?: unknown;
  tool_call_id?: string;
}

interface AiChatData {
  messages?: unknown;
  temperature?: unknown;
  maxTokens?: unknown;
  purpose?: unknown;
  tools?: unknown;
  turnId?: unknown;
  loopIndex?: unknown;
}

// Agent loop bounds: a "turn" is one user message; the client may make a few
// follow-up calls in the same turn to execute tool calls. Only the first call
// of a turn consumes quota.
const MAX_LOOP_INDEX = 3;
const TURN_WINDOW_MS = 3 * 60 * 1000;
const MAX_TOOLS = 8;

function validateMessages(raw: unknown): ChatMessage[] {
  if (!Array.isArray(raw) || raw.length === 0) {
    throw new HttpsError("invalid-argument", "messages must be a non-empty array.");
  }
  if (raw.length > MAX_MESSAGES) {
    throw new HttpsError("invalid-argument", "Too many messages.");
  }
  const allowedRoles = new Set(["system", "user", "assistant", "tool"]);
  let totalChars = 0;
  const messages: ChatMessage[] = [];
  for (const entry of raw) {
    if (typeof entry !== "object" || entry === null) {
      throw new HttpsError("invalid-argument", "Each message must be an object.");
    }
    const record = entry as Record<string, unknown>;
    const role = record.role;
    const content = record.content;
    if (typeof role !== "string" || !allowedRoles.has(role)) {
      throw new HttpsError("invalid-argument", "Invalid message role.");
    }
    const message: ChatMessage = { role };

    // Assistant messages in an agent loop may carry tool_calls with no content.
    const toolCalls = record.tool_calls;
    if (role === "assistant" && Array.isArray(toolCalls) && toolCalls.length > 0) {
      if (toolCalls.length > MAX_TOOLS) {
        throw new HttpsError("invalid-argument", "Too many tool calls.");
      }
      message.tool_calls = toolCalls;
      totalChars += JSON.stringify(toolCalls).length;
    }
    if (role === "tool") {
      const toolCallId = record.tool_call_id;
      if (typeof toolCallId !== "string" || toolCallId.length === 0) {
        throw new HttpsError("invalid-argument", "tool messages need tool_call_id.");
      }
      message.tool_call_id = toolCallId;
    }

    if (typeof content === "string" && content.length > 0) {
      message.content = content;
      totalChars += content.length;
    } else if (message.tool_calls === undefined) {
      throw new HttpsError("invalid-argument", "Message content must be a non-empty string.");
    }
    messages.push(message);
  }
  if (totalChars > MAX_TOTAL_CHARS) {
    throw new HttpsError("invalid-argument", "Prompt too large.");
  }
  return messages;
}

/// Shallow validation of OpenAI tool definitions supplied by the client.
function validateTools(raw: unknown): Record<string, unknown>[] | undefined {
  if (raw === undefined || raw === null) return undefined;
  if (!Array.isArray(raw) || raw.length === 0 || raw.length > MAX_TOOLS) {
    throw new HttpsError("invalid-argument", "Invalid tools array.");
  }
  for (const tool of raw) {
    if (typeof tool !== "object" || tool === null) {
      throw new HttpsError("invalid-argument", "Each tool must be an object.");
    }
    const t = tool as Record<string, unknown>;
    const fn = t.function as Record<string, unknown> | undefined;
    if (t.type !== "function" || typeof fn?.name !== "string") {
      throw new HttpsError("invalid-argument", "Tools must be function definitions.");
    }
  }
  if (JSON.stringify(raw).length > 20_000) {
    throw new HttpsError("invalid-argument", "Tools payload too large.");
  }
  return raw as Record<string, unknown>[];
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

/// Sliding-hour quota counted per TURN, not per OpenAI call: follow-up calls
/// in the same agent loop (same turnId, loopIndex > 0, within the turn
/// window) do not consume quota but are bounded by MAX_LOOP_INDEX.
async function enforceRateLimit(
  uid: string,
  turnId: string | undefined,
  loopIndex: number,
): Promise<void> {
  const db = getFirestore();
  const ref = db.collection("aiUsage").doc(uid);
  const now = Date.now();

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    const windowStartMs: number =
      data?.windowStart instanceof Timestamp ? data.windowStart.toMillis() : 0;
    const count: number = typeof data?.count === "number" ? data.count : 0;
    const lastTurnId: string | undefined =
      typeof data?.lastTurnId === "string" ? data.lastTurnId : undefined;
    const lastTurnAtMs: number =
      data?.lastTurnAt instanceof Timestamp ? data.lastTurnAt.toMillis() : 0;

    // Free follow-up call inside an already-charged turn.
    if (
      loopIndex > 0 &&
      turnId !== undefined &&
      turnId === lastTurnId &&
      now - lastTurnAtMs < TURN_WINDOW_MS
    ) {
      return;
    }

    const totalCount = (typeof data?.totalCount === "number" ? data.totalCount : 0) + 1;
    const turnFields = {
      lastTurnId: turnId ?? null,
      lastTurnAt: Timestamp.fromMillis(now),
    };

    if (now - windowStartMs >= RATE_WINDOW_MS) {
      tx.set(ref, {
        windowStart: Timestamp.fromMillis(now),
        count: 1,
        totalCount,
        ...turnFields,
      });
      return;
    }
    if (count >= RATE_LIMIT_PER_HOUR) {
      throw new HttpsError(
        "resource-exhausted",
        "AI request limit reached. Try again later.",
      );
    }
    tx.update(ref, { count: count + 1, totalCount, ...turnFields });
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
    // Guest (anonymous) accounts cannot call the paid AI proxy — creating
    // fresh anonymous uids is free, so per-uid quotas don't bound spend.
    // TODO: enable App Check enforcement (enforceAppCheck: true) once a
    // client version that attests has shipped.
    const signInProvider = (request.auth.token as Record<string, any>)
      ?.firebase?.sign_in_provider;
    if (signInProvider === "anonymous") {
      throw new HttpsError(
        "permission-denied",
        "Sign in with an account to use Coach AI.",
      );
    }
    const uid = request.auth.uid;

    const messages = validateMessages(request.data?.messages);
    const temperature = clampTemperature(request.data?.temperature);
    const maxTokens = clampMaxTokens(request.data?.maxTokens);
    const tools = validateTools(request.data?.tools);
    const purpose =
      typeof request.data?.purpose === "string" ? request.data.purpose.slice(0, 64) : "unknown";
    const turnId =
      typeof request.data?.turnId === "string" ? request.data.turnId.slice(0, 64) : undefined;
    const rawLoopIndex = request.data?.loopIndex;
    const loopIndex =
      typeof rawLoopIndex === "number" && Number.isInteger(rawLoopIndex) ? rawLoopIndex : 0;
    if (loopIndex < 0 || loopIndex > MAX_LOOP_INDEX) {
      throw new HttpsError("invalid-argument", "loopIndex out of range.");
    }

    await enforceRateLimit(uid, turnId, loopIndex);

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
          // Tool-calling turns return natural text or tool calls; only
          // legacy schema-mode callers force a JSON object body.
          ...(tools === undefined
            ? { response_format: { type: "json_object" } }
            : { tools, tool_choice: "auto" }),
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
      choices?: Array<{
        message?: {
          content?: string | null;
          tool_calls?: Array<{
            id?: string;
            function?: { name?: string; arguments?: string };
          }>;
        };
      }>;
      usage?: { total_tokens?: number };
    };
    const message = json.choices?.[0]?.message;
    const content = typeof message?.content === "string" ? message.content : null;
    const toolCalls = (message?.tool_calls ?? [])
      .filter((c) => typeof c.id === "string" && typeof c.function?.name === "string")
      .map((c) => ({
        id: c.id,
        name: c.function?.name,
        arguments: c.function?.arguments ?? "{}",
      }));

    if ((content === null || content.length === 0) && toolCalls.length === 0) {
      logger.error("OpenAI empty content", { uid, purpose });
      throw new HttpsError("internal", "AI returned an empty response.");
    }

    logger.info("aiChat ok", {
      uid,
      purpose,
      toolCallCount: toolCalls.length,
      totalTokens: json.usage?.total_tokens ?? -1,
    });
    return { content, toolCalls };
  },
);
