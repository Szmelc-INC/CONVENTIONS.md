# Subagents & tools
> Load when: considering a subagent, parallel work, skills/MCP use, or long-running commands.

- Default: do it yourself. A subagent cold-starts and re-reads context; it must earn that.
- Use one only for: wide multi-dir/multi-repo search where only the conclusion matters (Explore), or 2+ independent streams each needing heavy reading.
- Never for: one file, known location, quick grep, < ~5 tool calls.
- Max 3 parallel. Prompt = self-contained: paths, known facts, exact deliverable. `effort: medium` unless the subtask is hard.
- Skills/MCP/plugins: only when they directly fit; never speculative loading.
- Long commands: background, keep working, check when needed.
