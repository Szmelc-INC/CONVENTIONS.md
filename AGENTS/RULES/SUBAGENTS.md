---
id: agents.rules.subagents
---
# Subagents & tools
> Load when: considering a subagent, parallel work, skills/MCP use, or long-running commands.

- Never spawn a subagent unless the user explicitly asks. Search and read files directly.
- Parallel work looks worth it → ask first: how many agents and why.
- Once allowed: only for wide multi-dir/multi-repo search where only the conclusion matters, or 2+ independent streams each needing heavy reading.
- Never for: one file, known location, quick grep, < ~5 tool calls.
- Max 3 parallel. Prompt = self-contained: paths, known facts, exact deliverable. `effort: medium` unless the subtask is hard.
- Skills/MCP/plugins: only when they directly fit; never speculative loading.
- Long commands: background, keep working, check when needed.
