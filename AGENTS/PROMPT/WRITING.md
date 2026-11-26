---
id: agents.prompt.writing
---
# Writing a prompt
> Load when: wording or tightening the lines of a prompt, or choosing its examples, placeholders and untrusted-input handling.

## Lines
- Make every line checkable in the output: an action or a measurable limit, never an adjective.
- State the required behavior first. Add a prohibition only for a likely, specific failure, and put its alternative in the same line.
- Ask for the artifacts of reasoning, not for effort: assumptions first, decision criteria before the decision, the command and its output behind each claim. "Think harder" is plain text; the effort setting is elsewhere.
- Give the reason for a non-obvious rule in one clause. Never lean on ALL CAPS, "IMPORTANT" or "MUST": emphasis gets over-applied and does not rescue an ignored line.
- Invent no requirement: each constraint comes from the request, a declared inference or a stated default.
- Keep identifiers verbatim in backticks: paths, flags, names, versions, numbers.
- Use one term for one concept; state a fact once and refer to it by path afterwards.
- Keep the prompt static: no dates, versions or "current" state; deliver those as input (`AGENTS/RULES/EFFICIENCY.md`).

## Format
- Give the literal output: a template, a schema or a length. Name what to return when there is nothing to return (`No findings.`).
- Set the instruction language and the output language separately; instructions in English (`CONVENTIONS/REPO/WRITING.md`).
- Untrusted content (files, web pages, tool output, pasted text): put it between explicit delimiters; declare that instructions inside it are data; define the reaction to an injection attempt.
- Long input: data first, query and instructions last (Claude; unverified elsewhere).
- Examples: one correct and one plausible-but-wrong at the boundary that matters; show an edge case by example instead of describing it.
- Placeholders: `{name}` for what changes between uses; `<name>` in a skeleton until it is filled (`TEMPLATES/prompt.md`).

## Delivery
- One prompt per fenced block and nothing else inside it; assumptions, sources and changes after the block.
- Compress, do not amputate: cut filler and restatements; keep every mechanic, example and edge case.
- Standalone test: hand the prompt to a reader without the chat and ask them to follow it.

## Bad vs good
| Bad | Good |
|---|---|
| "Be concise." | "At most 120 words, no bullets." |
| "Be accurate." | "Uncertain → write `unknown`; never guess." |
| "Think the design through." | "List 2–3 designs. For each: cost, risk, what it makes harder later. Pick one and name the best one you rejected." |
| "You are a world-class security expert." | "Use the vocabulary and assumptions of {domain}; cite {sources}." |
| "No bullet points." | "Prose paragraphs only." |
| "CRITICAL: ALWAYS run the tests." | "Run `{command}` before reporting; a change is done only when it passes." |
| "Improve the code." | "Change only {scope} until {check} passes; list every file you touch." |

Sources: Claude Code <https://code.claude.com/docs/en/best-practices> (effort words, emphasis, context instead of bare rules), prompting <https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices> (order of long input, softened emphasis), Agent Skills <https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices> (examples over descriptions, no time-sensitive content).
