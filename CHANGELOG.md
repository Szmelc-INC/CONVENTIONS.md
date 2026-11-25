# Changelog

All notable changes to the conventions are documented here. Format: [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/); versioning: `CONTRIBUTING/VERSIONING.md`. Before the first tag the repo was unversioned (1.x).

## [Unreleased]

Planned as 2.0.0: rule paths were renamed (major).

### Changed

- Breaking: categories are UPPERCASE directories under `CONVENTIONS/` (workflow/ → `CONVENTIONS/WORKFLOW/`, design/ → `CONVENTIONS/DESIGN/`, …) and rule files are UPPERCASE kebab (`CONVENTIONS/GITHUB/RELEASES/TAGS.md`, `CONVENTIONS/SPECS/THIRD-PARTY/LLMS-TXT.md`); update pinned paths and re-run `install.sh`.
- Breaking: document-format rules split into `CONVENTIONS/SPECS/THIRD-PARTY/` (AGENTS.md, SKILL.md, CHANGELOG.md, SECURITY.md, …) and `CONVENTIONS/SPECS/ORIGINAL/` (Szmelc formats).
- Six cores at the root: `CONVENTIONS/`, `AGENTS/`, `HUMANS/`, `CONTRIBUTING/`, `SZMELC/`, `META/`, each with a generated root map.

### Added

- `CONVENTIONS/GITHUB/`: repo settings, labels, metadata, pull requests, issues, discussions, projects, wiki, code security, organizations, coding agents.
- `CONVENTIONS/GITHUB/ACTIONS/` (workflows, CI), `CONVENTIONS/GITHUB/RELEASES/` (versioning, tags, automation, channels), `CONVENTIONS/GITHUB/DEPLOYMENTS/` (environments, Pages, WebUI style).
- `CONVENTIONS/FORMATS/` and `CONVENTIONS/SYSTEMS/` categories.
- `CONTRIBUTING/` core: 101, DIY, writing, indexing, templates, versioning, lifecycle, prompts.
- This repo follows its own GitHub conventions: issue forms, PR template, labels as code (`META/tools/labels.sh`), settings and rulesets as code (`META/tools/github-setup.sh`), Dependabot for Actions, security policy, release workflow with bundle assets and `SHA256SUMS` (`META/tools/release.sh`).

[Unreleased]: https://github.com/Szmelc-INC/CONVENTIONS.md/commits/main
