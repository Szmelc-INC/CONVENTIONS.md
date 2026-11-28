---
id: conventions.workflow.branches
---
# Branches
> Load when: creating branches, opening/merging PRs, releasing, or promoting/deprecating a convention.

- `main` is the only long-lived branch: current stable truth; installs track it. No direct commits.
- Every change: short-lived branch off `main` → PR into `main` → merge → delete the branch.
- Name by intent: `feat/<x>`, `fix/<x>`, `docs/<x>`, `chore/<x>`, `experimental/<x>`, `legacy/<x>`; private staging: `local/<x>`.
- Examples: `docs/issue-form-guide`, `fix/lane-check-scope`, `feat/profile-defaults`.

| Prefix | Use for | Scope (CI-enforced) |
|---|---|---|
| `feat/*` `fix/*` `docs/*` `chore/*` | Stable changes | Any source file |
| `experimental/*` | New or changed proposals | `CONVENTIONS/EXPERIMENTAL/` + generated files |
| `legacy/*` | Archiving superseded material | `CONVENTIONS/LEGACY/` + generated files |
| `local/*` | Private or unverified material awaiting review | Never pushed, never merged |

- Merge: `gh pr merge --merge --delete-branch` (merge commit) or `gh pr merge --rebase --delete-branch`, then `git checkout main && git pull --ff-only`; never squash. One topic per PR, every commit on the branch clean and conventional (all of them land on `main`).
- Stale branch with no open PR and nothing ahead of `main`: delete it.
- Promote: move `CONVENTIONS/EXPERIMENTAL/<x>.md` to `CONVENTIONS/<category>/<x>.md` in a `feat/*` PR.
- Demote: move to `CONVENTIONS/LEGACY/` in a `legacy/*` PR; add `> Superseded by: <path>` as line 3. Legacy files are never deleted.
- `local/*`: one commit per proposal; never pushed (pre-push hook `META/tools/hooks/pre-push`, enable with `git config core.hooksPath META/tools/hooks`); CI rejects it. Approved commits are re-applied on a `feat/*` or `experimental/*` branch after review; rejected ones stay local.
- CI enforces prefix scope (`META/tools/lane-check.sh`).
- Projects that ship releases: `main` = stable, other branches = `-ex` builds; channels and tags: `CONVENTIONS/GITHUB/RELEASES/CHANNELS.md`.
