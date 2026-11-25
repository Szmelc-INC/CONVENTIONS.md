# v2 repo baseline
> Load when: user opts into experimental conventions, or ports a v1 project to the v2 baseline.

Proposal from the v2 draft (2026-11-25): rules not yet observed across the public repos.

- `CHANGELOG.md` in keep-a-changelog format, updated with every release.
- `.gitattributes` with `* text=auto eol=lf`.
- CI fails when the version copies disagree (source constant, PKGBUILD, flake, changelog).
- Commit type `pkg:` for packaging-only changes.
- Every major version with a DB, daemon or plugin system has its architecture contract before the first release.
