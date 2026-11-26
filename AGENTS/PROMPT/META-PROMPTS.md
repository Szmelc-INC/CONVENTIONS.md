---
id: agents.prompt.meta-prompts
---
# Meta-prompts
> Load when: asking an agent to write, review, tighten or test a prompt.

Paste one into any chat; each is self-contained. Replace `{...}`. Rules behind them: `AGENTS/PROMPT/WRITING.md`, `AGENTS/PROMPT/TESTING.md`.

## Write
| Task | Prompt |
|---|---|
| Interview | Before writing a prompt for {task}, interview me. Send at most 5 questions in one message, each with a default I can accept by silence. Cover: the result I want, what the prompt receives, hard limits, where it will run, what a bad result looks like. Then wait for my answers. |
| Compile | Turn my request into a prompt for {model/any LLM}. Sections: role and objective; numbered instructions; the literal output format; edge cases and fallbacks (empty, malformed, out-of-scope, contradictory input). Put only the prompt in one fenced block. After it, list every assumption you made. Add no requirement I did not state. |
| Tighten | Rewrite this prompt. Replace each adjective with a checkable constraint, each bare prohibition with the required behavior, each restatement with a reference. Keep every mechanic, example and edge case. Return the new prompt in one fenced block, then each change with its reason. |

## Check
| Task | Prompt |
|---|---|
| Review | Review this prompt; change nothing. For each line: can the output prove it; does it collide with another line; what is the laziest output that still complies. Then check empty, malformed, out-of-scope, contradictory and hostile input. Report each defect as `line, defect, fix`. If there is none, say "No findings." |
| Red-team | Attack this {prompt/plan/design} as a hostile reviewer. List the strongest objections, most damaging first. For each: fix it in the text or concede it in one line. Keep the length; do not summarize. |

## Test
| Task | Prompt |
|---|---|
| Test inputs | Write 5 inputs for this prompt: one typical, one empty, one malformed, one out of scope, one near-miss that must not match. For each, name the property of the output that shows pass or fail. |
| Grade | Run this prompt on the inputs below and grade each output against {criteria}. For every failure state the mechanism: why it happens and which line lets it. Return a table: input, pass or fail, mechanism. Change nothing. |
| Improve | Run this prompt on {inputs} and grade the outputs against {criteria}. For each failure, fix the prompt where the failure starts, then run again. Stop when all pass or after 3 rounds. Return the final prompt in one fenced block; after it, the pass count of each round and each change with its reason. |
