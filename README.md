<div align="center">

# CONVENTIONS.md

**One set of rules for humans and AI agents, built into every format that agent tools read.**

```sh
git clone https://github.com/Szmelc-INC/CONVENTIONS.md ~/.config/szmelc/conventions && ~/.config/szmelc/conventions/install.sh
```

[![CI status](https://img.shields.io/github/actions/workflow/status/Szmelc-INC/CONVENTIONS.md/check.yml?branch=main&label=check&logo=githubactions&logoColor=white)](https://github.com/Szmelc-INC/CONVENTIONS.md/actions/workflows/check.yml)
[![Latest release](https://img.shields.io/github/v/release/Szmelc-INC/CONVENTIONS.md?logo=github&color=105c5c)](https://github.com/Szmelc-INC/CONVENTIONS.md/releases/latest)
[![License: MIT](https://img.shields.io/github/license/Szmelc-INC/CONVENTIONS.md?logo=opensourceinitiative&logoColor=white&color=105c5c)](LICENSE)
[![Live site](https://img.shields.io/website?url=https%3A%2F%2Fszmelc-inc.github.io%2FCONVENTIONS.md%2F&label=site&logo=githubpages&logoColor=white&up_color=105c5c&up_message=live)](https://szmelc-inc.github.io/CONVENTIONS.md/)

<a href="https://szmelc-inc.github.io/CONVENTIONS.md/"><img src="META/assets/screenshots/hero-dark.png" width="900" alt="The CONVENTIONS.md site: title, By Szmelc™, the Compatible with carousel and the tabs for each core"></a>

<sub>Live site: <a href="https://szmelc-inc.github.io/CONVENTIONS.md/">szmelc-inc.github.io/CONVENTIONS.md</a> · made by <a href="https://github.com/Szmelc-INC">Szmelc™</a></sub>

</div>

<details>
<summary><b>More screenshots</b> (click to expand)</summary>
<br>
<table>
<tr>
<td align="center" width="50%"><img src="META/assets/screenshots/menu.png" alt="The [MENU] list: install, star, contribute, links, share, theme and keys"><br><sub>[MENU]</sub></td>
<td align="center" width="50%"><img src="META/assets/screenshots/projects.png" alt="The Projects tab with the All, Third-party and Szmelc™ filters"><br><sub>Projects</sub></td>
</tr>
<tr>
<td align="center"><img src="META/assets/screenshots/popup-about.png" alt="The About Szmelc™ popup with Shields.io badges"><br><sub>About popup</sub></td>
<td align="center"><img src="META/assets/screenshots/mobile.png" width="220" alt="The site on a phone screen, 390 px wide"><br><sub>Phone</sub></td>
</tr>
</table>
</details>

## Usage
### Install
```sh
git clone https://github.com/Szmelc-INC/CONVENTIONS.md ~/.config/szmelc/conventions
~/.config/szmelc/conventions/install.sh
```
Harness table, flags and per-project setup: [`HUMANS/README.md`](HUMANS/README.md). Agents read [`INDEX.md`](INDEX.md) once, then load only the rule files that match the task.

### Live site
[szmelc-inc.github.io/CONVENTIONS.md](https://szmelc-inc.github.io/CONVENTIONS.md/), built by [`META/tools/site.sh`](META/tools/site.sh) and deployed to GitHub Pages nightly and on pushes to `main` that change its sources.
- Tabs: one per core with its guide and nested category groups; every rule readable inline, copyable as Markdown or a raw URL.
- Projects tab: public Szmelc™ repositories from the GitHub API (owners in [`SZMELC/sources.conf`](SZMELC/sources.conf)) and the third-party projects from the compatibility registry, with `All · Third-party · Szmelc™` sub-tabs; experimental proposals and the legacy archive.
- "Compatible with" carousel under the title; click an entry for its popup, or `Compatible with [N] conventions` for the full list.
- `[MENU]`: install, star count, contribute, issues, GitHub, releases, discussions, About Szmelc™, share, theme, keys.
- Themes: dark (default), light, mono, terminal; saved per browser, `?theme=<name>` overrides.
- Keys: `/` filter, `1`–`9` and `0` tabs, `e` expand all, `t` theme, `?` keys list, `esc` close or clear.
- Deep links: `#<core>`, `#<core>/<category>/`, `#<path>`, `#projects`, and popups `#install`, `#about`, `#compat`, `#compat/<id>`.

## Compatible with
31 third-party formats, specs, platforms, languages and tools (AGENTS.md, Agent Skills, CLAUDE.md, llms.txt, MCP, Keep a Changelog, SemVer, Shields.io and more): [`COMPATIBILITY.md`](COMPATIBILITY.md), generated from [`META/compat/registry.toml`](META/compat/registry.toml). Names and logos are trademarks of their respective owners; Szmelc™ is not affiliated with them.

## How it works
### Cores
Seven top-level categories. Each is a directory `X/` with a full guide `X/README.md`, mapped by a root file `X.md`.

| Map | Directory | What |
|---|---|---|
| [`CONVENTIONS.md`](CONVENTIONS.md) | [`CONVENTIONS/`](CONVENTIONS/README.md) | The rules: workflow, GitHub, specs, repo, design, interfaces, packaging, code; experimental proposals and legacy archive |
| [`AGENTS.md`](AGENTS.md) | [`AGENTS/`](AGENTS/README.md) | Always-on global rules, agent behaviour rules, prompt engineering, skills, tool adapters |
| [`HUMANS.md`](HUMANS.md) | [`HUMANS/`](HUMANS/README.md) | Install, browse |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | [`CONTRIBUTING/`](CONTRIBUTING/README.md) | Extend, write, name, version and ship conventions |
| [`SZMELC.md`](SZMELC.md) | [`SZMELC/`](SZMELC/README.md) | Public organisations, sites, principles, projects index sources |
| [`META.md`](META.md) | [`META/`](META/README.md) | Build/check tools, site generator, schema, compatibility registry, screenshots |
| [`TEMPLATES.md`](TEMPLATES.md) | [`TEMPLATES/`](TEMPLATES/README.md) | Skeletons for rules, prompts, skills, category READMEs, project `AGENTS.md` |

### Layout
```
SKILL.md            meta skill: entry point + format map (installed as skill `szmelc-conventions`)
INDEX.md            map: every file + when to load it (agents read only this first)   [generated]
index.json          same, machine-readable (META/schema/index.schema.json)             [generated]
llms.txt            llmstxt.org index                                                   [generated]
CONVENTIONS.md      map of CONVENTIONS/ + every stable rule in one file                 [generated]
AGENTS.md           instructions for agents in this repo + map of AGENTS/               [map block generated]
HUMANS.md CONTRIBUTING.md SZMELC.md META.md TEMPLATES.md   core maps                    [generated]
COMPATIBILITY.md    compatible third-party formats, specs and tools (META/compat/)     [generated]
CLAUDE.md GEMINI.md import AGENTS.md for agents working on this repo
CONVENTIONS/        rules by UPPERCASE category; EXPERIMENTAL/ proposals, LEGACY/ archive
AGENTS/             global/AGENTS.md, RULES/, PROMPT/, skills/, adapters/ [generated]
HUMANS/             human guide
CONTRIBUTING/       how to extend the conventions (root CONTRIBUTING.md = its map; GitHub shows it on issues/PRs)
SZMELC/             organisation guide, sources.conf (projects index)
META/               tools/, schema/, compat/ (compatibility registry + icons), assets/screenshots/
TEMPLATES/          skeletons (rule, prompt, skill, category README, project AGENTS.md)
install.sh          harness installer
CHANGELOG.md        release history (Keep a Changelog)
LICENSE             MIT
.github/            workflows, issue forms, PR template, release notes config, labels.tsv, SECURITY.md
claude/             compatibility symlinks for pre-1.0 install paths
public/             generated site (GitHub Pages); built in CI, never committed         [generated]
```

### Automation
- CI (`.github/workflows/check.yml`): `META/tools/check.sh`, ShellCheck, `META/tools/test-install.sh`, and the branch-prefix scope check `META/tools/lane-check.sh`.
- Pages (`.github/workflows/pages.yml`): builds and deploys the site on pushes to `main` that touch its sources and nightly at 03:00 UTC to refresh the Projects index.
- Keepalive (job `keepalive` in `pages.yml`): after ~45 quiet days re-enables `pages.yml` via the API so the nightly refresh stays scheduled; never pushes. Nothing bypasses the `main` ruleset (`META/tools/github-setup.sh`). Disabled anyway: `gh workflow enable pages.yml`.
- Dependabot: weekly grouped GitHub Actions updates as normal PRs (`.github/dependabot.yml`).
- Releases: pushing a `vX.Y.Z` tag runs `.github/workflows/release.yml` → `META/tools/release.sh` (`CHANGELOG.md`, `CONTRIBUTING/VERSIONING.md`).

## Contributing
Guide: [`CONTRIBUTING/README.md`](CONTRIBUTING/README.md).

### Branches
`main` is the only long-lived branch; no direct commits. Every change is a short-lived `feat/*`, `fix/*`, `docs/*`, `chore/*`, `experimental/*` or `legacy/*` branch, PR'd into `main`, merged with `gh pr merge --rebase --delete-branch`, then `git checkout main && git pull --ff-only`. Every commit on the branch lands on `main`, so each must be clean and conventional. Details: [`CONVENTIONS/WORKFLOW/BRANCHES.md`](CONVENTIONS/WORKFLOW/BRANCHES.md).

### Rules of this repo
1. One topic = one file. One rule = one line.
2. Every rule file and core `README.md` starts with `# Title` and `> Load when: <trigger>`.
3. Never duplicate a rule; reference it by path (`CONVENTIONS/DESIGN/COLORS.md`).
4. Never edit generated files. Run `META/tools/build.sh`, then `META/tools/check.sh` (CI runs both).
5. New domain → new UPPERCASE directory in a core. New topic → copy `TEMPLATES/rule.md`; format and naming in `CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md`. New core → directory + `README.md`, then add it to `CORES` in `META/tools/build.sh`, `META/tools/check.sh` and `META/tools/site.sh`.
6. Agents load rules lazily: `INDEX.md` once, then only matching files. Never `@import` rule files into global instructions; that loads every rule every session.
7. Public repo: only already-public material (public repos, orgs, sites).

## License
[MIT](LICENSE)
