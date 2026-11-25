# CONVENTIONS.md
>[![check](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/check.yml/badge.svg)](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/check.yml)
>[![pages](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/pages.yml/badge.svg)](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/pages.yml)
>[![browse](https://img.shields.io/badge/browse-conventions-105c5c)](https://szmelc-inc.github.io/CONVENTIONS.md/)
>[![License: MIT](https://img.shields.io/badge/license-MIT-105c5c.svg)](LICENSE)
>[![Agent Skill](https://img.shields.io/badge/SKILL.md-szmelc--conventions-105c5c.svg)](SKILL.md)
>[![AGENTS.md](https://img.shields.io/badge/AGENTS.md-compatible-105c5c.svg)](AGENTS/global/AGENTS.md)
>
> Global Conventions.md for everything, for Humans & AI agents. One source, every format like: \
> Agent Skill, `AGENTS.md`/`CLAUDE.md`/`GEMINI.md`/`QWEN.md` + `SKILL.md`/`MCP.md`/`PLUGIN.md` and so on. \
> All Rules, instructions, templates, formats and agreed upon schemes to make it maximally universal, deterministic, logic and parseable.
> Extras like documentation for LLM's: `llms.txt`, JSON index, and a single-file bundle.  (+ and all modern formats & rules.)
>
> ---
>
> ### [CONVENTIONS.md](https://Szmelc-INC.github.io/CONVENTIONS.md/) ~ Live WebUI on GitHub via Deployments on `github-pages`
> <img width="1193" height="911" alt="image" src="https://github.com/user-attachments/assets/ebafa0a5-e165-402e-b1af-b1dc720286ed" />
>
> ---
>
> Same idea but much more ***meta***:tm: and for basically everything makes it a unified universal "one convention to rule them all"! \
> Same logic for everything, from `/SZMELC.md` (with categories/subcategories like `/SZMELC/README.md`, \
> (index cats/sub-cats of SZMELC, same but for szmelc team etc: `/SZMELC/TEAM/README.md` 


## Cores
Six top-level categories. Each is a directory `X/` with a full guide `X/README.md`, mapped by a root file `X.md`.

| Map | Directory | What |
|---|---|---|
| [`CONVENTIONS.md`](CONVENTIONS.md) | [`CONVENTIONS/`](CONVENTIONS/README.md) | The rules: workflow, GitHub, specs, repo, design, interfaces, packaging, code; experimental proposals and legacy archive |
| [`AGENTS.md`](AGENTS.md) | [`AGENTS/`](AGENTS/README.md) | Always-on global rules, skills, tool adapters, agent-file rules |
| [`HUMANS.md`](HUMANS.md) | [`HUMANS/`](HUMANS/README.md) | Install, browse |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | [`CONTRIBUTING/`](CONTRIBUTING/README.md) | Extend, write, name, version and ship conventions |
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
HUMANS.md CONTRIBUTING.md SZMELC.md META.md   core maps                                                 [generated]
CONVENTIONS/        rules by UPPERCASE category; EXPERIMENTAL/ proposals, LEGACY/ archive
AGENTS/             global/AGENTS.md, RULES/, skills/, adapters/ [generated]
HUMANS/             human guide
CONTRIBUTING/       how to extend the conventions (root CONTRIBUTING.md = its map; GitHub shows it on issues/PRs)
SZMELC/             organisation guide, sources.conf (projects index)
META/               tools/, schema/, templates/
install.sh          harness installer
claude/             compatibility symlinks for pre-1.0 install paths
public/             generated site (GitHub Pages); built in CI, never committed         [generated]
```
`CLAUDE.md` / `GEMINI.md` at the root import `AGENTS.md` for agents working on this repo.

## Branches
`main` is the only long-lived branch. Every change is a short-lived `feat/*`, `fix/*`, `docs/*`, `chore/*`, `experimental/*` or `legacy/*` branch, PR'd into `main` and deleted after merge. Details: `CONVENTIONS/WORKFLOW/BRANCHES.md`.

## Rules of this repo
1. One topic = one file. One rule = one line.
2. Every rule file and core `README.md` starts with `# Title` and `> Load when: <trigger>`.
3. Never duplicate a rule; reference it by path (`CONVENTIONS/DESIGN/COLORS.md`).
4. Never edit generated files. Run `META/tools/build.sh`, then `META/tools/check.sh` (CI runs both).
5. New domain → new UPPERCASE directory in a core. New topic → copy `META/templates/rule.md`; naming in `CONTRIBUTING/README.md`. New core → directory + `README.md`, then add it to `CORES` in `META/tools/build.sh`.
6. Agents load rules lazily: `INDEX.md` once, then only matching files. Never `@import` rule files into global instructions; that loads every rule every session.
7. Public repo: only already-public material (public repos, orgs, sites).

## License
MIT
