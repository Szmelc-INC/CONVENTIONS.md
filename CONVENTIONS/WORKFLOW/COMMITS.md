---
id: conventions.workflow.commits
---
# Commits
> Load when: writing a commit message or PR title.

- English, imperative, one subject line ≤ 72 chars; body only when the why is not obvious.
- Type prefix with optional scope: `feat(core): …`, `fix(core): …`, `docs: …`, `ci: …`, `chore: …`, `refactor: …`, `test: …`.
- Version bump → append the version: `feat: signed package lists (0.3.1)`.
- Never web-UI defaults (`Update README.md`, `Create file`) on `main`.
- One topic per commit and per PR; commits land on `main` as written (merge commit or rebase, never squash), so each one follows this format (`CONVENTIONS/WORKFLOW/BRANCHES.md`).
