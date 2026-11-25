# META
> Load when: changing how this repo is built, checked, indexed or published (tools, schema, templates, site, CI).

How the conventions repo works: sources in, every format out.

## Pipeline
| Tool | Does |
|---|---|
| `META/tools/build.sh` | Sources → `INDEX.md`, `index.json`, `llms.txt`, `CONVENTIONS.md`, core maps (`AGENTS.md` block, `HUMANS.md`, `SZMELC.md`, `META.md`), `AGENTS/adapters/`. `--check` fails when stale |
| `META/tools/check.sh` | Generated files fresh, rule/core headers, skills frontmatter, index entries, path references, case collisions, dangling links |
| `META/tools/lane-check.sh` | Branch-lane scope for PRs (`CONVENTIONS/workflow/branches.md`) |
| `META/tools/test-install.sh` | `install.sh` smoke test in a throwaway `$HOME` |
| `META/tools/site.sh` | GitHub Pages site into gitignored `public/`; projects from the GitHub API over `SZMELC/sources.conf` |

## Layout contract
- Five cores at the root: `CONVENTIONS/`, `AGENTS/`, `HUMANS/`, `SZMELC/`, `META/`. Each has `X/README.md` (line 1 `# Title`, line 2 `> Load when:`) and a root map `X.md`.
- Root maps are generated: `HUMANS.md`, `SZMELC.md`, `META.md` whole; `AGENTS.md` below its `map:begin` marker; `CONVENTIONS.md` is the bundle, opening with its map.
- Rule = any `.md` under a core outside `AGENTS/{global,skills,adapters}`, `META/{tools,schema,templates}` and core `README.md`s. Status from path: `CONVENTIONS/experimental/`, `CONVENTIONS/legacy/`, else stable.
- Root stays: `SKILL.md` (the repo is the skill), `install.sh`, `README.md`, `LICENSE`, `CLAUDE.md`/`GEMINI.md` (`@AGENTS.md`), generated indexes.
- `claude/` holds compatibility symlinks for pre-1.0 install paths.

## Other
- `META/schema/index.schema.json`: JSON Schema for `index.json`.
- `META/templates/`: skeletons for a rule, a skill, a project `AGENTS.md`.
- CI: `.github/workflows/check.yml` (check, shellcheck, installer test, lane scope), `.github/workflows/pages.yml` (site on push to `main`, nightly, on demand).
