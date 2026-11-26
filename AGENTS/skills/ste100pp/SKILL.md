---
name: ste100pp
description: STE100++ writing mode. Applies controlled technical writing (inspired by ASD-STE100 Simplified Technical English, not certified) to docs prose, procedures, help text, error messages, tool descriptions and agent prompts, in English or Polish. Use when the user asks for STE, STE100++, "plain technical English", "write it like a maintenance manual", "no fluff, no hedging", or wants text that a tired non-native reader cannot misread. Stays on until the user says "stop ste".
---

# STE100++ writing mode

ASD-STE100 is the controlled language of aerospace maintenance manuals. Its core idea: one word has one meaning, and one sentence has one possible structure. STE100++ keeps the rules that remove ambiguity, drops the rules that only remove voice, and adds rules for software docs, errors and agent prompts. It is a style layer. Do the task first, then shape the prose.

Rule summary: `CONVENTIONS/REPO/STE100PP.md`. Polish: `references/PL.md`.

## 1. Hard rules (always)
1. Answer first. Sentence 1 gives the answer, the result or the verdict.
2. One idea per sentence. One action per procedure step.
3. Active voice, named actor. Passive only when the actor is unknown or irrelevant.
4. Condition before command. "If the build fails, read the log."
5. Warnings: the command or the condition first, then the risk. "Do not run this on production. It drops the table."
6. No semicolons in prose.
7. One word, one meaning per document. Do not rotate check/verify/validate or config/settings/options for one idea.
8. Verb, not noun. "Analyze the log", not "perform an analysis of the log".
9. No claim words and no slop: robust, seamless, powerful, leverage, comprehensive, production-ready, "it is worth noting", "not just X but Y", summary closers.
10. No dropped words. Keep articles, subjects and "that".
11. Never change code, commands, flags, paths, identifiers, quoted errors, product names, numbers or the strength of a hedge.

## 2. Soft targets (default, break with a reason)
- Sentence length: ≤ 20 words for instructions, ≤ 25 for explanations, 30 hard cap. Go longer only when a split separates a condition from its result.
- Tenses: simple present, simple past, simple future, imperative. Keep present perfect when it carries current state.
- Paragraphs: one topic, ≤ 6 sentences.
- Noun stacks: ≤ 3 nouns. "the timeout for the connection pool", not "connection pool timeout value".
- Phrasal verbs: prefer the single verb (start, not "spin up"). Keep fixed tech idioms (log in, roll back).
- Lists: numbered for 3+ ordered steps, bullets for 3+ parallel items, prose for the rest. List items share one grammatical form.
- Em dashes: rare. A dash usually hides two sentences.
- Define a new concept term once, in a few words, at first use: "idempotent (safe to run twice)".

## 3. The "++" additions
- Procedures: one action per step, then the expected result in the same step. More than 9 steps: split into named stages.
- Error messages: what happened, the cause if known, the next action. Name the file, value or limit. No apology, no blame. `config.toml: unknown key "colour" (line 12). Use "color".`
- Help text and flags: start with a verb, state the default and the unit. `--timeout <s>  Stop waiting after <s> seconds (default 30).`
- Agent prompts and tool descriptions: imperative, one rule per line, the reason in one clause only when it is not obvious.
- Numbers: digits, units with a space (`30 s`, `2 GiB`), ISO 8601 dates, ranges with an en dash or "to".
- Hedges: keep may/might/could when the uncertainty is real. One hedge per claim.
- Glossary: a project with more than ~5 domain terms keeps one glossary. Docs use its terms only.

## 4. Off
- The STE approved-word dictionary and the one-part-of-speech rule. Prefer common words instead.
- The modal ban. Uncertainty is content.
- Flat tone. Keep the user's register, humor and profanity. STE controls structure, not personality.
- The contraction ban in chat. Avoid contractions in docs for non-native readers and in text for translation.

## 5. Scope by output
| Output | Strength |
|---|---|
| Chat replies, explanations | Sections 1, 2 |
| Procedures, runbooks, install steps, errors, help text, tool descriptions, agent prompts | Sections 1–3, length caps strict |
| READMEs, changelogs, PR descriptions | Sections 1–3 |
| Rule one-liners in this repo | Exempt from the semicolon and length rules |
| Code and identifiers | Never changed. Prose comments follow section 1 |
| Creative, lyrics, marketing, persuasion | Off unless asked |

## 6. Self-check
1. Does sentence 1 give the answer?
2. Search for `;` in prose. Split.
3. Read the three longest sentences. Over the cap? Split, unless the split cuts a condition from its result.
4. Search for "is/was/been + participle" with no actor. Name the actor.
5. Search for claim words and stacked hedges. Delete.
6. Two words for one thing? Keep one.
7. Did you change a number, an identifier or a hedge? Undo it.

## 7. Activation
- On invocation, answer in this mode. Do not announce it and do not explain the rules.
- Stay on until the user says "stop ste", "wyłącz ste" or "normal mode".
- Rewrite request: return only the rewritten text. Add a before/after table only on request.
- Compliance question: say in one sentence that this mode is STE-inspired, not certified, and that the official standard is available from ASD (<https://www.asd-ste100.org/>).
- Polish output: apply `references/PL.md`.
