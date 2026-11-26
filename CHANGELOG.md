# Changelog

All notable changes to the conventions are documented here. Format: [Keep a Changelog 1.1](https://keepachangelog.com/en/1.1.0/); versioning: `CONTRIBUTING/VERSIONING.md`. Before the first tag the repo was unversioned (1.x).

<!-- markdownlint-disable MD024 -->

## [Unreleased]

## [3.1.0] - 2026-11-26

### Added

- Conventions Format 1.0: normative spec, schemas, conformance fixtures, validator, migration guide, interop compiler, and minimal adopter example.
- Opt-in rule-ID bundles for review, research and release modes, and English-canonical locale companions for rules.
- Repository support routes and the inbound MIT, no-CLA contribution policy.

### Changed

- Split Web UI guidance into theme, layout, components and accessibility rules, while preserving the legacy rule ID.
- Apply the STE100++ prose pass to hand-written documentation.

### Security and release integrity

- Pin workflow actions to full commit SHAs, limit workflow permissions, and check schema conformance, dependencies, and release dry runs in CI.
- Require signed release tags and attest release asset provenance.

## [3.0.0] - 2026-11-26

The neutral core and profile-aware installation contract are now stable.

### Breaking

- Rule paths and the install contract changed. The six neutral cores replace the former identity-specific core, and Szmelc™ identity data and project discovery now live under `PROFILES/szmelc/`.
- Re-run `install.sh` after upgrading. Existing global instruction files are preserved; the installer manages only its marked block unless `--replace` is requested. See [`MIGRATION-v2-to-v3.md`](MIGRATION-v2-to-v3.md).

### Added

- Stable rule IDs, profile-aware rendering and installation, layered profile overlays, and the neutral and Szmelc™ profiles.
- A v2-to-v3 migration guide, profile template, profile request issue form, site profile switcher, and v2 compatibility snapshot checks.
- Community governance files, contribution guidance, and weekly issue triage automation.

### Changed

- The default profile now uses the user's language and does not prescribe a privilege tool or color palette.
- The skill is now named `conventions`; the old `szmelc-conventions` name remains as a one-major-version alias.

### Added

- `CONVENTIONS/REPO/DOCS.md`: docs structure (hook + payoff, "Start here" table, annotated tree, install options, concept + minimal example, limits as numbers).
- `AGENTS/PROMPT/DOCS-VOICE.md`: docs voice profile from an analysis of the everything-claude-code README (six pillars, keep/reject table, Voice Card, agent prompt block).
- `TEMPLATES/project-README.md`: project README skeleton that follows `CONVENTIONS/REPO/DOCS.md`.

### Changed

- `CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`: full section order, no star calls or `(NEW)` markers. `CONVENTIONS/REPO/WRITING.md`: no claim words, no bold lead-ins.
- `AGENTS/RULES/MEMORY.md`: agent memory rules derived from the public #memory developer docs: one fact per memory, cue keywords, stable refs, stale-write skip, least-privilege grants, confirmed deletes, cited recall.

### Added

- STE100++ controlled writing (inspired by ASD-STE100, not certified): rule `CONVENTIONS/REPO/STE100PP.md`, skill `AGENTS/skills/ste100pp/` with procedures, error messages, help text, numbers and hedges, and a natively written `pl` companion. Scope: prose; rule one-liners are exempt.
- Web UI blueprint, extracted from the project's own Pages site: `CONVENTIONS/INTERFACES/WEBUI/` (`ARCHITECTURE.md`, `ROUTING.md`, `OVERLAYS.md`, `KEYBOARD.md`) and the starter `TEMPLATES/webui.html` (inlined data, hash router with transient overlay routes, one `<dialog>`, menu disclosure, gated keymap, theme before first paint).

## [2.0.2] - 2026-11-26

Governance and roadmap; no rule path, schema or install change.

### Added

- README: Roadmap section that links the pinned roadmap issue #49 (10 stage sub-issues with milestones), the Development discussion #60 and the Integrations discussion #61.
- Maintainer review gate for outside PRs: required status `review-gate` (`.github/workflows/review-gate.yml`, `META/tools/review-gate.sh` with `--self-test` in CI) passes maintainer PRs, and other PRs only after a maintainer approves the head commit; `review-signal.yml` wakes it on review changes; `.github/CODEOWNERS` requests the review.
- `META/tools/github-setup.sh`: `review-gate` required on `main`, fork PR workflows need approval for all outside contributors, ruleset keeps `require_extra_approval_for_unattributed_changes`.
- Rules: `CONVENTIONS/GITHUB/REPO/SETTINGS.md` (review gate, fork approval), `CONVENTIONS/GITHUB/PULL-REQUESTS.md` (agents never approve or merge non-maintainer PRs).

### Changed

- README and `CONTRIBUTING/README.md`: contributors fork; the maintainer reviews and merges.

## [2.0.1] - 2026-11-26

README rewrite and roadmap setup; no rule path, schema or install change.

### Changed

- README: centered header with four badges and the main screenshot, collapsible gallery, short what-it-is, install, update and browse sections, plain compatible-with section, short cores table, build note, collapsible file layout, automation, contributing as numbered steps, simpler repo rules, license line.

### Added

- Label `roadmap` (`.github/labels.tsv`) for the pinned roadmap issue and its stage sub-issues (`CONVENTIONS/GITHUB/ISSUES.md`).

## [2.0.0] - 2026-11-26

First tagged release. Rule paths were renamed (major); see Changed first.

### Changed

- Merge policy: rebase-merge only (`gh pr merge --rebase --delete-branch`, then `git pull --ff-only`); squash and merge commits disabled in repo settings and the `main` ruleset (`CONVENTIONS/GITHUB/REPO/SETTINGS.md`, `CONVENTIONS/WORKFLOW/BRANCHES.md`, `META/tools/github-setup.sh`).
- Site: Experimental and Legacy tabs merged into Projects (experimental groups in deep red, legacy in muted grey-green); `#experimental` and `#legacy` deep links open Projects.
- Brand written as Szmelc™ in all human-readable text; the origin label `Szmelc original` became `Szmelc™`.
- Breaking: categories are UPPERCASE directories under `CONVENTIONS/` (workflow/ → `CONVENTIONS/WORKFLOW/`, design/ → `CONVENTIONS/DESIGN/`, …) and rule files are UPPERCASE kebab (`CONVENTIONS/GITHUB/RELEASES/TAGS.md`, `CONVENTIONS/SPECS/THIRD-PARTY/LLMS-TXT.md`); update pinned paths and re-run `install.sh`.
- Breaking: document-format rules split into `CONVENTIONS/SPECS/THIRD-PARTY/` (AGENTS.md, SKILL.md, CHANGELOG.md, SECURITY.md, …) and `CONVENTIONS/SPECS/ORIGINAL/` (Szmelc formats).
- Seven cores at the root: `CONVENTIONS/`, `AGENTS/`, `HUMANS/`, `CONTRIBUTING/`, `SZMELC/`, `META/`, `TEMPLATES/`, each with a generated root map.
- Breaking: skeletons moved from META/templates/ to the `TEMPLATES/` core; the catalogue CONTRIBUTING/TEMPLATES.md became `TEMPLATES/README.md`.

### Added

- Site [MENU] in three groups (Install / use, Star on GitHub [N], Contribute, Report an issue · GitHub, Releases, Discussions, About Szmelc™ · Share, Theme [name], Keys & Shortcuts); it stays open on item activation; index files moved to the footer; the star count is built in and refreshed live.
- Site: universal Share (`navigator.share`, else a popup with copy link and share links); `Keys & Shortcuts` popup (key `?`).
- Site: `By Szmelc™` signature under the title opens an About popup with Shields.io badges (deep link `#about`); `Compatible with [N] conventions` label under the carousel opens the full list (deep link `#compat`).
- Site: Projects tab lists every Szmelc™ account from `SZMELC/sources.conf` (Szmelc-INC, sernik77, Entropy-Linux, SZYCHTA, Szmelc-OS) as Szmelc™ and a third-party table built from the compatibility registry; `sources.conf` gains a `third-party <owner/name>` directive.
- Site: centered bracketed footer (`[ EOF ]`, `[files]` and `[szmelc™]` link groups, stats, keys, fine print).
- Compatibility registry: Simple Icons, Shields.io, Awesome Badges and Awesome (awesome lists); rule `CONVENTIONS/SPECS/THIRD-PARTY/AWESOME-LIST.md`; badges are Shields.io with Simple Icons logos (`CONVENTIONS/SPECS/THIRD-PARTY/README-MD.md`).
- Site: "Compatible with" carousel under the title (registry icons inlined as `currentColor` paths, monograms otherwise; rAF glide that eases to a stop on hover, focus or touch, manual scroll with seamless wrap, static under reduced motion) and a popup per entry (version, versioning note, dates, covering rules, official links, disclaimer; deep link `#compat/<id>`); origin sub-tabs `All · Third-party · Szmelc original` with row badges and registry chips; TEMPLATES tab icon; key `0` for the 10th tab; `COMPATIBILITY.md` in `[MENU]`; the install command wraps instead of clipping.
- Compatibility registry: `META/compat/registry.toml` (TOML, one record per third-party format, spec, platform, language or tool: version, dates, official links, icon, covering rules) generates `COMPATIBILITY.md` and `index.json` `compatible` with a trademark disclaimer; monochrome CC0 Simple Icons in `META/compat/icons/`; `META/tools/check.sh` validates it.
- `origin` (`third-party` / `original`) on `index.json` entries and site rules, derived from the path; third-party specs carry the `compat` ids of the registry entries that cite them.
- `TEMPLATES/` core with root map `TEMPLATES.md`; the site gains a TEMPLATES tab.
- Site: inlined data escapes every `<`, so no rule text can close the data block.
- Site: `[MENU]` in the top-right corner (star, install, theme, every index link) replaces the link row and theme button under the title; the intro and install command move into a reusable modal (native `<dialog>`, vignette backdrop, deep link `#install`); the title grows ~37% with a `❯` prompt and stays on one line down to 320px; `esc` closes menu or modal before clearing the filter. `CONVENTIONS/GITHUB/DEPLOYMENTS/WEBUI-STYLE.md` documents the menu and modal.
- Site layout: centered navbar (large title, centered link row with the theme toggle, full-width tabs and filter directly below); intro moves into a panel under the toolbar, byline into the footer.
- Site readability: layered shade ramps (surfaces, lines, text, accent and danger shades) with framed category panels, sunken reading wells and larger type; sticky tab and filter toolbar; filter hits highlighted and counted; skip link, arrow-key tabs, `prefers-contrast` and `forced-colors` support. Link text moves to `#34a3a3` and danger text to `#dc6464` for WCAG AA on raised surfaces. `CONVENTIONS/DESIGN/COLORS.md` gains the ramps.
- Site: nested category groups with a category index, themes (dark, light, mono, terminal; key `t`), inline SVG icons, copyable prompts, link row (release, `llms.txt`, `index.json`, `INDEX.md`, `CONVENTIONS.md`, `SKILL.md`, Discussions, roadmap while its project is public); the index files are served from the site root, so `llms.txt` no longer 404s. `CONVENTIONS/GITHUB/DEPLOYMENTS/WEBUI-STYLE.md` describes the theme set.
- `CONVENTIONS/GITHUB/`: repo settings, labels, metadata, pull requests, issues, discussions, projects, wiki, code security, organizations, coding agents.
- `CONVENTIONS/GITHUB/ACTIONS/` (workflows, CI), `CONVENTIONS/GITHUB/RELEASES/` (versioning, tags, automation, channels), `CONVENTIONS/GITHUB/DEPLOYMENTS/` (environments, Pages, WebUI style).
- `CONVENTIONS/FORMATS/` and `CONVENTIONS/SYSTEMS/` categories.
- `AGENTS/PROMPT/`: prompt engineering 101, rules for writing, classifying, testing and checking prompts and agent briefs, a paste-ready prompt library, and the skeleton `TEMPLATES/prompt.md`.
- `CONTRIBUTING/` core: 101, DIY, writing, indexing, versioning, lifecycle, prompts.
- This repo follows its own GitHub conventions: issue forms, PR template, labels as code (`META/tools/labels.sh`), settings and rulesets as code (`META/tools/github-setup.sh`), Dependabot for Actions, security policy, release workflow with bundle assets and `SHA256SUMS` (`META/tools/release.sh`).
- `CONVENTIONS/GITHUB/ACTIONS/CI.md`: scheduled workflows stay alive through an API re-enable keepalive, not a heartbeat commit; bots never bypass rulesets.

[Unreleased]: https://github.com/Szmelc-INC/CONVENTIONS.md/compare/v3.0.0...HEAD
[3.0.0]: https://github.com/Szmelc-INC/CONVENTIONS.md/compare/v2.0.2...v3.0.0
[2.0.2]: https://github.com/Szmelc-INC/CONVENTIONS.md/compare/v2.0.1...v2.0.2
[2.0.1]: https://github.com/Szmelc-INC/CONVENTIONS.md/compare/v2.0.0...v2.0.1
[2.0.0]: https://github.com/Szmelc-INC/CONVENTIONS.md/commits/v2.0.0
