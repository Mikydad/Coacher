import { onCall, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { getRemoteConfig, ServerTemplate } from "firebase-admin/remote-config";

import { parseRouteOverrides, resolveRoute, utcDayKey } from "./ai_routing";
import { openAiApiKey } from "./secrets";

initializeApp();

// Accountability Stakes (PRD/Accountability_feature/prd-accountability-stakes.md).
// Outcome engine is pure + unit-tested (src/stakes/*.test.ts); these are the
// thin IO shells around it.
export {
  stakeCreateChallenge,
  stakeCancelDraft,
  stakeAcceptChallenge,
  stakeDeclineChallenge,
  stakeApplyVeto,
  stakeConfirmOutcome,
  stakeCastVote,
  stakeReportScreenshot,
  stakeReportPhoto,
  stakeRemovePhoto,
} from "./stakes/callables";
export { grantPoints, pointsSignupBonus } from "./stakes/ledger";
export { stakeSweep } from "./stakes/sweep";
export { intentionSweep } from "./intentions/sweep";
export { morningBrief } from "./intentions/morning_brief";
export { devRunSweep } from "./stakes/dev";
export { stakeEvidenceArrived, stakeDisbursementReceipt } from "./stakes/triggers";
export { stakePhotoUploaded } from "./stakes/nsfw_screen";
export { stakeAccountPurge } from "./stakes/account_purge";
export { aiSpeech } from "./speech";
export { aiSpeechStream } from "./speech_stream";

// The model comes from the purpose routing table (ai_routing.ts) — pinned
// server-side per purpose; clients cannot request a different one.
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

function clampMaxTokens(raw: unknown, cap: number = MAX_TOKENS_CAP): number {
  const value = typeof raw === "number" && Number.isFinite(raw) ? Math.floor(raw) : cap;
  return Math.min(Math.max(value, 1), cap);
}

// ─── Purpose routing config (Remote Config server template) ─────────────────
//
// Config can DEGRADE the routing table (kill a purpose, swap a model) but
// never break the proxy: any Remote Config failure falls back to the
// compile-time defaults in ai_routing.ts.

const RC_DEFAULTS = {
  ai_purpose_routes: "{}",
  ai_system_daily_budget: 20,
};
const RC_TTL_MS = 5 * 60 * 1000;

let rcTemplate: ServerTemplate | undefined;
let rcLoadedAtMs = 0;

async function aiServerConfig(): Promise<{
  routesJson: string;
  systemDailyBudget: number;
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
    const budget = config.getNumber("ai_system_daily_budget");
    return {
      routesJson: config.getString("ai_purpose_routes"),
      systemDailyBudget: budget > 0 ? budget : RC_DEFAULTS.ai_system_daily_budget,
    };
  } catch (error) {
    logger.warn("Remote Config unavailable; using default AI routes", {
      error: `${error}`,
    });
    return {
      routesJson: RC_DEFAULTS.ai_purpose_routes,
      systemDailyBudget: RC_DEFAULTS.ai_system_daily_budget,
    };
  }
}

/// Per-user daily budget for SYSTEM purposes (extraction, parsing, nudge
/// phrasing) — separate from the user's hourly chat quota so background
/// work can never eat the quota the user sees. UTC-day window on the same
/// aiUsage doc.
async function enforceSystemBudget(uid: string, dailyBudget: number): Promise<void> {
  const db = getFirestore();
  const ref = db.collection("aiUsage").doc(uid);
  const dayKey = utcDayKey(Date.now());

  await db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data();
    const currentKey = typeof data?.systemDayKey === "string" ? data.systemDayKey : "";
    const count =
      currentKey === dayKey && typeof data?.systemCount === "number" ? data.systemCount : 0;
    if (count >= dailyBudget) {
      // Clients treat this as silent-skip: deterministic fallbacks run and
      // the user never sees a quota error for a call they didn't make.
      throw new HttpsError("resource-exhausted", "System AI budget exhausted for today.");
    }
    tx.set(ref, { systemDayKey: dayKey, systemCount: count + 1 }, { merge: true });
  });
}

/// Per-purpose usage telemetry (ships WITH Phase 2, not after). Firestore
/// field keys must be path-safe.
function telemetryKey(purpose: string): string {
  return purpose.replace(/[^a-zA-Z0-9_]/g, "_");
}

async function recordPurposeUsage(
  uid: string,
  purpose: string,
  totalTokens: number,
): Promise<void> {
  try {
    await getFirestore()
      .collection("aiUsage")
      .doc(uid)
      .set(
        {
          byPurpose: {
            [telemetryKey(purpose)]: {
              count: FieldValue.increment(1),
              tokens: FieldValue.increment(totalTokens > 0 ? totalTokens : 0),
            },
          },
        },
        { merge: true },
      );
  } catch (error) {
    // Telemetry must never fail a successful AI call.
    logger.warn("aiUsage telemetry write failed", { uid, purpose, error: `${error}` });
  }
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
    // One warm instance kills the 2-3s cold start on the conversational
    // path (latency batch 2026-08-07) — a few $/month, felt every turn.
    minInstances: 1,
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

    // Purpose routing: model / temperature / cap / quota class per purpose.
    const { routesJson, systemDailyBudget } = await aiServerConfig();
    const route = resolveRoute(purpose, parseRouteOverrides(routesJson));
    if (!route.enabled) {
      // Per-purpose kill switch. System callers fall back deterministically;
      // chat surfaces its normal degraded path.
      throw new HttpsError("failed-precondition", "This AI feature is disabled.");
    }
    const temperature = route.temperature ?? clampTemperature(request.data?.temperature);
    const maxTokens = clampMaxTokens(request.data?.maxTokens, route.maxTokens);

    if (route.quotaClass === "system") {
      await enforceSystemBudget(uid, systemDailyBudget);
    } else {
      await enforceRateLimit(uid, turnId, loopIndex);
    }

    let response: Response;
    try {
      response = await fetch(OPENAI_URL, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${openAiApiKey.value()}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          model: route.model,
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

    const totalTokens = json.usage?.total_tokens ?? -1;
    logger.info("aiChat ok", {
      uid,
      purpose,
      model: route.model,
      quotaClass: route.quotaClass,
      toolCallCount: toolCalls.length,
      totalTokens,
    });
    await recordPurposeUsage(uid, purpose, totalTokens);
    return { content, toolCalls };
  },
);
