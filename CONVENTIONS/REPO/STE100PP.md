---
id: conventions.repo.ste100pp
locales: pl=AGENTS/skills/ste100pp/references/PL.md
---
# STE100++ controlled writing
> Load when: writing or reviewing docs prose, procedures, help text, error messages, tool descriptions or agent prompts.

This standard is inspired by ASD-STE100 and is not certified. It does not reproduce the ASD dictionary. Full mode, scope table and self-check: `AGENTS/skills/ste100pp/SKILL.md`. Locale companions, written natively per language (first: `pl`): `AGENTS/skills/ste100pp/references/PL.md`. Scope: prose. Rule one-liners, code, tables of identifiers and quoted text are exempt.

- Answer or result in the first sentence. No preamble, no restated question.
- One idea per sentence. One action per procedure step, then its expected result.
- Active voice with a named actor. Passive only when the actor is unknown or irrelevant.
- Condition before command: "If the build fails, read the log." Warning: command first, then the risk.
- No semicolons in prose. Write two sentences.
- One word, one meaning: one term per concept in a file. New concept terms are defined once at first use.
- Verbs, not nominalizations: "check", not "perform a check".
- Sentence length: ≤ 20 words in procedures, ≤ 25 in explanations, 30 hard cap.
- Keep real uncertainty (may, might) with one hedge. Delete stacked hedges and claim words (`CONVENTIONS/REPO/WRITING.md`).
- Keep articles, subjects and "that". Short is not telegraphic.
- Numbers as digits with units (`30 s`, `2 GiB`), dates ISO 8601, one name per command or file, in backticks.
- Error messages: what happened, the cause if known, the next action. No apology, no blame.
- Never change code, commands, identifiers, quoted errors, numbers or the strength of a hedge to fit a rule.
