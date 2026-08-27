import { onCall, onRequest, HttpsError, CallableRequest } from "firebase-functions/v2/https";
import { logger } from "firebase-functions/v2";
import { initializeApp } from "firebase-admin/app";
import { getFirestore, Timestamp, FieldValue } from "firebase-admin/firestore";
import { getAuth } from "firebase-admin/auth";
import { getRemoteConfig, ServerTemplate } from "firebase-admin/remote-config";

import { parseRouteOverrides, resolveRoute, utcDayKey } from "./ai_routing";
import { openAiApiKey } from "./secrets";
import { bearerTokenFrom } from "./speech_rules";

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
  stakeSurrender,
  stakeConfirmOutcome,
  stakeCastVote,
  stakeReportScreenshot,
  stakeReportPhoto,
  stakeRemovePhoto,
} from "./stakes/callables";
// Circle invites (2026-08-26) — the first circle callables: server-held
// invite keys, the only door into private circles.
export { circleInvite, circleJoinWithInvite } from "./circles/callables";
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
let rcFailedAtMs = 0;

async function aiServerConfig(): Promise<{
  routesJson: string;
  systemDailyBudget: number;
}> {
  const now = Date.now();
  const defaults = {
    routesJson: RC_DEFAULTS.ai_purpose_routes,
    systemDailyBudget: RC_DEFAULTS.ai_system_daily_budget,
  };
  // Failure caching (2026-08-19 stage ledgers) applies in BOTH states: a
  // failed refresh must not be retried on every call (~100-250ms tax), and
  // — critically — an RC outage must serve the LAST-KNOWN template, never
  // the compiled defaults: defaults have every purpose enabled, so falling
  // back to them would silently revive a killed purpose mid-outage.
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
      logger.warn("Remote Config refresh failed; serving last-known AI routes", {
        error: `${error}`,
      });
    }
  }
  if (rcTemplate === undefined) return defaults;
  try {
    const config = rcTemplate.evaluate();
    const budget = config.getNumber("ai_system_daily_budget");
    return {
      routesJson: config.getString("ai_purpose_routes"),
      systemDailyBudget: budget > 0 ? budget : RC_DEFAULTS.ai_system_daily_budget,
    };
  } catch (error) {
    logger.warn("Remote Config evaluate failed; using default AI routes", {
      error: `${error}`,
    });
    return defaults;
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

// Per-instance over-quota marker: the interactive path fires the OpenAI
// call concurrently with the quota transaction (latency win), so a 429'd
// caller has already paid for one request. Once a uid is KNOWN to be over
// quota, subsequent calls are rejected before OpenAI fires, until the
// sliding window can have rolled (Tier-1 review fix).
const chatOverQuotaUntilByUid = new Map<string, number>();

function chatQuotaExhausted(uid: string): boolean {
  const until = chatOverQuotaUntilByUid.get(uid);
  if (until !== undefined && Date.now() < until) return true;
  chatOverQuotaUntilByUid.delete(uid);
  return false;
}

function markChatOverQuota(uid: string, untilMs: number): void {
  if (chatOverQuotaUntilByUid.size > 1000) {
    const now = Date.now();
    for (const [key, until] of chatOverQuotaUntilByUid) {
      if (until <= now) chatOverQuotaUntilByUid.delete(key);
    }
  }
  chatOverQuotaUntilByUid.set(uid, untilMs);
}

/// Sliding-hour quota counted per TURN, not per OpenAI call: follow-up calls
/// in the same agent loop (same turnId, loopIndex > 0, within the turn
/// window) do not consume quota — and are themselves counted and capped at
/// MAX_LOOP_INDEX per turn, so the free window cannot be farmed for
/// unmetered completions (Tier-1 review fix).
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

    // Free follow-up call inside an already-charged turn — bounded: the
    // agent loop legitimately makes at most MAX_LOOP_INDEX follow-ups, so
    // anything beyond that is quota farming, not an agent loop.
    if (
      loopIndex > 0 &&
      turnId !== undefined &&
      turnId === lastTurnId &&
      now - lastTurnAtMs < TURN_WINDOW_MS
    ) {
      const turnFollowUps: number =
        typeof data?.turnFollowUps === "number" ? data.turnFollowUps : 0;
      if (turnFollowUps >= MAX_LOOP_INDEX) {
        throw new HttpsError(
          "resource-exhausted",
          "AI request limit reached. Try again later.",
        );
      }
      tx.set(ref, { turnFollowUps: turnFollowUps + 1 }, { merge: true });
      return;
    }

    const totalCount = (typeof data?.totalCount === "number" ? data.totalCount : 0) + 1;
    const turnFields = {
      lastTurnId: turnId ?? null,
      lastTurnAt: Timestamp.fromMillis(now),
      turnFollowUps: 0,
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
      // Remember when the window can roll so subsequent requests are
      // rejected BEFORE the concurrent OpenAI leg fires.
      markChatOverQuota(uid, windowStartMs + RATE_WINDOW_MS);
      throw new HttpsError(
        "resource-exhausted",
        "AI request limit reached. Try again later.",
      );
    }
    tx.update(ref, { count: count + 1, totalCount, ...turnFields });
  });
}

/** Best-effort compensation when the upstream leg fails AFTER the turn was
 * charged (fix-wave Phase 3, AUDIT.md §8 H4): an OpenAI outage must not eat
 * the user's hourly quota — before this, every visible retry burned one of
 * the 40 turns while delivering nothing. The turn fields are deliberately
 * KEPT, so a client retry with the same turnId rides the free same-turn
 * follow-up window. Imprecision under concurrency is accepted (same stance
 * as markChatOverQuota). Follow-ups (loopIndex > 0) were never charged. */
async function refundChatTurn(uid: string, loopIndex: number): Promise<void> {
  if (loopIndex > 0) return;
  try {
    await getFirestore()
      .collection("aiUsage")
      .doc(uid)
      .set({ count: FieldValue.increment(-1) }, { merge: true });
  } catch (error) {
    logger.warn("refundChatTurn failed", { uid, error: `${error}` });
  }
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

    // Stage ledger (latency batch 3): read next to the client's
    // [ai-timing] round lines — round-call minus this total ≈ the
    // phone↔server network share, which decides the region question.
    const tStart = Date.now();

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
    const tConfig = Date.now();

    const quotaAbort = new AbortController();
    const doFetch = (): Promise<Response> =>
      fetch(OPENAI_URL, {
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
        signal: AbortSignal.any([quotaAbort.signal, AbortSignal.timeout(45_000)]),
      });

    let response: Response;
    let tQuota: number;
    if (route.quotaClass === "system") {
      // Background callers: latency is irrelevant and the budget's
      // silent-skip semantics must stay strict — check first, spend after.
      await enforceSystemBudget(uid, systemDailyBudget);
      tQuota = Date.now();
      try {
        response = await doFetch();
      } catch (error) {
        logger.error("OpenAI request failed", { uid, purpose, error: `${error}` });
        throw new HttpsError("unavailable", "AI service unreachable. Try again.");
      }
    } else {
      // Known-over-quota callers are rejected before OpenAI fires at all.
      if (chatQuotaExhausted(uid)) {
        throw new HttpsError(
          "resource-exhausted",
          "AI request limit reached. Try again later.",
        );
      }
      // Interactive path: the quota transaction (~0.5s of Firestore,
      // 2026-08-19 ledgers) runs CONCURRENTLY with the OpenAI call. An
      // over-quota caller pays for at most one aborted request per instance
      // per window (the marker above short-circuits the rest); the latency
      // win lands on every legitimate turn.
      const quotaPromise = enforceRateLimit(uid, turnId, loopIndex);
      const fetchPromise = doFetch();
      try {
        await quotaPromise;
      } catch (error) {
        quotaAbort.abort();
        fetchPromise.catch(() => {});
        throw error;
      }
      tQuota = Date.now();
      try {
        response = await fetchPromise;
      } catch (error) {
        logger.error("OpenAI request failed", { uid, purpose, error: `${error}` });
        if (route.quotaClass === "user") await refundChatTurn(uid, loopIndex);
        throw new HttpsError("unavailable", "AI service unreachable. Try again.");
      }
    }

    if (response.status === 429) {
      logger.warn("OpenAI rate limited", { uid, purpose });
      if (route.quotaClass === "user") await refundChatTurn(uid, loopIndex);
      throw new HttpsError("resource-exhausted", "AI service is busy. Try again shortly.");
    }
    if (!response.ok) {
      const body = await response.text().catch(() => "");
      logger.error("OpenAI non-200", { uid, purpose, status: response.status, body: body.slice(0, 500) });
      if (route.quotaClass === "user") await refundChatTurn(uid, loopIndex);
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
      if (route.quotaClass === "user") await refundChatTurn(uid, loopIndex);
      throw new HttpsError("internal", "AI returned an empty response.");
    }

    // Since batch 4 the quota and OpenAI legs OVERLAP on the user path
    // (both measured from tConfig); totalMs stays honest wall clock.
    const tOpenAi = Date.now();
    logger.info("aiChat stages", {
      uid,
      purpose,
      configMs: tConfig - tStart,
      quotaMs: tQuota - tConfig,
      openaiMs: tOpenAi - tConfig,
      totalMs: tOpenAi - tStart,
    });

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

// ─── aiChatStream (voice Level 2) ────────────────────────────────────────────
// Streaming twin of aiChat for CONVERSATIONAL voice turns only: no tools,
// purpose pinned to coach_agent_voice, text deltas as NDJSON lines
// {"d":"..."} followed by {"done":true}. Mutate-classified turns keep the
// full agent pipeline through the aiChat callable. onRequest because
// callables cannot stream; auth/quota mirror aiSpeechStream/aiChat.
export const aiChatStream = onRequest(
  {
    secrets: [openAiApiKey],
    region: "us-central1",
    timeoutSeconds: 120,
    memory: "256MiB",
    maxInstances: 10,
    // Voice Level 2 made this the spoken-turn critical path — the first
    // conversational turn after idle was paying its full cold start
    // (first-turn latency fix 2026-08-22). Same one-warm-instance trade as
    // aiChat and aiSpeechStream.
    minInstances: 1,
  },
  async (req, res) => {
    const tStart = Date.now();
    // Warmup ping from the client when Voice Mode opens: spins the
    // instance and warms the TLS path, no work done.
    if (req.method === "GET") {
      res.status(204).end();
      return;
    }
    if (req.method !== "POST") {
      res.status(405).json({ error: "POST only." });
      return;
    }
    const token = bearerTokenFrom(req.headers.authorization);
    if (!token) {
      res.status(401).json({ error: "Missing bearer token." });
      return;
    }
    let uid: string;
    try {
      const decoded = await getAuth().verifyIdToken(token);
      // Anonymous uids are free to mint — same spend stance as aiChat.
      if (decoded.firebase?.sign_in_provider === "anonymous") {
        res.status(403).json({ error: "Sign in with an account to use Coach AI." });
        return;
      }
      uid = decoded.uid;
    } catch {
      res.status(401).json({ error: "Invalid token." });
      return;
    }

    let messages: ChatMessage[];
    try {
      messages = validateMessages(req.body?.messages);
    } catch (error) {
      res.status(400).json({
        error: error instanceof HttpsError ? error.message : "Invalid messages.",
      });
      return;
    }

    const purpose = "coach_agent_voice";
    const { routesJson } = await aiServerConfig();
    const route = resolveRoute(purpose, parseRouteOverrides(routesJson));
    if (!route.enabled) {
      res.status(503).json({ error: "Purpose disabled." });
      return;
    }
    const tConfig = Date.now();

    // Known-over-quota callers never reach OpenAI (same marker as aiChat).
    if (chatQuotaExhausted(uid)) {
      res.status(429).json({ error: "AI request limit reached." });
      return;
    }

    const upstreamAbort = new AbortController();
    res.on("close", () => upstreamAbort.abort());

    // Quota transaction concurrent with the OpenAI connect (aiChat pattern;
    // the marker above bounds over-quota spend per instance per window).
    const quotaPromise = enforceRateLimit(uid, undefined, 0);
    const fetchPromise = fetch(OPENAI_URL, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${openAiApiKey.value()}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        model: route.model,
        messages,
        max_tokens: route.maxTokens,
        temperature: route.temperature ?? 0.6,
        stream: true,
      }),
      signal: upstreamAbort.signal,
    });

    try {
      await quotaPromise;
    } catch (error) {
      upstreamAbort.abort();
      fetchPromise.catch(() => {});
      if (error instanceof HttpsError && error.code === "resource-exhausted") {
        res.status(429).json({ error: "AI request limit reached." });
        return;
      }
      logger.error("aiChatStream quota check failed", { uid, error: `${error}` });
      res.status(500).json({ error: "Quota check failed." });
      return;
    }
    const tQuota = Date.now();

    let response: Response;
    try {
      response = await fetchPromise;
    } catch (error) {
      logger.error("aiChatStream OpenAI request failed", { uid, error: `${error}` });
      await refundChatTurn(uid, 0);
      res.status(502).json({ error: "AI service unreachable." });
      return;
    }
    if (response.status !== 200 || response.body == null) {
      const body = await response.text().catch(() => "");
      logger.error("aiChatStream OpenAI non-200", {
        uid, status: response.status, body: body.slice(0, 300),
      });
      await refundChatTurn(uid, 0);
      res.status(response.status === 429 ? 429 : 502).json({ error: "AI service error." });
      return;
    }

    logger.info("aiChatStream stages", {
      uid,
      configMs: tConfig - tStart,
      quotaMs: tQuota - tConfig,
      openaiHeadersMs: Date.now() - tConfig,
      totalToFirstPipeMs: Date.now() - tStart,
    });

    res.status(200);
    res.setHeader("Content-Type", "application/x-ndjson");
    res.setHeader("Cache-Control", "no-store");

    // Parse OpenAI SSE → NDJSON delta lines. Chars counted for telemetry.
    // Honest ending contract (fix-wave Phase 3, §8 H5/G18): the terminator
    // carries finish_reason, an upstream SSE error emits an {"e": …} line,
    // and a mid-pipe death emits one too when the socket still stands — a
    // truncated reply must never end indistinguishably from a complete one.
    let sseCarry = "";
    let chars = 0;
    let finishReason: string | null = null;
    let upstreamErrored = false;
    try {
      for await (const chunk of response.body as unknown as AsyncIterable<Uint8Array>) {
        sseCarry += Buffer.from(chunk).toString("utf8");
        const lines = sseCarry.split("\n");
        sseCarry = lines.pop() ?? "";
        for (const line of lines) {
          const trimmed = line.trim();
          if (!trimmed.startsWith("data:")) continue;
          const payload = trimmed.slice(5).trim();
          if (payload === "[DONE]") continue;
          try {
            const parsed = JSON.parse(payload);
            if (parsed?.error != null) {
              upstreamErrored = true;
              logger.error("aiChatStream upstream SSE error", {
                uid, error: JSON.stringify(parsed.error).slice(0, 300),
              });
              continue;
            }
            const choice = parsed?.choices?.[0];
            if (typeof choice?.finish_reason === "string") {
              finishReason = choice.finish_reason;
            }
            const delta: unknown = choice?.delta?.content;
            if (typeof delta === "string" && delta.length > 0) {
              chars += delta.length;
              res.write(`${JSON.stringify({ d: delta })}\n`);
            }
          } catch {
            // Partial/keep-alive SSE line — skip.
          }
        }
      }
      if (upstreamErrored) {
        res.write(`${JSON.stringify({ e: "upstream" })}\n`);
      } else {
        res.write(`${JSON.stringify({ done: true, finish: finishReason ?? "stop" })}\n`);
      }
    } catch (error) {
      // Client hung up or upstream died mid-stream. When our socket still
      // stands, say so — silence here used to present half a reply as done.
      logger.warn("aiChatStream pipe ended early", { uid, error: `${error}` });
      try {
        if (!res.writableEnded) res.write(`${JSON.stringify({ e: "upstream" })}\n`);
      } catch {
        // Socket already gone.
      }
    } finally {
      res.end();
    }
    logger.info("aiChatStream ok", { uid, chars, totalMs: Date.now() - tStart });
    await recordPurposeUsage(uid, purpose, -1);
  },
);
