---
id: contributing.decisions
---
# Project decisions
> Load when: checking why the project adopted a policy, format, or compatibility change.

Short record of decisions that affect the project beyond one pull request. Detailed proposals and discussion remain linked from the relevant issue or Discussion.

| Date | Decision | Reason | Record |
|---|---|---|---|
| 2026-11-26 | Require a current maintainer approval for outside PRs through the `review-gate` status. | Protect the default branch while allowing outside contributions through the normal PR flow. | `.github/workflows/review-gate.yml`, issue #55 |
| 2026-11-26 | Keep changes on `main` behind pull requests and use rebase merges. | Preserve review and CI gates while keeping a linear release history. | `CONVENTIONS/WORKFLOW/BRANCHES.md` |
| 2026-11-26 | Adopt the context-system proposal in slices: rule metadata in front matter, `conventions resolve` in the Go CLI, no empty domain directories. | Extend the existing format and CLI instead of a parallel registry and a shell resolver. | `SPEC/decisions/0002-context-system.md` |
| 2026-11-26 | Contributions are licensed under MIT when submitted; no CLA is required. | Keep the contribution path simple and make inbound licensing match the repository's outbound license. | `CONTRIBUTING/README.md`, issue #55 |

Add entries when a maintainer accepts a cross-cutting decision. Do not use this table for routine implementation choices.
