# META
> Load when: changing how this repo is built, checked, indexed or published (tools, schema, templates, site, CI).

How the conventions repo works: sources in, every format out.

## Pipeline
| Tool | Does |
|---|---|
| `META/tools/build.sh` | Sources → `INDEX.md`, `index.json`, `llms.txt`, `CONVENTIONS.md`, core maps (`AGENTS.md` block, `HUMANS.md`, `CONTRIBUTING.md`, `SZMELC.md`, `META.md`), `AGENTS/adapters/`. `--check` fails when stale |
| `META/tools/check.sh` | Generated files fresh, rule/core headers, skills frontmatter, index entries, path references, case collisions, dangling links |
| `META/tools/lane-check.sh` | Branch-prefix scope for PRs; rejects `local/*` (`CONVENTIONS/WORKFLOW/BRANCHES.md`) |
| `META/tools/hooks/pre-push` | Refuses to push `local/*`; enable with `git config core.hooksPath META/tools/hooks` |
| `META/tools/test-install.sh` | `install.sh` smoke test in a throwaway `$HOME` |
| `META/tools/site.sh` | GitHub Pages site into gitignored `public/`; projects from the GitHub API over `SZMELC/sources.conf` |
| `META/tools/release.sh` | Verifies the tag (annotated, on `main`), runs check, builds bundle assets + `SHA256SUMS` into gitignored `dist/`, publishes the GitHub release. `--dry-run` prints instead |
| `META/tools/labels.sh` | Applies `.github/labels.tsv` with `gh label create --force`; never deletes. `--dry-run` |
| `META/tools/github-setup.sh` | Repo settings, security toggles, rulesets (`main`, `release-tags`) and labels as code; idempotent. `--dry-run` |

## Layout contract
- Six cores at the root: `CONVENTIONS/`, `AGENTS/`, `HUMANS/`, `CONTRIBUTING/`, `SZMELC/`, `META/`. Each has `X/README.md` (line 1 `# Title`, line 2 `> Load when:`) and a root map `X.md`.
- Root maps are generated: `HUMANS.md`, `CONTRIBUTING.md`, `SZMELC.md`, `META.md` whole; `AGENTS.md` below its `map:begin` marker; `CONVENTIONS.md` is the bundle, opening with its map.
- Rule = any `.md` under a core outside `AGENTS/{global,skills,adapters}`, `META/{tools,schema,templates}` and core `README.md`s. Status from path: `CONVENTIONS/EXPERIMENTAL/`, `CONVENTIONS/LEGACY/`, else stable. Rule paths are UPPERCASE kebab (check.sh rule 11).
- Root stays: `SKILL.md` (the repo is the skill), `install.sh`, `README.md`, `CHANGELOG.md`, `LICENSE`, `CLAUDE.md`/`GEMINI.md` (`@AGENTS.md`), generated indexes.
- `claude/` holds compatibility symlinks for pre-1.0 install paths.

## Other
- `META/schema/index.schema.json`: JSON Schema for `index.json`.
- `META/templates/`: skeletons for a rule, a category README, a skill, a project `AGENTS.md`; catalogue `CONTRIBUTING/TEMPLATES.md`.
- CI: `.github/workflows/check.yml` (check, shellcheck, installer test, branch scope), `.github/workflows/pages.yml` (site on push to `main`, nightly, on demand), `.github/workflows/release.yml` (`v*` tag push, or dispatch with `dry_run`).
- GitHub setup in `.github/`: issue forms, PR template, `release.yml` note categories, `dependabot.yml`, `labels.tsv`, `SECURITY.md`.
