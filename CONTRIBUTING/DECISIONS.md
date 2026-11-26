# Project decisions
> Load when: checking why the project adopted a policy, format, or compatibility change.

Short record of decisions that affect the project beyond one pull request. Detailed proposals and discussion remain linked from the relevant issue or Discussion.

| Date | Decision | Reason | Record |
|---|---|---|---|
| 2026-11-26 | Require a current maintainer approval for outside PRs through the `review-gate` status. | Protect the default branch while allowing outside contributions through the normal PR flow. | `.github/workflows/review-gate.yml`, issue #55 |
| 2026-11-26 | Keep changes on `main` behind pull requests and use rebase merges. | Preserve review and CI gates while keeping a linear release history. | `CONVENTIONS/WORKFLOW/BRANCHES.md` |

Add entries when a maintainer accepts a cross-cutting decision. Do not use this table for routine implementation choices.
