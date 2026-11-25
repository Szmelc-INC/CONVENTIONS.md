# CONVENTIONS
> Load when: asked which conventions exist, how rules are organised, or before adding/promoting/demoting a rule.

The rules themselves: how Szmelc projects are built, shipped and maintained. One topic per file, one rule per line. Agents never read this tree whole; they read `INDEX.md` once and load only rules whose trigger matches.

## Categories
| Directory | Covers |
|---|---|
| `CONVENTIONS/workflow/` | Branches, commits, git/PR/CI, releases, finishing work, verification, notifications |
| `CONVENTIONS/repo/` | Repo layout, README, design docs and agent briefs, writing and voice, metadata and license |
| `CONVENTIONS/design/` | Colors and visual identity for UI, TUI, CLI, web, badges |
| `CONVENTIONS/interfaces/` | CLI, TUI and configuration design |
| `CONVENTIONS/packaging/` | Arch `PKGBUILD` and SAUR, Nix flakes, installers |
| `CONVENTIONS/code/` | Stack defaults, naming, Go, shell scripts, shell environment and dotfiles |
| `CONVENTIONS/experimental/` | Opt-in proposals; load only when the user opts in (branch `experimental/<x>`) |
| `CONVENTIONS/legacy/` | Superseded drafts, never deleted; load only when asked (branch `legacy/<x>`) |

Agent-specific rules (subagents, token efficiency, agent-file formats, skills) live in `AGENTS/rules/`.

## Rule format
- Line 1 `# Title`, line 2 `> Load when: <trigger>`, then imperative one-liners. Skeleton: `META/templates/rule.md`.
- Never duplicate a rule; reference it by path (`CONVENTIONS/design/colors.md`).
- New domain → new directory under `CONVENTIONS/`. New topic → copy the skeleton.

## Lifecycle
- New idea → `CONVENTIONS/experimental/<x>.md` via an `experimental/<x>` branch.
- Adopted → moved to `CONVENTIONS/<category>/<x>.md` in a `feat/<x>` PR.
- Superseded → moved to `CONVENTIONS/legacy/` in a `legacy/<x>` PR with `> Superseded by: <path>` on line 3.
- Details: `CONVENTIONS/workflow/branches.md`.

## Formats
- Root `CONVENTIONS.md` is the generated all-in-one bundle: a map of this tree plus every stable rule inlined, for tools that cannot lazy-load.
- `INDEX.md`, `index.json`, `llms.txt` index the same rules for agents and the web.
