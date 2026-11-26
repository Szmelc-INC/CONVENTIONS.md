# CONVENTIONS
> Load when: asked which conventions exist, how rules are organised, or before adding/promoting/demoting a rule.

The rules themselves: how {{profile.project_name}} projects are built, shipped and maintained. One topic per file, one rule per line. Agents never read this tree whole. They read `INDEX.md` once and load only rules whose trigger matches.

## Categories
| Directory | Covers |
|---|---|
| `CONVENTIONS/WORKFLOW/` | Branches, commits, finishing work, verification, notifications |
| `CONVENTIONS/GITHUB/` | Everything GitHub: repo settings, metadata and labels, pull requests, issues, discussions, projects, wiki, organisations, coding agents, code security, `ACTIONS/` (workflows, CI), `RELEASES/` (versioning, tags, automation, channels), `DEPLOYMENTS/` (Pages, environments, web UI style) |
| `CONVENTIONS/SPECS/` | Named document files: `THIRD-PARTY/` (format set by an outside standard or tool: `AGENTS.md` + imports, `SKILL.md`, `README.md`, `llms.txt`, `CHANGELOG.md`, `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md`, `CODEOWNERS`, `LICENSE`, `.mcp.json`), `ORIGINAL/` (project formats: `DESIGN.md`, rule files, core maps, lazy-load indexes). Third-party specs map to `COMPATIBILITY.md` entries |
| `CONVENTIONS/FORMATS/` | File formats: `MARKDOWN/` (style, frontmatter, tables, GitHub extras), JSON, TOML, YAML, `.env`, `.editorconfig` and `.gitattributes` |
| `CONVENTIONS/SYSTEMS/` | Target platforms: support order, Arch, Nix, other Linux, Windows via WSL2, macOS |
| `CONVENTIONS/REPO/` | Repo layout, writing and voice, docs structure |
| `CONVENTIONS/PROFILES/` | Profile values and layered rule overrides |
| `CONVENTIONS/DESIGN/` | Colors and visual identity for UI, TUI, CLI, web, badges |
| `CONVENTIONS/INTERFACES/` | CLI, TUI and configuration design, `WEBUI/` (web UI architecture, routing, overlays, keyboard, components, accessibility) |
| `CONVENTIONS/PACKAGING/` | Arch `PKGBUILD` and `{{profile.package_registry}}`, Nix flakes, installers |
| `CONVENTIONS/CODE/` | Stack defaults, naming, Go, shell scripts, shell environment and dotfiles |
| `CONVENTIONS/EXPERIMENTAL/` | Opt-in proposals; load only when the user opts in (branch `experimental/*`) |
| `CONVENTIONS/LEGACY/` | Superseded drafts, never deleted; load only when asked (branch `legacy/*`) |

Agent behaviour rules (subagents, token efficiency) live in `AGENTS/RULES/`, prompt engineering in `AGENTS/PROMPT/`. How to add or change a rule: `CONTRIBUTING/WRITING.md`.

## Rule format
- Header, length, naming (`X-EXT.md`), references and status: `CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md`. Skeleton: `TEMPLATES/rule.md`.
- New domain → new directory under `CONVENTIONS/`. New topic → copy the skeleton.

## Lifecycle
- Experimental → stable → legacy, never deleted: `CONTRIBUTING/LIFECYCLE.md`; branch mechanics: `CONVENTIONS/WORKFLOW/BRANCHES.md`.

## Formats
- Root `CONVENTIONS.md` is the generated all-in-one bundle: a map of this tree plus every stable rule inlined, for tools that cannot lazy-load.
- `INDEX.md`, `index.json`, `llms.txt` index the same rules for agents and the web (`CONVENTIONS/SPECS/ORIGINAL/INDEX-MD.md`, `CONVENTIONS/SPECS/THIRD-PARTY/LLMS-TXT.md`).
