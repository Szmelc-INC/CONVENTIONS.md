# Changelog

All notable changes to the conventions are documented here. Format: [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/); versioning: `CONTRIBUTING/VERSIONING.md`. Before the first tag the repo was unversioned (1.x).

## [Unreleased]

Planned as 2.0.0: rule paths were renamed (major).

### Changed

- Breaking: categories are UPPERCASE directories under `CONVENTIONS/` (workflow/ → `CONVENTIONS/WORKFLOW/`, design/ → `CONVENTIONS/DESIGN/`, …) and rule files are UPPERCASE kebab (`CONVENTIONS/GITHUB/RELEASES/TAGS.md`, `CONVENTIONS/SPECS/THIRD-PARTY/LLMS-TXT.md`); update pinned paths and re-run `install.sh`.
- Breaking: document-format rules split into `CONVENTIONS/SPECS/THIRD-PARTY/` (AGENTS.md, SKILL.md, CHANGELOG.md, SECURITY.md, …) and `CONVENTIONS/SPECS/ORIGINAL/` (Szmelc formats).
- Six cores at the root: `CONVENTIONS/`, `AGENTS/`, `HUMANS/`, `CONTRIBUTING/`, `SZMELC/`, `META/`, each with a generated root map.

### Added

- Site: `[MENU]` in the top-right corner (star, install, theme, every index link) replaces the link row and theme button under the title; the intro and install command move into a reusable modal (native `<dialog>`, vignette backdrop, deep link `#install`); the title grows ~37% with a `❯` prompt and stays on one line down to 320px; `esc` closes menu or modal before clearing the filter. `CONVENTIONS/GITHUB/DEPLOYMENTS/WEBUI-STYLE.md` documents the menu and modal.
- Site layout: centered navbar (large title, centered link row with the theme toggle, full-width tabs and filter directly below); intro moves into a panel under the toolbar, byline into the footer.
- Site readability: layered shade ramps (surfaces, lines, text, accent and danger shades) with framed category panels, sunken reading wells and larger type; sticky tab and filter toolbar; filter hits highlighted and counted; skip link, arrow-key tabs, `prefers-contrast` and `forced-colors` support. Link text moves to `#34a3a3` and danger text to `#dc6464` for WCAG AA on raised surfaces. `CONVENTIONS/DESIGN/COLORS.md` gains the ramps.
- Site: nested category groups with a category index, themes (dark, light, mono, terminal; key `t`), inline SVG icons, copyable prompts, link row (release, `llms.txt`, `index.json`, `INDEX.md`, `CONVENTIONS.md`, `SKILL.md`, Discussions, roadmap while its project is public); the index files are served from the site root, so `llms.txt` no longer 404s. `CONVENTIONS/GITHUB/DEPLOYMENTS/WEBUI-STYLE.md` describes the theme set.
- `CONVENTIONS/GITHUB/`: repo settings, labels, metadata, pull requests, issues, discussions, projects, wiki, code security, organizations, coding agents.
- `CONVENTIONS/GITHUB/ACTIONS/` (workflows, CI), `CONVENTIONS/GITHUB/RELEASES/` (versioning, tags, automation, channels), `CONVENTIONS/GITHUB/DEPLOYMENTS/` (environments, Pages, WebUI style).
- `CONVENTIONS/FORMATS/` and `CONVENTIONS/SYSTEMS/` categories.
- `AGENTS/PROMPT/`: prompt engineering 101, rules for writing, classifying, testing and checking prompts and agent briefs, a paste-ready prompt library, and the skeleton `META/templates/prompt.md`.
- `CONTRIBUTING/` core: 101, DIY, writing, indexing, templates, versioning, lifecycle, prompts.
- This repo follows its own GitHub conventions: issue forms, PR template, labels as code (`META/tools/labels.sh`), settings and rulesets as code (`META/tools/github-setup.sh`), Dependabot for Actions, security policy, release workflow with bundle assets and `SHA256SUMS` (`META/tools/release.sh`).
- `CONVENTIONS/GITHUB/ACTIONS/CI.md`: scheduled workflows stay alive through an API re-enable keepalive, not a heartbeat commit; bots never bypass rulesets.

[Unreleased]: https://github.com/Szmelc-INC/CONVENTIONS.md/commits/main
