# CONVENTIONS.md
[![check](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/check.yml/badge.svg)](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/check.yml)
[![pages](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/pages.yml/badge.svg)](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/pages.yml)
[![browse](https://img.shields.io/badge/browse-conventions-105c5c)](https://szmelc-inc.github.io/CONVENTIONS.md/)
[![License: MIT](https://img.shields.io/badge/license-MIT-105c5c.svg)](LICENSE)
[![Agent Skill](https://img.shields.io/badge/SKILL.md-szmelc--conventions-105c5c.svg)](SKILL.md)
[![AGENTS.md](https://img.shields.io/badge/AGENTS.md-compatible-105c5c.svg)](AGENTS/global/AGENTS.md)

Global Szmelc conventions for everything, for humans and AI agents. One source, every format: Agent Skill, `AGENTS.md`, `CLAUDE.md`, `GEMINI.md`, `QWEN.md`, Cursor/Copilot/Kiro rules, `llms.txt`, JSON index, and a single-file bundle.

Browse it all at **<https://szmelc-inc.github.io/CONVENTIONS.md/>**.

## Cores
Five top-level categories. Each is a directory `X/` with a full guide `X/README.md`, mapped by a root file `X.md`.

| Map | Directory | What |
|---|---|---|
| [`CONVENTIONS.md`](CONVENTIONS.md) | [`CONVENTIONS/`](CONVENTIONS/README.md) | The rules: workflow, design, interfaces, packaging, code; experimental proposals and legacy archive |
| [`AGENTS.md`](AGENTS.md) | [`AGENTS/`](AGENTS/README.md) | Always-on global rules, skills, tool adapters, agent-file rules |
| [`HUMANS.md`](HUMANS.md) | [`HUMANS/`](HUMANS/README.md) | Install, browse, contribute |
| [`SZMELC.md`](SZMELC.md) | [`SZMELC/`](SZMELC/README.md) | Public organisations, sites, principles, projects index sources |
| [`META.md`](META.md) | [`META/`](META/README.md) | Build/check tools, site generator, schema, templates |

## Install
```sh
git clone https://github.com/Szmelc-INC/CONVENTIONS.md ~/.config/szmelc/conventions
~/.config/szmelc/conventions/install.sh
```
Harness table, flags and per-project setup: [`HUMANS/README.md`](HUMANS/README.md).

## Layout
```
SKILL.md            meta skill: entry point + format map (installed as skill `szmelc-conventions`)
INDEX.md            map: every file + when to load it (agents read only this first)   [generated]
index.json          same, machine-readable (META/schema/index.schema.json)             [generated]
llms.txt            llmstxt.org index                                                   [generated]
CONVENTIONS.md      map of CONVENTIONS/ + every stable rule in one file                 [generated]
AGENTS.md           instructions for agents in this repo + map of AGENTS/               [map block generated]
HUMANS.md SZMELC.md META.md   core maps                                                 [generated]
CONVENTIONS/        rules by category; experimental/ proposals, legacy/ archive
AGENTS/             global/AGENTS.md, rules/, skills/, adapters/ [generated]
HUMANS/             human guide
SZMELC/             organisation guide, sources.conf (projects index)
META/               tools/, schema/, templates/
install.sh          harness installer
claude/             compatibility symlinks for pre-1.0 install paths
public/             generated site (GitHub Pages); built in CI, never committed         [generated]
```
`CLAUDE.md` / `GEMINI.md` at the root import `AGENTS.md` for agents working on this repo.

## Branches
`main` is the only long-lived branch. Every change is a short-lived `feat/*`, `fix/*`, `docs/*`, `chore/*`, `experimental/*` or `legacy/*` branch, PR'd into `main` and deleted after merge. Details: `CONVENTIONS/workflow/branches.md`.

## Rules of this repo
1. One topic = one file. One rule = one line.
2. Every rule file and core `README.md` starts with `# Title` and `> Load when: <trigger>`.
3. Never duplicate a rule; reference it by path (`CONVENTIONS/design/colors.md`).
4. Never edit generated files. Run `META/tools/build.sh`, then `META/tools/check.sh` (CI runs both).
5. New domain → new directory in a core. New topic → copy `META/templates/rule.md`. New core → directory + `README.md`, then add it to `CORES` in `META/tools/build.sh`.
6. Agents load rules lazily: `INDEX.md` once, then only matching files. Never `@import` rule files into global instructions; that loads every rule every session.
7. Public repo: only already-public material (public repos, orgs, sites).

## License
MIT
