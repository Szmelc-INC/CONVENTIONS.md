# Labels
> Load when: creating, editing or applying issue/PR labels, or setting up a new repo.

- Keep the set small; plain names, no `type:` prefixes, so `--force` recolors the matching GitHub defaults (`bug`, `good first issue`, `help wanted`).
- Other defaults stay (never delete): use the profile's secondary color, description `Deprecated: use <label>` (`documentation` → `docs`, `enhancement` → `feat`).

| Label | Color | Use |
|---|---|---|
| `bug` `feat` `docs` `chore` | `{{profile.colors.accent}}` | Type, one per issue/PR |
| `area/<x>` | `1b1b1b` | Per-project subsystem, defined in the project |
| `breaking` | `{{profile.colors.danger}}` | Major bump; its own section in release notes |
| `experimental` | `{{profile.colors.danger}}` | Proposal on an experimental branch |
| `legacy` | `{{profile.colors.secondary}}` | Superseded material |
| `blocked` | `{{profile.colors.danger_text}}` | Waiting on something external |
| `good first issue` | `{{profile.colors.highlight}}` | Easy entry; the one highlight color |
| `help wanted` | `{{profile.colors.accent_text}}` | Maintainer wants outside help |

- Colors come from `CONVENTIONS/DESIGN/COLORS.md`, hex without `#`; replace unsuitable platform defaults.
- Labels as code: a script or `labels.tsv` in the repo, applied with `gh label create <name> -c <hex> -d <desc> --force`.
- Same set across an org: `gh label clone <source-repo> --force`.
- Never delete or rename a label others use; mark it deprecated in its description first.
- Label on creation (`gh issue create -l`, `gh pr create -l`), not afterwards.
