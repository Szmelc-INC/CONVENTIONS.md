# CONTRIBUTING
> Load when: adding, changing, promoting, versioning or indexing a convention, or contributing to this repo.

How to extend the conventions: where a rule goes, how it is written, named, built, checked and shipped. Root `CONTRIBUTING.md` is the generated map of this core; GitHub links it on every new issue and PR.

## Flow
1. Branch off `main` with a prefix: `feat/*`, `fix/*`, `docs/*`, `chore/*` (stable), `experimental/*` (proposals), `legacy/*` (archive). Private or unverified material: `local/*`, never pushed; run `git config core.hooksPath META/tools/hooks` once per clone to enforce it.
2. Edit sources only; generated files are rebuilt by `META/tools/build.sh`.
3. `META/tools/build.sh && META/tools/check.sh` must pass; CI runs the same plus shellcheck and the installer smoke test.
4. PR into `main`; it is squash-merged and the branch deleted. Rules: `CONVENTIONS/WORKFLOW/BRANCHES.md`, `CONVENTIONS/GITHUB/PULL-REQUESTS.md`.

## Where a rule goes
| Rule is about | Path |
|---|---|
| Everyday flow: branches, commits, finishing, verifying, notifying | `CONVENTIONS/WORKFLOW/` |
| Anything GitHub: repo settings, PRs, Actions, releases, Pages | `CONVENTIONS/GITHUB/` |
| A named document file (`AGENTS.md`, `CHANGELOG.md`, `SECURITY.md`, `DESIGN.md`) | `CONVENTIONS/SPECS/THIRD-PARTY/` if an outside standard defines it, else `CONVENTIONS/SPECS/ORIGINAL/` |
| Agent behaviour (subagents, token efficiency) | `AGENTS/RULES/` |
| Not yet adopted | `CONVENTIONS/EXPERIMENTAL/` via an `experimental/*` branch |
| No category fits | New UPPERCASE directory under `CONVENTIONS/`; add it to the table in `CONVENTIONS/README.md` |

## Naming
- Rule paths (UPPERCASE kebab, `X-EXT.md`) and format: `CONVENTIONS/SPECS/ORIGINAL/RULE-FILES.md`. `check.sh` enforces them.
- Machinery keeps lowercase paths that installs and hooks depend on: `AGENTS/global/`, `AGENTS/skills/`, `AGENTS/adapters/`, `META/tools/`, `META/templates/`, `META/schema/`.
- Rule format: `META/templates/rule.md`. Repo rules: root `README.md`, "Rules of this repo".
