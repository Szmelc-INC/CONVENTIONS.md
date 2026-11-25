# CONVENTIONS
> Load when: asked which conventions exist, how rules are organised, or before adding/promoting/demoting a rule.

The rules themselves: how Szmelc projects are built, shipped and maintained. One topic per file, one rule per line. Agents never read this tree whole; they read `INDEX.md` once and load only rules whose trigger matches.

## Categories
| Directory | Covers |
|---|---|
| `CONVENTIONS/WORKFLOW/` | Branches, commits, finishing work, verification, notifications |
| `CONVENTIONS/GITHUB/` | Everything GitHub: repo settings, metadata and labels, pull requests, issues, discussions, projects, wiki, organisations, coding agents, code security, `ACTIONS/` (workflows, CI), `RELEASES/` (versioning, tags, automation, channels), `DEPLOYMENTS/` (Pages, environments, web UI style) |
| `CONVENTIONS/SPECS/` | Named document files: `THIRD-PARTY/` (format set by an outside standard or tool: `AGENTS.md` + imports, `SKILL.md`, `README.md`, `llms.txt`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CODEOWNERS`, `LICENSE`, `.mcp.json`), `ORIGINAL/` (Szmelc formats: `DESIGN.md`, rule files, core maps, lazy-load indexes) |
| `CONVENTIONS/REPO/` | Repo layout, writing and voice |
| `CONVENTIONS/DESIGN/` | Colors and visual identity for UI, TUI, CLI, web, badges |
| `CONVENTIONS/INTERFACES/` | CLI, TUI and configuration design |
| `CONVENTIONS/PACKAGING/` | Arch `PKGBUILD` and SAUR, Nix flakes, installers |
| `CONVENTIONS/CODE/` | Stack defaults, naming, Go, shell scripts, shell environment and dotfiles |
| `CONVENTIONS/EXPERIMENTAL/` | Opt-in proposals; load only when the user opts in (branch `experimental/*`) |
| `CONVENTIONS/LEGACY/` | Superseded drafts, never deleted; load only when asked (branch `legacy/*`) |

Agent behaviour rules (subagents, token efficiency) live in `AGENTS/RULES/`. How to add or change a rule: `CONTRIBUTING/README.md`.

## Rule format
- Header, length, naming (`X-EXT.md`), references and status: `CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md`. Skeleton: `META/templates/rule.md`.
- New domain → new directory under `CONVENTIONS/`. New topic → copy the skeleton.

## Lifecycle
- New idea → `CONVENTIONS/EXPERIMENTAL/<X>.md` via an `experimental/*` branch.
- Adopted → moved to `CONVENTIONS/<CATEGORY>/<X>.md` in a `feat/*` PR.
- Superseded → moved to `CONVENTIONS/LEGACY/` in a `legacy/*` PR with `> Superseded by: <path>` on line 3.
- Details: `CONVENTIONS/WORKFLOW/BRANCHES.md`.

## Formats
- Root `CONVENTIONS.md` is the generated all-in-one bundle: a map of this tree plus every stable rule inlined, for tools that cannot lazy-load.
- `INDEX.md`, `index.json`, `llms.txt` index the same rules for agents and the web (`CONVENTIONS/SPECS/ORIGINAL/INDEX-MD.md`, `CONVENTIONS/SPECS/THIRD-PARTY/LLMS-TXT.md`).
