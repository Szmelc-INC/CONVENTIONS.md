# CONVENTIONS.md
[![check](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/check.yml/badge.svg)](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/check.yml)
[![pages](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/pages.yml/badge.svg)](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/pages.yml)
[![browse](https://img.shields.io/badge/browse-conventions-105c5c)](https://szmelc-inc.github.io/CONVENTIONS.md/)
[![License: MIT](https://img.shields.io/badge/license-MIT-105c5c.svg)](LICENSE)
[![Agent Skill](https://img.shields.io/badge/SKILL.md-szmelc--conventions-105c5c.svg)](SKILL.md)
[![AGENTS.md](https://img.shields.io/badge/AGENTS.md-compatible-105c5c.svg)](global/AGENTS.md)

Global Szmelc conventions for everything, for humans and AI agents. One source, every format: Agent Skill, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `QWEN.md`, Cursor/Copilot/Kiro rules, `llms.txt`, JSON index, and a single-file bundle.

Browse it all at **<https://szmelc-inc.github.io/CONVENTIONS.md/>** — a tab per category, filterable, with the Szmelc projects index alongside.

## Install
```sh
git clone https://github.com/Szmelc-INC/CONVENTIONS.md ~/.config/szmelc/conventions
~/.config/szmelc/conventions/install.sh status   # what would be linked
~/.config/szmelc/conventions/install.sh          # link into every detected harness
```
- Links global rules and the `szmelc-conventions` + `deep` skills into each harness found under `$HOME`. Existing files are moved to `*.bak.<timestamp>`, never overwritten; `install.sh uninstall` restores them.
- Pick harnesses: `--only claude,codex`. Preview: `--dry-run`. Into a project: `install.sh project <dir>`.
- Update: `git -C ~/.config/szmelc/conventions pull`. Old `~/.claude/conventions` clone → move it to the path above and re-run `install.sh`.

| Harness | Global rules | Skills root |
|---|---|---|
| Claude Code | `~/.claude/CLAUDE.md` | `~/.claude/skills` |
| Codex | `~/.codex/AGENTS.md` | `~/.codex/skills` |
| Gemini CLI / Antigravity | `~/.gemini/GEMINI.md` | `~/.gemini/config/skills` (unverified) |
| Qwen Code | `~/.qwen/QWEN.md` (unverified) | `~/.qwen/skills` |
| OpenCode | `~/.config/opencode/AGENTS.md` (unverified) | — |
| Kiro | `~/.kiro/steering/szmelc-conventions.md` | `~/.kiro/skills` |
| Windsurf | `~/.codeium/windsurf/memories/global_rules.md` (unverified) | — |
| Grok, jcode, `~/.agents` | — | `~/.grok/skills`, `~/.jcode/skills`, `~/.agents/skills` |
| Cursor, Copilot | per project: `install.sh project <dir>` | — |
| Aider, web chats | `aider --read CONVENTIONS.md`, or paste/upload `CONVENTIONS.md` | — |

## Layout
```
SKILL.md            meta skill: entry point + format map (installed as skill `szmelc-conventions`)
global/AGENTS.md    always-on rules; source of every global adapter
INDEX.md            map: every file + when to load it (agents read only this first)   [generated]
index.json          same, machine-readable (schema/index.schema.json)                  [generated]
llms.txt            llmstxt.org index                                                   [generated]
CONVENTIONS.md      every stable rule in one file, for tools that cannot lazy-load     [generated]
adapters/           Cursor .mdc, Copilot .instructions.md, Kiro steering               [generated]
<category>/<topic>.md   one topic per file: agents, design, interfaces, meta, packaging, workflow
skills/<name>/      extra skills (deep)
experimental/       opt-in proposals (branch lane `experimental`)
legacy/             superseded material, archived (branch lane `legacy`)
_template/          skeletons: rule.md, SKILL.md, project AGENTS.md
tools/              build.sh, check.sh, lane-check.sh, test-install.sh, site.sh
index/sources.conf  GitHub owners scanned for the site's Projects tab
public/             generated site (GitHub Pages); built in CI, never committed   [generated]
claude/             compatibility symlinks for pre-1.0 install paths
```
`AGENTS.md` / `CLAUDE.md` / `GEMINI.md` at the root are for agents working on this repo.

## Site

`tools/site.sh` renders `public/`: a single-page browser with one tab per category
(agents, design, interfaces, meta, packaging, workflow), then Skills, Experimental,
Legacy, and a **Projects** tab indexing every public Szmelc repo. Rule data comes from
the source `.md` files; the projects list comes from the GitHub API over
[`index/sources.conf`](index/sources.conf), so the same build reproduces in CI and
locally. Dark by default with a light toggle, `/` to filter, hash deep-links (`#design`).

The `pages` workflow rebuilds and deploys to GitHub Pages on every push to `main`,
nightly (to refresh the projects index as repos change), and on demand. `public/` is
gitignored — it is a build artifact, never committed, so it never makes `check.sh` stale.
Build it yourself with `tools/site.sh` (needs `jq`; `gh` for the projects list).

## Branches
`main` is the current truth. Changes arrive by PR from the lanes `testing` (stable changes), `experimental` (proposals) and `legacy` (archive). Details: `workflow/branches.md`.

## Rules of this repo
1. One topic = one file. One rule = one line.
2. Every rule file starts with `# Title` and `> Load when: <trigger>`.
3. Never duplicate a rule; reference it by path (`design/colors.md`).
4. Never edit generated files. Run `tools/build.sh`, then `tools/check.sh` (CI runs both).
5. New domain → new directory. New topic → copy `_template/rule.md`.
6. Agents load rules lazily: `INDEX.md` once, then only matching files. Never `@import` rule files into global instructions; that loads every rule every session.

## License
MIT
