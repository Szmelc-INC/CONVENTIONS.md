# Branches & lanes
> Load when: creating branches, opening/merging PRs, releasing, or promoting/deprecating a convention.

| Branch | Role | Scope |
|---|---|---|
| `main` | Current stable truth; installs track it. No direct commits. | Everything |
| `testing` | Integration lane for stable changes. | Any source file |
| `experimental` | Proposals, opt-in only. | `experimental/` + generated files |
| `legacy` | Archive of superseded material. Never deleted. | `legacy/` + generated files |

- Flow: feature branch → PR into a lane → PR lane → `main`. Small fixes may PR straight from the lane.
- Lanes are long-lived: merge with a merge commit (`gh pr merge --merge`); never squash, never `--delete-branch`.
- After a lane merges, fast-forward the other lanes: `git push origin main:<lane>` (fast-forward only; otherwise PR `main` → lane).
- Promote: move `experimental/<x>.md` to `<category>/<x>.md` in a `testing` PR. Demote: move to `legacy/` in a `legacy` PR, add `> Superseded by: <path>` as line 3.
- CI enforces lane scope (`tools/lane-check.sh`).
- Projects that ship releases map lanes to channels: `main` = stable, `testing` = rc, `experimental` = `-ex` builds, `legacy` = old-major maintenance.
