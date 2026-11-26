---
id: conventions.github.actions.workflows
---
# Workflows
> Load when: writing or editing a GitHub Actions workflow, reusable workflow or composite action.

- One purpose per file in `.github/workflows/`: `check.yml` (CI), `release.yml` (releases), `pages.yml` (site).
- Triggers: `push` + `pull_request` for checks; add `workflow_dispatch` to anything worth rerunning by hand.
- `schedule` only for data from outside the repo; public repos disable it after 60 days without activity, so add a keepalive (`CONVENTIONS/GITHUB/ACTIONS/CI.md`).
- Cross-repo triggers: `repository_dispatch` with a named `types:` entry.
- Top-level `permissions: contents: read`; elevate per job only (`contents: write`, `pages: write`, `id-token: write`).
- `concurrency:` group per workflow + ref; `cancel-in-progress: true` for checks, `false` for deploys and releases.
- Pin actions to a major tag (`actions/*`) or a full commit SHA with a `# vX` comment (third-party); Dependabot keeps them current (`CONVENTIONS/GITHUB/CODE-SECURITY.md`).
- Logic lives in repo scripts that run locally (Docker/Podman when the host differs); the workflow only checks out, sets up and calls them.
- Pass `${{ }}` values into `run:` through `env:`, never inline (script injection).
- Secrets only via `secrets.*` or OIDC (`id-token: write`); never echo them or put them on a command line; mask derived values with `::add-mask::`.
- `GITHUB_TOKEN` over PATs. Events it causes start no workflows (except `workflow_dispatch`/`repository_dispatch`) and it cannot reach other repos; for those cases only, use a GitHub App token (`actions/create-github-app-token`) or a fine-grained PAT scoped to the target repo.
- Same steps in 2+ repos → reusable workflow (`on: workflow_call`) or composite action in one org repo, called pinned.
- Results people read go to `$GITHUB_STEP_SUMMARY` as Markdown, not only to logs.
- Minutes: public repos run free on standard runners, private repos on GitHub Free get 2,000 min/month; keep matrices to supported targets, cache dependencies (`actions/cache` or a setup action's `cache:`).
