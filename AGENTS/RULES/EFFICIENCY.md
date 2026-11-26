---
id: agents.rules.efficiency
---
# Token efficiency
> Load when: choosing a model or effort level, configuring a harness or subagent, writing instruction files, or a session grows long.

- Free savings, always: locate before reading; read ranges; check size (`wc -l`) before ingesting; never re-read a file after editing it; batch independent calls; stop once you can act.
- Big output (logs, test runs, JSON) → into a file, then grep/jq the part you need.
- Risky savings, weigh each time: skipping verification, cutting exploration short, a weaker model for reasoning. Never cut the quality of thinking.
- Match model and effort to difficulty: mechanical work (search, rename, move, format) → small model or low effort; design, root cause, security → strong model, high effort.
- Default effort medium; raise per task, never permanently. Pick model and effort at session start; switching mid-task can invalidate the prompt cache.
- Custom subagents pin `model` and `effort` so they never inherit the top model by accident. When to spawn at all: `AGENTS/RULES/SUBAGENTS.md`.
- Instruction files stay static, short (< ~200 lines) and index-like; an import loads at session start, so it saves nothing.
- Load tool and MCP schemas on demand; never attach servers mid-session.
- One task per session; clear between unrelated tasks; compact keeping goal, decisions, files changed, failing checks.
- No scheduled loops on idle sessions: each run resends the whole context.
