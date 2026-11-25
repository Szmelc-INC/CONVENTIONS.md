# Pull requests & CI
> Load when: committing, pushing, opening/reviewing/merging a PR, or fixing CI.

- Self-review before PR: correctness, security/escaping, docs + shell completions in sync.
- Work in progress → draft PR (`gh pr create --draft`); `gh pr ready` only when done and self-reviewed.
- Body follows `.github/PULL_REQUEST_TEMPLATE.md` (what, why, checks run); org default: `CONVENTIONS/GITHUB/ORGANIZATIONS.md`.
- Link issues with `Closes #<n>` (`CONVENTIONS/GITHUB/ISSUES.md`); label on creation (`CONVENTIONS/GITHUB/REPO/LABELS.md`).
- Review: concrete fixes as suggested changes (a `suggestion` code block); the author batch-applies them as one commit.
- Wait for green CI → merge yourself → verify main CI + live result → one short report.
- Checks still running → `gh pr merge --auto --squash --delete-branch`; verify after it lands all the same.
- Never merge red, force-push, or bypass branch protection; repo settings: `CONVENTIONS/GITHUB/REPO/SETTINGS.md`.
- CI builds the package and runs the tests on every PR; its logic is a script that also runs locally (Docker/Podman), the workflow only calls it.
- Commit and PR titles: `CONVENTIONS/WORKFLOW/COMMITS.md`.
