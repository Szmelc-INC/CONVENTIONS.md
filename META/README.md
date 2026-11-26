# META
> Load when: changing how this repo is built, checked, indexed or published (tools, schema, compatibility registry, site, CI).

How the conventions repo works: sources in, every format out.

## Pipeline

| Tool | Does |
|---|---|
| `META/tools/build.sh` | Sources → `INDEX.md`, `index.json`, `llms.txt`, `CONVENTIONS.md`, configured core maps, `COMPATIBILITY.md`, `AGENTS/adapters/`. `--check` fails when stale |
| `META/tools/check.sh` | Generated files fresh, rule/core headers, skills and experimental mode bundle metadata, index entries, path references, case collisions, dangling links, compatibility registry |
| `META/tools/lane-check.sh` | Branch-prefix scope for PRs; rejects `local/*` (`CONVENTIONS/WORKFLOW/BRANCHES.md`) |
| `META/tools/prose-lint.sh` | STE100++ prose checks (semicolons, claim words, sentences over 30 words); CI runs `--strict`, `--summary` shows counts |
| `META/tools/hooks/pre-push` | Refuses to push `local/*`; enable with `git config core.hooksPath META/tools/hooks` |
| `META/tools/test-install.sh` | `install.sh` smoke test in a throwaway `$HOME` |
| `META/tools/test-generated.sh` | Committed generated-output goldens and repeat-build byte comparison |
| `META/tools/site.sh` | GitHub Pages site into gitignored `public/`: `index.html`, JSON, `llms.txt`, `index.json`, `INDEX.md`, `CONVENTIONS.md`, `COMPATIBILITY.md`, `SKILL.md` at the site root, registry icons at their repo paths; projects from the GitHub API using the selected profile's source list |
| `META/tools/screenshots.sh` | README screenshots into `META/assets/screenshots/`: builds the site, captures it with headless Chromium over CDP (Node 22 or later), optimizes the PNGs. `--help` |
| `META/tools/release.sh` | Verifies the signed, annotated tag on `main`, runs check, builds bundle assets + `SHA256SUMS` into gitignored `dist/`, publishes the GitHub release. `--dry-run` prints instead |
| `META/tools/labels.sh` | Applies `.github/labels.tsv` with `gh label create --force`; never deletes. `--dry-run` |
| `META/tools/github-setup.sh` | Repo settings, security toggles, rulesets (`main`, `release-tags`) and labels as code; idempotent. `--dry-run` |

## Layout contract

- Each configured core has `X/README.md` (line 1 `# Title`, line 2 `> Load when:`) and a root map `X.md`.
- Root maps are generated; `AGENTS.md` is generated below its `map:begin` marker, and `CONVENTIONS.md` is the stable-rule bundle with its map.
- Rule = any `.md` under a core outside `AGENTS/{global,skills,adapters}`, `META/{tools,schema,compat}`, `TEMPLATES/` and core `README.md`s. Status from path: `CONVENTIONS/EXPERIMENTAL/`, `CONVENTIONS/LEGACY/`, else stable. Rule paths are UPPERCASE kebab (check.sh rule 11).
- Root stays: `SKILL.md` (the repo is the skill), `install.sh`, `README.md`, `CHANGELOG.md`, `LICENSE`, `CLAUDE.md`/`GEMINI.md` (`@AGENTS.md`), generated indexes.
- `claude/` holds compatibility symlinks for pre-1.0 install paths.

## Other

- `META/schema/index.schema.json`: JSON Schema for `index.json`.
- `META/assets/`: non-rule files such as `screenshots/` for the root `README.md`; build, check and site skip it as rules.
- `AGENTS/modes/`: experimental, opt-in rule-ID bundles; the index lists these separately, and the default bundle excludes their contents.

## Compatibility registry

- Source: `META/compat/registry.toml`, one `[[compat]]` record per third-party format, spec, platform, language or tool; fields and the TOML subset in its header. Parsed by `META/tools/compat.awk` (POSIX awk, no new deps).
- Outputs: `COMPATIBILITY.md` (table + disclaimer), `index.json` `compatible` and `compatible_disclaimer`, site data `compatible`, `compatible_disclaimer`, `icons` (path data inlined by `META/tools/site.sh`).
- Site: every entry is an item of the "Compatible with" carousel and a popup (`#compat/<id>`); third-party rules show their entries as chips (`CONVENTIONS/INTERFACES/WEBUI/COMPONENTS.md`).
- Disclaimer: `disclaimer` key in the registry, the one source for every output.
- `spec` links an entry to its rule files; build derives the reverse as `compat` ids on those `index.json` entries and site rules.
- `version`: exact upstream version targeted, or `unversioned`. `added`/`updated` are stored, never derived from git; bump `updated` on every edit.
- Links: official https URLs that returned HTTP 200 when added; no network calls in CI.
- Icons: `META/compat/icons/` (`META/compat/icons/README.md`: Simple Icons, CC0, `fill="currentColor"`); none upstream → omit `icon`.
- check.sh rule 12: grammar, required fields, unique kebab ids, kind, real dates, icon files and their safety, spec paths, https links, every `CONVENTIONS/SPECS/THIRD-PARTY/` file cited, no unused icon.
- Origin: `origin` on `index.json` entries and site rules, from the path: `*/THIRD-PARTY/*` → `third-party`, `*/ORIGINAL/*` → `original`; absent otherwise.
- Skeletons live in the `TEMPLATES/` core (`TEMPLATES/README.md`); build, check, site and install skip them as rules.
- CI: `.github/workflows/check.yml` (generated-output goldens, pinned actions, actionlint, schema, ShellCheck, markdownlint, typos, EditorConfig, local links, installer tests on Ubuntu and macOS, release dry run, dependency review, branch scope, axe and Lighthouse budgets), `.github/workflows/links.yml` (weekly external-link check), `.github/workflows/scorecard.yml` (weekly supply-chain score), `.github/workflows/pages.yml` (site on push to `main`, nightly, on demand; stable `SOURCE_DATE_EPOCH` and nightly failure summary), `.github/workflows/release.yml` (`v*` tag push, provenance attestation, or dispatch with `dry_run`).
- GitHub setup in `.github/`: issue forms, PR template, `release.yml` note categories, `dependabot.yml`, `labels.tsv`, `SECURITY.md`.
