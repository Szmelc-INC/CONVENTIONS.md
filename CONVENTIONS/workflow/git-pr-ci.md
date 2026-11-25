# Git, PRs & CI
> Load when: committing, pushing, opening/merging a PR, or fixing CI.

- Self-review before PR: correctness, security/escaping, docs + shell completions in sync.
- Wait for green CI → merge yourself → verify main CI + live result → one short report.
- Never merge red, force-push, or bypass branch protection.
- CI builds the package and runs the tests on every PR.
- CI logic lives in a script that also runs on any machine with Docker/Podman; the workflow file only calls it, so no host lock-in.
- Commit and PR titles: `CONVENTIONS/workflow/commits.md`.
