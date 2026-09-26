/**
 * OpenAI Chat Completions request shaping per model family — pure logic,
 * unit-tested (AI chat fix plan Phase 5.1, review §2 #1).
 *
 * The proxy used to send `max_tokens` and a pinned `temperature` to every
 * model, which is exactly what the gpt-5.x / gpt-6 families reject: they
 * take `max_completion_tokens`, accept sampling parameters only when
 * `reasoning_effort` is "none", and (gpt-5.4+, gpt-6 Sol/Luna) support
 * function calling on Chat Completions only with `reasoning_effort: "none"`.
 * gpt-6 Astra has no "none" at all (and no Chat Completions tool calling),
 * so it is not a valid Coach model here. Sources: OpenAI model guidance and
 * model pages, fetched 2026-09-26.
 */

export type ModelFamily = "legacy" | "reasoning";

/** gpt-4o* and gpt-4.1* take the classic parameters; everything newer is
 *  a reasoning-family model. */
export function modelFamily(model: string): ModelFamily {
  const m = model.toLowerCase();
  if (m.startsWith("gpt-4o") || m.startsWith("gpt-4.1")) return "legacy";
  return "reasoning";
}

/** The reasoning effort a Coach turn should request for [model], or null
 *  when the model takes none of that parameter. The Coach wants no
 *  reasoning tokens (latency, cost) and NEEDS "none" for tool calling on
 *  the current generation; the original gpt-5 family knows only
 *  "minimal". */
export function reasoningEffortFor(model: string): "none" | "minimal" | null {
  const m = model.toLowerCase();
  if (modelFamily(m) === "legacy") return null;
  if (/^gpt-5(-mini|-nano)?$/.test(m)) return "minimal";
  return "none";
}

/** True when the model can be used by the Coach agent path at all. */
export function supportsChatToolCalling(model: string): boolean {
  const m = model.toLowerCase();
  if (m.startsWith("gpt-6-astra")) return false;
  if (m.startsWith("o1") || m.startsWith("o3") || m.startsWith("o4")) return false;
  return true;
}

export interface ChatBodyArgs {
  model: string;
  messages: unknown[];
  maxTokens: number;
  /** The route's pinned temperature; dropped where the model rejects it. */
  temperature?: number;
  tools?: unknown[];
  stream?: boolean;
  /** Tool-less callers force a JSON object body (legacy schema mode). */
  jsonMode?: boolean;
}

/** The request body for one Chat Completions call, shaped for the model. */
export function buildChatBody(args: ChatBodyArgs): Record<string, unknown> {
  const family = modelFamily(args.model);
  const effort = reasoningEffortFor(args.model);
  const body: Record<string, unknown> = {
    model: args.model,
    messages: args.messages,
  };
  if (family === "legacy") {
    body.max_tokens = args.maxTokens;
    if (args.temperature !== undefined) body.temperature = args.temperature;
  } else {
    body.max_completion_tokens = args.maxTokens;
    if (effort !== null) body.reasoning_effort = effort;
    // Sampling parameters are accepted only with reasoning_effort "none".
    if (effort === "none" && args.temperature !== undefined) {
      body.temperature = args.temperature;
    }
  }
  if (args.tools !== undefined) {
    body.tools = args.tools;
    body.tool_choice = "auto";
  } else if (args.jsonMode) {
    body.response_format = { type: "json_object" };
  }
  if (args.stream) {
    body.stream = true;
    body.stream_options = { include_usage: true };
  }
  return body;
}
