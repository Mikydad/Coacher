#!/usr/bin/env node
/**
 * Coach model bake-off (AI chat fix plan Phase 5.2). Replays fixture
 * prompts — rendered the way the app renders them — through the SERVER's
 * own system prompt (lib/coach_prompts.js) and request shaping
 * (lib/ai_request.js) against candidate models, calling OpenAI directly.
 * Measures per model: tool-call validity, expectation pass rate, latency
 * p50/p95, tokens and cost. Never runs in CI; every call spends money.
 *
 *   cd functions && npm run build
 *   OPENAI_API_KEY=sk-... node eval/bakeoff.mjs \
 *     --models gpt-4o-mini,gpt-4.1-mini,gpt-6-luna,gpt-6-sol \
 *     --max-calls 80 [--fixtures eval/fixtures] [--runs 1] [--out eval/results.json]
 *
 * Regenerate eval/coach_tools.json after any change to kCoachAgentTools:
 *   python3 eval/export_tools.py
 */
import { readFileSync, readdirSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const { DEFAULT_SYSTEM_PROMPTS } = await import(join(here, "../lib/coach_prompts.js"));
const { buildChatBody } = await import(join(here, "../lib/ai_request.js"));

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, a, i, arr) => {
    if (a.startsWith("--")) acc.push([a.slice(2), arr[i + 1]?.startsWith("--") ? "true" : arr[i + 1]]);
    return acc;
  }, []),
);
const apiKey = process.env.OPENAI_API_KEY;
if (!apiKey) {
  console.error("OPENAI_API_KEY is required (the proxy's secret is not used here).");
  process.exit(2);
}
const models = (args.models ?? "gpt-4o-mini").split(",").map((s) => s.trim()).filter(Boolean);
const maxCalls = Number(args["max-calls"] ?? 60);
const runs = Number(args.runs ?? 1);
const fixturesDir = args.fixtures ?? join(here, "fixtures");
const outPath = args.out ?? join(here, "results.json");

const tools = JSON.parse(readFileSync(join(here, "coach_tools.json"), "utf8"));
const fixtures = readdirSync(fixturesDir)
  .filter((f) => f.endsWith(".json"))
  .sort()
  .map((f) => ({ file: f, ...JSON.parse(readFileSync(join(fixturesDir, f), "utf8")) }));

const planned = models.length * fixtures.length * runs;
if (planned > maxCalls) {
  console.error(`Planned ${planned} calls exceeds --max-calls ${maxCalls}. Raise the cap deliberately.`);
  process.exit(2);
}

// USD per 1M tokens (OpenAI pricing page, 2026-09-26). Extend as needed.
const PRICE = {
  "gpt-4o-mini": [0.15, 0.6],
  "gpt-4.1-mini": [0.4, 1.6],
  "gpt-4.1-nano": [0.1, 0.4],
  "gpt-5-mini": [0.25, 2.0],
  "gpt-5.4-mini": [0.75, 4.5],
  "gpt-5.6-luna": [0.2, 1.2],
  "gpt-6-luna": [0.1, 0.5],
  "gpt-6-sol": [2.0, 10.0],
};

const ACTION_VERBS = new Set(
  tools.find((t) => t.function.name === "propose_changes").function.parameters.properties.actions.items
    .properties.actionType.enum,
);

function evaluate(fixture, reply) {
  const problems = [];
  const calls = reply.tool_calls ?? [];
  const proposes = calls.filter((c) => c.function?.name === "propose_changes");
  let actions = [];
  let flattened = 0;
  for (const c of proposes) {
    try {
      const parsed = JSON.parse(c.function.arguments ?? "{}");
      if (!Array.isArray(parsed.actions)) problems.push("actions not an array");
      else {
        for (const a of parsed.actions) {
          // Parameters at the top level (no `parameters` map): the app
          // lifts them (AiAction.fromJson); counted here as drift.
          if (a && typeof a === "object" && !("parameters" in a)) {
            flattened++;
            const { actionType, confidence, ...rest } = a;
            actions.push({ actionType, confidence, parameters: rest });
          } else {
            actions.push(a);
          }
        }
      }
    } catch {
      problems.push("tool arguments not JSON");
    }
  }
  for (const a of actions) {
    if (!ACTION_VERBS.has(a.actionType)) problems.push(`unknown verb ${a.actionType}`);
    const p = a.parameters ?? {};
    if (a.actionType === "createTask" && (!p.title || !p.time)) problems.push("createTask missing title/time");
  }
  const e = fixture.expect ?? {};
  if (e.toolCall === true && proposes.length === 0) problems.push("expected a propose_changes call");
  if (e.toolCall === false && proposes.length > 0) problems.push("expected NO propose_changes call");
  if (e.verb && !actions.some((a) => a.actionType === e.verb)) problems.push(`expected verb ${e.verb}`);
  if (e.verbAny && !actions.some((a) => e.verbAny.includes(a.actionType))) {
    problems.push(`expected one of ${e.verbAny.join("/")}`);
  }
  if (e.paramContainsAny) {
    const flat = JSON.stringify(actions).toLowerCase();
    if (!e.paramContainsAny.some((s) => flat.includes(s.toLowerCase()))) {
      problems.push(`params lack any of ${e.paramContainsAny.join("/")}`);
    }
  }
  if (e.paramContains) {
    const flat = JSON.stringify(actions).toLowerCase();
    for (const s of e.paramContains) if (!flat.includes(s.toLowerCase())) problems.push(`params lack "${s}"`);
  }
  if (e.textContains) {
    const t = (reply.content ?? "").toLowerCase();
    for (const s of e.textContains) if (!t.includes(s.toLowerCase())) problems.push(`text lacks "${s}"`);
  }
  if (e.textAvoids) {
    const t = (reply.content ?? "").toLowerCase();
    for (const s of e.textAvoids) if (t.includes(s.toLowerCase())) problems.push(`text contains "${s}"`);
  }
  return { problems, flattened };
}

function percentile(values, p) {
  if (values.length === 0) return 0;
  const sorted = [...values].sort((a, b) => a - b);
  return sorted[Math.min(sorted.length - 1, Math.floor(p * sorted.length))];
}

const results = {};
for (const model of models) {
  const rows = [];
  for (const fixture of fixtures) {
    for (let run = 0; run < runs; run++) {
      const messages = [
        { role: "system", content: DEFAULT_SYSTEM_PROMPTS.coach_agent },
        ...(fixture.history ?? []),
        { role: "user", content: fixture.user },
      ];
      const body = buildChatBody({ model, messages, maxTokens: 800, temperature: 0.6, tools });
      const t0 = Date.now();
      let json;
      try {
        const res = await fetch("https://api.openai.com/v1/chat/completions", {
          method: "POST",
          headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
          body: JSON.stringify(body),
        });
        json = await res.json();
        if (!res.ok) {
          rows.push({ fixture: fixture.file, run, error: json?.error?.message ?? `HTTP ${res.status}`, ms: Date.now() - t0 });
          continue;
        }
      } catch (err) {
        rows.push({ fixture: fixture.file, run, error: String(err), ms: Date.now() - t0 });
        continue;
      }
      const ms = Date.now() - t0;
      const reply = json.choices?.[0]?.message ?? {};
      const usage = json.usage ?? {};
      const { problems, flattened } = evaluate(fixture, reply);
      rows.push({
        fixture: fixture.file,
        run,
        ms,
        promptTokens: usage.prompt_tokens ?? 0,
        completionTokens: usage.completion_tokens ?? 0,
        finish: json.choices?.[0]?.finish_reason,
        problems,
        flattened,
        // Full text and arguments: a truncated record hid replies once.
        text: reply.content ?? "",
        toolCalls: (reply.tool_calls ?? []).map((c) => c.function?.arguments ?? ""),
      });
      process.stdout.write(`${model} ${fixture.file} run${run}: ${problems.length === 0 ? "ok" : problems.join("; ")} (${ms} ms)\n`);
    }
  }
  const ok = rows.filter((r) => !r.error && r.problems.length === 0).length;
  const errors = rows.filter((r) => r.error).length;
  const flattenedTotal = rows.reduce((s, r) => s + (r.flattened ?? 0), 0);
  const latencies = rows.filter((r) => !r.error).map((r) => r.ms);
  const promptTok = rows.reduce((s, r) => s + (r.promptTokens ?? 0), 0);
  const compTok = rows.reduce((s, r) => s + (r.completionTokens ?? 0), 0);
  const [pin, pout] = PRICE[model] ?? [0, 0];
  const cost = (promptTok * pin + compTok * pout) / 1_000_000;
  results[model] = {
    fixtures: rows.length,
    passed: ok,
    errors,
    passRate: rows.length ? +(ok / rows.length).toFixed(3) : 0,
    flattenedParams: flattenedTotal,
    p50ms: percentile(latencies, 0.5),
    p95ms: percentile(latencies, 0.95),
    promptTokens: promptTok,
    completionTokens: compTok,
    costUsd: +cost.toFixed(4),
    costPerTurnUsd: rows.length ? +(cost / rows.length).toFixed(5) : 0,
    rows,
  };
}

writeFileSync(outPath, JSON.stringify(results, null, 2));
console.log("\nmodel | pass | errors | flattened params | p50 ms | p95 ms | $/turn");
for (const [model, r] of Object.entries(results)) {
  console.log(`${model} | ${r.passed}/${r.fixtures} | ${r.errors} | ${r.flattenedParams} | ${r.p50ms} | ${r.p95ms} | ${r.costPerTurnUsd}`);
}
console.log(`\nDetails: ${outPath}`);
