---
id: conventions.github.releases.channels
---
# Release channels
> Load when: deciding where a build is published: stable, pre-release, experimental or nightly.

| Channel | Built from | Tag | GitHub release |
|---|---|---|---|
| Stable | `main` | `vX.Y.Z` | Normal, marked Latest |
| Pre-release | `main` | `vX.Y.Z-rc.N` | `--prerelease` |
| Experimental | any other branch | none | none |
| Nightly (optional) | `main`, scheduled | `nightly`, rolling | `--prerelease --latest=false` |

- Latest = newest stable; never mark a pre-release or nightly as latest.
- Experimental: `-ex` in package name or version, installs next to stable; ships as workflow artifacts or a package channel (Arch: `CONVENTIONS/PACKAGING/ARCH.md`).
- Nightly is the only tag and release that is re-created: `gh release delete nightly --cleanup-tag -y`, then `gh release create nightly --target main --prerelease --latest=false`.
- Nightly only when people test unreleased builds; skip the run when `main` has not changed.
- Install docs point at stable; other channels are opt-in.
