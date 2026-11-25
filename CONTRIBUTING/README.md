# CONTRIBUTING
> Load when: adding, changing, promoting, versioning or indexing a convention, or contributing to this repo.

How to use, extend and maintain the conventions: where a rule goes, how it is written, named, built, versioned and shipped. Root `CONTRIBUTING.md` is the generated map of this core; GitHub links it on every new issue and PR.

| File | Covers |
|---|---|
| `CONTRIBUTING/101.md` | Fastest path to using the conventions: install, load order, apply to a project, look up |
| `CONTRIBUTING/PROMPTS.md` | Copy-paste agent prompts for every task: use, apply, extend, maintain |
| `CONTRIBUTING/WRITING.md` | Rule checklist, where a rule goes, new categories, good vs bad lines |
| `CONTRIBUTING/LIFECYCLE.md` | Propose, promote, change, demote; how installs see changes |
| `CONTRIBUTING/VERSIONING.md` | SemVer of this repo, releases, pinning an install |
| `CONTRIBUTING/INDEXING.md` | Sources to every generated format; adding a format |
| `CONTRIBUTING/TEMPLATES.md` | Skeletons in `META/templates/` and when to copy each |
| `CONTRIBUTING/DIY.md` | Your own conventions repo on this skeleton; layering on Szmelc |

## Flow
1. Branch off `main` with a prefix (`CONVENTIONS/WORKFLOW/BRANCHES.md`). Private or unverified material: `local/*`, never pushed; run `git config core.hooksPath META/tools/hooks` once per clone to enforce it.
2. Edit sources only; generated files are rebuilt by `META/tools/build.sh` (`CONTRIBUTING/INDEXING.md`).
3. `META/tools/build.sh && META/tools/check.sh` must pass; CI runs the same plus shellcheck and the installer smoke test.
4. PR into `main`; it is squash-merged and the branch deleted (`CONVENTIONS/GITHUB/PULL-REQUESTS.md`).

## Naming
- Where a rule goes: `CONTRIBUTING/WRITING.md`. Rule paths (UPPERCASE kebab, `X-EXT.md`) and format: `CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md`. `META/tools/check.sh` enforces them.
- Machinery keeps lowercase paths that installs and hooks depend on: `AGENTS/global/`, `AGENTS/skills/`, `AGENTS/adapters/`, `META/tools/`, `META/templates/`, `META/schema/`.
- Repo rules: root `README.md`, "Rules of this repo".
