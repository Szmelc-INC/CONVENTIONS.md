# Versioning the conventions
> Load when: deciding the version bump for a change to this conventions repo, releasing it, or pinning an install.

- SemVer on the whole repo per `CONVENTIONS/GITHUB/RELEASES/VERSIONING.md`; tags per `CONVENTIONS/GITHUB/RELEASES/TAGS.md`.
- The public contract is: rule paths, core and category names, index schema (`META/schema/index.schema.json`), install path and `install.sh` commands.
- Ecosystem eras (`SZMELC/README.md`) and layout generations named in commit history (v2, v3 taxonomy) are not SemVer.

| Bump | When |
|---|---|
| Major | Rule path renamed or removed, core or category renamed, `index.json` schema break, install path or `install.sh` command changed |
| Minor | New rule, category or core; experimental rule promoted; new generated format |
| Patch | Wording, fixes, examples, experimental-only changes, docs and tooling with no contract change |

## Release
- Tag `main` after green CI; GitHub release with the bundle assets `CONVENTIONS.md`, `INDEX.md`, `index.json`, `llms.txt`, `SKILL.md` plus `SHA256SUMS` (`CONVENTIONS/GITHUB/RELEASES/AUTOMATION.md`).
- Run: annotated tag with the `CHANGELOG.md` section as message, `git push origin vX.Y.Z`; `.github/workflows/release.yml` calls `META/tools/release.sh` (local `--dry-run` first).
- Notes list moved and removed paths first, so pinned users know what breaks.
- Release cadence: on demand, when a batch of merged changes is worth pinning; `main` stays the rolling channel.

## Pinning
- Default install tracks `main`.
- Pin: `git -C ~/.config/szmelc/conventions checkout vX.Y.Z` (detached HEAD; `pull` stops working).
- Unpin: `git -C ~/.config/szmelc/conventions checkout main && git -C ~/.config/szmelc/conventions pull`.
- Re-run `install.sh` after a major bump.
