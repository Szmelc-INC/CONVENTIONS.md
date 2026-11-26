---
id: agents.prompt.task-prompts
---
# Task prompts
> Load when: looking for a ready prompt for everyday work: planning, debugging, reviewing, summarizing, distilling, deciding, learning.

Paste one into any chat. Each prompt is self-contained. Replace `{...}`. Prompts for working on these conventions: `CONTRIBUTING/PROMPTS.md`.

## Build
| Task | Prompt |
|---|---|
| Plan | Plan first; change nothing until I say "go". Restate the goal in one sentence. List the steps; for each the risk and the check that proves it done. List the edge cases and the strongest other approach. |
| Debug | Reproduce {bug}. Read the whole error before changing anything. Test one hypothesis at a time and name it. Report: root cause, the smallest fix, the check that proves it. Two failed hypotheses in a row → change strategy. |
| Review | Review {diff} read-only. Findings first, most severe first, each as `[P0] imperative title — path:line` (P0 blocker, P1 urgent, P2 ordinary, P3 minor) with one sentence on the scenario and the fix. Only defects this change introduced and I would fix. No style nits, no guesses. If there are none, say "No findings." |
| Verify | Prove that {change} works. Run {check} and paste the command with its output. List what you could not check and why. Never say "works" without a run. |
| Explain | Explain {path or concept} to a developer new to it: what it is for, how it works step by step, what must always hold, where the traps are. Cite `path:line` for each claim. |
| Commit message | Write a commit message for this diff: one imperative subject line; a body only if the why is not visible in the diff. |

## Distill
| Task | Prompt |
|---|---|
| Defluff | Strip filler from the text below: hedging, filler adjectives, restatements, polite padding. Keep every fact, number and identifier, the logic, the language and the order. Return only the cleaned text. |
| Summarize | Summarize {document} in {n} lines for {reader}. Each fact with its source line; mark each inference `inference`; name what the document does not say. No introduction, no conclusion. |
| Distill | Turn {documents} into instructions for {agent or role} doing {goal}. Sections: purpose; numbered directives; failure modes with the fix; boundaries; how to tell a good result; open questions. Keep identifiers verbatim. Never invent to fill a gap: list it under open questions. |
| Rubric | Below are good and bad examples of {thing}. For each difference ask: if only this changed, would good become bad? Keep the causes, drop the correlates. Return the principles, and for each how to apply it to a new case. Say how many pairs you saw. |
| Evaluate | Grade {artifact} against {criteria}. For each criterion: `pass`, `partial` or `fail`, then the exact place in the artifact that proves it. For each fail: the mechanism and the direction of the fix. List criteria that cannot be judged from the artifact and criteria that are vague or contradict each other. Judge by the criteria, not by taste. |
| Research | Research {question} across at least {n} independent sources. Mark each claim `consensus` (several independent sources agree), `single` (one source) or `contested` (sources disagree; keep both sides). Cite a source for every claim. End with open questions. |

## Think
| Task | Prompt |
|---|---|
| Decide | I must decide {question}. Give 2–3 genuinely different options. For each: cost, risk, what it makes harder later. Recommend one and name the strongest option you rejected and why. |
| Interview to spec | Interview me, one question at a time, until you can write a spec for {feature}: goal, non-goals, constraints, acceptance checks. Then write the spec. I will build from it in a new session. |
| Learn | Teach me {topic}. Start with one question to find where I am. Then one step per message: a short explanation, one example, one question for me to answer. Say when I have it and what to learn next. |
