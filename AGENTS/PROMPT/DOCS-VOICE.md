---
id: agents.prompt.docs-voice
---
# Docs voice profile
> Load when: drafting or rewriting a README or guide in the house docs voice, or briefing an agent to write docs.

Voice profile built with the clone-my-style method (six pillars) and the Voice Card attributes of match-my-writing-style. Source sample: the README of everything-claude-code by Affaan Mustafa (<https://github.com/affaan-m/everything-claude-code>; copy analysed: <https://github.com/WorldFlowAI/everything-claude-code>, read 2026-11-26). The sample gives the structure. `CONVENTIONS/REPO/WRITING.md` overrides its voice. Rules: `CONVENTIONS/REPO/DOCS.md`.

## 1. Persona core
- Vibe: a practitioner who hands over a working kit and tells you where to start.
- Tone: direct, second person, practical. It tells the reader what to do next.
- Registers: README is scannable and command-first. Guides carry the long explanations. Notes carry the warnings and the limits.

## 2. Linguistic mechanics
- Lexicon: tool nouns stay verbatim (`agents`, `skills`, `hooks`, `rules`, `MCP`). Verbs are plain: install, copy, add, run, keep, remove.
- Sentences: short. A section opens with one sentence that frames it ("Rules are always-follow guidelines."), then a block or a list.
- Person: "you" for the reader, "I" only in a background or author section.
- Casing: sentence case in prose. Title Case headings in the sample; this repo keeps sentence case (`CONVENTIONS/FORMATS/MARKDOWN/STYLE.md`).
- Punctuation: colon before a block or list. In the sample a hyphen often replaces a dash or colon ("install it directly - or copy"); here, write a colon or two sentences.

## 3. Structure moves (keep)
| Move | Sample | Here |
|---|---|---|
| Hook + payoff | bold one-liner, then "what you get" | `CONVENTIONS/REPO/DOCS.md` open |
| Guide router | two-cell table, "Read this first" | "Start here" table |
| Topic map | `Topic \| What You'll Learn` | ≤ 8 rows |
| Annotated tree | `\|--` tree with aligned comments | `text` block, aligned comments |
| Ranked lookup | numbered precedence, highest first | `` `source` `` then effect |
| Install options | Option 1 (Recommended), Option 2 manual | same, a comment above every command |
| Concept + minimal example | one sentence, then a 5–10 line file | same |
| Rule of thumb | "20-30 configured, under 10 enabled, under 80 tools" | limits as numbers |
| Customization | start, modify, remove, add | same |

## 4. Anti-patterns (reject)
- Claim words: "Production-ready", "battle-tested", "comprehensive", "complete collection", "maximum compatibility", "instant access". State the fact instead: count, test command, platform list.
- Closers and calls to action: "Star this repo if it helps", "Build something great", "Please contribute!".
- `(NEW)` markers in trees: the changelog records what is new.
- Bold lead-ins on list items (`**Environment variable**: …`): use the identifier in backticks.
- Static badges and badge colors outside the palette (`CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`).
- Unverified config syntax presented as working. Example: the sample's hook matchers (`tool == "Bash" && …`) do not match the documented Claude Code hook schema. Verify every config block against its upstream docs.
- Background and social links above the install section.

## 5. Voice Card snapshot
- Opening: name, one bold sentence, one payoff sentence. No greeting.
- Rhythm: frame sentence → block → one result line.
- Formatting: tables for maps, numbered lists for order, fenced blocks for anything the reader types.
- Closing: license line. Nothing after it.
- Never: claim words, hedging stacks, "Here is…", emoji in headings.

## 6. Agent prompt block
```text
Write project docs in this voice:
1. Open with "# <Name>", one bold sentence (what it is, for whom), one plain sentence (what the reader gets). Facts only.
2. Each section: one framing sentence, then a table, list or fenced block, then one line that says the result.
3. Install: "Option 1 (recommended)" before "Option 2 (manual)"; a "#" comment above every command.
4. Limits as numbers in a notes section near the end.
5. Never write quality claims (production-ready, comprehensive, battle-tested), calls to star or share, or bold lead-ins.
6. Keep every command, path, flag and number verbatim. Do not invent features, counts or versions.
Return only the Markdown.
```

## 7. Example
Before: "**The complete, battle-tested toolkit!** Production-ready configs for maximum productivity."
After: "**Claude Code agents, skills, hooks and rules in one plugin.** Install it once and get 9 agents, 11 skills and 15 commands."
