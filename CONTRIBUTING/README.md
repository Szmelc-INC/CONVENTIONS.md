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
| `CONTRIBUTING/DIY.md` | Your own conventions repo on this skeleton; layering on Szmelc™ |
| `CONTRIBUTING/DECISIONS.md` | Short record of project-wide decisions |

## Flow
1. Branch off `main` with a prefix (`CONVENTIONS/WORKFLOW/BRANCHES.md`). Private or unverified material: `local/*`, never pushed; run `git config core.hooksPath META/tools/hooks` once per clone to enforce it.
2. Edit sources only; generated files are rebuilt by `META/tools/build.sh` (`CONTRIBUTING/INDEXING.md`).
3. `META/tools/build.sh && META/tools/check.sh` must pass; CI runs the same plus shellcheck and the installer smoke test.
4. PR into `main`; it is rebase-merged and the branch deleted (`CONVENTIONS/GITHUB/PULL-REQUESTS.md`). Outside PRs (from a fork) merge only after the maintainer approves the latest commit (`review-gate` status); fork CI starts once a maintainer approves the run.

## Five-minute wording fix

1. Open the page with the wording issue and edit the source file in your fork.
2. Commit the change and open a pull request. You do not need to run the build for wording-only changes; CI builds generated files and reports problems.
3. A maintainer aims to acknowledge the PR within 48 hours. The maintainer merges after review and green CI.

Contributions are licensed under the repository's MIT License. By submitting a contribution, you agree that it may be distributed under MIT; there is no CLA.

## Triage

New issues and pull requests use the `needs-triage` label. A weekly scheduled reminder prompts the maintainer to review issues, pull requests, and Discussions.

## Naming
- Where a rule goes: `CONTRIBUTING/WRITING.md`. Rule paths (UPPERCASE kebab, `X-EXT.md`) and format: `CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md`. `META/tools/check.sh` enforces them.
- Machinery keeps lowercase paths that installs and hooks depend on: `AGENTS/global/`, `AGENTS/skills/`, `AGENTS/adapters/`, `META/tools/`, `META/schema/`, `META/compat/`; template file names in `TEMPLATES/`.
- Repo rules: root `README.md`, "Rules of this repo".
