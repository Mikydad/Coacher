# Coach model bake-off (fix plan Phase 5.2)

Replays fixture prompts through the server's real system prompt and request
shaping against candidate models, calling OpenAI directly with your own key.
It never runs in CI and every call costs money, so it caps itself with
`--max-calls`.

```bash
cd functions && npm run build
python3 eval/export_tools.py           # after any change to kCoachAgentTools
OPENAI_API_KEY=sk-... node eval/bakeoff.mjs \
  --models gpt-4o-mini,gpt-4.1-mini,gpt-6-luna,gpt-6-sol --max-calls 80 --runs 2
```

Each fixture in `eval/fixtures/` is `{ "user": <rendered prompt>, "history": [...],
"expect": { toolCall, verb, paramContains, textContains, textAvoids } }`. The
`user` text mirrors what `ProxyAiOperatingLayerClient._buildUserPrompt` renders;
keep the two in step when the renderer changes.

Read the table for: pass rate (tool-call validity + the fixture's expectation),
p50/p95 latency, and cost per turn. `eval/results.json` keeps every reply for
inspection. Record the winner and the numbers in the decision log; switch the
model with the `ai_purpose_routes` Remote Config parameter (per purpose), which
the server allow-list now accepts for the current generation.
