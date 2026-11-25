# CONVENTIONS
> Load when: asked which conventions exist, how rules are organised, or before adding/promoting/demoting a rule.

The rules themselves: how Szmelc projects are built, shipped and maintained. One topic per file, one rule per line. Agents never read this tree whole; they read `INDEX.md` once and load only rules whose trigger matches.

## Categories
| Directory | Covers |
|---|---|
| `CONVENTIONS/workflow/` | Branch lanes, git/PR/CI, finishing work, verification, notifications, repo metadata |
| `CONVENTIONS/design/` | Colors and visual identity for UI, TUI, CLI, web, badges |
| `CONVENTIONS/interfaces/` | CLI and TUI design |
| `CONVENTIONS/packaging/` | Arch `PKGBUILD`, Nix flakes |
| `CONVENTIONS/code/` | Stack defaults: language, dependencies, config formats, persistence |
| `CONVENTIONS/experimental/` | Opt-in proposals; load only when the user opts in (lane `experimental`) |
| `CONVENTIONS/legacy/` | Superseded drafts, never deleted; load only when asked (lane `legacy`) |

Agent-specific rules (subagents, agent-file formats, skills) live in `AGENTS/rules/`.

## Rule format
- Line 1 `# Title`, line 2 `> Load when: <trigger>`, then imperative one-liners. Skeleton: `META/templates/rule.md`.
- Never duplicate a rule; reference it by path (`CONVENTIONS/design/colors.md`).
- New domain → new directory under `CONVENTIONS/`. New topic → copy the skeleton.

## Lifecycle
- New idea → `CONVENTIONS/experimental/<x>.md` via lane `experimental`.
- Adopted → moved to `CONVENTIONS/<category>/<x>.md` in a `testing` PR.
- Superseded → moved to `CONVENTIONS/legacy/` in a `legacy` PR with `> Superseded by: <path>` on line 3.
- Details: `CONVENTIONS/workflow/branches.md`.

## Formats
- Root `CONVENTIONS.md` is the generated all-in-one bundle: a map of this tree plus every stable rule inlined, for tools that cannot lazy-load.
- `INDEX.md`, `index.json`, `llms.txt` index the same rules for agents and the web.
