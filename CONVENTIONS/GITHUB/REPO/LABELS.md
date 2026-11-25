# Labels
> Load when: creating, editing or applying issue/PR labels, or setting up a new repo.

- Keep the set small; plain names, no `type:` prefixes, so `--force` recolors GitHub defaults instead of duplicating them.

| Label | Color | Use |
|---|---|---|
| `bug` `feat` `docs` `chore` | `105c5c` | Type, one per issue/PR |
| `area/<x>` | `1b1b1b` | Per-project subsystem, defined in the project |
| `experimental` | `750f0f` | Proposal on an experimental branch |
| `legacy` | `c0c0c0` | Superseded material |
| `blocked` | `b83a3a` | Waiting on something external |
| `good first issue` | `7fffd4` | Easy entry; the one highlight color |
| `help wanted` | `1f8a8a` | Maintainer wants outside help |

- Colors come from `CONVENTIONS/DESIGN/COLORS.md`, hex without `#`; recolor GitHub's purple defaults.
- Labels as code: a script or `labels.tsv` in the repo, applied with `gh label create <name> -c <hex> -d <desc> --force`.
- Same set across an org: `gh label clone <source-repo> --force`.
- Never delete or rename a label others use; mark it deprecated in its description first.
- Label on creation (`gh issue create -l`, `gh pr create -l`), not afterwards.
