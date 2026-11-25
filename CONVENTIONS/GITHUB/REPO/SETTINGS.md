# Repo settings
> Load when: creating a repo, changing its GitHub settings, merge options, rulesets or feature toggles.

- Apply settings as code: `gh repo edit` flags and `gh api` calls in a script, not web-UI clicks. Metadata: `CONVENTIONS/GITHUB/REPO/METADATA.md`.
- Default branch `main` (`--default-branch main`); branch model: `CONVENTIONS/WORKFLOW/BRANCHES.md`.
- Merge: squash only (`--enable-squash-merge --enable-merge-commit=false --enable-rebase-merge=false`).
- Squash message `--squash-merge-commit-message pr-title-commits`: PR title becomes the subject, commit trailers (`Co-Authored-By:`) survive.
- `--delete-branch-on-merge`, `--enable-auto-merge`, `--allow-update-branch`.
- Ruleset on the default branch via `gh api repos/<owner>/<repo>/rulesets` (`gh ruleset` only lists, views, checks):
  - `pull_request` with 0 required approvals: PR required, solo maintainers self-merge.
  - `required_status_checks`: only checks that run on every PR; a path-filtered or not-yet-existing check blocks merges forever.
  - `non_fast_forward`, `deletion`, `required_linear_history`.
- Rulesets are free on public repos; private repos on GitHub Free get none, so the PR flow is self-enforced there.
- Features: issues on; discussions only for a community (`CONVENTIONS/GITHUB/DISCUSSIONS.md`); projects per `CONVENTIONS/GITHUB/PROJECTS.md`; wiki off (`CONVENTIONS/GITHUB/WIKI.md`).
- Security toggles: `CONVENTIONS/GITHUB/CODE-SECURITY.md`.
- Visibility change, transfer, archive or rename: owner approval first; never pass `--accept-visibility-change-consequences` on your own.
