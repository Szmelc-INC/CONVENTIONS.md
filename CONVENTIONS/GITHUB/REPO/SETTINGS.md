---
id: conventions.github.repo.settings
---
# Repo settings
> Load when: creating a repo, changing its GitHub settings, merge options, rulesets or feature toggles.

- Apply settings as code: `gh repo edit` flags and `gh api` calls in a script, not web-UI clicks. Metadata: `CONVENTIONS/GITHUB/REPO/METADATA.md`.
- Default branch `main` (`--default-branch main`); branch model: `CONVENTIONS/WORKFLOW/BRANCHES.md`.
- Merge: merge commit or rebase, never squash (`--enable-merge-commit --enable-rebase-merge --enable-squash-merge=false`): branch commits land on `main` as written and trailers (`Co-Authored-By:`) survive.
- `--delete-branch-on-merge`, `--enable-auto-merge`, `--allow-update-branch`.
- Ruleset on the default branch via `gh api repos/<owner>/<repo>/rulesets` (`gh ruleset` only lists, views, checks):
  - `pull_request` with 0 required approvals and `allowed_merge_methods: ["merge", "rebase"]`: PR required, every maintainer reviews and self-merges; no `required_linear_history` (it blocks merge commits).
  - `required_status_checks`: only checks that run on every PR; a path-filtered or not-yet-existing check blocks merges forever.
  - Public repo with outside contributors: also require `review-gate`, a commit status set from trusted triggers (`pull_request_target`, `workflow_run`, schedule) that passes maintainer PRs and other PRs only after a maintainer approves the head commit; `.github/CODEOWNERS` requests the review. Reference: `META/tools/review-gate.sh`.
- Fork PR workflows: approval for all outside contributors (`actions/permissions/fork-pr-contributor-approval`, `all_external_contributors`).
  - `non_fast_forward`, `deletion`, `required_linear_history`.
- Rulesets are free on public repos; private repos on GitHub Free get none, so the PR flow is self-enforced there.
- Features: issues on; discussions only for a community (`CONVENTIONS/GITHUB/DISCUSSIONS.md`); projects per `CONVENTIONS/GITHUB/PROJECTS.md`; wiki off (`CONVENTIONS/GITHUB/WIKI.md`).
- Security toggles: `CONVENTIONS/GITHUB/CODE-SECURITY.md`.
- Visibility change, transfer, archive or rename: owner approval first; never pass `--accept-visibility-change-consequences` on your own.
