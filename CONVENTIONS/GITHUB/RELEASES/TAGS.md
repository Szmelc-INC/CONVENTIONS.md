---
id: conventions.github.releases.tags
---
# Tags
> Load when: creating, pushing, protecting or fixing a release tag.

- Annotated only: `git tag -a vX.Y.Z -F <notes-file>`; never lightweight.
- Format `vMAJOR.MINOR.PATCH` (`CONVENTIONS/GITHUB/RELEASES/VERSIONING.md`); pre-releases `vX.Y.Z-rc.N`.
- Tag `main` only, on a commit whose CI is green.
- `-ex` builds are never tagged `v*` (`CONVENTIONS/GITHUB/RELEASES/CHANNELS.md`).
- Tag message: title `vX.Y.Z`, then that version's changelog section.
- Push one tag explicitly: `git push origin vX.Y.Z`; never `git push --tags`.
- Published tags are immutable: never move, delete or re-push one; fix a bad release with a new patch tag.
- Only exception: the rolling `nightly` tag (`CONVENTIONS/GITHUB/RELEASES/CHANNELS.md`).
- Protect with a tag ruleset (`gh api repos/<owner>/<repo>/rulesets`): `target: tag`, `conditions.ref_name.include: ["refs/tags/v*"]`, rules `update` + `deletion`; `nightly` stays outside it.
