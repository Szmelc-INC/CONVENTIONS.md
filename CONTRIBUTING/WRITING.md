# Writing a rule
> Load when: writing or reviewing a convention rule, deciding where a rule goes, or creating a category.

## Checklist
- Grep first: `grep -ril '<topic>' CONVENTIONS AGENTS/RULES AGENTS/PROMPT`; extend the owning file instead of adding a duplicate.
- Format, naming and length: `CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md`; skeleton `META/templates/rule.md`.
- Trigger names a concrete task ("bumping a version"), never a topic ("versions").
- Imperative one-liners; one rule per line; ~20 lines max, else split.
- Universal: true for every project; project specifics go in that project's `AGENTS.md`.
- Reference other rules by backticked path; never restate them.
- Verified facts only; cite the source (doc URL, spec) for tool-specific claims; mark unverified ones `(unverified)`.
- Public material only: no personal IDs, emails, private repo names, local paths.

## Where a rule goes
| Rule is about | Path |
|---|---|
| Everyday flow: branches, commits, finishing, verifying, notifying | `CONVENTIONS/WORKFLOW/` |
| Anything GitHub: repo settings, PRs, Actions, releases, Pages | `CONVENTIONS/GITHUB/` |
| A named document file (`AGENTS.md`, `CHANGELOG.md`, `DESIGN.md`) | `CONVENTIONS/SPECS/THIRD-PARTY/` if an outside standard defines it, else `CONVENTIONS/SPECS/ORIGINAL/` |
| Agent behaviour (subagents, token efficiency) | `AGENTS/RULES/` |
| A prompt, or how to write, test or check one | `AGENTS/PROMPT/` |
| Not yet adopted | `CONVENTIONS/EXPERIMENTAL/` via an `experimental/*` branch (`CONTRIBUTING/LIFECYCLE.md`) |
| Anything else | The matching category in `CONVENTIONS/README.md`; none fits → new category |

## New category
1. UPPERCASE directory under `CONVENTIONS/` (sub-category: under an existing one) + its row in `CONVENTIONS/README.md`.
2. Optional category `README.md` only when a row is not enough (`META/templates/category-README.md`).
3. `META/tools/build.sh && META/tools/check.sh`.

## Good vs bad
| Bad | Good |
|---|---|
| "It is generally a good idea to keep commits small and focused." | "One logical change per commit." |
| "Use the accent color #105c5c for buttons." (restates a rule) | "Buttons: accent fill (`CONVENTIONS/DESIGN/COLORS.md`)." |
| Trigger "git" | Trigger "creating branches or opening/merging PRs" |
