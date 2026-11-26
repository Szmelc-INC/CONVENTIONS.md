---
name: deep
description: Escalate to deep reasoning for hard problems — architecture and design decisions, cross-cutting refactors, bugs with unclear root cause, security-sensitive code, concurrency, or anything where a wrong first approach is expensive. Use it before writing code for such tasks. Do not use it for routine edits.
effort: high
---

# Deep mode
> Install: `./install.sh` links this dir as skill `deep` into every harness skill root. Spend reasoning, not tool calls.

1. State the real problem in one sentence. Name any hidden underlying problem.
2. Read only context that decides between approaches.
3. 2–3 genuinely different approaches: risk, cost, what each makes easy later.
4. Pick one and give the reason in 1–2 lines. Note the strongest rejected alternative.
5. List edge cases and failure modes, then implement.
6. Verify them with the cheapest real check.
7. Report: decision, changes, verified, remaining risk. Short.
