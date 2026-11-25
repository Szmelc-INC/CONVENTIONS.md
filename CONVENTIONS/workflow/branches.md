# Branches
> Load when: creating branches, opening/merging PRs, releasing, or promoting/deprecating a convention.

- `main` is the only long-lived branch: current stable truth; installs track it. No direct commits.
- Every change: short-lived branch off `main` → PR into `main` → merge → delete the branch.
- Name by intent: `feat/<x>`, `fix/<x>`, `docs/<x>`, `chore/<x>`, `experimental/<x>`, `legacy/<x>`.

| Prefix | Use for | Scope (CI-enforced) |
|---|---|---|
| `feat/*` `fix/*` `docs/*` `chore/*` | Stable changes | Any source file |
| `experimental/*` | New or changed proposals | `CONVENTIONS/experimental/` + generated files |
| `legacy/*` | Archiving superseded material | `CONVENTIONS/legacy/` + generated files |

- Merge: `gh pr merge --squash --delete-branch`; keep one topic per PR so the squash reads as one change.
- Stale branch with no open PR and nothing ahead of `main`: delete it.
- Promote: move `CONVENTIONS/experimental/<x>.md` to `CONVENTIONS/<category>/<x>.md` in a `feat/*` PR.
- Demote: move to `CONVENTIONS/legacy/` in a `legacy/*` PR; add `> Superseded by: <path>` as line 3. Legacy files are never deleted.
- CI enforces prefix scope (`META/tools/lane-check.sh`).
- Projects that ship releases: `main` = stable channel; any other branch = `-ex` experimental build; tags on `main` only.
